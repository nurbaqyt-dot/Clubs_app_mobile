import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/announcement_model.dart';
import '../../providers/announcements_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/loading_widget.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key, this.announcementId});

  final String? announcementId;

  bool get isEditing => announcementId != null;

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;
  bool _didSeed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save(AnnouncementModel? existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final controller = ref.read(announcementControllerProvider);
      if (existing == null) {
        final id = await controller.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created successfully.')),
        );
        context.go('/announcements/$id');
      } else {
        await controller.update(
          announcement: existing,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated successfully.')),
        );
        context.go('/announcements/${existing.id}');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement could not be saved: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    if (profile?.isHead != true) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Edit Announcement' : 'Create Announcement',
          ),
        ),
        body: const EmptyStateWidget(
          message: 'Only heads can create or edit announcements.',
          icon: Icons.lock_outline_rounded,
        ),
      );
    }

    if (!widget.isEditing) {
      return _AnnouncementFormScaffold(
        title: 'Create Announcement',
        formKey: _formKey,
        titleController: _titleController,
        descriptionController: _descriptionController,
        isSaving: _isSaving,
        onSubmit: () => _save(null),
      );
    }

    final announcementAsync = ref.watch(
      announcementProvider(widget.announcementId!),
    );
    return announcementAsync.when(
      data: (announcement) {
        if (announcement == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Announcement')),
            body: const EmptyStateWidget(
              message: 'This announcement could not be found.',
              icon: Icons.search_off_rounded,
            ),
          );
        }

        if (!_didSeed) {
          _titleController.text = announcement.title;
          _descriptionController.text = announcement.description;
          _didSeed = true;
        }

        return _AnnouncementFormScaffold(
          title: 'Edit Announcement',
          formKey: _formKey,
          titleController: _titleController,
          descriptionController: _descriptionController,
          isSaving: _isSaving,
          onSubmit: () => _save(announcement),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Announcement')),
        body: const LoadingWidget(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Announcement')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load announcement.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementFormScaffold extends StatelessWidget {
  const _AnnouncementFormScaffold({
    required this.title,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.isSaving,
    required this.onSubmit,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool isSaving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Share the headline of the update',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Write the full announcement details',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              GoldButton(
                label: isSaving ? 'Saving...' : title,
                onPressed: onSubmit,
                icon: Icons.campaign_outlined,
                isLoading: isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
