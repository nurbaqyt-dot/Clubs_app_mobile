import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/loading_widget.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  XFile? _selectedImage;
  bool _initialized = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppUser profile) async {
    if (!_formKey.currentState!.validate()) return;
    final firebaseUser = ref.read(currentUserProvider);
    if (firebaseUser == null) return;
    setState(() => _loading = true);
    try {
      var photoURL = profile.profileImage;
      if (_selectedImage != null) {
        photoURL = await ref
            .read(storageServiceProvider)
            .uploadImage(_selectedImage!, 'profiles/${firebaseUser.uid}.jpg');
      }
      await firebaseUser.updateDisplayName(_nameController.text.trim());
      await firebaseUser.updatePhotoURL(photoURL);
      await ref
          .read(firestoreServiceProvider)
          .updateUserProfile(
            uid: firebaseUser.uid,
            fullName: _nameController.text.trim(),
            email: profile.email,
            studentId: _studentIdController.text.trim(),
            role: profile.role,
            profileImage: photoURL,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        Navigator.pop(context);
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
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }
          if (!_initialized) {
            _initialized = true;
            _nameController.text = profile.fullName;
            _studentIdController.text = profile.studentId;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ImagePickerWidget(
                    selectedImage: _selectedImage,
                    imageUrl: profile.profileImage,
                    onImageSelected: (file) =>
                        setState(() => _selectedImage = file),
                    label: 'Choose avatar',
                    isUploading: _loading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter your name.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(labelText: 'Student ID'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter your student ID.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: profile.email,
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: profile.role.value,
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  const SizedBox(height: 24),
                  GoldButton(
                    label: 'Save Profile',
                    onPressed: () => _submit(profile),
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
