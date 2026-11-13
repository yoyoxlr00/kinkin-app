import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'restaurant_service.dart';

class RestaurantPhoto extends StatelessWidget {
  const RestaurantPhoto(
      {super.key, required this.restaurant, required this.emoji});
  final Restaurant restaurant;
  final String emoji;

  Future<void> openLink(BuildContext context, String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null || uri.scheme != 'https') return;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {/* Show a readable failure below. */}
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิดลิงก์รูปภาพได้')));
  }

  @override
  Widget build(BuildContext context) {
    final photo = restaurant.photo;
    final fallback = ColoredBox(
        color: const Color(0xFFFFF0DF),
        child:
            Center(child: Text(emoji, style: const TextStyle(fontSize: 32))));
    if (photo == null || demoMode || apiBaseUrl.isEmpty) {
      return SizedBox(
          width: 80,
          height: 80,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(16), child: fallback));
    }
    final url = Uri.parse('$apiBaseUrl/photo')
        .replace(queryParameters: {'name': photo.name});
    final source = photo.mapsUrl ?? restaurant.mapsUrl;
    return SizedBox(
        width: 96,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Semantics(
              label: 'รูป ${restaurant.name}',
              button: source != null,
              child: InkWell(
                  onTap:
                      source == null ? null : () => openLink(context, source),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        url.toString(),
                        width: 96,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) =>
                            SizedBox(width: 96, height: 88, child: fallback),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const SizedBox(
                                width: 96,
                                height: 88,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                      )))),
          for (final author in photo.authors)
            InkWell(
                onTap: author.url == null
                    ? null
                    : () => openLink(context, author.url),
                child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      if (author.avatar != null)
                        Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: ClipOval(
                                child: Image.network(author.avatar!,
                                    width: 16,
                                    height: 16,
                                    errorBuilder: (_, error, stack) =>
                                        const Icon(Icons.person_outline,
                                            size: 16)))),
                      Expanded(
                          child: Text('ภาพ: ${author.name}',
                              style: const TextStyle(fontSize: 10))),
                    ]))),
          if (source != null)
            InkWell(
                onTap: () => openLink(context, source),
                child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child:
                        Text('Google Maps ↗', style: TextStyle(fontSize: 10)))),
        ]));
  }
}
