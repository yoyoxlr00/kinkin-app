import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'models.dart';
import 'business_dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.locationName,
    required this.restaurants,
    required this.favoriteCount,
    required this.rollHistory,
    required this.totalDirections,
    required this.onAuthChanged,
  });

  final String locationName;
  final List<Restaurant> restaurants;
  final int favoriteCount;
  final List<Restaurant> rollHistory;
  final int totalDirections;
  final VoidCallback onAuthChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool isRegisterMode = false;
  bool loading = false;
  String? errorMsg;
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (FirebaseService.currentUser == null) {
      setState(() => profileData = null);
      return;
    }
    final data = await FirebaseService.getUserProfile();
    if (mounted) setState(() => profileData = data);
  }

  Future<void> _submitAuth() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });
    try {
      if (isRegisterMode) {
        if (_nameCtrl.text.trim().isEmpty) {
          throw Exception('กรุณากรอกชื่อของคุณ');
        }
        await FirebaseService.register(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );
      } else {
        await FirebaseService.login(
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );
      }
      await _loadProfile();
      widget.onAuthChanged();
    } catch (e) {
      setState(() {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFEC693E);
    const darkGreen = Color(0xFF1F362C);
    final user = FirebaseService.currentUser;

    // กรณีล็อกอินแล้ว -> แสดงหน้าข้อมูลโปรไฟล์และสิทธิ์การใช้งาน
    if (user != null) {
      final role = profileData?['role'] ?? 'user';
      final isAdmin = role == 'admin';
      final displayName =
          profileData?['name'] ?? user.displayName ?? 'สมาชิก kinkin';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: orange.withValues(alpha: 0.15),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: orange),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                Text(
                  user.email ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFFE7F0EC)
                        : const Color(0xFFFFEFEA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAdmin
                        ? '🛡️ ผู้ดูแลระบบ / พาร์ทเนอร์ (Admin)'
                        : '🍽️ สมาชิกทั่วไป (Customer)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isAdmin ? darkGreen : orange,
                    ),
                  ),
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('ร้านโปรด', '${widget.favoriteCount}'),
                    _statItem('สุ่มร้านแล้ว', '${widget.rollHistory.length}'),
                    _statItem('นำทางแล้ว', '${widget.totalDirections}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ปุ่มพิเศษเฉพาะบัญชี Admin เท่านั้น
          if (isAdmin)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BusinessDashboardPage(
                      locationName: widget.locationName,
                      totalRolls: widget.rollHistory.length,
                      totalDirections: widget.totalDirections,
                      favoriteCount: widget.favoriteCount,
                      restaurants: widget.restaurants,
                      rollHistory: widget.rollHistory,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text(
                  'เปิดระบบวิเคราะห์ธุรกิจ (Admin Dashboard)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseService.logout();
                await _loadProfile();
                widget.onAuthChanged();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('ออกจากระบบ'),
            ),
          ),
        ],
      );
    }

    // กรณียังไม่ล็อกอิน -> แสดงฟอร์มเข้าสู่ระบบ / สมัครสมาชิก
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRegisterMode ? 'สมัครสมาชิก kinkin' : 'เข้าสู่ระบบ kinkin',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'เชื่อมต่อบัญชี Firebase เพื่อบันทึกร้านโปรดและประวัติข้ามอุปกรณ์',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          if (isRegisterMode) ...[
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'ชื่อผู้ใช้งาน',
                prefixIcon: const Icon(Icons.person_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'อีเมล',
              prefixIcon: const Icon(Icons.email_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'รหัสผ่าน (อย่างน้อย 6 ตัวอักษร)',
              prefixIcon: const Icon(Icons.lock_outline),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(errorMsg!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : _submitAuth,
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      isRegisterMode ? 'สร้างบัญชีใหม่' : 'เข้าสู่ระบบ',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                isRegisterMode = !isRegisterMode;
                errorMsg = null;
              }),
              child: Text(
                isRegisterMode
                    ? 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบที่นี่'
                    : 'ยังไม่มีบัญชี? สมัครสมาชิกใหม่',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}