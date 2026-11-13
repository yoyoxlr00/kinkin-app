import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'restaurant_service.dart';
import 'location_picker.dart';
import 'restaurant_photo.dart';
import 'restaurant_details.dart';

const orange = Color(0xFFEC693E);
void main() => runApp(const KinkinApp());

class KinkinApp extends StatelessWidget {
  const KinkinApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'kinkin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFFFBF5),
            colorScheme:
                ColorScheme.fromSeed(seedColor: orange, primary: orange),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFFBF5)),
            cardTheme: const CardThemeData(elevation: 0, color: Colors.white),
            inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none))),
        home: const DiscoverPage(),
      );
}

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
  double lat = 13.7465, lng = 100.5345, radius = 3, rating = 0;
  bool openOnly = false, loading = true, locating = false;
  String? error, previousId;
  String? budget;
  String query = '';
  String locationName = 'สยาม กรุงเทพฯ';
  int tab = 0, requestId = 0;

  List<Restaurant> get results => filterRestaurants(restaurants,
          cuisines: cuisines,
          lat: lat,
          lng: lng,
          radiusKm: radius,
          openOnly: openOnly,
          minimumRating: rating, priceLevel: budget)
      .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    search();
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

  void notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> chooseLocation() async {
    final choice = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('เลือกพื้นที่ค้นหาร้าน',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              ListTile(
                  leading: const Icon(Icons.my_location),
                  title: const Text('ใช้ตำแหน่งของฉัน'),
                  onTap: () => Navigator.pop(context, 'gps')),
              ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('ค้นหาสถานที่'),
                  onTap: () => Navigator.pop(context, 'search')),
              ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: const Text('ปักหมุดบนแผนที่'),
                  subtitle: mapsEnabled
                      ? null
                      : const Text('เปิดใช้ Google Maps เพื่อปักหมุด'),
                  enabled: mapsEnabled,
                  onTap: () => Navigator.pop(context, 'map')),
              ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('มหาวิทยาลัยธุรกิจบัณฑิตย์'),
                  subtitle: const Text('ค้นหาร้านรอบมหาวิทยาลัย'),
                  onTap: () => Navigator.pop(context, 'dpu')),
              const SizedBox(height: 12),
            ])));
    if (!mounted || choice == null) return;
    if (choice == 'gps') {
      await locate();
      return;
    }
    SearchLocation? selected;
    if (choice == 'dpu') {
      selected = dpuLocation;
    } else if (choice == 'search') {
      selected = await Navigator.push<SearchLocation>(context,
          MaterialPageRoute(builder: (_) => const LocationSearchPage()));
    } else if (choice == 'map') {
      selected = await Navigator.push<SearchLocation>(
          context,
          MaterialPageRoute(
              builder: (_) => MapLocationPage(
                  initial: SearchLocation(locationName, lat, lng))));
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
      notice('โหมดตัวอย่างใช้ตำแหน่งสยาม กรุงเทพฯ');
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
            'ยังไม่ได้รับสิทธิ์ตำแหน่ง คุณสามารถค้นหาจากสยามหรือเปิดสิทธิ์ในการตั้งค่า');
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(timeLimit: Duration(seconds: 15)));
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

  void roll() {
    if (loading || error != null) return;
    final picked = pickRestaurant(results, random, previousId: previousId);
    if (picked == null) {
      notice('ยังไม่มีร้านตรงกับตัวกรอง ลองเพิ่มระยะทางหรือเปลี่ยนประเภทอาหาร');
      return;
    }
    previousId = picked.id;
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🎉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('มื้อนี้… ไปร้านนี้กัน!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  restaurantCard(picked),
                  const SizedBox(height: 16),
                  TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        roll();
                      },
                      icon: const Icon(Icons.shuffle),
                      label: const Text('ขอสุ่มอีกครั้ง')),
                ]))));
  }

  Widget restaurantCard(Restaurant r) {
    final cuisine =
        Cuisine.values.where((c) => r.types.contains(c.placeType)).firstOrNull;
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFF0E8DE))),
        child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => RestaurantDetailsPage(restaurant: r, onDirections: directions))),
          borderRadius: BorderRadius.circular(22), child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              RestaurantPhoto(restaurant: r, emoji: cuisine?.emoji ?? '🍽️'),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(r.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(r.priceLabel, style: const TextStyle(color: Colors.brown, fontSize: 12)),
                    Text(r.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                        '★ ${r.rating?.toStringAsFixed(1) ?? "–"}  •  ${r.distanceFrom(lat, lng).toStringAsFixed(1)} กม.',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                        r.open == null
                            ? 'ไม่ทราบเวลาเปิด'
                            : r.open!
                                ? 'เปิดอยู่'
                                : 'ปิดอยู่',
                        style: TextStyle(
                            color: r.open == true
                                ? const Color(0xFF338263)
                                : Colors.black45,
                            fontSize: 12)),
                  ])),
              IconButton(
                  tooltip: 'เส้นทางไปร้าน',
                  onPressed: () => directions(r),
                  icon: const Icon(Icons.north_east, color: orange)),
            ]))));
  }

  Widget filters() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('วันนี้อยากกินอะไร?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 4, children: [
          FilterChip(
              label: const Text('🍽️ ทั้งหมด'),
              selected: cuisines.isEmpty,
              onSelected: (_) {
                setState(() => cuisines = {});
                search();
              }),
          for (final c in Cuisine.values)
            FilterChip(
                label: Text('${c.emoji} ${c.label}'),
                selected: cuisines.contains(c),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      cuisines.add(c);
                    } else {
                      cuisines.remove(c);
                    }
                  });
                  search();
                }),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.near_me_outlined, size: 18),
          const SizedBox(width: 8),
          Text('ระยะ ${radius.round()} กม.'),
          Expanded(
              child: Slider(
                  value: radius,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${radius.round()} กม.',
                  onChanged: (v) {
                    ++requestId;
                    setState(() {
                      radius = v;
                      loading = true;
                    });
                  },
                  onChangeEnd: (_) => search()))
        ]),
        Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                  label: const Text('เปิดอยู่ตอนนี้'),
                  selected: openOnly,
                  onSelected: (v) => setState(() => openOnly = v)),
              FilterChip(
                  label: const Text('★ 4.5 ขึ้นไป'),
                  selected: rating > 0,
                  onSelected: (v) => setState(() => rating = v ? 4.5 : 0)),
            ]),
        const SizedBox(height: 12),
        const Text('งบประมาณ', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(label: const Text('ทุกงบ'), selected: budget == null,
            onSelected: (_) => setState(() => budget = null)),
          for (final entry in priceLabels.entries) ChoiceChip(label: Text(entry.value), selected: budget == entry.key,
            onSelected: (_) => setState(() => budget = budget == entry.key ? null : entry.key)),
          ChoiceChip(label: const Text('ไม่ทราบราคา'), selected: budget == 'unknown',
            onSelected: (_) => setState(() => budget = budget == 'unknown' ? null : 'unknown')),
        ]),
        const Text('ระดับราคาจาก Google • ไม่ใช่ราคาต่อคน', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 20),
      ]);

  Widget content() {
    if (loading) {
      return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Column(children: [
        Text(error!, textAlign: TextAlign.center),
        TextButton.icon(
            onPressed: search,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองใหม่'))
      ]);
    }
    final visible = results;
    if (visible.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(32),
          child: Column(children: [
            Text('🍽️', style: TextStyle(fontSize: 44)),
            SizedBox(height: 12),
            Text('ยังไม่เจอร้านที่ใช่',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('ลองเพิ่มระยะทาง หรือลดตัวกรองบางรายการ',
                textAlign: TextAlign.center),
          ]));
    }
    if (tab == 1) {
      if (!mapsEnabled) {
        return Container(
            height: 260,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: const Color(0xFFEAF0E6),
                borderRadius: BorderRadius.circular(24)),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.map_outlined, size: 56, color: Color(0xFF338263)),
              SizedBox(height: 16),
              Text('แผนที่พร้อมเมื่อเชื่อม Google Maps',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('ขณะนี้ดูร้านและระยะทางได้ในหน้าสำรวจ',
                  textAlign: TextAlign.center)
            ]));
      }
      return SizedBox(
          height: 400,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GoogleMap(
                  key: ValueKey('$lat,$lng,$radius'),
                  initialCameraPosition:
                      CameraPosition(target: LatLng(lat, lng), zoom: 13),
                  circles: {
                    Circle(
                        circleId: const CircleId('radius'),
                        center: LatLng(lat, lng),
                        radius: radius * 1000,
                        fillColor: orange.withValues(alpha: .08),
                        strokeColor: orange,
                        strokeWidth: 1)
                  },
                  markers: visible
                      .map((r) => Marker(
                          markerId: MarkerId(r.id),
                          position: LatLng(r.lat, r.lng),
                          infoWindow: InfoWindow(
                              title: r.name,
                              snippet: 'แตะเพื่อเปิดเส้นทาง',
                              onTap: () => directions(r))))
                      .toSet())));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('ร้านที่น่าลอง (${visible.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        const Text('ใกล้ที่สุดก่อน',
            style: TextStyle(color: Colors.black45, fontSize: 12))
      ]),
      const SizedBox(height: 12),
      ...visible.map(restaurantCard),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('kinkin',
                style: TextStyle(
                    color: orange,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5)),
            actions: [
              TextButton.icon(
                  onPressed: locating ? null : chooseLocation,
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: SizedBox(
                      width: 170,
                      child: Text(locating ? 'กำลังหาตำแหน่ง…' : locationName,
                          maxLines: 1, overflow: TextOverflow.ellipsis)))
            ]),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: RefreshIndicator(
                        onRefresh: search,
                        child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              if (demoMode)
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text(
                                        'โหมดตัวอย่าง • ร้านทั้งหมดเป็นข้อมูลสมมติ',
                                        style: TextStyle(
                                            color: Colors.brown,
                                            fontSize: 12))),
                              const Text('ความอร่อยอยู่ใกล้คุณ',
                                  style: TextStyle(
                                      fontSize: 29,
                                      fontWeight: FontWeight.w800)),
                              const Text(
                                  'เลือกรสชาติที่ชอบ แล้วออกไปเจอมื้อโปรดกัน',
                                  style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 22),
                              TextField(
                                  onChanged: (v) =>
                                      setState(() => query = v.trim()),
                                  decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.search),
                                      hintText: 'ค้นหาชื่อร้านในผลลัพธ์')),
                              const SizedBox(height: 24),
                              filters(),
                              Container(
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF283F35),
                                      borderRadius: BorderRadius.circular(24)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                            'คิดไม่ออก? ให้ kinkin เลือกให้ 🎲',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        const Text(
                                            'สุ่มร้านจากตัวกรองและผลค้นหาที่คุณเลือก',
                                            style: TextStyle(
                                                color: Color(0xFFD0DDD3))),
                                        const SizedBox(height: 14),
                                        FilledButton.icon(
                                            onPressed: loading || error != null
                                                ? null
                                                : roll,
                                            icon: const Icon(Icons.shuffle),
                                            label: const Text(
                                                'สุ่มเลย มื้อนี้กินอะไรดี')),
                                      ])),
                              content(),
                              const SizedBox(height: 16),
                              Text(
                                  demoMode
                                      ? 'kinkin • มื้อเล็ก ๆ ความสุขใหญ่ ๆ'
                                      : 'Google Maps • แสดงผลใกล้เคียงสูงสุด 20 ร้านต่อการค้นหา',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.black45, fontSize: 12)),
                            ]))))),
        bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant),
                  label: 'สำรวจร้าน'),
              NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'แผนที่')
            ]),
      );
}
