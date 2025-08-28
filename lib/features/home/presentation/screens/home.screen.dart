import 'dart:async';
import 'package:campign_project/features/profile/presentation/providers/user.provider.dart';
import 'package:campign_project/core/widgets/resuable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../../../core/constants/appColors.dart';
import '../../../sites/presentation/models/distance.model.dart';
import '../../../sites/provider/site.provider.dart';
import '../../../search/presentation/screens/search.screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../sites/presentation/screens/site.screen.dart';
import '../../../users/repository/user.repository.dart';
import '../../../sites/presentation/models/site.model.dart';
import '../../../auth/repository/auth.repository.dart';
import '../../../sites/presentation/screens/add_form.screen.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: 'home_screen'),
      builder: (context) => const HomeScreen(),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  double? _userLat;
  double? _userLng;
  bool _locLoading = true;
  bool _hasLocationError = false;
  late final UserRepository userRepo;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Position>? _locationSubscription;
  final TextEditingController searchController = TextEditingController();
  late AnimationController _searchBarAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _searchBarOpacityAnimation;
  late Animation<double> _searchIconOpacityAnimation;
  late Animation<double> _fabTextOpacityAnimation;
  late Animation<double> _fabWidthAnimation;

  double _fabCollapseProgress = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentUser!.uid;

    _searchBarAnimationController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);

    _fabAnimationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _searchBarOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _searchBarAnimationController, curve: Curves.easeInOut));

    _searchIconOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _searchBarAnimationController, curve: Curves.easeInOut));
    _fabTextOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _searchBarAnimationController, curve: Curves.easeInOut));

    _fabWidthAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut));

    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().getUser(uid);
    });
    userRepo = UserRepository();
    _fetchLocation();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _locationSubscription?.cancel();
    _searchBarAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;

    final scrollOffset = _scrollController.offset;

    final searchBarProgress = (scrollOffset / 60).clamp(0.0, 1.0);
    _searchBarAnimationController.value = searchBarProgress;

    final fabCollapseStart = 100.0;
    final fabCollapseEnd = 300.0;
    final fabCollapseProgress = ((scrollOffset - fabCollapseStart) / (fabCollapseEnd - fabCollapseStart)).clamp(
      0.0,
      1.0,
    );

    setState(() {
      _fabCollapseProgress = fabCollapseProgress;
    });
  }

  final List<Map<String, String>> categories = [
    {'name': 'Shaded', 'icon': 'assets/icons/shaded.svg'},
    {'name': 'Fire Pit', 'icon': 'assets/icons/fire_pit.svg'},
    {'name': 'Fishing', 'icon': 'assets/icons/fishing.svg'},
    {'name': 'Camping', 'icon': 'assets/icons/camping.svg'},
  ];

  Future<void> _fetchLocation() async {
    try {
      setState(() {
        _locLoading = true;
        _hasLocationError = false;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled. Please enable location services.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied. Please enable them in settings.');
        return;
      }

      Position? lastKnownPosition;
      try {
        lastKnownPosition = await Geolocator.getLastKnownPosition();
      } catch (e) {
        debugPrint('No last known position: $e');
      }

      Position position;
      if (lastKnownPosition != null) {
        final timeDiff = DateTime.now().difference(lastKnownPosition.timestamp);
        if (timeDiff.inMinutes < 5) {
          position = lastKnownPosition;
        } else {
          // Get fresh position
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
        }
      } else {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
      }

      if (!mounted) return;

      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _locLoading = false;
        _hasLocationError = false;
      });

      context.read<SiteProvider>().setUserLocation(position.latitude, position.longitude);
      _startLocationUpdates();
    } catch (e) {
      if (!mounted) return;
      _showLocationError('Failed to get location: ${e.toString()}');
      debugPrint('Location error: $e');
    }
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100,
      ),
    ).listen(
      (Position position) {
        if (mounted) {
          setState(() {
            _userLat = position.latitude;
            _userLng = position.longitude;
          });
          context.read<SiteProvider>().setUserLocation(position.latitude, position.longitude);
        }
      },
      onError: (e) {
        debugPrint('Location stream error: $e');
      },
    );
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    setState(() {
      _locLoading = false;
      _hasLocationError = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            _fetchLocation();
          },
        ),
      ),
    );
  }


  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchBarOpacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _searchBarOpacityAnimation.value,
          child: CustomSearchBar(
            controller: searchController,
            onTap: () async {
              FocusScope.of(context).unfocus();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen(userLat: _userLat, userLng: _userLng)),
              );
              if (mounted && _userLat != null && _userLng != null) {
                context.read<SiteProvider>().setUserLocation(_userLat!, _userLng!);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildLocationErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.red[400]),
          const SizedBox(height: 12),
          Text(
            'Location Access Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'This app needs location access to show nearby camping sites. Please enable location services and grant permission.',
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                icon: Icon(Icons.settings),
                label: Text('Settings'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: _fetchLocation,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.read<AuthRepository>();
    final user = auth.currentUser;
    final isWide = MediaQuery.of(context).size.width > 600;
    final screenWidth = MediaQuery.of(context).size.width;
    final expandedFabWidth = screenWidth * 0.4;
    final collapsedFabWidth = 56.0;

    final currentFabWidth = collapsedFabWidth + (expandedFabWidth - collapsedFabWidth) * (1.0 - _fabCollapseProgress);

    final isFabCollapsed = _fabCollapseProgress > 0.9;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Campgrounds',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: AnimatedBuilder(
          animation: _searchIconOpacityAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _searchIconOpacityAnimation.value,

              child: IconButton(icon: SvgPicture.asset('assets/icons/search.svg'), onPressed: () {}),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              child: SvgPicture.asset('assets/icons/person_1.svg', width: 48, height: 48),
              onTap: () => Navigator.push(context, UserProfileScreen.route()),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                _locLoading
                    ? CustomLoadingIndicator(text: 'Getting your location...')
                    : _hasLocationError
                    ? _buildLocationErrorWidget()
                    : _buildContent(user),
          ),
        ],
      ),
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        width: currentFabWidth,
        child:
            _fabCollapseProgress > 0.9
                ? FloatingActionButton(
                  backgroundColor: const Color(0xFF638773),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFormScreen()));
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SvgPicture.asset('assets/icons/contribute.svg', width: 24, height: 24),
                )
                : FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF638773),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFormScreen()));
                  },
                  label: ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: ((1.0 - _fabCollapseProgress).clamp(0.0, 1.0)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              'Contribute'.split('').asMap().entries.map((entry) {
                                final index = entry.key;
                                final char = entry.value;

                                final total = 'Contribute'.length;
                                final fadeProgress = (_fabCollapseProgress * (total + 1) - (total - index)).clamp(
                                  0.0,
                                  1.0,
                                );
                                final opacity = 1.0 - fadeProgress;

                                return Opacity(
                                  opacity: 1.0 - _fabCollapseProgress,
                                  child: Text(
                                    char,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                  icon: SvgPicture.asset('assets/icons/contribute.svg', width: 24, height: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
      ),
    );
  }

  Widget _buildContent(User? user) {
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildNearbySection(user),
            _buildTrendingSection(user),
            _buildCategorySection(),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbySection(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 24),
          child: const Text(
            'Nearby',
            style: TextStyle(color: Color(0xFF121714), fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 240,
          child: StreamBuilder<List<SiteDistanceModel>>(
            stream: context.watch<SiteProvider>().nearbySitesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CustomLoadingIndicator(text: 'Getting Nearby location...');
              }

              if (snapshot.hasError) {
                return ErrorStateView(
                  message: 'Failed to load Nearby sites',
                  onRetry: () {
                    if (_userLat != null && _userLng != null) {
                      context.read<SiteProvider>().setUserLocation(_userLat!, _userLng!);
                    }
                  },
                );
              }

              final nearbySites = snapshot.data ?? [];

              if (nearbySites.isEmpty) {
                return EmptyStateView(message: 'No Nearby locations found');
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: nearbySites.length,
                itemBuilder: (context, index) {
                  final entry = nearbySites[index];
                  final site = entry.sites;

                  return _NearBySites(
                    site: site,
                    isMine: site.userId == user?.uid,
                    siteImages: entry,
                    distanceMeters: entry.distanceMeters,
                    distanceLabel: entry.distanceLabel,
                    onTap: () async {
                      if (user != null) {
                        try {
                          context.read<SiteProvider>().registerSiteView(site.id, user.uid);
                        } catch (e) {
                          debugPrint("[ERROR] Failed to register site view: $e");
                        }
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SiteDetailsScreen(site: site, sites: entry)),
                      );
                    },
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 12),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 24),
          child: const Text(
            'Trending',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 22),
          ),
        ),
        StreamBuilder<List<SiteDistanceModel>>(
          stream: context.watch<SiteProvider>().nearbySitesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CustomLoadingIndicator(text: 'Getting Trending location');
            }

            if (snapshot.hasError) {
              return ErrorStateView(
                message: 'Failed to load trending locations',
                onRetry: () {
                  if (_userLat != null && _userLng != null) {
                    context.read<SiteProvider>().setUserLocation(_userLat!, _userLng!);
                  }
                },
              );
            }

            final trendingSites = snapshot.data ?? [];

            if (trendingSites.isEmpty) {
              return EmptyStateView(message: 'No trending locations found');
            }
            final topTrending = trendingSites.take(5).toList();

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: topTrending.length,
              itemBuilder: (context, index) {
                final entry = topTrending[index];
                final site = entry.sites;

                return _TrendingSites(
                  site: site,
                  siteImages: entry,
                  distanceMeters: entry.distanceMeters,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SiteDetailsScreen(site: site, sites: entry)),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 20),
          child: const Text(
            'Explore by category',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 20),
          ),
        ),
        SizedBox(height: 24),
        SizedBox(height: 160, width: screenWidth, child: CategoryGrid(categories: categories)),
      ],
    );
  }
}

class _NearBySites extends StatelessWidget {
  final SiteModel site;
  final SiteDistanceModel siteImages;
  final bool isMine;
  final double distanceMeters;
  final String? distanceLabel;
  final void Function()? onTap;

  const _NearBySites({
    required this.site,
    required this.isMine,
    required this.siteImages,
    required this.distanceMeters,
    this.distanceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 240,
        width: isWide ? 350 : 240,
        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child:
                      siteImages.imageUrls.isNotEmpty
                          ? FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: siteImages.imageUrls.first,
                            height: isWide ? 180 : 135,
                            width: 240,
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
                            height: isWide ? 180 : 135,
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
                    Text(site.siteName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      distanceLabel ?? '${(distanceMeters / 1000).toStringAsFixed(2)} kms away',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF638773), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        site.description,
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

class _TrendingSites extends StatelessWidget {
  final SiteModel site;
  final SiteDistanceModel siteImages;
  final double distanceMeters;
  final void Function()? onTap;

  const _TrendingSites({
    required this.site,
    required this.distanceMeters,
    required this.siteImages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final cardWidth = isWide ? 358.0 : MediaQuery.of(context).size.width - 32;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(color: Colors.transparent),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            site.siteName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      site.description,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF638773), fontWeight: FontWeight.w400),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Container(
                width: isWide ? 200 : 130,
                height: isWide ? 150 : 91,
                color: Colors.grey[200],
                child:
                    siteImages.imageUrls.isNotEmpty
                        ? FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: siteImages.imageUrls.first,
                          fit: BoxFit.cover,
                          width: isWide ? 200 : 130,
                          height: isWide ? 150 : 91,
                          imageErrorBuilder:
                              (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 40)),
                        )
                        : const Center(child: Icon(Icons.image, size: 40)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryGrid extends StatefulWidget {
  final List<Map<String, String>> categories;

  const CategoryGrid({super.key, required this.categories});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  final Set<int> selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseDesignWidth = 390.0;
    final containerWidth = screenWidth * (173 / baseDesignWidth);
    final containerHeight = screenWidth * (58 / baseDesignWidth);

    final isWide = screenWidth > 600;
    final crossAxisCount = isWide ? 3 : 2;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.categories.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 3.5 : 3,
      ),
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        final name = category['name'] ?? 'Category';
        final iconPath = category['icon'] ?? '';

        final isSelected = selectedIndices.contains(index);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedIndices.remove(index);
              } else {
                selectedIndices.add(index);
              }
            });
          },
          child: Container(
            width: containerWidth,
            height: containerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.borderColor : Colors.transparent,
              border: Border.all(color: const Color(0xFFDBE5DE), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: Colors.black,
                  placeholderBuilder: (context) => const SizedBox(width: 24, height: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
