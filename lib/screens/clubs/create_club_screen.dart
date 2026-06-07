import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import 'clubs_list_screen.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/image_picker_widget.dart';

class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categories = ClubsListScreen.categories
      .where((item) => item != 'All')
      .toList();
  String _category = 'Academic';
  XFile? _selectedImage;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final firebaseUser = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (firebaseUser == null || profile == null) return;
    if (!profile.isHead) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only heads can create clubs.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      var photoURL = '';
      if (_selectedImage != null) {
        photoURL = await ref
            .read(storageServiceProvider)
            .uploadImage(
              _selectedImage!,
              'clubs/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
      }
      await ref
          .read(firestoreServiceProvider)
          .createClub(
            ClubModel(
              id: '',
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              category: _category,
              photoURL: photoURL,
              adminUid: firebaseUser.uid,
              memberCount: 1,
              memberUids: [firebaseUser.uid],
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club created successfully.')),
        );
        context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Club')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerWidget(
                selectedImage: _selectedImage,
                onImageSelected: (file) =>
                    setState(() => _selectedImage = file),
                label: 'Upload club photo',
                isUploading: _loading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Club name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a club name.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a description.'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 24),
              GoldButton(
                label: 'Create Club',
                onPressed: _submit,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
