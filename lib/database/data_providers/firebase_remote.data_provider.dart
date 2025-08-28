import 'package:campign_project/database/data_providers/i.data_provider.dart';
import 'package:campign_project/features/sites/presentation/models/distance.model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/sites/presentation/models/site.model.dart';
import '../../features/users/presentation/models/user.model.dart';

class FirebaseRemoteDataProvider implements IDataProvider {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  Future<void> addSavedSite(String userId, String siteId) async {
    try {
      await _firebaseFirestore.collection('users').doc(userId).update({
        'savedSites': FieldValue.arrayUnion([siteId]),
      });
    } catch (e) {
      throw Exception('the error was $e');
    }
  }

  @override
  Future<void> addUploadedSite(String userId, String siteId) async {
    try {
      await _firebaseFirestore.collection('users').doc(userId).update({
        'uploadedSites': FieldValue.arrayUnion([siteId]),
      });
    } catch (e) {
      throw Exception('Failed to add uploaded site: $e');
    }
  }

  @override
  Future<UserModel?> fetchCurrentUser(String uid) async {
    final user = await _firebaseFirestore.collection('users').doc(uid).get();
    return user.exists ? UserModelMapper.fromMap(user.data()!) : null;
  }

  @override
  Stream<List<SiteDistanceModel>> fetchNearbySites({
    required double userLat,
    required double userLng,
    required double radiusKm,
    required bool isRadiusSelected,
  }) {
    final precision = _getGeohashPrecision(radiusKm);
    final centerHash = GeoHash.fromDecimalDegrees(userLat, userLng, precision: precision);
    final centerPrefix = centerHash.geohash;

    return _firebaseFirestore.collection('sites').snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return <SiteDistanceModel>[];

      List<SiteDistanceModel> filteredSites = [];

      if (isRadiusSelected) {
        final futures = snapshot.docs.map((doc) async {
          try {
            final data = doc.data();
            final site = SiteModelMapper.fromMap(data);

            final siteGeohash = (data['geohash'] as String?) ?? '';
            if (siteGeohash.length < precision || siteGeohash.substring(0, precision) != centerPrefix) {
              return null;
            }

            final distance = Geolocator.distanceBetween(userLat, userLng, site.latitude, site.longitude);
            if (distance <= radiusKm * 1000) {
              return SiteDistanceModel(sites: site, distanceMeters: distance, imageUrls: site.coverImages ?? []);
            }
            return null;
          } catch (_) {
            return null;
          }
        });

        filteredSites = (await Future.wait(futures)).whereType<SiteDistanceModel>().toList();
        filteredSites.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        return filteredSites;
      }

      double dynamicRadius = 500;
      const int stepKm = 100;
      const double maxRadius = 6300;
      const int minSites = 10;

      while (dynamicRadius <= maxRadius && filteredSites.length < minSites) {
        final futures = snapshot.docs.map((doc) async {
          try {
            final data = doc.data();
            final site = SiteModelMapper.fromMap(data);

            final siteGeohash = (data['geohash'] as String?) ?? '';
            if (siteGeohash.length < precision || siteGeohash.substring(0, precision) != centerPrefix) {
              return null;
            }

            final distance = Geolocator.distanceBetween(userLat, userLng, site.latitude, site.longitude);
            if (distance <= dynamicRadius * 1000) {
              return SiteDistanceModel(sites: site, distanceMeters: distance, imageUrls: site.coverImages ?? []);
            }
            return null;
          } catch (_) {
            return null;
          }
        });

        final siteList = (await Future.wait(futures)).whereType<SiteDistanceModel>().toList();
        siteList.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        filteredSites = siteList;

        if (filteredSites.length >= minSites) break;
        dynamicRadius += stepKm;
      }

      return filteredSites;
    });
  }

  int _getGeohashPrecision(double radiusKm) {
    if (radiusKm >= 100) return 1;
    if (radiusKm >= 20) return 3;
    if (radiusKm >= 5) return 4;
    if (radiusKm >= 1) return 5;
    return 6;
  }

  @override
  Future<void> registerSiteViews(String siteId, String userId) async {
    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month}-${today.day}";
    final viewerRef = _firebaseFirestore.collection('sites').doc(siteId).collection('viewers').doc(userId);
    await _firebaseFirestore.runTransaction((transaction) async {
      final snapShot = await transaction.get(viewerRef);
      if (snapShot.exists) {
        transaction.set(viewerRef, {'lastViewedDate': todayKey});
        transaction.update(_firebaseFirestore.collection('sites').doc(siteId), {
          'views.$todayKey': FieldValue.increment(1),
        });
      } else {
        final lastViewed = snapShot.get('lastViewedDate');
        if (lastViewed != todayKey) {
          transaction.update(viewerRef, {'lastViewedDate': todayKey});
          transaction.update(_firebaseFirestore.collection('sites').doc(siteId), {
            'views.$todayKey': FieldValue.increment(1),
          });
        }
      }
    });
  }

  @override
  Future<void> removeSavedSite(String userId, String siteId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'savedSites': FieldValue.arrayRemove([siteId]),
      });
    } catch (e) {
      throw Exception('Failed to remove saved site: $e');
    }
  }

  @override
  Future<void> removeUploadedSite(String userId, String siteId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'uploadedSites': FieldValue.arrayRemove([siteId]),
      });
    } catch (e) {
      throw Exception('the error occurred $e');
    }
  }
}
