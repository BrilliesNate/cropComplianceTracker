// Migration Script: Add Package Fields to Existing Data
// Run this ONCE to update existing categories and companies
//
// USAGE: In your main.dart, after Firebase.initializeApp():
//
//   await migrateAddPackageFields();
//
// Then REMOVE the line after running once!

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateAddPackageFields() async {
  final firestore = FirebaseFirestore.instance;

  int categoriesUpdated = 0;
  int companiesUpdated = 0;
  int errors = 0;

  print('\n========================================');
  print('STARTING DATABASE MIGRATION');
  print('Adding package fields to existing data...');
  print('========================================\n');

  try {
    // ============================================================
    // STEP 1: Update all existing CATEGORIES with packageId
    // ============================================================
    print('STEP 1: Adding packageId to categories...');

    final categoriesSnapshot = await firestore.collection('categories').get();
    print('Found ${categoriesSnapshot.docs.length} categories');

    for (var doc in categoriesSnapshot.docs) {
      try {
        final data = doc.data();

        // Only update if packageId doesn't exist yet
        if (!data.containsKey('packageId') || data['packageId'] == null) {
          await firestore.collection('categories').doc(doc.id).update({
            'packageId': 'siza_wieta',
          });
          categoriesUpdated++;
          print('  Updated: ${data['name']}');
        } else {
          print('  Skipped (already has packageId): ${data['name']}');
        }
      } catch (e) {
        print('  Error updating category ${doc.id}: $e');
        errors++;
      }
    }

    // ============================================================
    // STEP 2: Update all existing COMPANIES with packages array
    // ============================================================
    print('\nSTEP 2: Adding packages array to companies...');

    final companiesSnapshot = await firestore.collection('companies').get();
    print('Found ${companiesSnapshot.docs.length} companies');

    for (var doc in companiesSnapshot.docs) {
      try {
        final data = doc.data();

        // Only update if packages doesn't exist yet
        if (!data.containsKey('packages') || data['packages'] == null) {
          await firestore.collection('companies').doc(doc.id).update({
            'packages': ['siza_wieta'],
          });
          companiesUpdated++;
          print('  Updated: ${data['name']}');
        } else {
          print('  Skipped (already has packages): ${data['name']}');
        }
      } catch (e) {
        print('  Error updating company ${doc.id}: $e');
        errors++;
      }
    }

    // ============================================================
    // COMPLETE - Print results
    // ============================================================
    print('\n========================================');
    print('MIGRATION COMPLETE');
    print('========================================');
    print('Categories updated: $categoriesUpdated');
    print('Companies updated: $companiesUpdated');
    print('Errors: $errors');
    print('========================================');
    print('');
    print('NOW REMOVE the migration call from main.dart!');
    print('========================================\n');

  } catch (e) {
    print('\n========================================');
    print('MIGRATION FAILED: $e');
    print('========================================\n');
  }
}