import 'package:dart_mappable/dart_mappable.dart';
part 'comment.model.mapper.dart';
@MappableClass()
class CommentModel {
  final String id;
  final String siteId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;


  CommentModel({
    required this.id,
    required this.siteId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });
}
