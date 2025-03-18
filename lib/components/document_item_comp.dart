// Add this to your DocumentItem class in document_item_comp.dart
import 'package:flutter/foundation.dart';

enum Priority { high, medium, low }

enum DocumentStatus { approved, rejected, pending }

class DocumentItem {
  final int id;
  String title;
  Priority priority;
  DocumentStatus status;
  DateTime expiryDate;
  String category;
  String? filePath;
  String? storageRef; // Added to store Firebase Storage reference

  DocumentItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.expiryDate,
    required this.category,
    this.filePath,
    this.storageRef,
  });
}