import 'package:campign_project/database/data_providers/i.data_provider.dart';
import 'package:campign_project/features/sites/presentation/models/distance.model.dart';

class SiteRepository {
  final IDataProvider remoteDataProvider;
  SiteRepository({required this.remoteDataProvider});
  Stream<List<SiteDistanceModel>> fetchNearbySites({
    required double userLat,
    required double userLng,
    required double radiusKm,
    required bool isRadiusSelected,
  }) => remoteDataProvider.fetchNearbySites(
    userLat: userLat,
    userLng: userLng,
    radiusKm: radiusKm,
    isRadiusSelected: isRadiusSelected,

  );
  Future<void> addSavedSite(String userId, String siteId) => remoteDataProvider.addSavedSite(userId, siteId);
  Future<void> addUploadedSite(String userId, String siteId) => remoteDataProvider.addUploadedSite(userId, siteId);
  Future<void> removeUploadedSite(String userId, String siteId) => remoteDataProvider.removeUploadedSite(userId, siteId);
  Future<void> removeSavedSite( String userId, String siteId) => remoteDataProvider.removeSavedSite(userId, siteId);
  Future<void> registerSiteView(String siteId, String userId) => remoteDataProvider.registerSiteViews(siteId, userId);
}
