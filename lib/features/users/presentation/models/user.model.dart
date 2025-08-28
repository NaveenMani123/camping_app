
import 'package:dart_mappable/dart_mappable.dart';
part'user.model.mapper.dart';
@MappableClass()
class UserModel with UserModelMappable{
  final String uid;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final String? email;

  final List<dynamic>? savedSites;
  final List<dynamic>?uploadedSites;
  final String? profileImageUrl;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    this.savedSites,
    this.uploadedSites,
    this.email,
    this.fcmToken,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });
}
