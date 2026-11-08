import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/app_snackbar.dart';
import 'network_image_view.dart';

Future<XFile?> pickChatImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(context: context,
    builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photo library'),
        onTap: () => Navigator.pop(context, ImageSource.gallery)),
      ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Camera'),
        onTap: () => Navigator.pop(context, ImageSource.camera)),
    ])));
  if (source == null) return null;
  try {
    return await ImagePicker().pickImage(source: source, maxWidth: 1080, maxHeight: 1080, imageQuality: 80);
  } catch (_) {
    if (context.mounted) AppSnackbar.showError(context, 'Photo access is unavailable. Check camera or photo permissions.');
    return null;
  }
}

class ChatImageView extends StatelessWidget {
  final String? imageUrl;
  final double? height, width;
  final double borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;
  const ChatImageView({super.key, this.imageUrl, this.height, this.width,
    this.borderRadius = 8, this.fit = BoxFit.cover, this.fallbackIcon = Icons.broken_image_outlined});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: imageUrl == null ? null : () => Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Photo')),
        body: Center(child: InteractiveViewer(minScale: 1, maxScale: 5,
          child: NetworkImageView(imageUrl: imageUrl, fit: BoxFit.contain, borderRadius: 0))))),
    ),
    child: NetworkImageView(imageUrl: imageUrl, height: height, width: width,
      borderRadius: borderRadius, fit: fit, fallbackIcon: fallbackIcon),
  );
}
