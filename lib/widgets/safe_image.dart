import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api.dart';

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
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _fallback(),
      errorWidget: (context, url, error) => _fallback(),
    );
  }

  Widget _fallback() {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(fallbackEmoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}
