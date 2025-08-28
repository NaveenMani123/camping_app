import 'dart:io';
import 'dart:ui';
import 'package:campign_project/core/widgets/resuable_widgets.dart';
import 'package:campign_project/features/sites/provider/site.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/appColors.dart';
import '../../../profile/presentation/providers/user.provider.dart';
import '../../../profile/presentation/screens/other_user_profile.screen.dart';
import '../models/site.model.dart';
import '../models/distance.model.dart';
import '../../../auth/presentation/screens/image_gallery.screen.dart';

class SiteDetailsScreen extends StatefulWidget {
  final SiteModel site;
  final SiteDistanceModel? sites;
  final String? highlightCommentId;
  const SiteDetailsScreen({required this.site, this.highlightCommentId, this.sites, super.key});

  @override
  State<SiteDetailsScreen> createState() => _SiteDetailsScreenState();
}

class _SiteDetailsScreenState extends State<SiteDetailsScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _hasHighlighted = false;
  bool _isCommentUploading = false;

  bool _isLoadingMore = false;
  bool _isLoading = false;
  bool _hasMoreComments = true;
  String? replyingToCommentId;
  String? replyingToReplyId;
  int currentIndex = 0;
  List<Map<String, dynamic>> _comments = [];
  Map<String, List<Map<String, dynamic>>> _replies = {};
  Map<String, List<String>> _commentImages = {};

  DocumentSnapshot? _lastComment;
  static const int _commentsPerPage = 2;

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedCommentMedia = [];

  @override
  void initState() {
    super.initState();
    _loadInitialComments();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlightedComment());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlightedComment() {
    if (widget.highlightCommentId == null || _comments.isEmpty || _hasHighlighted) return;

    final idx = _comments.indexWhere((c) => c['id'] == widget.highlightCommentId);
    if (idx != -1) {
      _hasHighlighted = true;
      _scrollController.animateTo(idx * 200.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  Future<void> _loadInitialComments() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final query = FirebaseFirestore.instance
          .collection('sites')
          .doc(widget.site.id)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .limit(_commentsPerPage);

      final snap = await query.get();

      if (snap.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _comments = [];
          _hasMoreComments = false;
        });
        return;
      }

      final comments = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      _lastComment = snap.docs.last;
      _hasMoreComments = snap.docs.length == _commentsPerPage;

      await _loadCommentDetails(comments);

      setState(() {
        _isLoading = false;
        _comments = comments;
      });
    } catch (e) {
      debugPrint('Error loading initial comments: $e');
    }
  }

  Future<void> _navigateToSite(BuildContext context) async {
    debugPrint('[Navigation] Started navigation process');
    _showLoadingDialog(context);
    try {
      setState(() {
        _isLoading = true;
      });
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

      final destinationLat = widget.site.latitude;
      final destinationLng = widget.site.longitude;

      final googleMapUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${position.latitude},${position.longitude}'
        '&destination=$destinationLat,$destinationLng'
        '&travelmode=driving',
      );
      debugPrint('[Navigation] Constructed URL: $googleMapUrl');

      if (await canLaunchUrl(googleMapUrl)) {
        await launchUrl(googleMapUrl);
      } else {
      }
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Navigation] Error occurred: $e');
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMoreComments || _lastComment == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final query = FirebaseFirestore.instance
          .collection('sites')
          .doc(widget.site.id)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastComment!)
          .limit(_commentsPerPage);

      final snap = await query.get();

      if (snap.docs.isEmpty) {
        setState(() {
          _hasMoreComments = false;
          _isLoadingMore = false;
        });
        return;
      }

      final newComments = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      _lastComment = snap.docs.last;
      _hasMoreComments = snap.docs.length == _commentsPerPage;

      await _loadCommentDetails(newComments);

      setState(() {
        _comments.addAll(newComments);
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more comments: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => WillPopScope(
            onWillPop: () async => false,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: Colors.black.withOpacity(0.6),
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 20),
                      Text("Please wait ", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _loadCommentDetails(List<Map<String, dynamic>> comments) async {
    for (var comment in comments) {
      final commentId = comment['id'];

      final imageSnap =
          await FirebaseFirestore.instance
              .collection('sites')
              .doc(widget.site.id)
              .collection('comments')
              .doc(commentId)
              .collection('commentImages')
              .orderBy('timestamp')
              .get();

      final images = imageSnap.docs.map((d) => d.data()['imageUrl'] as String).toList();
      _commentImages[commentId] = images;

      final replySnap =
          await FirebaseFirestore.instance
              .collection('sites')
              .doc(widget.site.id)
              .collection('comments')
              .doc(commentId)
              .collection('replies')
              .orderBy('timestamp')
              .get();

      final replies = replySnap.docs.map((r) => {...r.data(), 'id': r.id}).toList();
      _replies[commentId] = replies;
    }
  }

  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_${basename(file.path)}');

    final stopwatch = Stopwatch()..start();
    final result = await FlutterImageCompress.compressAndGetFile(file.absolute.path, targetPath, quality: 80);
    stopwatch.stop();
    debugPrint('Compressed in: ${stopwatch.elapsedMilliseconds} ms');

    return result != null ? File(result.path) : null;
  }

  Future<void> _pickCommentMedia() async {
    final media = await _picker.pickMultiImage();
    if (media.isNotEmpty) {
      final List<File> compressedFiles = [];

      for (final image in media) {
        final originalFile = File(image.path);
        final safeDir = await getApplicationDocumentsDirectory();
        final safePath = join(safeDir.path, basename(originalFile.path));
        final safeFile = await originalFile.copy(safePath);
        final compressed = await _compressImage(safeFile);
        if (compressed != null) {
          compressedFiles.add(compressed);
        }
      }

      setState(() {
        _selectedCommentMedia = compressedFiles;
      });
    }
  }

  void shareSite(String siteId) {
    final url = 'https://mycampingapp.web.app/site?id=$siteId';
    Share.share('Check out this campsite: $url');
  }

  Future<String?> _uploadFile(String path, File file) async {
    try {
      if (!(await file.exists()) || await file.length() == 0) return null;
      final ref = FirebaseStorage.instance
          .ref()
          .child(path)
          .child('${DateTime.now().millisecondsSinceEpoch}_${basename(file.path)}');
      final snap = await ref.putFile(
        file,
        SettableMetadata(contentType: file.path.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg'),
      );
      return await snap.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _addComment(BuildContext context) async {
    final user = _auth.currentUser;
    final text = _commentController.text.trim();
    if (user == null) return;

    setState(() => _isCommentUploading = true);
    _showLoadingDialog(context);

    try {
      final userName = Provider.of<UserProvider>(context, listen: false).user?.name ?? 'Anonymous';

      final commentRef = await FirebaseFirestore.instance
          .collection('sites')
          .doc(widget.site.id)
          .collection('comments')
          .add({
            'userId': user.uid,
            'userName': userName,
            'text': text,
            'likes': [],
            'dislikes': [],
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (_selectedCommentMedia.isNotEmpty) {
        final uploadFutures = _selectedCommentMedia.map((file) => _uploadFile('commentImages', file));
        final imageUrls = await Future.wait(uploadFutures);

        for (final url in imageUrls) {
          if (url != null) {
            await FirebaseFirestore.instance
                .collection('sites')
                .doc(widget.site.id)
                .collection('comments')
                .doc(commentRef.id)
                .collection('commentImages')
                .add({
                  'imageUrl': url,
                  'uploaderId': user.uid,
                  'commentId': commentRef.id,
                  'uploaderName': userName,
                  'timestamp': FieldValue.serverTimestamp(),
                });
          }
        }
      }

      _commentController.clear();
      _selectedCommentMedia.clear();
      if (context.mounted) {
      }
      await _loadInitialComments();
    } catch (e) {
      debugPrint('Error adding comment: $e');
    } finally {
      setState(() => _isCommentUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // blur strength
            child: Container(color: Colors.white.withOpacity(0.2)), // tint
          ),
        ),
        elevation: 0,
        forceMaterialTransparency: true,
        backgroundColor: Colors.black.withOpacity(0.2),
        actions: [
          IconButton(
            onPressed: () {
              shareSite(widget.site.id);
            },
            icon: SvgPicture.asset('assets/icons/share.svg'),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(site.siteName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))],
            ),
          ),
          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              site.description,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 20),

          if (_comments.isEmpty && !_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No comments yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Be the first to share your experience!', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          if (_isLoading) CustomLoadingIndicator(text: 'Comments are loading please wait...'),
          ...List.generate(_comments.length, (idx) {
            final comment = _comments[idx];
            final replies = _replies[comment['id']] ?? [];
            final images = _commentImages[comment['id']] ?? [];
            final isCurrentUser = _auth.currentUser?.uid == comment['userId'];
            final liked = (comment['likes'] as List).contains(_auth.currentUser?.uid);
            final disliked = (comment['dislikes'] as List).contains(_auth.currentUser?.uid);

            return _buildCommentTile(context, comment, replies, images, isCurrentUser, liked, disliked);
          }),

          if (_hasMoreComments) _buildLoadMoreButton(),
          _buildCommentInput(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child:
            _isLoadingMore
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _loadMoreComments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF638773),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Load More Comments'),
                ),
      ),
    );
  }

  void _openImageGallery(BuildContext context, String commentId, List<String> images) {
    final galleryComments = _comments.where((c) => (_commentImages[c['id']]?.isNotEmpty ?? false)).toList();

    if (galleryComments.isEmpty) return;

    int startIndex = 0;
    bool found = false;

    for (var comment in galleryComments) {
      final commentImages = _commentImages[comment['id']]!;
      if (comment['id'] == commentId) {
        found = true;
        break;
      }
      startIndex += commentImages.length;
    }

    if (!found) startIndex = 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ImageGalleryScreen(comments: galleryComments, commentImages: _commentImages, startIndex: startIndex),
      ),
    );
  }

  Widget _buildCommentTile(
    BuildContext context,
    Map<String, dynamic> comment,
    List<Map<String, dynamic>> replies,
    List<String> images,
    bool isOwner,
    bool liked,
    bool disliked,
  ) {
    final userProvider = Provider.of<UserProvider>(context);
    final profileImageUrl = userProvider.getProfileImage(comment['userId']);
    if (profileImageUrl == null) {
      userProvider.fetchProfileImage(comment['userId']);
    }
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OtherUserProfileScreen(userId: comment['userId'])),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor:
                  (profileImageUrl != null && profileImageUrl.isNotEmpty)
                      ? Colors.transparent
                      : const Color(0xFF638773),
              backgroundImage:
                  (profileImageUrl != null && profileImageUrl.isNotEmpty) ? NetworkImage(profileImageUrl) : null,
              child:
                  (profileImageUrl == null || profileImageUrl.isEmpty)
                      ? Text(
                        (comment['userName'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                      : null,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['userName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatTimestamp(comment['timestamp']),
                      style: TextStyle(color: AppColors.appColor, fontSize: 13, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (images.isNotEmpty) _buildImageGrid(context, images, comment['id']),
                SizedBox(height: 10),
                if (comment['text']?.isNotEmpty == true) Text(comment['text'], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '${replies.length} comments',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.appColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<String> images, String commentId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = 4.0;
    final imageHeight = screenWidth * 0.5;

    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _openImageGallery(context, commentId, images),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            images[0],
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: imageHeight,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      );
    }

    if (images.length == 2) {
      return SizedBox(
        height: imageHeight * 0.57,
        child: Row(
          children: List.generate(2, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 1 ? spacing : 0),
                child: GestureDetector(
                  onTap: () => _openImageGallery(context, commentId, images),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }
    return SizedBox(
      height: imageHeight,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageGallery(context, commentId, images),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  images[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator()));
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              children: [
                for (int i = 1; i < 3; i++) ...[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: i == 2 ? 0 : spacing),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () => _openImageGallery(context, commentId, images),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                images[i],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (i == 2 && images.length > 3)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _openImageGallery(context, commentId, images),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: const Color(0x85000000), shape: BoxShape.circle),
                                  child: Text(
                                    '+${images.length - 3}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[300]!))),
      child: Column(
        children: [
          _selectedCommentMedia.isNotEmpty
              ? Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      _selectedCommentMedia
                          .map(
                            (file) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(file, height: 80, width: 80, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedCommentMedia.remove(file);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              )
              : SizedBox.shrink(),
          // Input Row
          Row(
            children: [
              IconButton(icon: const Icon(Icons.photo), onPressed: _pickCommentMedia),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isCommentUploading
                  ? const CircularProgressIndicator()
                  : IconButton(icon: const Icon(Icons.send), onPressed: () => _addComment(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircularIconButton(label: 'Navigate', iconName: 'navigate', onPressed: () => _navigateToSite(context)),
            CircularIconButton(label: 'Comment', iconName: 'comment', onPressed: () {}),
            Consumer<SiteProvider>(
              builder: (context, siteProvider, child) {
                final isSaved = siteProvider.isSiteSaved(widget.site.id);
                return CircularIconButton(
                  label: isSaved ? 'Saved' : 'Save',
                  iconName: 'save',
                  onPressed: () async {
                    try {
                      await siteProvider.toggleSavedSite(widget.site.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isSaved ? 'Removed from saved' : 'Saved successfully'),
                          backgroundColor: isSaved ? Colors.red : Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('failed to save the site'), backgroundColor: Colors.red));
                    }
                  },
                );
              },
            ),
            CircularIconButton(label: 'Improve', iconName: 'improve', onPressed: () {}),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final commentTime = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    final difference = now.difference(commentTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class CircularIconButton extends StatelessWidget {
  final String label;
  final String iconName;
  final VoidCallback onPressed;

  const CircularIconButton({super.key, required this.label, required this.iconName, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: const Color(0xFFF0F5F2), borderRadius: BorderRadius.circular(20)),
              child: SvgPicture.asset('assets/icons/$iconName.svg', fit: BoxFit.scaleDown, width: 20, height: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
