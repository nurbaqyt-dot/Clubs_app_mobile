import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/loading_widget.dart';
import 'clubs_list_screen.dart';

class EditClubScreen extends ConsumerStatefulWidget {
  const EditClubScreen({super.key, required this.clubId});

  final String clubId;

  @override
  ConsumerState<EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends ConsumerState<EditClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Academic';
  XFile? _selectedImage;
  bool _initialized = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit(ClubModel club) async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.uid != club.adminUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the club creator can edit this club.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      var photoURL = club.photoURL;
      if (_selectedImage != null) {
        photoURL = await ref
            .read(storageServiceProvider)
            .uploadImage(_selectedImage!, 'clubs/${club.id}.jpg');
      }

      await ref
          .read(firestoreServiceProvider)
          .updateClub(
            club.copyWith(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              category: _category,
              photoURL: photoURL,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club updated successfully.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update club: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(clubProvider(widget.clubId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Club')),
      body: clubAsync.when(
        data: (club) {
          if (club == null) {
            return const EmptyStateWidget(
              message: 'This club could not be found.',
              icon: Icons.search_off_rounded,
            );
          }

          if (currentUser == null || currentUser.uid != club.adminUid) {
            return const EmptyStateWidget(
              message: 'Only the club creator can edit this club.',
              icon: Icons.lock_outline_rounded,
            );
          }

          if (!_initialized) {
            _initialized = true;
            _nameController.text = club.name;
            _descriptionController.text = club.description;
            _category = club.category;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ImagePickerWidget(
                    selectedImage: _selectedImage,
                    imageUrl: club.photoURL,
                    onImageSelected: (file) =>
                        setState(() => _selectedImage = file),
                    label: 'Update club photo',
                    isUploading: _loading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Club name'),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return 'Enter a club name.';
                      if (trimmed.length < 3) {
                        return 'Club name must be at least 3 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return 'Enter a description.';
                      if (trimmed.length < 10) {
                        return 'Description must be at least 10 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: ClubsListScreen.categories
                        .where((item) => item != 'All')
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? _category),
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Select a category.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  GoldButton(
                    label: 'Save Changes',
                    onPressed: () => _submit(club),
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this club.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
