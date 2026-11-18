import 'package:flutter/material.dart';
import 'models.dart';

class BusinessDashboardPage extends StatelessWidget {
  const BusinessDashboardPage({
    super.key,
    required this.locationName,
    required this.totalRolls,
    required this.totalDirections,
    required this.favoriteCount,
    required this.restaurants,
    required this.rollHistory,
  });

  final String locationName;
  final int totalRolls;
  final int totalDirections;
  final int favoriteCount;
  final List<Restaurant> restaurants;
  final List<Restaurant> rollHistory;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFEC693E);
    const creamBg = Color(0xFFFAF7F2);
    const darkGreen = Color(0xFF1F362C);

    // คำนวณจำนวนร้านพาร์ทเนอร์ในพื้นที่ปัจจุบัน
    final partnerCount = restaurants.where((r) => r.isPartner).length;

    // วิเคราะห์สัดส่วนประเภทอาหารในพื้นที่ปัจจุบัน
    final Map<Cuisine, int> cuisineStats = {};
    for (final c in Cuisine.values) {
      final count =
          restaurants.where((r) => r.types.contains(c.placeType)).length;
      if (count > 0) {
        cuisineStats[c] = count;
      }
    }
    final sortedCuisines = cuisineStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: creamBg,
        title: const Text(
          'Business Insights & Analytics',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header แสดงพื้นที่วิเคราะห์
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [darkGreen, Color(0xFF2E5142)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '📊 DPU Digital Business Analytics',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ภาพรวมข้อมูลธุรกิจย่าน: $locationName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'วิเคราะห์จากฐานข้อมูลร้านอาหาร ${restaurants.length} แห่ง และพฤติกรรมผู้ใช้งานแบบเรียลไทม์',
                        style: const TextStyle(
                            color: Color(0xFFC8D8CE), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ตัวเลข KPI 4 ช่อง
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _kpiCard(
                      title: 'จำนวนการกดสุ่มร้าน',
                      value: '$totalRolls ครั้ง',
                      subtitle: 'User Engagement',
                      icon: Icons.casino_rounded,
                      color: orange,
                    ),
                    _kpiCard(
                      title: 'ยอดกดนำทางไปร้าน',
                      value: '$totalDirections ครั้ง',
                      subtitle: 'Conversion to Visit',
                      icon: Icons.directions_rounded,
                      color: const Color(0xFF237A57),
                    ),
                    _kpiCard(
                      title: 'ร้านพาร์ทเนอร์ในพื้นที่',
                      value: '$partnerCount ร้าน',
                      subtitle: 'โอกาสสร้างรายได้ GP/Ads',
                      icon: Icons.handshake_rounded,
                      color: const Color(0xFFC58300),
                    ),
                    _kpiCard(
                      title: 'ร้านที่ถูกบันทึกโปรด',
                      value: '$favoriteCount ร้าน',
                      subtitle: 'Customer Retention',
                      icon: Icons.favorite_rounded,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // กราฟแท่งวิเคราะห์สัดส่วนประเภทร้านอาหารในพื้นที่
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สัดส่วนหมวดหมู่อาหารในพื้นที่ (Market Supply)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ข้อมูลสำหรับวางแผนเจาะกลุ่มร้านค้าพาร์ทเนอร์',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      if (sortedCuisines.isEmpty)
                        const Text('ยังไม่มีข้อมูลหมวดหมู่เฉพาะในชุดผลลัพธ์นี้',
                            style: TextStyle(color: Colors.black45))
                      else
                        ...sortedCuisines.map((entry) {
                          final ratio = restaurants.isEmpty
                              ? 0.0
                              : entry.value / restaurants.length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${entry.key.emoji}${entry.key.label}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5),
                                    ),
                                    Text(
                                      '${entry.value} ร้าน (${(ratio * 100).toStringAsFixed(0)}%)',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: darkGreen),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFF3EEE7),
                                    color: orange,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ประวัติการสุ่มล่าสุด (User Behavior Log)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ประวัติการสุ่มร้านล่าสุด (Activity Log)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'บันทึกผลลัพธ์เพื่อใช้วิเคราะห์ความชอบของผู้ใช้',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      if (rollHistory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'ยังไม่มีประวัติการสุ่ม ลองกลับไปกดปุ่ม "สุ่มเลย" ในหน้าหลัก',
                              style: TextStyle(
                                  color: Colors.black45, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ...rollHistory.reversed.take(5).map(
                              (r) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor:
                                      orange.withValues(alpha: 0.12),
                                  child: const Icon(Icons.restaurant,
                                      color: orange, size: 18),
                                ),
                                title: Text(r.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                subtitle: Text(
                                    '★ ${r.rating?.toStringAsFixed(1) ?? "-"} • ${r.priceLabel}',
                                    style: const TextStyle(fontSize: 12)),
                                trailing: r.isPartner
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF4D9),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text('Partner',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFB36B00))),
                                      )
                                    : null,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}