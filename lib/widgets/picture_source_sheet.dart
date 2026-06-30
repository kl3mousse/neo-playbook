import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/combofox_theme.dart';

/// Shows a classic "+ Picture" action sheet asking whether to take a photo
/// or choose from the gallery. Returns the chosen [ImageSource] or null if
/// the user cancels. Reused anywhere collection item photos are edited.
Future<ImageSource?> showPictureSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: ComboFoxColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ComboFoxColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: ComboFoxColors.neonBlue,
              ),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: ComboFoxColors.neonPurple,
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
