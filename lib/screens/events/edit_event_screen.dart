import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club_model.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';
import '../../providers/events_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/loading_widget.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  const EditEventScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  XFile? _selectedImage;
  String? _clubId;
  bool _initialized = false;
  bool _loading = false;

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
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
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

  Future<void> _submit(EventModel event, List<ClubModel> clubs) async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _clubId == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      final selectedClub = clubs.firstWhere((club) => club.id == _clubId);
      var photoURL = event.photoURL;
      if (_selectedImage != null) {
        photoURL = await ref
            .read(storageServiceProvider)
            .uploadImage(_selectedImage!, 'events/${event.id}.jpg');
      }
      await ref
          .read(firestoreServiceProvider)
          .updateEvent(
            event.copyWith(
              clubId: selectedClub.id,
              clubName: selectedClub.name,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              location: _locationController.text.trim(),
              date: _selectedDate,
              photoURL: photoURL,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully.')),
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
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final clubsAsync = ref.watch(adminClubsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found.'));
          }
          return clubsAsync.when(
            data: (clubs) {
              if (!_initialized) {
                _initialized = true;
                _titleController.text = event.title;
                _descriptionController.text = event.description;
                _locationController.text = event.location;
                _selectedDate = event.date;
                _clubId = event.clubId;
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ImagePickerWidget(
                        selectedImage: _selectedImage,
                        imageUrl: event.photoURL,
                        onImageSelected: (file) =>
                            setState(() => _selectedImage = file),
                        label: 'Update event banner',
                        isUploading: _loading,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _clubId,
                        items: clubs
                            .map<DropdownMenuItem<String>>(
                              (club) => DropdownMenuItem<String>(
                                value: club.id,
                                child: Text(club.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _clubId = value),
                        decoration: const InputDecoration(labelText: 'Club'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event title',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Enter an event title.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Enter a description.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
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
                        label: 'Save Changes',
                        onPressed: () => _submit(event, clubs),
                        isLoading: _loading,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LoadingWidget(),
            error: (error, _) => Center(child: Text(error.toString())),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
