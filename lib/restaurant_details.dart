import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'restaurant_service.dart';
import 'restaurant_photo.dart';

class RestaurantDetailsPage extends StatefulWidget {
  const RestaurantDetailsPage(
      {super.key,
      required this.restaurant,
      required this.onDirections,
      this.loader});
  final Restaurant restaurant;
  final Future<void> Function(Restaurant) onDirections;
  final Future<Restaurant> Function(Restaurant)? loader;
  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  late Restaurant restaurant = widget.restaurant;
  bool loading = true;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final result = await (widget.loader ??
          RestaurantService().details)(widget.restaurant);
      if (!mounted) return;
      setState(() {
        restaurant = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        failed = true;
        loading = false;
      });
    }
  }

  Future<void> open(String value, {bool phone = false}) async {
    final uri = phone
        ? Uri(scheme: 'tel', path: value.replaceAll(RegExp(r'[^0-9+]'), ''))
        : Uri.tryParse(value);
    if (uri == null || (!phone && !['https', 'http'].contains(uri.scheme)))
      return;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('อุปกรณ์นี้เปิดลิงก์ไม่ได้ สามารถคัดลอกข้อมูลไปใช้ได้')));
  }

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final cuisine =
        Cuisine.values.where((c) => r.types.contains(c.placeType)).firstOrNull;
    return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดร้าน')),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child:
                        ListView(padding: const EdgeInsets.all(20), children: [
                      if (demoMode)
                        const Text('ข้อมูลสมมติสำหรับทดลอง',
                            style: TextStyle(color: Colors.brown)),
                      if (loading) const LinearProgressIndicator(),
                      if (failed)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(children: [
                                  const Text(
                                      'โหลดรายละเอียดเพิ่มเติมไม่สำเร็จ ข้อมูลเดิมยังแสดงอยู่'),
                                  TextButton.icon(
                                      onPressed: load,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('ลองใหม่')),
                                ]))),
                      const SizedBox(height: 16),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RestaurantPhoto(
                                restaurant: r, emoji: cuisine?.emoji ?? '🍽️'),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(r.name,
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold)),
                                  if (cuisine != null) Text(cuisine.label),
                                  const SizedBox(height: 8),
                                  Text(
                                      '★ ${r.rating?.toStringAsFixed(1) ?? "ยังไม่มีคะแนน"}'),
                                  Text(r.open == null
                                      ? 'ไม่ทราบสถานะเปิด–ปิด'
                                      : r.open!
                                          ? 'เปิดอยู่'
                                          : 'ปิดอยู่'),
                                ])),
                          ]),
                      const SizedBox(height: 24),
                      const Text('งบประมาณ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(r.priceLabel, style: const TextStyle(fontSize: 20)),
                      const Text(
                          'ระดับราคาจาก Google ไม่ใช่ราคาต่อคนหรือราคาของทุกเมนู',
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 24),
                      const Text('ที่อยู่',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SelectableText(
                          r.address.isEmpty ? 'ไม่มีข้อมูลที่อยู่' : r.address),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        FilledButton.icon(
                            onPressed: () => widget.onDirections(r),
                            icon: const Icon(Icons.directions),
                            label: const Text('นำทางไปร้าน')),
                        if (r.mapsUrl != null)
                          OutlinedButton.icon(
                              onPressed: () => open(r.mapsUrl!),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('ดูใน Google Maps')),
                      ]),
                      const SizedBox(height: 24),
                      const Text('เวลาเปิดปกติ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (r.hours.isEmpty)
                        const Text('ร้านนี้ยังไม่มีข้อมูลเวลาเปิด'),
                      ...r.hours.map((h) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(h))),
                      if (r.hours.isNotEmpty)
                        const Text('วันหยุดและวันพิเศษอาจเปิดต่างจากเวลาปกติ',
                            style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 24),
                      const Text('ติดต่อร้าน',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (r.phone == null)
                        const Text('ไม่มีข้อมูลเบอร์โทร')
                      else
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.phone_outlined),
                            title: SelectableText(r.phone!),
                            onTap: () => open(r.phone!, phone: true),
                            trailing: IconButton(
                                tooltip: 'คัดลอกเบอร์โทร',
                                icon: const Icon(Icons.copy),
                                onPressed: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: r.phone!));
                                  if (context.mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('คัดลอกเบอร์โทรแล้ว')));
                                })),
                      if (r.website == null)
                        const Text('ไม่มีข้อมูลเว็บไซต์')
                      else
                        TextButton.icon(
                            onPressed: () => open(r.website!),
                            icon: const Icon(Icons.language),
                            label: const Text('เปิดเว็บไซต์ร้าน')),
                      const SizedBox(height: 24),
                      if (!demoMode)
                        const Text('ข้อมูลร้านจาก Google Maps',
                            textAlign: TextAlign.center),
                    ])))));
  }
}
