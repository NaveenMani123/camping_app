import 'package:campign_project/features/profile/presentation/providers/user.provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../../../core/constants/appColors.dart';
import '../../../auth/presentation/screens/help.screen.dart';
import '../../../sites/presentation/models/site.model.dart';
import '../../../sites/presentation/models/distance.model.dart';
import '../../../sites/presentation/screens/site.screen.dart';
import 'profile.screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  static route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: 'user_profile_screen'),
      builder: (context) => UserProfileScreen(),
    );
  }

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<List<Map<String, dynamic>>> _savedSitesFuture;
  late List<dynamic> _savedSiteIds = [];
  late Future<List<Map<String, dynamic>>> _uploadedSitesFuture;
  late List<dynamic> _uploadedSiteIds = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).fetchUserComment();
    });
    _loadSavedSites();
  }

  void _loadSavedSites() {
    final user = context.read<UserProvider>().user;
    _savedSiteIds = user?.savedSites ?? [];
    _uploadedSiteIds = user?.uploadedSites ?? [];
    _uploadedSitesFuture = _uploadedSiteIds.isEmpty ? Future.value([]) : fetchUploadedSites(_uploadedSiteIds);
    _savedSitesFuture = _savedSiteIds.isEmpty ? Future.value([]) : fetchSavedSites(_savedSiteIds);
  }

  Future<List<Map<String, dynamic>>> fetchSavedSites(List<dynamic> ids) async {
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < ids.length; i += 10) {
      final batch = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snapshot =
          await FirebaseFirestore.instance.collection('sites').where(FieldPath.documentId, whereIn: batch).get();

      results.addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }),
      );
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> fetchUploadedSites(List<dynamic> ids) async {
    List<Map<String, dynamic>> results = [];
    for (int i = 0; i < ids.length; i += 10) {
      final batch = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snapshot =
          await FirebaseFirestore.instance.collection('sites').where(FieldPath.documentId, whereIn: batch).get();
      results.addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }),
      );
    }
    return results;
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
    final userProvider = context.watch<UserProvider>();

    if (!userProvider.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading profile...')],
          ),
        ),
      );
    }

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading user data...')],
          ),
        ),
      );
    }

    final user = userProvider.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'User not logged in or failed to load',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (userProvider.error != null) ...[
                Text(
                  'Error: ${userProvider.error}',
                  style: TextStyle(fontSize: 14, color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () {
                  userProvider.refreshUser();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(child: SvgPicture.asset('assets/icons/edit_profile.svg', width: 24, height: 24)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await userProvider.refreshUser();
          setState(() {
            _loadSavedSites();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildProfileHeader(user), const SizedBox(height: 20), _buildSavedSitesSection()],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.appColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => HelpScreen()));
        },
        label: Text('Help', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        icon: SvgPicture.asset('assets/icons/help.svg'),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.grey[200],
              backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
              child:
                  user.profileImageUrl == null
                      ? Text(
                        user.initials,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                      )
                      : null,
            ),
          ),
        ),
        Text(user.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

        Text(
          'Joined in ${user.createdAt?.year}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.appColor),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UploadedSites(text: '${user.uploadedSites?.length ?? 0}', label: 'Listings'),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return UploadedSites(text: '${userProvider.commentCount}', label: 'Comments');
                },
              ),
              UploadedSites(text: '0', label: 'Verifications'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedSitesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Saved', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))],
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _savedSitesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Error loading saved sites', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            }

            final savedSites = snapshot.data ?? [];

            if (savedSites.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/save.svg',
                        width: 64,
                        height: 64,
                        colorFilter: ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved sites yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save your favorite camping sites to see them here',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 220,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: savedSites.length,
                itemBuilder: (context, index) {
                  final site = savedSites[index];
                  return _SaveSiteCard(
                    siteName: site['siteName'] ?? 'Unnamed Site',
                    description: site['description'],
                    address: site['address'],
                    imageUrls: List<String>.from(site['coverImages'] ?? []),
                    isWide: false,
                    onTap: () {
                      openSiteScreen(context, site['id']);
                    },
                    onSaved: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Site saved!'), backgroundColor: Colors.green));
                    },
                    onUnsaved: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Site removed from saved'), backgroundColor: Colors.orange),
                      );
                    },
                  );
                },
                separatorBuilder: (context, index) => SizedBox(width: 12),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _uploadedSitesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Error loading uploaded sites', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            }

            final uploadedSites = snapshot.data ?? [];

            if (uploadedSites.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/save.svg',
                        width: 64,
                        height: 64,
                        colorFilter: ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No uploaded sites yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'upload your favorite camping sites to see them here',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 220,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: uploadedSites.length,
                itemBuilder: (context, index) {
                  final site = uploadedSites[index];
                  return _SaveSiteCard(
                    siteName: site['siteName'] ?? 'Unnamed Site',
                    description: site['description'],
                    address: site['address'],
                    imageUrls: List<String>.from(site['coverImages'] ?? []),
                    isWide: false,
                    onTap: () {
                      openSiteScreen(context, site['id']);
                    },
                    onSaved: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Site saved!'), backgroundColor: Colors.green));
                    },
                    onUnsaved: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Site removed from saved'), backgroundColor: Colors.orange),
                      );
                    },
                  );
                },
                separatorBuilder: (context, index) => SizedBox(width: 12),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SaveSiteCard extends StatelessWidget {
  final String siteName;
  final String? description;

  final String? address;
  final List<String> imageUrls;
  final bool isWide;
  final VoidCallback onTap;
  final VoidCallback onSaved;
  final VoidCallback onUnsaved;

  const _SaveSiteCard({
    required this.siteName,
    this.description,
    this.address,
    required this.imageUrls,
    this.isWide = false,
    required this.onTap,
    required this.onSaved,
    required this.onUnsaved,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 187,
        width: isWide ? 350 : 173,
        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child:
                      imageUrls.isNotEmpty
                          ? FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: imageUrls.first,
                            height: isWide ? 180 : 97,
                            width: 173,
                            fit: BoxFit.cover,
                            imageErrorBuilder:
                                (context, error, stackTrace) => Container(
                                  height: isWide ? 180 : 135,
                                  width: 240,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, size: 40),
                                ),
                          )
                          : Container(
                            height: isWide ? 180 : 97,
                            width: 240,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                ),
              ],
            ),
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
          ],
        ),
      ),
    );
  }
}

class UploadedSites extends StatelessWidget {
  final String text;
  final String label;

  const UploadedSites({required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final containerWidth = screenWidth * 0.28;
        final containerHeight = screenWidth * 0.22;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          height: containerHeight,
          width: containerWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 1, color: AppColors.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.appColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
