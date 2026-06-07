import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club_model.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/loading_widget.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key, this.initialClubId});

  final String? initialClubId;

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  XFile? _selectedImage;
  String? _clubId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _clubId = widget.initialClubId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit(List<ClubModel> clubs) async {
    if (!_formKey.currentState!.validate() ||
        _clubId == null ||
        _selectedDate == null) {
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final selectedClub = clubs.firstWhere((club) => club.id == _clubId);
      var photoURL = '';
      if (_selectedImage != null) {
        photoURL = await ref
            .read(storageServiceProvider)
            .uploadImage(
              _selectedImage!,
              'events/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
      }
      await ref
          .read(firestoreServiceProvider)
          .createEvent(
            EventModel(
              id: '',
              clubId: selectedClub.id,
              clubName: selectedClub.name,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              date: _selectedDate,
              location: _locationController.text.trim(),
              photoURL: photoURL,
              attendeeUids: const [],
              createdBy: user.uid,
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully.')),
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
    final clubsAsync = ref.watch(adminClubsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: clubsAsync.when(
        data: (clubs) {
          if (clubs.isEmpty) {
            return const EmptyStateWidget(
              message: 'You need to admin a club before creating an event.',
              icon: Icons.admin_panel_settings_outlined,
            );
          }
          _clubId ??= clubs.first.id;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ImagePickerWidget(
                    selectedImage: _selectedImage,
                    onImageSelected: (file) =>
                        setState(() => _selectedImage = file),
                    label: 'Upload event banner',
                    isUploading: _loading,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _clubId,
                    items: clubs.map<DropdownMenuItem<String>>((club) {
                      return DropdownMenuItem<String>(
                        value: club.id,
                        child: Text(club.name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _clubId = value),
                    decoration: const InputDecoration(labelText: 'Club'),
                    validator: (value) =>
                        value == null ? 'Select a club.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Event title'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter an event title.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter a description.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter a location.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _selectedDate == null
                          ? 'Select event date'
                          : _selectedDate.toString(),
                    ),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  GoldButton(
                    label: 'Create Event',
                    onPressed: () => _submit(clubs),
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
