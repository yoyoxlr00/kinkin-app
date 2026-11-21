import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'firebase_service.dart' as fb ;
import 'models.dart';
import 'restaurant_service.dart';
import 'location_picker.dart';
import 'restaurant_photo.dart';
import 'restaurant_details.dart';
import 'local_storage.dart';
import 'profile_page.dart';

const orange = Color(0xFFEC693E);
const creamBg = Color(0xFFFAF7F2);
const darkGreen = Color(0xFF1F362C);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KinkinApp());
}

class KinkinApp extends StatelessWidget {
  const KinkinApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'kinkin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: creamBg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: orange,
            primary: orange,
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: creamBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            color: Colors.white,
          ),
        ),
        home: const WelcomePage(),
      );
}

// ==========================================
// หน้าต้อนรับก่อนเข้าแอป (Welcome Screen)
// ==========================================
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enterApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const DiscoverPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orange.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: darkGreen.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF37D55), orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(34),
                              boxShadow: [
                                BoxShadow(
                                  color: orange.withValues(alpha: 0.32),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.ramen_dining_rounded,
                                size: 54,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'kinkin',
                                style: TextStyle(
                                  color: orange,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2.0,
                                ),
                              ),
                              SizedBox(width: 5),
                              CircleAvatar(
                                radius: 4.5,
                                backgroundColor: darkGreen,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'มื้อนี้กินอะไรดี? ให้เราช่วยเลือกให้',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E1E1E),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'รวมร้านเด็ดใกล้ตัว คัดกรองตามงบและสไตล์ที่ชอบ\nพร้อมฟีเจอร์สุ่มร้านสำหรับคนตัดสินใจไม่ถูก',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border:
                                  Border.all(color: const Color(0xFFEDE6DC)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                _FeatureRow(
                                  icon: Icons.explore_rounded,
                                  iconBg: Color(0xFFFFEFEA),
                                  iconColor: orange,
                                  title: 'ค้นหาร้านอร่อยรอบตัว',
                                  subtitle:
                                      'กรองประเภทอาหาร ระยะทาง และช่วงราคาได้ทันที',
                                ),
                                Divider(height: 24, color: Color(0xFFF3EEE7)),
                                _FeatureRow(
                                  icon: Icons.casino_rounded,
                                  iconBg: Color(0xFFE7F0EC),
                                  iconColor: darkGreen,
                                  title: 'สุ่มร้านจบปัญหาคิดไม่ออก',
                                  subtitle:
                                      'กดสุ่ม 1 ครั้ง ได้ร้านที่ตรงใจพร้อมออกเดินทาง',
                                ),
                                Divider(height: 24, color: Color(0xFFF3EEE7)),
                                _FeatureRow(
                                  icon: Icons.near_me_rounded,
                                  iconBg: Color(0xFFFFF6E0),
                                  iconColor: Color(0xFFC58300),
                                  title: 'เปิดแผนที่นำทางทันที',
                                  subtitle:
                                      'ดูพิกัดบนแผนที่และกดนำทางไปหน้าร้านได้เลย',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF37D55), orange],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: orange.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _enterApp,
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(child: Text(
                                        'เริ่มใช้งาน kinkin',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      )),
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'พร้อมแล้วกดปุ่มด้านบนเพื่อสำรวจร้านอร่อยได้เลย',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// หน้าหลักค้นหาร้าน (Discover Page)
// ==========================================
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final service = RestaurantService();
  final random = Random();
  Set<Cuisine> cuisines = {};
  List<Restaurant> restaurants = [];
  late Map<String, Restaurant> favoriteMap;
  late List<Restaurant> rollHistory;
  late int totalDirectionsCount;

  double lat = dpuLocation.lat, lng = dpuLocation.lng, radius = 3, rating = 0;
  bool openOnly = false, loading = true, locating = false;
  String? error, previousId;
  String? budget;
  String query = '';
  String locationName = dpuLocation.name;
  int tab = 0, requestId = 0;

  List<Restaurant> get results => filterRestaurants(
        restaurants,
        cuisines: cuisines,
        lat: lat,
        lng: lng,
        radiusKm: radius,
        openOnly: openOnly,
        minimumRating: rating,
        priceLevel: budget,
      )
          .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

  int get activeFilterCount =>
      (openOnly ? 1 : 0) +
      (rating > 0 ? 1 : 0) +
      (budget != null ? 1 : 0) +
      (radius != 3 ? 1 : 0);

  @override
  void initState() {
    super.initState();
    favoriteMap = LocalStorageService.loadFavorites();
    rollHistory = LocalStorageService.loadHistory();
    totalDirectionsCount = LocalStorageService.loadDirectionsCount();
    _syncFirebaseFavorites();
    search();
  }

  Future<void> _syncFirebaseFavorites() async {
    if (fb.FirebaseService.currentUser != null) {
      final cloudFavs = await fb.FirebaseService.loadFavorites();
      if (mounted) {
        setState(() {
          favoriteMap = cloudFavs;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          favoriteMap = LocalStorageService.loadFavorites();
        });
      }
    }
  }

  Future<void> search() async {
    final id = ++requestId;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await service.search(lat, lng, radius, Set.of(cuisines));
      if (!mounted || id != requestId) return;
      setState(() {
        restaurants = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted || id != requestId) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  void notice(String text) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Future<void> chooseLocation() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'เลือกพื้นที่ค้นหาร้าน',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location, color: orange, size: 20),
                ),
                title: const Text('ใช้ตำแหน่งปัจจุบันของฉัน',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, 'gps'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search, size: 20),
                ),
                title: const Text('ค้นหาสถานที่ / ย่าน',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, 'search'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_location_alt_outlined, size: 20),
                ),
                title: const Text('ปักหมุดบนแผนที่',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: mapsEnabled
                    ? null
                    : const Text('เปิดใช้ Google Maps เพื่อปักหมุด'),
                enabled: mapsEnabled,
                onTap: () => Navigator.pop(context, 'map'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_outlined,
                      color: Colors.blueAccent, size: 20),
                ),
                title: const Text('มหาวิทยาลัยธุรกิจบัณฑิตย์',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('ค้นหาร้านอร่อยรอบมหาวิทยาลัย'),
                onTap: () => Navigator.pop(context, 'dpu'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'gps') {
      await locate();
      return;
    }
    SearchLocation? selected;
    if (choice == 'dpu') {
      selected = dpuLocation;
    } else if (choice == 'search') {
      selected = await Navigator.push<SearchLocation>(
        context,
        MaterialPageRoute(builder: (_) => const LocationSearchPage()),
      );
    } else if (choice == 'map') {
      selected = await Navigator.push<SearchLocation>(
        context,
        MaterialPageRoute(
          builder: (_) => MapLocationPage(
            initial: SearchLocation(locationName, lat, lng),
          ),
        ),
      );
    }
    if (!mounted || selected == null) return;
    setState(() {
      lat = selected!.lat;
      lng = selected.lng;
      locationName = selected.name;
      previousId = null;
    });
    await search();
  }

  Future<void> locate() async {
    if (demoMode) {
      notice('โหมดตัวอย่างไม่ใช้ GPS ร้านตัวอย่างอยู่บริเวณสยาม');
      return;
    }
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('กรุณาเปิดบริการตำแหน่งบนอุปกรณ์');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
            'ยังไม่ได้รับสิทธิ์ตำแหน่ง คุณสามารถค้นหาจากพื้นที่ที่เลือกหรือเปิดสิทธิ์ในการตั้งค่า');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(timeLimit: Duration(seconds: 15)),
      );
      if (!mounted) return;
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        locationName = 'ตำแหน่งของฉัน';
        previousId = null;
      });
      await search();
    } catch (e) {
      if (mounted) notice(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> directions(Restaurant r) async {
    setState(() {
      totalDirectionsCount++;
      LocalStorageService.saveDirectionsCount(totalDirectionsCount);
    });
    fb.FirebaseService.logActivity(action: 'directions', restaurant: r);
    if (demoMode) {
      notice('ร้านนี้เป็นข้อมูลสมมติ จึงยังไม่มีเส้นทางไปร้านจริง');
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${r.lat},${r.lng}',
      'destination_place_id': r.id,
    });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        notice('ไม่สามารถเปิดแผนที่ได้');
      }
    } catch (_) {
      if (mounted) notice('ไม่สามารถเปิดแผนที่ได้');
    }
  }

  Future<void> roll() async {
    if (loading || error != null) return;
    final currentResults = results;
    if (currentResults.isEmpty) {
      notice('ยังไม่มีร้านตรงกับตัวกรอง ลองเพิ่มระยะทางหรือเปลี่ยนประเภทอาหาร');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: creamBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: orange),
            const SizedBox(height: 20),
            const Text(
              'กำลังสุ่มร้านเด็ดให้คุณ...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'คัดจาก ${currentResults.length} ร้านที่ตรงเงื่อนไข',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pop(context);

    final picked =
        pickRestaurant(currentResults, random, previousId: previousId);
    if (picked == null) return;
    setState(() {
      previousId = picked.id;
      rollHistory.add(picked);
      LocalStorageService.saveHistory(rollHistory);
    });
    fb.FirebaseService.logActivity(action: 'roll', restaurant: picked);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: creamBg,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎉', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 12),
              const Text(
                'มื้อนี้… ไปร้านนี้กัน!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              restaurantCard(picked),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailsPage(
                          restaurant: picked,
                          onDirections: directions,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('ดูรายละเอียดร้าน'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        roll();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.shuffle),
                      label: const Text('สุ่มใหม่'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        directions(picked);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.directions),
                      label: const Text('นำทางเลย'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'ตัวกรองการค้นหา',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          radius = 3;
                          openOnly = false;
                          rating = 0;
                          budget = null;
                        });
                        setModalState(() {});
                        search();
                      },
                      child: const Text('รีเซ็ตทั้งหมด'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined, size: 18, color: orange),
                    const SizedBox(width: 8),
                    Text(
                      'รัศมีการค้นหา: ${radius.round()} กม.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Slider(
                  value: radius,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: orange,
                  label: '${radius.round()} กม.',
                  onChanged: (v) {
                    setModalState(() => radius = v);
                    setState(() => radius = v);
                  },
                  onChangeEnd: (_) => search(),
                ),
                const SizedBox(height: 12),
                const Text('เงื่อนไขร้าน',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    FilterChip(
                      label: const Text('🟢 เปิดอยู่ตอนนี้'),
                      selected: openOnly,
                      selectedColor: orange.withValues(alpha: 0.15),
                      checkmarkColor: orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) {
                        setModalState(() => openOnly = v);
                        setState(() => openOnly = v);
                      },
                    ),
                    FilterChip(
                      label: const Text('⭐ 4.5 ขึ้นไป'),
                      selected: rating > 0,
                      selectedColor: orange.withValues(alpha: 0.15),
                      checkmarkColor: orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) {
                        setModalState(() => rating = v ? 4.5 : 0);
                        setState(() => rating = v ? 4.5 : 0);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('งบประมาณ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('ทุกงบ'),
                      selected: budget == null,
                      selectedColor: orange.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (_) {
                        setModalState(() => budget = null);
                        setState(() => budget = null);
                      },
                    ),
                    for (final entry in priceLabels.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: budget == entry.key,
                        selectedColor: orange.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        onSelected: (_) {
                          final next = budget == entry.key ? null : entry.key;
                          setModalState(() => budget = next);
                          setState(() => budget = next);
                        },
                      ),
                    ChoiceChip(
                      label: const Text('ไม่ทราบราคา'),
                      selected: budget == 'unknown',
                      selectedColor: orange.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (_) {
                        final next = budget == 'unknown' ? null : 'unknown';
                        setModalState(() => budget = next);
                        setState(() => budget = next);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'ระดับราคาจาก Google • ไม่ใช่ราคาต่อคน',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: darkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('ดูผลลัพธ์ (${results.length} ร้าน)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget restaurantCard(Restaurant r) {
    final cuisine =
        Cuisine.values.where((c) => r.types.contains(c.placeType)).firstOrNull;
    final isFav = favoriteMap.containsKey(r.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: r.isPartner
            ? Border.all(color: const Color(0xFFFFD180), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailsPage(
                restaurant: r,
                onDirections: directions,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: RestaurantPhoto(
                    restaurant: r,
                    emoji: cuisine?.emoji ?? '🍽️',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.isPartner)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4D9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '✨ ร้านพาร์ทเนอร์ • ลด 10%',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB36B00),
                            ),
                          ),
                        ),
                      Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '★ ${r.rating?.toStringAsFixed(1) ?? "–"}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB87A00),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${r.distanceFrom(lat, lng).toStringAsFixed(1)} กม.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (r.open != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: r.open!
                                    ? const Color(0xFFE6F4EE)
                                    : const Color(0xFFFDECEC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                r.open! ? 'เปิดอยู่' : 'ปิดแล้ว',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: r.open!
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
                const SizedBox(width: 4),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'บันทึกเป็นร้านโปรด',
                      onPressed: () {
                        setState(() {
                          if (isFav) {
                            favoriteMap.remove(r.id);
                          } else {
                            favoriteMap[r.id] = r;
                            notice('เพิ่ม "${r.name}" ในร้านโปรดแล้ว ❤️');
                          }
                          LocalStorageService.saveFavorites(favoriteMap);
                          fb.FirebaseService.toggleFavorite(r, !isFav);
                        });
                      },
                      icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? Colors.redAccent : Colors.black38,
                        size: 22,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: 'เส้นทางไปร้าน',
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        onPressed: () => directions(r),
                        icon: const Icon(Icons.north_east_rounded,
                            color: orange, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget categoryStrip() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryPill(
            label: '🍽️ ทั้งหมด',
            selected: cuisines.isEmpty,
            onTap: () {
              setState(() => cuisines = {});
              search();
            },
          ),
          for (final c in Cuisine.values)
            _categoryPill(
              label: '${c.emoji} ${c.label}',
              selected: cuisines.contains(c),
              onTap: () {
                setState(() {
                  if (cuisines.contains(c)) {
                    cuisines.remove(c);
                  } else {
                    cuisines.add(c);
                  }
                });
                search();
              },
            ),
        ],
      ),
    );
  }

  Widget _categoryPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? orange : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? orange : const Color(0xFFEBE4DA),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: orange.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget quickFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            avatar: Icon(
              Icons.tune_rounded,
              size: 16,
              color: activeFilterCount > 0 ? Colors.white : Colors.black87,
            ),
            label: Text(
              activeFilterCount > 0
                  ? 'ตัวกรอง ($activeFilterCount)'
                  : 'ตัวกรอง',
              style: TextStyle(
                color: activeFilterCount > 0 ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            backgroundColor: activeFilterCount > 0 ? darkGreen : Colors.white,
            side: BorderSide(
              color: activeFilterCount > 0
                  ? darkGreen
                  : const Color(0xFFEBE4DA),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onPressed: openFilterSheet,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('เปิดอยู่ตอนนี้', style: TextStyle(fontSize: 12.5)),
            selected: openOnly,
            selectedColor: orange.withValues(alpha: 0.14),
            checkmarkColor: orange,
            backgroundColor: Colors.white,
            side:
                BorderSide(color: openOnly ? orange : const Color(0xFFEBE4DA)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) => setState(() => openOnly = v),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('★ 4.5 ขึ้นไป', style: TextStyle(fontSize: 12.5)),
            selected: rating > 0,
            selectedColor: orange.withValues(alpha: 0.14),
            checkmarkColor: orange,
            backgroundColor: Colors.white,
            side: BorderSide(
                color: rating > 0 ? orange : const Color(0xFFEBE4DA)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) => setState(() => rating = v ? 4.5 : 0),
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: Text(
              'ระยะ ${radius.round()} กม.',
              style: const TextStyle(fontSize: 12.5),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFEBE4DA)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onPressed: openFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget content() {
    if (tab == 3) {
      return ProfilePage(
        locationName: locationName,
        restaurants: restaurants,
        favoriteCount: favoriteMap.length,
        rollHistory: rollHistory,
        totalDirections: totalDirectionsCount,
        onAuthChanged: _syncFirebaseFavorites,
      );
    }

    if (tab == 2) {
      final favList = favoriteMap.values.toList();
      if (favList.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            children: [
              Icon(Icons.favorite_border_rounded,
                  size: 48, color: Colors.black26),
              SizedBox(height: 12),
              Text(
                'ยังไม่มีร้านโปรดที่บันทึกไว้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'กดไอคอนรูปหัวใจบนการ์ดร้านอาหารที่ถูกใจ\nเพื่อเก็บไว้ดูย้อนหลังตรงนี้ได้เลย',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ร้านโปรดของคุณ (${favList.length})',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...favList.map(restaurantCard),
        ],
      );
    }

    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(56),
        child: Center(child: CircularProgressIndicator(color: orange)),
      );
    }
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 42, color: Colors.black38),
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: search,
              style: FilledButton.styleFrom(backgroundColor: orange),
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }
    final visible = results;
    if (visible.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Text('🍽️', style: TextStyle(fontSize: 44)),
            SizedBox(height: 12),
            Text(
              'ยังไม่เจอร้านที่ใช่',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'ลองขยายระยะทาง หรือกดรีเซ็ตตัวกรองบางรายการ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (tab == 1) {
      if (!mapsEnabled) {
        return Container(
          height: 280,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0E6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 52, color: Color(0xFF338263)),
              SizedBox(height: 14),
              Text(
                'แผนที่พร้อมเมื่อเชื่อม Google Maps',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'ขณะนี้ดูร้านและระยะทางได้ในหน้าสำรวจ',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return SizedBox(
        height: 440,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GoogleMap(
            key: ValueKey('$lat,$lng,$radius'),
            initialCameraPosition:
                CameraPosition(target: LatLng(lat, lng), zoom: 13.5),
            circles: {
              Circle(
                circleId: const CircleId('radius'),
                center: LatLng(lat, lng),
                radius: radius * 1000,
                fillColor: orange.withValues(alpha: .08),
                strokeColor: orange,
                strokeWidth: 1,
              ),
            },
            markers: visible
                .map(
                  (r) => Marker(
                    markerId: MarkerId(r.id),
                    position: LatLng(r.lat, r.lng),
                    infoWindow: InfoWindow(
                      title: r.name,
                      snippet: 'แตะเพื่อเปิดเส้นทาง',
                      onTap: () => directions(r),
                    ),
                  ),
                )
                .toSet(),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ร้านน่าลองใกล้คุณ (${visible.length})',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'เรียงตามระยะทาง',
                style: TextStyle(color: Colors.black54, fontSize: 11.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...visible.map(restaurantCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Text(
                'kinkin',
                style: TextStyle(
                  color: orange,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              SizedBox(width: 4),
              CircleAvatar(radius: 3.5, backgroundColor: darkGreen),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: locating ? null : chooseLocation,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEBE4DA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: orange),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          locating ? 'กำลังหาพิกัด…' : locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: Colors.black45),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: RefreshIndicator(
                color: orange,
                onRefresh: search,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    if (demoMode)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'โหมดตัวอย่าง • ร้านทั้งหมดเป็นข้อมูลสมมติ',
                          style: TextStyle(color: Colors.brown, fontSize: 12),
                        ),
                      ),
                    if (tab < 2) ...[
                      const Text(
                        'มื้อนี้กินอะไรดี?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ค้นหาร้านอร่อยใกล้ตัว หรือให้ kinkin ช่วยสุ่มให้เลย',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => query = v.trim()),
                          decoration: const InputDecoration(
                            prefixIcon:
                                Icon(Icons.search_rounded, color: orange),
                            hintText: 'ค้นหาชื่อร้านในผลลัพธ์…',
                            hintStyle:
                                TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      categoryStrip(),
                      const SizedBox(height: 12),
                      quickFilterChips(),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D352B), Color(0xFF2E5142)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      '✨ ตัวช่วยตัดสินใจ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'คิดไม่ออก? ให้ kinkin เลือกให้',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'สุ่มจากร้านที่ตรงกับเงื่อนไขของคุณ',
                                    style: TextStyle(
                                      color: Color(0xFFC8D8CE),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton.icon(
                                    onPressed:
                                        loading || error != null ? null : roll,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(Icons.casino_rounded,
                                        size: 20),
                                    label: const Text(
                                      'สุ่มเลย มื้อนี้กินอะไรดี',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    content(),
                    const SizedBox(height: 20),
                    Text(
                      demoMode
                          ? 'kinkin • มื้อเล็ก ๆ ความสุขใหญ่ ๆ'
                          : 'Google Maps • แสดงผลใกล้เคียงสูงสุด 20 ร้านต่อการค้นหา',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: Colors.white,
            indicatorColor: orange.withValues(alpha: 0.15),
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant, color: orange),
                label: 'สำรวจร้าน',
              ),
              const NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map, color: orange),
                label: 'แผนที่',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: favoriteMap.isNotEmpty,
                  label: Text('${favoriteMap.length}'),
                  child: const Icon(Icons.favorite_outline),
                ),
                selectedIcon: const Icon(Icons.favorite, color: orange),
                label: 'ร้านโปรด',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: orange),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      );
}
