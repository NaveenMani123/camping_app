import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/appColors.dart';
import '../../../profile/presentation/providers/user.provider.dart';
import '../../../profile/presentation/screens/other_user_profile.screen.dart';

class CommentImageInfo {
  final Map<String, dynamic> comment;
  final int imageIndex;

  CommentImageInfo({required this.comment, required this.imageIndex});
}

class ImageGalleryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> comments;
  final Map<String, List<String>> commentImages;
  final int startIndex;

  const ImageGalleryScreen({required this.comments, required this.commentImages, required this.startIndex, super.key});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getTotalImages() {
    return widget.comments.fold(0, (sum, comment) => sum + (widget.commentImages[comment['id']]?.length ?? 0));
  }

  CommentImageInfo _findCommentForIndex(int globalIndex) {
    int accumulated = 0;
    for (var comment in widget.comments) {
      final images = widget.commentImages[comment['id']] ?? [];
      if (globalIndex < accumulated + images.length) {
        return CommentImageInfo(comment: comment, imageIndex: globalIndex - accumulated);
      }
      accumulated += images.length;
    }
    return CommentImageInfo(comment: widget.comments.last, imageIndex: 0);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final commentTime =
        timestamp is Timestamp ? timestamp.toDate() : (timestamp is DateTime ? timestamp : DateTime.now());

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

  @override
  Widget build(BuildContext context) {
    final totalImages = _getTotalImages();
    final screenSize = MediaQuery.of(context).size;
    final imageHeight = screenSize.height * 0.7;
    final comment = _findCommentForIndex(_currentIndex).comment;
    final userProvider = Provider.of<UserProvider>(context);
    final profileImageUrl = userProvider.getProfileImage(comment['userId']);
    if (profileImageUrl == null) {
      userProvider.fetchProfileImage(comment['userId']);
    }
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OtherUserProfileScreen(userId: comment['userId'])),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF638773),
                      backgroundImage:
                          (profileImageUrl != null && profileImageUrl.isNotEmpty)
                              ? NetworkImage(profileImageUrl)
                              : null,

                      child:
                          (profileImageUrl == null || profileImageUrl.isEmpty)
                              ? Text(
                                (comment['userName'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                              : null,
                    ),
                  ),
                ),
                Text(
                  comment['userName'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 10),
                Text(_formatTimestamp(comment['timestamp']), style: TextStyle(fontSize: 12, color: AppColors.appColor)),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 16),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: totalImages,
                      onPageChanged: (index) => setState(() => _currentIndex = index),
                      itemBuilder: (context, index) {
                        final info = _findCommentForIndex(index);
                        final imageUrl = widget.commentImages[info.comment['id']]![info.imageIndex];

                        return InteractiveViewer(
                          child: Image.network(
                            height: imageHeight,
                            imageUrl,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  if (_currentIndex > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: _buildArrowButton(Icons.arrow_back_ios, Alignment.centerLeft, () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }),
                    ),
                  if (_currentIndex < totalImages - 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildArrowButton(Icons.arrow_forward_ios, Alignment.centerRight, () {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCommentCard(_findCommentForIndex(_currentIndex).comment),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, Alignment alignment, VoidCallback onTap) {
    return Align(
      alignment: alignment,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black, size: 14),
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((comment['text'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                comment['text'],
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ),
        ],
      ),
    );
  }
}
