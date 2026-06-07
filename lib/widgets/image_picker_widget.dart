import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({
    super.key,
    this.selectedImage,
    this.imageUrl,
    required this.onImageSelected,
    this.label = 'Choose Image',
    this.isUploading = false,
  });

  final XFile? selectedImage;
  final String? imageUrl;
  final ValueChanged<XFile> onImageSelected;
  final String label;
  final bool isUploading;

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  bool get _isPickerSupported {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _pick(ImageSource source) async {
    if (widget.isUploading) return;
    if (!_isPickerSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picking is not supported on this platform.'),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        widget.onImageSelected(picked);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _buildPreview() {
    if (widget.selectedImage != null) {
      return FutureBuilder<Uint8List>(
        future: widget.selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
            ),
          );
        },
      );
    }

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          widget.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image_outlined, size: 44),
            );
          },
        ),
      );
    }

    return const Center(child: Icon(Icons.photo_camera_back_rounded, size: 44));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPreview(),
              if (widget.isUploading)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.isUploading
                    ? null
                    : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(widget.label),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.isUploading
                    ? null
                    : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
