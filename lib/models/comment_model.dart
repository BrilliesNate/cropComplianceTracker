import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String documentId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      documentId: map['documentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}