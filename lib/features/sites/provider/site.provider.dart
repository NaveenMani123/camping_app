import 'package:campign_project/features/sites/repository/site.repository.dart';
import 'package:flutter/material.dart';
import '../../users/presentation/models/user.model.dart';
import '../presentation/models/distance.model.dart';

class SiteProvider extends ChangeNotifier {
  final SiteRepository siteRepository;
  SiteProvider({required this.siteRepository});
  UserModel? _user;
  double _radiusKm = 500;

  double? _userLat;
  double? _userLng;
  int? _sitesLength;
  bool _isRadiusSelected = false;
  Stream<List<SiteDistanceModel>>? _nearbySitesStream;
  List<SiteDistanceModel> _trendingSites = [];
  String _searchQuery = '';
  List<String> _selectedCategories = [];
  final List<Map<String, dynamic>> _uploadedSiteDocs = [];

  double get radiusKm => _radiusKm;
  double? get userLat => _userLat;
  double? get userLng => _userLng;
  int? get sitesLength => _sitesLength;
  List<SiteDistanceModel> get trendingSites => _trendingSites;
  List<dynamic> get savedSites => _user?.savedSites ?? [];
  List<Map<String, dynamic>> get uploadedSites => _uploadedSiteDocs;
  List<String> get selectedCategories => _selectedCategories;
  Stream<List<SiteDistanceModel>>? get nearbySitesStream => _nearbySitesStream;
  bool get isReady => _userLat != null && _userLng != null && _nearbySitesStream != null;
  List<SiteDistanceModel> get filteredSites {
    return _trendingSites.where((entry) {
      final siteName = entry.sites.siteName.toLowerCase();
      final siteDescription = entry.sites.description.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty || siteName.contains(_searchQuery) || siteDescription.contains(_searchQuery);

      final siteCategories = entry.sites.category ?? [];
      final matchesCategory =
          _selectedCategories.isEmpty || siteCategories.any((cat) => _selectedCategories.contains(cat));

      return matchesSearch && matchesCategory;
    }).toList();
  }

  int get filteredSitesLength => filteredSites.length;

  void setRadius(double newRadius) {
    if (_radiusKm != newRadius) {
      _radiusKm = newRadius;
      _isRadiusSelected = true;
      _updateNearbySitesStream();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void setSelectedCategories(List<String> categories) {
    _selectedCategories = categories;
    notifyListeners();
  }

  void setTrendingSites(List<SiteDistanceModel> sites) {
    _trendingSites = sites;
    notifyListeners();
  }

  Future<void> removeUploadedSite(String userId, String siteId) async {
    if (_user == null) return;
    try {
      final currentSavedSites = _user!.savedSites ?? [];
      final updatedSavedSites = currentSavedSites.where((id) => id != siteId).toList();
      await siteRepository.removeUploadedSite(_user!.uid, siteId);
      _user = _user!.copyWith(uploadedSites: updatedSavedSites);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove uploaded site: $e');
    }
  }

  Future<void> addUploadedSite(String siteId) async {
    if (_user == null) return;

    try {
      final currentUploadedSites = _user!.uploadedSites ?? [];
      final updatedUploadedSites = [...currentUploadedSites, siteId];
      siteRepository.addUploadedSite(_user!.uid, siteId);
      _user = _user!.copyWith(uploadedSites: updatedUploadedSites);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add uploaded site: $e');
      throw Exception('Failed to add uploaded site: $e');
    }
  }

  Future<void> removeSavedSite(String siteId) async {
    if (_user == null) return;

    try {
      final currentSavedSites = _user!.savedSites ?? [];

      if (currentSavedSites.contains(siteId)) {
        final updatedSavedSites = currentSavedSites.where((id) => id != siteId).toList();
        siteRepository.removeSavedSite(_user!.uid, siteId);
        _user = _user!.copyWith(savedSites: updatedSavedSites);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to remove saved site: $e');
      throw Exception('Failed to remove saved site: $e');
    }
  }

  Future<void> addSavedSite(String siteId) async {
    if (_user == null) return;

    try {
      final currentSavedSites = _user!.savedSites ?? [];

      if (!currentSavedSites.contains(siteId)) {
        final updatedSavedSites = [...currentSavedSites, siteId];
        siteRepository.addSavedSite(_user!.uid, siteId);
        _user = _user!.copyWith(savedSites: updatedSavedSites);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to add saved site: $e');
      throw Exception('Failed to add saved site: $e');
    }
  }

  Future<void> toggleSavedSite(String siteId) async {
    if (_user == null) return;

    try {
      final currentSavedSites = _user!.savedSites ?? [];

      if (currentSavedSites.contains(siteId)) {
        await removeSavedSite(siteId);
      } else {
        await addSavedSite(siteId);
      }
    } catch (e) {
      debugPrint('Failed to toggle saved site: $e');
    }
  }

  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    _updateNearbySitesStream();
    notifyListeners();
  }

  void _updateNearbySitesStream() {
    if (_userLat == null || _userLng == null) {
      _nearbySitesStream = null;
      return;
    }
    try {
      _nearbySitesStream = siteRepository.fetchNearbySites(
        userLat: _userLat!,
        userLng: _userLng!,
        radiusKm: radiusKm,
        isRadiusSelected: _isRadiusSelected,
      );
      _nearbySitesStream!.listen((sites) {
        if (_sitesLength != sites.length) {
          _sitesLength = sites.length;
        }
      });
    } catch (e) {
      throw Exception('error occured in fetching sites $e');
    }
  }

  Future<void> registerSiteView(String siteId, String userId) async {
    try {
      await siteRepository.registerSiteView(siteId, userId);
    } catch (e) {
      throw Exception('error occured in site views $e');
    }
  }

  bool isSiteSaved(String siteId) {
    return _user?.savedSites?.contains(siteId) ?? false;
  }

  void clearData() {
    _userLat = null;
    _userLng = null;
    _nearbySitesStream = null;
    notifyListeners();
  }
}
