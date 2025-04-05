import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Future<String?> uploadFile(dynamic file, String companyId, String documentId, String fileName) async {
    try {
      print("DEBUG Storage: Starting file upload");
      print("DEBUG Storage: Company ID: $companyId");
      print("DEBUG Storage: Document ID: $documentId");
      print("DEBUG Storage: Filename: $fileName");

      final storagePath = AppConstants.documentsStoragePath
          .replaceAll('{companyId}', companyId)
          .replaceAll('{documentId}', documentId);
      print("DEBUG Storage: Storage path: $storagePath");

      final uniqueFileName = '${_uuid.v4()}_$fileName';
      print("DEBUG Storage: Unique filename: $uniqueFileName");

      final ref = _storage.ref().child('$storagePath/$uniqueFileName');
      print("DEBUG Storage: Storage reference created");

      UploadTask uploadTask;

      if (kIsWeb) {
        print("DEBUG Storage: Using web upload method");

        // Web environment - handle different possible input types
        if (file is Uint8List) {
          // Direct bytes input
          print("DEBUG Storage: Using provided Uint8List data, size: ${file.length} bytes");
          uploadTask = ref.putData(file, SettableMetadata(
            contentType: _getContentType(fileName),
            customMetadata: {'picked-file-path': fileName},
          ));
        }
        else if (file is Map<String, dynamic>) {
          // Map with bytes key
          if (file.containsKey('bytes') && file['bytes'] is Uint8List) {
            Uint8List bytes = file['bytes'] as Uint8List;
            print("DEBUG Storage: Using bytes from map, size: ${bytes.length} bytes");
            uploadTask = ref.putData(bytes, SettableMetadata(
              contentType: _getContentType(fileName),
              customMetadata: {'picked-file-path': fileName},
            ));
          } else {
            print("DEBUG Storage: Map does not contain valid bytes data");
            return null;
          }
        }
        else {
          // Fallback for empty upload (for debugging - remove in production)
          print("DEBUG Storage: WARNING - Using empty bytes for upload. File type: ${file.runtimeType}");
          uploadTask = ref.putData(Uint8List(0), SettableMetadata(
            contentType: _getContentType(fileName),
            customMetadata: {'picked-file-path': fileName},
          ));
        }
        print("DEBUG Storage: Web upload task started");
      } else {
        // Mobile/Desktop environment
        print("DEBUG Storage: Using file upload method");
        if (file is File) {
          uploadTask = ref.putFile(file);
        } else {
          print("DEBUG Storage: Error - Non-web environment requires File objects, got: ${file.runtimeType}");
          return null;
        }
      }

      final snapshot = await uploadTask;
      print("DEBUG Storage: Upload completed");

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("DEBUG Storage: Download URL obtained: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      print('ERROR uploading file: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      return null;
    }
  }

  String _getContentType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.doc')) return 'application/msword';
    if (fileName.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    return 'application/octet-stream';
  }

  Future<String?> uploadSignature(dynamic signatureFile, String companyId, String signatureId) async {
    try {
      print("DEBUG Storage: Starting signature upload");

      final storagePath = AppConstants.signaturesStoragePath
          .replaceAll('{companyId}', companyId)
          .replaceAll('{signatureId}', signatureId);
      print("DEBUG Storage: Signature path: $storagePath");

      final ref = _storage.ref().child('$storagePath.png');
      print("DEBUG Storage: Signature reference created");

      UploadTask uploadTask;

      if (kIsWeb) {
        print("DEBUG Storage: Using web upload for signature");

        if (signatureFile is Uint8List) {
          // Direct bytes input
          print("DEBUG Storage: Using Uint8List for signature, size: ${signatureFile.length} bytes");
          uploadTask = ref.putData(signatureFile, SettableMetadata(contentType: 'image/png'));
        }
        else if (signatureFile is Map<String, dynamic> && signatureFile.containsKey('bytes')) {
          // Map with bytes key
          Uint8List bytes = signatureFile['bytes'] as Uint8List;
          print("DEBUG Storage: Using bytes from map for signature, size: ${bytes.length} bytes");
          uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
        }
        else {
          print("DEBUG Storage: Error - Web signature upload requires Uint8List data");
          return null;
        }
      } else {
        if (signatureFile is File) {
          uploadTask = ref.putFile(signatureFile);
        } else {
          print("DEBUG Storage: Error - Non-web signature upload requires File objects");
          return null;
        }
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("DEBUG Storage: Signature URL: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      print('ERROR uploading signature: $e');
      print('ERROR stack trace: ${StackTrace.current}');
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