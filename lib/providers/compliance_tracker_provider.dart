import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
// Import with aliases to resolve naming conflicts
import 'package:cropcompliance/components/document_item_comp.dart' as components;
import 'package:cropcompliance/models/compliance_tracker_model.dart' as models;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ComplianceTrackerProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local state
  List<components.DocumentItem> _documents = [];
  List<models.ChecklistCategory> _auditChecklist = [];
  Map<String, Uint8List> _fileData = {};
  bool _isLoading = false;
  String? _error;

  // Upload progress tracking state
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String _uploadStatusMessage = "";

  // Optimization-related state
  Map<String, bool> _downloadAttempted = {}; // Track which files we've tried to download
  List<String> _recentErrors = []; // Track recent errors for pattern detection
  bool _isBackgroundLoading = false; // Track if background loading is in progress

  // Getters
  List<components.DocumentItem> get documents => _documents;
  List<models.ChecklistCategory> get auditChecklist => _auditChecklist;
  Map<String, Uint8List> get fileData => _fileData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Upload progress getters
  double get uploadProgress => _uploadProgress;
  bool get isUploading => _isUploading;
  String get uploadStatusMessage => _uploadStatusMessage;

  // User ID getter
  String? get userId => _auth.currentUser?.uid;

  // Constructor
  ComplianceTrackerProvider() {
    // Initialize the audit checklist with default values
    _auditChecklist = models.initializeAuditChecklist();

    // Listen for auth state changes to load data
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in, load their data
        loadUserData();
      } else {
        // User logged out, clear data
        _documents = [];
        _fileData = {};
        notifyListeners();
      }
    });
  }

  // DIAGNOSTIC METHOD - Call this to test Firebase Storage permissions
  Future<void> testStoragePermissions() async {
    if (userId == null) {
      print('ERROR: No user ID available for testing');
      return;
    }

    print('INFO: Running Firebase Storage diagnostics...');
    print('INFO: User ID: $userId');

    try {
      // 1. Test creating a tiny test file
      final testContent = Uint8List.fromList(utf8.encode('test content'));
      final testPath = 'users/$userId/test/permissions_test.txt';

      print('INFO: Attempting to upload tiny test file to: $testPath');
      print('INFO: Test file size: ${testContent.length} bytes');

      final testRef = _storage.ref().child(testPath);

      try {
        // Try with metadata to see if that's an issue
        final uploadTask = testRef.putData(
          testContent,
          SettableMetadata(contentType: 'text/plain'),
        );

        // Monitor for 10 seconds max
        final result = await uploadTask.timeout(const Duration(seconds: 10));
        print('INFO: Test upload successful! State: ${result.state}');

        // Try to get the download URL
        try {
          final url = await testRef.getDownloadURL();
          print('INFO: Download URL obtained: $url');
          print('SUCCESS: Storage permissions working correctly');
        } catch (e) {
          print('ERROR: Could upload but couldn\'t get download URL: $e');
        }

        // Clean up the test file
        try {
          await testRef.delete();
          print('INFO: Test file cleaned up successfully');
        } catch (e) {
          print('WARNING: Couldn\'t clean up test file: $e');
        }
      } catch (e) {
        print('ERROR: Test upload failed with error: $e');

        if (e is FirebaseException) {
          print('ERROR CODE: ${e.code}');
          print('ERROR MESSAGE: ${e.message}');

          if (e.code == 'unauthorized') {
            print('DIAGNOSIS: Storage rules are blocking the upload.');
            print('SOLUTION: Update Firebase Storage rules to:');
            print('''
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}''');
          } else if (e.code == 'storage/quota-exceeded') {
            print('DIAGNOSIS: Storage quota exceeded');
          } else if (e.code == 'storage/retry-limit-exceeded') {
            print(
                'DIAGNOSIS: Network issues or storage not properly initialized');
          } else if (e.code == 'storage/invalid-argument') {
            print('DIAGNOSIS: Problem with the file data or metadata');
          }
        }
      }

      // 2. Check if other files exist in your storage to confirm it's working
      try {
        final listResult = await _storage.ref('users/$userId').listAll();
        print('INFO: Found existing files in storage:');
        print(
            'INFO: ${listResult.items.length} items, ${listResult.prefixes.length} folders');

        if (listResult.items.isNotEmpty) {
          print('INFO: First few items:');
          final limit = min(3, listResult.items.length);
          for (int i = 0; i < limit; i++) {
            print('INFO: - ${listResult.items[i].fullPath}');
          }
        }
      } catch (e) {
        print('ERROR: Could not list storage contents: $e');
      }
    } catch (e, stackTrace) {
      print('ERROR: Diagnostics failed:');
      print('ERROR DETAILS: $e');
      // print('STACK TRACE: $stackTrace);
    }
  }

  // Load user data from Firestore - OPTIMIZED VERSION
  Future<void> loadUserData() async {
    if (userId == null) {
      print('ERROR: loadUserData - No user ID available');
      return;
    }

    print('INFO: Starting to load user data for user: $userId');
    _setLoading(true);

    try {
      // Load documents metadata first (fast operation)
      print('INFO: Loading document metadata...');
      try {
        await _loadDocumentMetadata();
        print('INFO: Document metadata loaded successfully');
      } catch (docError, stackTrace) {
        print('ERROR: Failed to load document metadata:');
        print('ERROR DETAILS: $docError');
        print('STACK TRACE: $stackTrace');
        // Continue to try loading the checklist
      }

      // Load checklist state
      print('INFO: Loading checklist state...');
      try {
        await _loadChecklistState();
        print('INFO: Checklist state loaded successfully');
      } catch (checklistError, stackTrace) {
        print('ERROR: Failed to load checklist state:');
        print('ERROR DETAILS: $checklistError');
        print('STACK TRACE: $stackTrace');
        // Continue since we at least tried to load everything
      }

      // Start background loading of files
      _startBackgroundFileLoading();

      setError(null);
      print('INFO: Initial user data loading completed');
    } catch (e, stackTrace) {
      print('ERROR: Unexpected error in loadUserData:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      setError('Error loading data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load document metadata only - OPTIMIZED METHOD
  Future<void> _loadDocumentMetadata() async {
    if (userId == null) {
      print('ERROR: _loadDocumentMetadata - No user ID available');
      return;
    }

    print('INFO: Starting to load document metadata from Firestore');
    try {
      // Get documents from Firestore
      print('INFO: Querying Firestore for documents');
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .get();

      print('INFO: Found ${snapshot.docs.length} documents in Firestore');

      // Convert to DocumentItem objects (without downloading files)
      final loadedDocuments = <components.DocumentItem>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('INFO: Processing document metadata: ${doc.id} - ${data['title']}');

          // Create DocumentItem from Firestore data
          final documentItem = components.DocumentItem(
            id: doc.id.hashCode,
            title: data['title'] ?? '',
            priority: _priorityFromString(data['priority'] ?? 'medium'),
            status: _statusFromString(data['status'] ?? 'pending'),
            expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ??
                DateTime.now().add(const Duration(days: 90)),
            category: data['category'] ?? '',
            filePath: data['filePath'],
            storageRef: data['storageRef'], // Store storage reference for later
          );

          loadedDocuments.add(documentItem);
        } catch (docError, stackTrace) {
          print('ERROR: Failed to process document metadata ${doc.id}:');
          print('ERROR DETAILS: $docError');
          print('STACK TRACE: $stackTrace');
          // Continue with other documents
        }
      }

      _documents = loadedDocuments;
      print('INFO: Loaded ${_documents.length} document metadata successfully');

      notifyListeners();
    } catch (e, stackTrace) {
      print('ERROR: Failed to load document metadata from Firestore:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      throw e;
    }
  }

  // Start background loading of document files
  void _startBackgroundFileLoading() {
    if (_isBackgroundLoading) {
      print('INFO: Background loading already in progress, skipping');
      return;
    }

    _isBackgroundLoading = true;

    print('INFO: Starting background file loading');

    // We use Future to run this in the background without blocking the UI
    Future(() async {
      try {
        final filesToLoad = <String, String>{};

        // Collect storage references from documents
        for (final doc in _documents) {
          if (doc.filePath != null && doc.storageRef != null) {
            filesToLoad[doc.storageRef!] = doc.filePath!;
          }
        }

        print('INFO: Found ${filesToLoad.length} files to load in background');

        // Load files with limited concurrency (2 at a time) to avoid overwhelming the network
        final maxConcurrent = 2;
        final entries = filesToLoad.entries.toList();

        for (int i = 0; i < entries.length; i += maxConcurrent) {
          final batch = entries.skip(i).take(maxConcurrent);
          final futures = batch.map((entry) =>
              _safeFetchFromStorage(entry.key, entry.value)
          ).toList();

          // Wait for batch to complete
          await Future.wait(futures);

          // Notify UI after each batch if files were loaded
          if (_fileData.isNotEmpty) {
            notifyListeners();
          }
        }

        print('INFO: Background file loading completed');
      } catch (e) {
        print('ERROR: Error during background file loading: $e');
      } finally {
        _isBackgroundLoading = false;
      }
    });
  }

  // Load checklist state from Firestore
  Future<void> _loadChecklistState() async {
    if (userId == null) {
      print('ERROR: _loadChecklistState - No user ID available');
      return;
    }

    print('INFO: Starting to load checklist state from Firestore');
    try {
      // Get checklist state from Firestore
      print('INFO: Querying Firestore for checklist state');
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checklist')
          .doc('state')
          .get();

      if (!doc.exists) {
        print('INFO: No saved checklist state found, saving default state');
        // No saved state, save default state
        await _saveChecklistState();
        return;
      }

      // Get completed items
      final Map<String, dynamic>? completedItems =
      doc.data()?['completedItems'];
      if (completedItems == null) {
        print('WARNING: Checklist document exists but completedItems is null');
        return;
      }

      print('INFO: Found ${completedItems.length} completed checklist items');

      // Update local checklist state
      int linkedItemsCount = 0;
      completedItems.forEach((itemName, value) {
        // Find the item in the checklist
        bool itemFound = false;
        for (var category in _auditChecklist) {
          for (var item in category.items) {
            if (item.name == itemName) {
              itemFound = true;
              // Mark as completed
              item.isCompleted = true;

              // Link to document if available
              final docId = value['documentId'];
              if (docId != null) {
                try {
                  final doc = _documents.firstWhere(
                        (d) => d.id.toString() == docId,
                    orElse: () => components.DocumentItem(
                      id: 0,
                      title: '',
                      priority: components.Priority.medium,
                      status: components.DocumentStatus.pending,
                      expiryDate: DateTime.now(),
                      category: '',
                    ),
                  );

                  if (doc.id != 0) {
                    item.linkedDocument = doc;
                    item.documentFilePath = doc.filePath;
                    linkedItemsCount++;
                  } else {
                    print('WARNING: Referenced document not found: $docId');
                  }
                } catch (e) {
                  print('ERROR: Error linking document to checklist item: $e');
                }
              }
              break;
            }
          }
          if (itemFound) break;
        }
        if (!itemFound) {
          print('WARNING: Checklist item not found: $itemName');
        }
      });

      print('INFO: Linked $linkedItemsCount documents to checklist items');
      notifyListeners();
    } catch (e, stackTrace) {
      print('ERROR: Error loading checklist state:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      throw e;
    }
  }

  // Save checklist state to Firestore
  Future<void> _saveChecklistState() async {
    if (userId == null) {
      print('ERROR: _saveChecklistState - No user ID available');
      return;
    }

    print('INFO: Starting to save checklist state to Firestore');
    try {
      // Build map of completed items
      final Map<String, dynamic> completedItems = {};

      for (var category in _auditChecklist) {
        for (var item in category.items) {
          if (item.isCompleted) {
            completedItems[item.name] = {
              'isCompleted': true,
              'documentId': item.linkedDocument?.id.toString(),
            };
          }
        }
      }

      print(
          'INFO: Found ${completedItems.length} completed checklist items to save');

      // Save to Firestore
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('checklist')
            .doc('state')
            .set({
          'completedItems': completedItems,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('INFO: Checklist state saved successfully to Firestore');
      } catch (firestoreError, stackTrace) {
        print('ERROR: Failed to save checklist state to Firestore:');
        print('ERROR DETAILS: $firestoreError');
        print('STACK TRACE: $stackTrace');
        throw firestoreError;
      }
    } catch (e, stackTrace) {
      print('ERROR: Unexpected error in _saveChecklistState:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      throw e;
    }
  }

  // Safely fetch a file from storage with error handling
  Future<void> _safeFetchFromStorage(String storagePath, String filePath) async {
    if (_downloadAttempted[storagePath] == true) {
      print('INFO: Already attempted to download this file, skipping: $storagePath');
      return;
    }

    _downloadAttempted[storagePath] = true;

    try {
      print('INFO: Attempting to download file with safe method: $storagePath');
      final ref = _storage.ref().child(storagePath);

      // Try to get download URL first to validate the file exists
      try {
        final downloadUrl = await ref.getDownloadURL();

        // Use different approaches for web vs mobile to avoid ClientException
        if (kIsWeb) {
          // For web, use HTTP to download the file
          try {
            final response = await http.get(Uri.parse(downloadUrl))
                .timeout(const Duration(seconds: 30));

            if (response.statusCode == 200) {
              final bytes = Uint8List.fromList(response.bodyBytes);
              if (bytes.isNotEmpty) {
                _fileData[filePath] = bytes;
                print('INFO: File downloaded successfully via HTTP: $filePath');
              } else {
                print('WARNING: Downloaded file was empty: $filePath');
              }
            } else {
              print('ERROR: HTTP download failed with status: ${response.statusCode}');
            }
          } catch (httpError) {
            print('ERROR: HTTP download failed: $httpError');

            // If HTTP download fails, try the direct method as fallback
            try {
              final bytes = await ref.getData();
              if (bytes != null) {
                _fileData[filePath] = bytes;
                print('INFO: File downloaded successfully via fallback method: $filePath');
              }
            } catch (fallbackError) {
              print('ERROR: Fallback download also failed: $fallbackError');
            }
          }
        } else {
          // For mobile, use the Firebase Storage API directly
          final bytes = await ref.getData();
          if (bytes != null) {
            _fileData[filePath] = bytes;
            print('INFO: File downloaded successfully: $filePath');
          } else {
            print('WARNING: Download returned null: $filePath');
          }
        }
      } catch (urlError) {
        print('ERROR: Failed to get download URL: $urlError');

        // If we can't get the URL, the file might not exist or be inaccessible
        if (urlError is FirebaseException && urlError.code == 'storage/object-not-found') {
          print('ERROR: File does not exist: $storagePath');
        }
      }
    } catch (e, stackTrace) {
      print('ERROR: Unexpected error in _safeFetchFromStorage:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');

      // Track error for pattern detection
      final errorMsg = e.toString();
      if (_isSameErrorRepeating(errorMsg, _recentErrors)) {
        print('WARNING: Same error repeating multiple times, might be a systemic issue');
      }
    }
  }

  // Get document file on demand
  Future<Uint8List?> getDocumentFile(components.DocumentItem document) async {
    if (document.filePath == null || document.storageRef == null) {
      print('WARNING: No file path or storage reference available for document: ${document.title}');
      return null;
    }

    // Check if we already have the file data in memory
    if (_fileData.containsKey(document.filePath)) {
      print('INFO: File already in memory: ${document.filePath}');
      return _fileData[document.filePath];
    }

    print('INFO: Downloading file on demand: ${document.storageRef}');
    _setLoading(true);

    try {
      // Try to download with safer method
      await _safeFetchFromStorage(document.storageRef!, document.filePath!);

      // Check if download succeeded
      if (_fileData.containsKey(document.filePath)) {
        return _fileData[document.filePath];
      } else {
        print('WARNING: File download failed for: ${document.filePath}');
        return null;
      }
    } catch (e) {
      print('ERROR: Failed to download file ${document.filePath}:');
      print('ERROR DETAILS: $e');
      setError('Error downloading file: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Check if the same error is repeating multiple times
  bool _isSameErrorRepeating(String errorMessage, List<String> recentErrors, {int threshold = 3}) {
    // Keep only recent errors
    if (recentErrors.length > 10) {
      recentErrors = recentErrors.sublist(recentErrors.length - 10);
    }

    // Add current error
    recentErrors.add(errorMessage);

    // Count occurrences of this error
    int count = 0;
    for (final error in recentErrors) {
      if (error == errorMessage) {
        count++;
      }
    }

    // If this error has repeated more than the threshold, it's likely a systemic issue
    return count >= threshold;
  }

  // Upload document to Firebase - ENHANCED WITH PROGRESS TRACKING AND TIMEOUT
  Future<components.DocumentItem?> uploadDocument({
    required String title,
    required components.Priority priority,
    required components.DocumentStatus status,
    required DateTime expiryDate,
    required String category,
    required String fileName,
    required Uint8List fileBytes,
    models.ChecklistItem? linkedChecklistItem,
  }) async {
    if (userId == null) {
      print('ERROR: Upload failed - No user ID available');
      return null;
    }

    _setLoading(true);
    _setUploading(true); // Set uploading state to true
    _updateUploadProgress(0.0, "Preparing upload..."); // Initial progress

    print('INFO: Starting document upload process for: $title');
    print('INFO: File size: ${(fileBytes.length / 1024).toStringAsFixed(2)} KB');

    try {
      // Generate unique file name
      final uuid = const Uuid().v4();
      final fileExtension = fileName.split('.').last;
      final storagePath = 'users/$userId/documents/$uuid.$fileExtension';
      print('INFO: Generated storage path: $storagePath');
      _updateUploadProgress(5.0, "Initializing upload..."); // Update progress

      // Upload file to Firebase Storage with progress monitoring
      print('INFO: Attempting to upload file to Firebase Storage...');
      final storageRef = _storage.ref().child(storagePath);

      try {
        // Create upload task
        final uploadTask = storageRef.putData(
          fileBytes,
          SettableMetadata(contentType: 'application/$fileExtension'),
        );

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('INFO: Upload progress: ${progress.toStringAsFixed(1)}%');

          // Update progress for UI
          _updateUploadProgress(
              progress,
              "Uploading file: ${progress.toStringAsFixed(1)}%"
          );

          if (snapshot.state == TaskState.error) {
            print('ERROR: Upload task reported error state');
            _updateUploadProgress(0.0, "Upload error occurred");
          }
        }, onError: (error) {
          print('ERROR: Upload stream error: $error');
          _updateUploadProgress(0.0, "Upload stream error: $error");
        });

        // Wait for upload with timeout
        print('INFO: Waiting for upload to complete (timeout: 120s)...');
        await uploadTask.timeout(const Duration(seconds: 120), onTimeout: () {
          print('ERROR: Upload timed out after 120 seconds');
          _updateUploadProgress(0.0, "Upload timed out after 120 seconds");
          throw TimeoutException('File upload timed out after 120 seconds');
        });

        // Get download URL to verify upload completed successfully
        final downloadUrl = await storageRef.getDownloadURL();
        print('INFO: File upload successful. Download URL available.');
        _updateUploadProgress(100.0, "File uploaded successfully");
      } catch (storageError, stackTrace) {
        print('ERROR: Firebase Storage upload failed:');
        print('ERROR DETAILS: $storageError');
        print('STACK TRACE: $stackTrace');

        // Check specific storage errors
        if (storageError is FirebaseException) {
          print('ERROR CODE: ${storageError.code}');
          print('ERROR MESSAGE: ${storageError.message}');

          // Handle specific storage error codes
          if (storageError.code == 'unauthorized') {
            print('ERROR: Storage rules are preventing the upload. Check Firebase Storage rules.');
            setError('Upload not authorized. Check storage permissions.');
            _updateUploadProgress(0.0, "Upload not authorized");
          } else if (storageError.code == 'canceled') {
            print('ERROR: Upload was canceled.');
            setError('Upload was canceled.');
            _updateUploadProgress(0.0, "Upload canceled");
          } else if (storageError.code == 'quota-exceeded') {
            print('ERROR: Storage quota exceeded.');
            setError('Storage quota exceeded.');
            _updateUploadProgress(0.0, "Storage quota exceeded");
          } else {
            setError('Storage error: ${storageError.message}');
            _updateUploadProgress(0.0, "Storage error: ${storageError.message}");
          }
        } else if (storageError is TimeoutException) {
          print('ERROR: Upload timed out. Check network connection or file size.');
          setError('Upload timed out. Check your connection or file size.');
          _updateUploadProgress(0.0, "Upload timed out");
        } else {
          setError('Storage upload failed: $storageError');
          _updateUploadProgress(0.0, "Upload failed");
        }

        _setUploading(false);
        _setLoading(false);
        return null;
      }

      // Update progress for creating the document record
      _updateUploadProgress(100.0, "Creating document record...");

      // Create document in Firestore
      print('INFO: Creating document record in Firestore...');
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc();

      // Document data
      final documentData = {
        'title': title,
        'priority': _priorityToString(priority),
        'status': _statusToString(status),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'category': category,
        'filePath': fileName,
        'storageRef': storagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      try {
        await docRef.set(documentData);
        print('INFO: Document record created in Firestore with ID: ${docRef.id}');
        _updateUploadProgress(100.0, "Document record created successfully");
      } catch (firestoreError, stackTrace) {
        print('ERROR: Firestore document creation failed:');
        print('ERROR DETAILS: $firestoreError');
        print('STACK TRACE: $stackTrace');

        // Try to clean up the storage file since Firestore failed
        try {
          print('INFO: Attempting to clean up storage file after Firestore failure');
          await storageRef.delete();
          print('INFO: Storage cleanup successful');
        } catch (cleanupError) {
          print('ERROR: Failed to clean up storage file: $cleanupError');
        }

        setError('Database record creation failed: $firestoreError');
        _updateUploadProgress(0.0, "Database record creation failed");
        _setUploading(false);
        _setLoading(false);
        return null;
      }

      // Create DocumentItem
      final documentItem = components.DocumentItem(
        id: docRef.id.hashCode,
        title: title,
        priority: priority,
        status: status,
        expiryDate: expiryDate,
        category: category,
        filePath: fileName,
        storageRef: storagePath, // Store storage reference
      );

      // Update local state
      print('INFO: Updating local state with new document');
      _documents.add(documentItem);
      _fileData[fileName] = fileBytes;

      // Link to checklist item if provided
      if (linkedChecklistItem != null) {
        _updateUploadProgress(100.0, "Linking document to checklist...");
        print('INFO: Linking document to checklist item: ${linkedChecklistItem.name}');
        linkedChecklistItem.isCompleted = true;
        linkedChecklistItem.documentFilePath = fileName;
        linkedChecklistItem.linkedDocument = documentItem;

        // Save updated checklist state
        try {
          await _saveChecklistState();
          print('INFO: Checklist state updated successfully');
        } catch (checklistError, stackTrace) {
          print('ERROR: Failed to update checklist state:');
          print('ERROR DETAILS: $checklistError');
          print('STACK TRACE: $stackTrace');
          // Continue since the document was already uploaded successfully
        }
      }

      print('INFO: Document upload process completed successfully');
      _updateUploadProgress(100.0, "Upload completed successfully");
      notifyListeners();
      setError(null);
      return documentItem;
    } catch (e, stackTrace) {
      print('ERROR: Unexpected error in uploadDocument:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      setError('Error uploading document: $e');
      _updateUploadProgress(0.0, "Error: $e");
      return null;
    } finally {
      _setLoading(false);
      _setUploading(false); // Reset uploading state
    }
  }

  // Update document in Firebase
  Future<bool> updateDocument(components.DocumentItem document) async {
    if (userId == null) {
      print('ERROR: updateDocument - No user ID available');
      return false;
    }

    print('INFO: Starting to update document: ${document.title}');
    _setLoading(true);

    try {
      // Find document by id
      print('INFO: Finding Firestore document ID...');
      final docId = await _getDocumentFirestoreId(document);
      if (docId == null) {
        print('ERROR: Document not found in Firestore: ${document.title}');
        setError('Document not found');
        return false;
      }
      print('INFO: Found Firestore document ID: $docId');

      // Update in Firestore
      try {
        print('INFO: Updating document record in Firestore');
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('documents')
            .doc(docId)
            .update({
          'title': document.title,
          'priority': _priorityToString(document.priority),
          'status': _statusToString(document.status),
          'expiryDate': Timestamp.fromDate(document.expiryDate),
          'category': document.category,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('INFO: Document record updated successfully in Firestore');
      } catch (firestoreError, stackTrace) {
        print('ERROR: Failed to update document record in Firestore:');
        print('ERROR DETAILS: $firestoreError');
        print('STACK TRACE: $stackTrace');
        throw firestoreError;
      }

      // Update local state
      print('INFO: Updating local state after update');
      final index = _documents.indexWhere((d) => d.id == document.id);
      if (index != -1) {
        // Preserve the storage reference when updating
        final storageRef = _documents[index].storageRef;
        document.storageRef = storageRef;

        _documents[index] = document;
        print('INFO: Local state updated successfully');
      } else {
        print('WARNING: Document not found in local state: ${document.id}');
      }

      // Update any linked checklist items
      print('INFO: Updating linked checklist items');
      _updateLinkedChecklistItems(document);

      notifyListeners();
      setError(null);
      print('INFO: Document update completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('ERROR: Unexpected error in updateDocument:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      setError('Error updating document: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete document from Firebase
  Future<bool> deleteDocument(components.DocumentItem document) async {
    if (userId == null) {
      print('ERROR: deleteDocument - No user ID available');
      return false;
    }

    print('INFO: Starting to delete document: ${document.title}');
    _setLoading(true);

    try {
      // Find document by id
      print('INFO: Finding Firestore document ID...');
      final docId = await _getDocumentFirestoreId(document);
      if (docId == null) {
        print('ERROR: Document not found in Firestore: ${document.title}');
        setError('Document not found');
        return false;
      }
      print('INFO: Found Firestore document ID: $docId');

      // Get document data to find the storage reference
      try {
        print('INFO: Retrieving document data to find storage reference');
        final docSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('documents')
            .doc(docId)
            .get();

        final storageRef = docSnapshot.data()?['storageRef'];

        // Delete from Storage if reference exists
        if (storageRef != null) {
          try {
            print('INFO: Deleting file from Storage: $storageRef');
            await _storage.ref().child(storageRef).delete();
            print('INFO: File deleted successfully from Storage');
          } catch (storageError, stackTrace) {
            print('ERROR: Failed to delete file from Storage:');
            print('ERROR DETAILS: $storageError');
            print('STACK TRACE: $stackTrace');
            // Continue to delete the document record anyway
          }
        } else {
          print('INFO: No storage reference found for document');
        }

        // Delete from Firestore
        try {
          print('INFO: Deleting document record from Firestore');
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('documents')
              .doc(docId)
              .delete();
          print('INFO: Document record deleted successfully from Firestore');
        } catch (firestoreError, stackTrace) {
          print('ERROR: Failed to delete document record from Firestore:');
          print('ERROR DETAILS: $firestoreError');
          print('STACK TRACE: $stackTrace');
          throw firestoreError;
        }

        // Update local state
        print('INFO: Updating local state after delete');
        _documents.removeWhere((d) => d.id == document.id);
        if (document.filePath != null) {
          _fileData.remove(document.filePath);
        }

        // Update any linked checklist items
        print('INFO: Updating linked checklist items');
        for (var category in _auditChecklist) {
          for (var item in category.items) {
            if (item.linkedDocument?.id == document.id) {
              item.isCompleted = false;
              item.documentFilePath = null;
              item.linkedDocument = null;
            }
          }
        }

        // Save updated checklist state
        try {
          print('INFO: Saving updated checklist state after document deletion');
          await _saveChecklistState();
          print('INFO: Checklist state updated successfully');
        } catch (checklistError, stackTrace) {
          print(
              'ERROR: Failed to update checklist state after document deletion:');
          print('ERROR DETAILS: $checklistError');
          print('STACK TRACE: $stackTrace');
          // Continue since the document was already deleted
        }

        notifyListeners();
        setError(null);
        print('INFO: Document deletion completed successfully');
        return true;
      } catch (e, stackTrace) {
        print('ERROR: Failed to delete document:');
        print('ERROR DETAILS: $e');
        print('STACK TRACE: $stackTrace');
        throw e;
      }
    } catch (e, stackTrace) {
      print('ERROR: Unexpected error in deleteDocument:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      setError('Error deleting document: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mark checklist item as completed and link to document
  Future<bool> markChecklistItemCompleted(
      models.ChecklistItem item, components.DocumentItem document) async {
    if (userId == null) {
      print('ERROR: markChecklistItemCompleted - No user ID available');
      return false;
    }

    print('INFO: Marking checklist item as completed: ${item.name}');
    _setLoading(true);

    try {
      // Update local state
      item.isCompleted = true;
      item.documentFilePath = document.filePath;
      item.linkedDocument = document;

      // Save updated checklist state
      try {
        await _saveChecklistState();
        print('INFO: Checklist state updated successfully');
      } catch (e, stackTrace) {
        print('ERROR: Failed to save checklist state:');
        print('ERROR DETAILS: $e');
        print('STACK TRACE: $stackTrace');
        throw e;
      }

      notifyListeners();
      setError(null);
      print('INFO: Checklist item marked as completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('ERROR: Unexpected error in markChecklistItemCompleted:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      setError('Error updating checklist: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update linked checklist items when a document is updated
  void _updateLinkedChecklistItems(components.DocumentItem document) {
    print(
        'INFO: Updating checklist items linked to document: ${document.title}');
    int updatedCount = 0;
    for (var category in _auditChecklist) {
      for (var item in category.items) {
        if (item.linkedDocument?.id == document.id) {
          item.linkedDocument = document;
          updatedCount++;
        }
      }
    }
    print('INFO: Updated $updatedCount linked checklist items');
  }

  // Find document Firestore ID by document item
  Future<String?> _getDocumentFirestoreId(components.DocumentItem document) async {
    print('INFO: Looking up Firestore ID for document: ${document.title}');
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .where('title', isEqualTo: document.title)
          .where('filePath', isEqualTo: document.filePath)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('WARNING: No matching document found in Firestore');
        return null;
      }

      print('INFO: Found Firestore ID: ${snapshot.docs.first.id}');
      return snapshot.docs.first.id;
    } catch (e, stackTrace) {
      print('ERROR: Error looking up document Firestore ID:');
      print('ERROR DETAILS: $e');
      print('STACK TRACE: $stackTrace');
      throw e;
    }
  }

  // Method to update upload progress
  void _updateUploadProgress(double progress, String message) {
    _uploadProgress = progress;
    _uploadStatusMessage = message;
    notifyListeners();
  }

  // Method to set upload state
  void _setUploading(bool uploading) {
    _isUploading = uploading;
    if (!uploading) {
      _uploadProgress = 0.0;
      _uploadStatusMessage = "";
    }
    notifyListeners();
  }

  // Helper method to convert Priority enum to string
  String _priorityToString(components.Priority priority) {
    switch (priority) {
      case components.Priority.high:
        return 'high';
      case components.Priority.medium:
        return 'medium';
      case components.Priority.low:
        return 'low';
      default:
        return 'medium';
    }
  }

  // Helper method to convert string to Priority enum
  components.Priority _priorityFromString(String priorityStr) {
    switch (priorityStr.toLowerCase()) {
      case 'high':
        return components.Priority.high;
      case 'medium':
        return components.Priority.medium;
      case 'low':
        return components.Priority.low;
      default:
        return components.Priority.medium;
    }
  }

  // Helper method to convert DocumentStatus enum to string
  String _statusToString(components.DocumentStatus status) {
    switch (status) {
      case components.DocumentStatus.approved:
        return 'approved';
      case components.DocumentStatus.rejected:
        return 'rejected';
      case components.DocumentStatus.pending:
        return 'pending';
      default:
        return 'pending';
    }
  }

  // Helper method to convert string to DocumentStatus enum
  components.DocumentStatus _statusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'approved':
        return components.DocumentStatus.approved;
      case 'rejected':
        return components.DocumentStatus.rejected;
      case 'pending':
        return components.DocumentStatus.pending;
      default:
        return components.DocumentStatus.pending;
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper method to set error
  void setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}