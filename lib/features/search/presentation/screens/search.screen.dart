import 'package:campign_project/features/sites/provider/site.provider.dart';
import 'package:campign_project/core/widgets/resuable_widgets.dart';
import 'package:campign_project/features/search/presentation/screens/ratings.screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../../maps/presentation/screens/map_screen.dart';
import '../../../sites/presentation/models/site.model.dart';
import '../../../sites/presentation/screens/site.screen.dart';
import 'category.screen.dart';
import '../../../sites/presentation/models/distance.model.dart';

class SearchScreen extends StatefulWidget {
  final double? userLat;
  final double? userLng;

  const SearchScreen({this.userLat, this.userLng, super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  List<String> selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      context.read<SiteProvider>().setSearchQuery(_controller.text.trim());
    });
    if (widget.userLat != null && widget.userLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
        context.read<SiteProvider>().setUserLocation(widget.userLat!, widget.userLng!);
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radiusProvider = context.watch<SiteProvider>();
    final radiusKm = radiusProvider.radiusKm;
    final userLat = widget.userLat;
    final userLng = widget.userLng;
    final isCategorySelected = radiusProvider.selectedCategories.isNotEmpty;
    final count = isCategorySelected ? radiusProvider.filteredSitesLength : radiusProvider.sitesLength;

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          centerTitle: true,
          title: const Text("Search", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomSearchBar(controller: _controller, focusNode: _searchFocusNode),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (userLat == null || userLng == null) return;
                      await showDialog<double>(
                        context: context,
                        builder: (_) => RadiusMapDialog(initialLocation: LatLng(userLat, userLng)),
                      );
                    },
                    child: InfoItem(text: '${context.read<SiteProvider>().radiusKm.toStringAsFixed(0)} kms'),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog<double>(context: context, builder: (_) => RatingsScreen());
                    },
                    child: InfoItem(text: 'Ratings'),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final selected = await showDialog<List<String>>(
                        context: context,
                        builder: (_) => CategoryScreen(preSelectedCategories: radiusProvider.selectedCategories),
                      );
                      if (selected != null) {
                        context.read<SiteProvider>().setSelectedCategories(selected);
                      }
                    },
                    child: InfoItem(text: 'Category'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '$count options in ${radiusKm.toStringAsFixed(0)} kms',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const TabBar(
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              labelColor: Color(0xFF638773),
              unselectedLabelColor: Colors.black,
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              indicator: UnderlineTabIndicator(borderSide: BorderSide(color: Color(0xFFE5E8EB), width: 3.5)),
              dividerColor: Color(0xFFDBE5DE),
              dividerHeight: 1.0,

              tabs: [Tab(text: 'List')],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SafeArea(
                child: TabBarView(
                  children: [
                    StreamBuilder<List<SiteDistanceModel>>(
                      stream: radiusProvider.nearbySitesStream,
                      builder: (context, snapshot) {
                        if (userLat == null || userLng == null) {
                          return const Center(child: Text('Location not available'));
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CustomLoadingIndicator(text: 'Getting Trending location');
                        }

                        if (snapshot.hasError) {
                          return ErrorStateView(
                            message: 'Failed to load trending sites',
                            onRetry: () {
                              context.read<SiteProvider>().setUserLocation(userLat, userLng);
                            },
                          );
                        }

                        final trendingSites = snapshot.data ?? [];
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          context.read<SiteProvider>().setTrendingSites(trendingSites);
                        });

                        final filteredSites = context.watch<SiteProvider>().filteredSites;

                        if (filteredSites.isEmpty) {
                          return const EmptyStateView(message: 'No sites found');
                        }

                        return ListView.separated(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                          ),
                          itemCount: filteredSites.length,
                          itemBuilder: (context, index) {
                            final entry = filteredSites[index];
                            return _SearchScreenSites(
                              site: entry.sites,
                              siteImages: entry,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => SiteDetailsScreen(sites: entry, site: entry.sites)),
                                );
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                        );
                      },
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

class InfoItem extends StatelessWidget {
  final String text;

  const InfoItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.28,
      height: screenHeight * 0.04,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: const Color(0xFFF0F5F2), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
          ),
          SvgPicture.asset('assets/icons/drop_down.svg'),
        ],
      ),
    );
  }
}

class _SearchScreenSites extends StatelessWidget {
  final SiteModel site;
  final SiteDistanceModel siteImages;
  final void Function()? onTap;
  const _SearchScreenSites({super.key, required this.site, required this.siteImages, this.onTap});

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
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Container(
                width: isWide ? 200 : 100,
                height: isWide ? 150 : 56,
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
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(site.siteName, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
