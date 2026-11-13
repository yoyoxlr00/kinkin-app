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
      this.mapsUrl});
  final PlacePhoto? photo;
  final String id, name, address;
  final double lat, lng;
  final List<String> types;
  final double? rating;
  final bool? open;
  final String? mapsUrl;

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
}) =>
    restaurants
        .where((r) =>
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
