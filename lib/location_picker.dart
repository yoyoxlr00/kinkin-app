import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'restaurant_service.dart';

class SearchLocation {
  const SearchLocation(this.name, this.lat, this.lng, [this.address = '']);
  final String name, address;
  final double lat, lng;
}

const dpuLocation = SearchLocation('มหาวิทยาลัยธุรกิจบัณฑิตย์', 13.8711,
    100.5500, 'ถนนประชาชื่น เขตหลักสี่ กรุงเทพฯ');

Future<List<SearchLocation>> findLocations(String query) async {
  if (demoMode) {
    return [
      dpuLocation,
      const SearchLocation('สยาม กรุงเทพฯ', 13.7465, 100.5345)
    ].where((p) => p.name.contains(query.trim())).toList();
  }
  if (apiBaseUrl.isEmpty) throw Exception('ยังไม่ได้เชื่อมต่อบริการค้นหา');
  final response = await http
      .get(Uri.parse('$apiBaseUrl/locations')
          .replace(queryParameters: {'q': query.trim()}))
      .timeout(const Duration(seconds: 20));
  if (response.statusCode != 200) {
    throw Exception('ค้นหาสถานที่ไม่สำเร็จ กรุณาลองใหม่');
  }
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return (data['places'] as List)
      .map((p) => SearchLocation(
          p['displayName']?['text'] ?? 'สถานที่',
          (p['location']['latitude'] as num).toDouble(),
          (p['location']['longitude'] as num).toDouble(),
          p['formattedAddress'] ?? ''))
      .toList();
}

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key, this.lookup = findLocations});
  final Future<List<SearchLocation>> Function(String) lookup;
  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final controller = TextEditingController();
  List<SearchLocation> places = [];
  bool loading = false, searched = false;
  String? error;
  int request = 0;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = controller.text.trim();
    final id = ++request;
    if (query.length < 2) {
      setState(() {
        error = 'กรอกชื่อสถานที่อย่างน้อย 2 ตัวอักษร';
        loading = false;
        places = [];
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
      places = [];
    });
    try {
      final found = await widget.lookup(query);
      if (!mounted || id != request) return;
      setState(() {
        places = found;
        loading = false;
        searched = true;
      });
    } catch (_) {
      if (!mounted || id != request) return;
      setState(() {
        loading = false;
        error = 'ค้นหาสถานที่ไม่สำเร็จ ตรวจสอบการเชื่อมต่อแล้วกดค้นหาอีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ค้นหาสถานที่')),
        body: SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  ++request;
                  setState(() {
                    loading = false;
                    searched = false;
                    error = null;
                    places = [];
                  });
                },
                onSubmitted: (_) => search(),
                decoration: InputDecoration(
                    hintText: 'เช่น อารีย์ เชียงใหม่ หรือชื่อมหาวิทยาลัย',
                    suffixIcon: IconButton(
                        tooltip: 'ค้นหา',
                        onPressed: search,
                        icon: const Icon(Icons.search))),
              )),
          if (demoMode)
            const Text('โหมดตัวอย่าง: ค้นหาได้เฉพาะสยามและธุรกิจบัณฑิตย์'),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
          if (searched && !loading && places.isEmpty && error == null)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('ไม่พบสถานที่ ลองระบุชื่อเขตหรือจังหวัดเพิ่ม')),
          Expanded(
              child: ListView.builder(
                  itemCount: places.length,
                  itemBuilder: (context, i) {
                    final place = places[i];
                    return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(place.name),
                        subtitle: Text(place.address),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, place));
                  })),
          if (!demoMode)
            const Padding(
                padding: EdgeInsets.all(12), child: Text('Google Maps')),
        ])),
      );
}

class MapLocationPage extends StatefulWidget {
  const MapLocationPage({super.key, required this.initial});
  final SearchLocation initial;
  @override
  State<MapLocationPage> createState() => _MapLocationPageState();
}

class _MapLocationPageState extends State<MapLocationPage> {
  late LatLng point = LatLng(widget.initial.lat, widget.initial.lng);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ปักหมุดบนแผนที่')),
        body: SafeArea(
            child: Column(children: [
          const Padding(
              padding: EdgeInsets.all(12),
              child: Text('แตะจุดบนแผนที่ หรือลากหมุดไปยังพื้นที่ที่ต้องการ')),
          Expanded(
              child: GoogleMap(
            initialCameraPosition: CameraPosition(target: point, zoom: 15),
            onTap: (p) => setState(() => point = p),
            markers: {
              Marker(
                  markerId: const MarkerId('selected'),
                  position: point,
                  draggable: true,
                  onDragEnd: (p) => setState(() => point = p))
            },
            myLocationButtonEnabled: false,
          )),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(
                    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'),
                const SizedBox(height: 8),
                FilledButton.icon(
                    onPressed: () => Navigator.pop(
                        context,
                        SearchLocation('ตำแหน่งที่ปักหมุด', point.latitude,
                            point.longitude)),
                    icon: const Icon(Icons.check),
                    label: const Text('ค้นหาร้านรอบจุดนี้')),
              ])),
        ])),
      );
}
