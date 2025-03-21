import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../models/document_type_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/app_drawer.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/responsive_layout.dart';
import 'widgets/category_progress_bar.dart';
import 'widgets/document_status_list.dart';

class AuditTrackerScreen extends StatefulWidget {
  const AuditTrackerScreen({Key? key}) : super(key: key);

  @override
  State<AuditTrackerScreen> createState() => _AuditTrackerScreenState();
}

class _AuditTrackerScreenState extends State<AuditTrackerScreen> {
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await categoryProvider.initialize();
      await documentProvider.initialize(authProvider.currentUser!.companyId);

      // Set first category as selected if available
      if (categoryProvider.categories.isNotEmpty && mounted) {
        setState(() {
          _selectedCategory = categoryProvider.categories.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = documentProvider.isLoading || categoryProvider.isLoading;
    final hasError = documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Audit Tracker',
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const LoadingIndicator(message: 'Loading audit data...')
          : hasError
          ? ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      )
          : ResponsiveLayout(
        mobileView: _buildMobileView(context),
        tabletView: _buildTabletView(context),
        desktopView: _buildDesktopView(context),
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildCategoryDropdown(categories),
        ),
        if (_selectedCategory != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CategoryProgressBar(categoryId: _selectedCategory!.id),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DocumentStatusList(
              categoryId: _selectedCategory!.id,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabletView(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildCategoryDropdown(categories),
        ),
        if (_selectedCategory != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CategoryProgressBar(categoryId: _selectedCategory!.id),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DocumentStatusList(
              categoryId: _selectedCategory!.id,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 250,
          child: Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory?.id == category.id;

                return ListTile(
                  title: Text(category.name),
                  selected: isSelected,
                  selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  leading: Icon(
                    Icons.folder,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),
        ),
        Expanded(
          child: _selectedCategory != null
              ? Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCategory!.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedCategory!.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    CategoryProgressBar(categoryId: _selectedCategory!.id),
                  ],
                ),
              ),
              Expanded(
                child: DocumentStatusList(
                  categoryId: _selectedCategory!.id,
                ),
              ),
            ],
          )
              : const Center(
            child: Text('Select a category to view documents'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(List<CategoryModel> categories) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select Category',
        border: OutlineInputBorder(),
      ),
      value: _selectedCategory?.id,
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final selected = categories.firstWhere((c) => c.id == value);
          setState(() {
            _selectedCategory = selected;
          });
        }
      },
    );
  }
}