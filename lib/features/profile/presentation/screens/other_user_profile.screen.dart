import 'package:campign_project/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../../../core/constants/appColors.dart';
import '../../../sites/presentation/models/site.model.dart';
import '../../../sites/presentation/models/distance.model.dart';
import '../../../sites/presentation/screens/site.screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _uploadedSites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndSites();
  }

  Future<void> _loadProfileAndSites() async {
    setState(() => _isLoading = true);

    try {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

      if (!userSnapshot.exists) {
        throw Exception("User not found");
      }

      final userData = userSnapshot.data()!;
      _userData = userData;

      final uploadedSiteIds = List<String>.from(userData['uploadedSites'] ?? []);
      if (uploadedSiteIds.isNotEmpty) {
        final siteFutures = uploadedSiteIds.map((siteId) async {
          final siteSnapshot = await FirebaseFirestore.instance.collection('sites').doc(siteId).get();
          if (siteSnapshot.exists) {
            return siteSnapshot.data()!..['id'] = siteSnapshot.id;
          }
          return null;
        });

        final sites = await Future.wait(siteFutures);
        _uploadedSites = sites.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> openSiteScreen(BuildContext context, String siteId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('sites').doc(siteId).get();

      if (!doc.exists) {
        throw Exception("Site not found");
      }

      final site = SiteModelMapper.fromMap(doc.data()!);

      final imageUrls = List<String>.from(doc['coverImages'] ?? []);

      final siteDistance = SiteDistanceModel(sites: site, distanceMeters: 0, imageUrls: imageUrls);

      Navigator.push(context, MaterialPageRoute(builder: (_) => SiteDetailsScreen(site: site, sites: siteDistance)));
    } catch (e) {
      debugPrint("Error loading site: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load site")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadProfileAndSites,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_userData != null) _buildProfileHeader(_userData!),
                      const SizedBox(height: 20),
                      _buildUploadedSitesSection(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.grey[200],
              backgroundImage: user['profileImageUrl'] != null ? NetworkImage(user['profileImageUrl']) : null,
              child:
                  user['profileImageUrl'] == null
                      ? Text(
                        (user['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                      )
                      : null,
            ),
          ),
        ),
        Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(
          'Joined in ${DateTime.fromMillisecondsSinceEpoch(user['createdAt'].millisecondsSinceEpoch).year}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.appColor),
        ),

        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UploadedSites(text: '${_uploadedSites.length}', label: 'Listings'),
              UploadedSites(text: '${(user['savedSites'] as List?)?.length ?? 0}', label: 'Saved'),
              UploadedSites(text: '0', label: 'Verifications'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedSitesSection() {
    if (_uploadedSites.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No uploaded sites found", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Listings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _uploadedSites.length,
          itemBuilder: (context, index) {
            final site = _uploadedSites[index];
            return SavedSiteCard(
              siteName: site['siteName'],
              imageUrls: site['coverImages'],
              onTap: () {
                openSiteScreen(context, site['id']);
              },
            );
          },
        ),
      ],
    );
  }
}


class SavedSiteCard extends StatelessWidget {
  final String siteName;
  final String? description;
  final String? address;
  final List<dynamic> imageUrls;
  final bool isWide;
  final double? distanceMeters;
  final String? distanceLabel;
  final VoidCallback onTap;

  const SavedSiteCard({
    super.key,
    required this.siteName,
    this.description,
    this.address,
    required this.imageUrls,
    this.isWide = false,
    this.distanceMeters,
    this.distanceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 187,
        width: isWide ? 350 : 173,
        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(siteName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                    const SizedBox(height: 2),
                    if (description != null)
                      Expanded(
                        child: Text(
                          description!,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF638773), fontWeight: FontWeight.w400),
                          maxLines: 3,
                          softWrap: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child:
                      imageUrls.isNotEmpty
                          ? FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: imageUrls.first,
                            height: isWide ? 180 : 70,
                            width: 130,
                            fit: BoxFit.cover,
                            imageErrorBuilder:
                                (context, error, stackTrace) => Container(
                                  height: isWide ? 180 : 70,
                                  width: 130,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, size: 40),
                                ),
                          )
                          : Container(
                            height: isWide ? 180 : 70,
                            width: 130,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
