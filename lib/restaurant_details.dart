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
  bool voucherClaimed = false;

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
    if (uri == null || (!phone && !['https', 'http'].contains(uri.scheme))) {
      return;
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('อุปกรณ์นี้เปิดลิงก์ไม่ได้ สามารถคัดลอกข้อมูลไปใช้ได้')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final cuisine =
        Cuisine.values.where((c) => r.types.contains(c.placeType)).firstOrNull;
    const orange = Color(0xFFEC693E);
    const darkGreen = Color(0xFF1F362C);

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดร้าน')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (demoMode)
                  const Text('ข้อมูลสมมติสำหรับทดลอง',
                      style: TextStyle(color: Colors.brown)),
                if (loading) const LinearProgressIndicator(color: orange),
                if (failed)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                              'โหลดรายละเอียดเพิ่มเติมไม่สำเร็จ ข้อมูลเดิมยังแสดงอยู่'),
                          TextButton.icon(
                              onPressed: load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('ลองใหม่')),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RestaurantPhoto(
                        restaurant: r, emoji: cuisine?.emoji ?? '🍽️'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          if (cuisine != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('${cuisine.emoji} ${cuisine.label}',
                                  style:
                                      const TextStyle(color: Colors.black54)),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF6E0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '★ ${r.rating?.toStringAsFixed(1) ?? "ยังไม่มีคะแนน"}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB87A00)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: r.open == true
                                      ? const Color(0xFFE6F4EE)
                                      : const Color(0xFFFDECEC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  r.open == null
                                      ? 'ไม่ทราบเวลาเปิด'
                                      : r.open!
                                          ? 'เปิดอยู่ตอนนี้'
                                          : 'ปิดอยู่',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: r.open == true
                                        ? const Color(0xFF237A57)
                                        : const Color(0xFFC63636),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ==========================================
                // กล่องสิทธิพิเศษสำหรับร้านพาร์ทเนอร์ (Business Model)
                // ==========================================
                if (r.isPartner) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF8E7), Color(0xFFFFECC2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFFCA62), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_offer_rounded,
                                color: Color(0xFFB36B00), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'สิทธิพิเศษพาร์ทเนอร์ kinkin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7A4900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'รับส่วนลดค่าอาหารทันที 10% เมื่อแสดงรหัสคูปองนี้กับพนักงานที่ร้าน (จำกัด 1 สิทธิ์/ใบเสร็จ)',
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFF5C3800)),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE5B85C)),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('โค้ดส่วนลด:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                    Text(
                                      'KINKIN10',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                        color: orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(
                                    const ClipboardData(text: 'KINKIN10'));
                                setState(() => voucherClaimed = true);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'คัดลอกโค้ด KINKIN10 แล้ว! แสดงให้ร้านค้าเพื่อรับส่วนลดได้เลย'),
                                    ),
                                  );
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    voucherClaimed ? darkGreen : orange,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: Icon(
                                voucherClaimed
                                    ? Icons.check_circle_outline
                                    : Icons.copy_rounded,
                                size: 18,
                              ),
                              label: Text(
                                  voucherClaimed ? 'รับสิทธิ์แล้ว' : 'เก็บโค้ด'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Text('งบประมาณ',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(r.priceLabel, style: const TextStyle(fontSize: 20)),
                const Text(
                    'ระดับราคาจาก Google ไม่ใช่ราคาต่อคนหรือราคาของทุกเมนู',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                const Text('ที่อยู่',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SelectableText(
                    r.address.isEmpty ? 'ไม่มีข้อมูลที่อยู่' : r.address),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => widget.onDirections(r),
                      style: FilledButton.styleFrom(backgroundColor: orange),
                      icon: const Icon(Icons.directions),
                      label: const Text('นำทางไปร้าน'),
                    ),
                    if (r.mapsUrl != null)
                      OutlinedButton.icon(
                        onPressed: () => open(r.mapsUrl!),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('ดูใน Google Maps'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('เวลาเปิดปกติ',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        await Clipboard.setData(ClipboardData(text: r.phone!));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('คัดลอกเบอร์โทรแล้ว')));
                        }
                      },
                    ),
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}