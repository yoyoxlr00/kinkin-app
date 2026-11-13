import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const mapsEnabled = bool.fromEnvironment('MAPS_ENABLED', defaultValue: false);

class RestaurantService {
  Future<List<Restaurant>> search(
      double lat, double lng, double radiusKm, Set<Cuisine> cuisines) async {
    if (demoMode) return demoRestaurants;
    if (apiBaseUrl.isEmpty) throw Exception('กรุณาตั้งค่า API_BASE_URL');
    final response = await http
        .get(Uri.parse('$apiBaseUrl/restaurants').replace(
          queryParameters: {
            'lat': '$lat',
            'lng': '$lng',
            'radius': '${radiusKm * 1000}',
            'types': cuisines.map((c) => c.placeType).join(',')
          },
        ))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
          'ค้นหาร้านไม่สำเร็จ (${response.statusCode}) กรุณาลองใหม่');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['places'] as List)
        .map((p) => Restaurant.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}

final demoRestaurants = <Restaurant>[
  for (final entry in [
    (
      'ครัวอิ่มใจ',
      'อาหารไทย • สยาม',
      Cuisine.thai,
      13.7468,
      100.5342,
      4.8,
      true
    ),
    (
      'Sakura Table',
      'อาหารญี่ปุ่น • สยามสแควร์',
      Cuisine.japanese,
      13.7445,
      100.5350,
      4.7,
      true
    ),
    (
      'Seoul Good',
      'อาหารเกาหลี • ปทุมวัน',
      Cuisine.korean,
      13.7480,
      100.5325,
      4.6,
      true
    ),
    (
      'บ้านติ่มซำ',
      'อาหารจีน • บรรทัดทอง',
      Cuisine.chinese,
      13.7435,
      100.5250,
      4.5,
      false
    ),
    (
      'Pasta & Friends',
      'อาหารอิตาเลียน • ชิดลม',
      Cuisine.italian,
      13.7440,
      100.5420,
      4.4,
      true
    ),
    (
      'ทะเลจานโปรด',
      'ซีฟู้ด • ราชเทวี',
      Cuisine.seafood,
      13.7520,
      100.5310,
      4.3,
      true
    ),
    (
      'Green Bowl',
      'มังสวิรัติ • สยาม',
      Cuisine.vegetarian,
      13.7450,
      100.5310,
      4.9,
      true
    ),
    (
      'Slow Morning',
      'คาเฟ่ • ปทุมวัน',
      Cuisine.cafe,
      13.7488,
      100.5290,
      4.7,
      true
    ),
  ])
    Restaurant(
        id: entry.$1,
        name: entry.$1,
        address: entry.$2,
        lat: entry.$4,
        lng: entry.$5,
        types: [entry.$3.placeType],
        rating: entry.$6,
        open: entry.$7),
];
