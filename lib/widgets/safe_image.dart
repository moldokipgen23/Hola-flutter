import 'package:flutter/material.dart';
import '../services/api.dart';

/// Image.network that prepends the backend origin to relative storage paths
/// and shows a graceful fallback instead of throwing on a broken URL.
class SafeImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackEmoji;
  final double emojiSize;

  const SafeImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackEmoji = '🏪',
    this.emojiSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiClient.imageUrl(path);
    if (url.isEmpty) {
      return _fallback();
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _fallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return SizedBox(
      width: width,
      height: height,
      child: Center(child: Text(fallbackEmoji, style: TextStyle(fontSize: emojiSize))),
    );
  }
}
