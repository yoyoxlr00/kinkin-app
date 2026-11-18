import 'dart:math';

enum Cuisine {
  thai('อาหารไทย', '🍛', 'thai_restaurant'),
  japanese('ญี่ปุ่น', '🍣', 'japanese_restaurant'),
  korean('เกาหลี', '🥘', 'korean_restaurant'),
  chinese('จีน', '🥟', 'chinese_restaurant'),
  italian('อิตาเลียน', '🍝', 'italian_restaurant'),
  seafood('ซีฟู้ด', '🦐', 'seafood_restaurant'),
  vegetarian('มังสวิรัติ', '🥗', 'vegetarian_restaurant'),
  cafe('คาเฟ่', '☕', 'cafe');

  const Cuisine(this.label, this.emoji, this.placeType);
  final String label, emoji, placeType;
}

class Restaurant {
  const Restaurant(
      {required this.id,
      required this.name,
      required this.address,
      required this.lat,
      required this.lng,
      required this.types,
      this.rating,
      this.open,
      this.photo,
      this.priceLevel,
      this.phone,
      this.website,
      this.hours = const [],
      this.mapsUrl});
  final String? priceLevel, phone, website;
  final List<String> hours;
  String get priceLabel => priceLabels[priceLevel] ?? 'ไม่ทราบราคา';
  final PlacePhoto? photo;
  final String id, name, address;
  final double lat, lng;
  final List<String> types;
  final double? rating;
  final bool? open;
  final String? mapsUrl;

  bool get isPartner => id.hashCode.abs() % 4 == 0;
  String? get partnerPromo =>
      isPartner ? '🎁 ดีลพิเศษ: ลด 10% เมื่อโชว์หน้าแอป kinkin' : null;

  // แปลง Object เป็น Map เพื่อบันทึกลง Storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': {'text': name},
        'formattedAddress': address,
        'location': {'latitude': lat, 'longitude': lng},
        'types': types,
        'rating': rating,
        'currentOpeningHours': open != null ? {'openNow': open} : null,
        'googleMapsUri': mapsUrl,
        'priceLevel': priceLevel,
        'nationalPhoneNumber': phone,
        'websiteUri': website,
        'regularOpeningHours': {'weekdayDescriptions': hours},
        'photos': photo != null
            ? [
                {'name': photo!.name, 'googleMapsUri': photo!.mapsUrl}
              ]
            : [],
      };

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as String,
        name: (json['displayName']?['text'] as String?) ?? 'ร้านอาหาร',
        address: json['formattedAddress'] as String? ?? '',
        lat: (json['location']['latitude'] as num).toDouble(),
        lng: (json['location']['longitude'] as num).toDouble(),
        types: List<String>.from(json['types'] ?? []),
        rating: (json['rating'] as num?)?.toDouble(),
        open: json['currentOpeningHours']?['openNow'] as bool?,
        mapsUrl: json['googleMapsUri'] as String?,
        priceLevel: json['priceLevel'] as String?,
        phone: json['nationalPhoneNumber'] as String?,
        website: json['websiteUri'] as String?,
        hours: List<String>.from(
            json['regularOpeningHours']?['weekdayDescriptions'] ?? []),
        photo: (json['photos'] as List?)?.isNotEmpty == true
            ? PlacePhoto.fromJson(json['photos'][0] as Map<String, dynamic>)
            : null,
      );

  double distanceFrom(double latitude, double longitude) {
    double rad(double v) => v * pi / 180;
    final a = pow(sin(rad(lat - latitude) / 2), 2) +
        cos(rad(latitude)) *
            cos(rad(lat)) *
            pow(sin(rad(lng - longitude) / 2), 2);
    return 6371 * 2 * asin(sqrt(a.clamp(0, 1)));
  }
}

class PlacePhoto {
  const PlacePhoto(this.name, this.authors, this.mapsUrl);
  final String name;
  final List<PhotoAuthor> authors;
  final String? mapsUrl;
  factory PlacePhoto.fromJson(Map<String, dynamic> json) => PlacePhoto(
        json['name'] as String,
        (json['authorAttributions'] as List? ?? [])
            .map((a) => PhotoAuthor(a['displayName'] as String? ?? 'เจ้าของภาพ',
                a['uri'] as String?, a['photoUri'] as String?))
            .toList(),
        json['googleMapsUri'] as String?,
      );
}

class PhotoAuthor {
  const PhotoAuthor(this.name, this.url, this.avatar);
  final String name;
  final String? url, avatar;
}

List<Restaurant> filterRestaurants(
  List<Restaurant> restaurants, {
  required Set<Cuisine> cuisines,
  required double lat,
  required double lng,
  required double radiusKm,
  required bool openOnly,
  required double minimumRating,
  String? priceLevel,
}) =>
    restaurants
        .where((r) =>
            (priceLevel == null ||
                (priceLevel == 'unknown'
                    ? !priceLabels.containsKey(r.priceLevel)
                    : r.priceLevel == priceLevel)) &&
            (cuisines.isEmpty ||
                cuisines.any((c) => r.types.contains(c.placeType))) &&
            (!openOnly || r.open == true) &&
            (minimumRating == 0 ||
                (r.rating != null && r.rating! >= minimumRating)) &&
            r.distanceFrom(lat, lng) <= radiusKm)
        .toList()
      ..sort((a, b) =>
          a.distanceFrom(lat, lng).compareTo(b.distanceFrom(lat, lng)));

Restaurant? pickRestaurant(List<Restaurant> candidates, Random random,
    {String? previousId}) {
  if (candidates.isEmpty) return null;
  final pool = candidates.length > 1
      ? candidates.where((r) => r.id != previousId).toList()
      : candidates;
  return pool[random.nextInt(pool.length)];
}

const priceLabels = <String, String>{
  'PRICE_LEVEL_FREE': 'ไม่มีค่าใช้จ่าย',
  'PRICE_LEVEL_INEXPENSIVE': '฿ ประหยัด',
  'PRICE_LEVEL_MODERATE': '฿฿ ปานกลาง',
  'PRICE_LEVEL_EXPENSIVE': '฿฿฿ ราคาสูง',
  'PRICE_LEVEL_VERY_EXPENSIVE': '฿฿฿฿ พรีเมียม',
};