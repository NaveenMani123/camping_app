import 'site.model.dart';

class SiteDistanceModel {
  final SiteModel sites;
  final double distanceMeters;
  final List<String> imageUrls;
  final List<String>? videoUrls;
  SiteDistanceModel({required this.sites, required this.distanceMeters, required this.imageUrls, this.videoUrls});

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m away';
    } else {

      final km = distanceMeters / 1000;
      return '${(km).toStringAsFixed(2)} km away';
    }
  }
}
