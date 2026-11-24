import 'package:cloud_firestore/cloud_firestore.dart';

class SignatureModel {
  final String id;
  final String documentId;
  final String userId;
  final String userName;
  final String imageUrl;
  final DateTime signedAt;
  // Signed offline: the record exists but the image is still on the
  // signer's phone, waiting in the upload outbox.
  final bool pendingImage;

  SignatureModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    required this.signedAt,
    this.pendingImage = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
      'signedAt': Timestamp.fromDate(signedAt),
      if (pendingImage) 'pendingImage': true,
    };
  }

  factory SignatureModel.fromMap(Map<String, dynamic> map, String id) {
    return SignatureModel(
      id: id,
      documentId: map['documentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      signedAt: (map['signedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pendingImage: map['pendingImage'] == true,
    );
  }
}