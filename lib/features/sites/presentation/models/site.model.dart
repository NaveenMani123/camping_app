import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_mappable/dart_mappable.dart';
part 'site.model.mapper.dart';


@MappableClass()
class SiteModel with SiteModelMappable {
  final String id;
  final String siteName;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String geohash;
  final String? review;
  final String userId;
  final List<String>? coverImages;
  final Map<String,int>?views;
  final List<String>? category;
  final String? subcategory;
  final Timestamp? timestamp;

  SiteModel({
    required this.id,
    required this.siteName,
    required this.description,
    required this.address,
    this.coverImages,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    this.review,
    this.views,
    required this.userId,
    this.timestamp,
    this.category,
    this.subcategory,
  });
}
