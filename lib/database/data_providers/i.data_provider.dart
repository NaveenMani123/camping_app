import 'package:campign_project/features/sites/presentation/models/distance.model.dart';

abstract class IDataProvider {
  Stream<List<SiteDistanceModel>> fetchNearbySites({
    required double userLat,
    required double userLng,
    required double radiusKm,
    required bool isRadiusSelected,
  });

  Future<void> registerSiteViews(String siteId, String userId);

  Future<void> addUploadedSite(String userId, String siteId);

  Future<void> removeUploadedSite(String userId, String siteId);

  Future<void> addSavedSite(String userId, String siteId);

  Future<void>removeSavedSite(String userId,String siteId);

  Future<void> fetchCurrentUser(String uid);

  
}
