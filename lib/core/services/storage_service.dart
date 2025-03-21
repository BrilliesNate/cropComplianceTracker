import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Future<String?> uploadFile(File file, String companyId, String documentId, String fileName) async {
    try {
      final storagePath = AppConstants.documentsStoragePath
          .replaceAll('{companyId}', companyId)
          .replaceAll('{documentId}', documentId);

      final uniqueFileName = '${_uuid.v4()}_$fileName';
      final ref = _storage.ref().child('$storagePath/$uniqueFileName');

      // Use a platform-independent method to upload
      UploadTask uploadTask;
      if (kIsWeb) {
        // For web platform
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        // For mobile and desktop
        uploadTask = ref.putFile(file);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<String?> uploadSignature(File file, String companyId, String signatureId) async {
    try {
      final storagePath = AppConstants.signaturesStoragePath
          .replaceAll('{companyId}', companyId)
          .replaceAll('{signatureId}', signatureId);

      final ref = _storage.ref().child('$storagePath.png');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading signature: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}