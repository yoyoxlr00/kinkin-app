import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinkin/models.dart';

void main() {
  const thai = Restaurant(
      id: 'thai',
      name: 'Thai',
      address: '',
      lat: 13,
      lng: 100,
      types: ['thai_restaurant'],
      rating: 4.8,
      open: true);
  const cafe = Restaurant(
      id: 'cafe',
      name: 'Cafe',
      address: '',
      lat: 13,
      lng: 100,
      types: ['cafe'],
      rating: 4.9,
      open: false);
  const unknown = Restaurant(
      id: 'unknown',
      name: 'Unknown',
      address: '',
      lat: 13,
      lng: 100,
      types: ['thai_restaurant']);
  const far = Restaurant(
      id: 'far',
      name: 'Far',
      address: '',
      lat: 14,
      lng: 100,
      types: ['thai_restaurant'],
      rating: 5,
      open: true);

  test('combines cuisine, open status, rating and distance filters', () {
    final results = filterRestaurants([thai, cafe, unknown, far],
        cuisines: {Cuisine.thai},
        lat: 13,
        lng: 100,
        radiusKm: 3,
        openOnly: true,
        minimumRating: 4.5);
    expect(results.map((r) => r.id), ['thai']);
  });
  test(
      'multiple cuisines are OR and missing values remain visible without restrictions',
      () {
    expect(
        filterRestaurants([thai, cafe, unknown],
                cuisines: {Cuisine.thai, Cuisine.cafe},
                lat: 13,
                lng: 100,
                radiusKm: 3,
                openOnly: false,
                minimumRating: 0)
            .length,
        3);
  });
  test('random selection handles empty, singleton and excludes last pick', () {
    expect(pickRestaurant([], Random(1)), isNull);
    expect(pickRestaurant([thai], Random(1), previousId: 'thai'), thai);
    expect(pickRestaurant([thai, cafe], Random(1), previousId: 'thai'), cafe);
  });
}
