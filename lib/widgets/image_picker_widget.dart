import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';
import 'animated_marks.dart';

/// Horizontal photo rail with a dashed "add" tile.
///
/// Capture settings and the max-of-3 limit are unchanged; only the
/// presentation was reworked.
class ImagePickerWidget extends StatelessWidget {
  final List<String> imagePaths;
  final Function(List<String>) onImagesChanged;

  static const int maxImages = 3;
  static const double _tileSize = 104;

  const ImagePickerWidget({
    super.key,
    required this.imagePaths,
    required this.onImagesChanged,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compresses image to 70% quality automatically
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile != null) {
        final updatedPaths = List<String>.from(imagePaths)
          ..add(pickedFile.path);
        onImagesChanged(updatedPaths);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
    }
  }

  void _showSourceBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Add a photo', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Clear, well-lit close-ups give the best results.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _SourceTile(
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        primary: true,
                        onTap: () => _pickImage(context, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SourceTile(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        primary: false,
                        onTap: () => _pickImage(context, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    final updatedPaths = List<String>.from(imagePaths)..removeAt(index);
    onImagesChanged(updatedPaths);
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = imagePaths.length < maxImages;

    return SizedBox(
      height: _tileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: imagePaths.length + (canAddMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == imagePaths.length) {
            return _AddTile(
              size: _tileSize,
              onTap: () => _showSourceBottomSheet(context),
              isFirst: imagePaths.isEmpty,
            );
          }
          return _Thumbnail(
            path: imagePaths[index],
            size: _tileSize,
            onRemove: () => _removeImage(index),
          );
        },
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  /// The empty state gets a label; once photos exist a bare "+" is enough.
  final bool isFirst;

  const _AddTile({
    required this.size,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.alpha(AppColors.primary, 0.55),
          radius: AppRadius.md,
        ),
        child: Container(
          width: isFirst ? size * 1.35 : size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.alpha(AppColors.primary, 0.05),
            borderRadius: AppRadius.brMd,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_a_photo_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              if (isFirst) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Add photo',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String path;
  final double size;
  final VoidCallback onRemove;

  const _Thumbnail({
    required this.path,
    required this.size,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            image: DecorationImage(
              image: FileImage(File(path)),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.alpha(AppColors.ink, 0.14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.criticalityEmergency,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    ).animate().scale(
      duration: AppDurations.medium,
      curve: Curves.easeOutBack,
      begin: const Offset(0.85, 0.85),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: primary ? AppColors.gradientPrimary : null,
          color: primary ? null : AppColors.surfaceSunken,
          borderRadius: AppRadius.brMd,
          border: primary ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : AppColors.textDark,
              size: 26,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: primary ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
