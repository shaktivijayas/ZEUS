import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zeus/core/nutrition/food_search_repository.dart';
import 'package:zeus/models/food_entry.dart';

void main() {
  test('search parses well-formed products into FoodSearchResult', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'products': [
            {
              'product_name': 'Rolled Oats',
              'nutriments': {
                'energy-kcal_100g': 380,
                'proteins_100g': 13,
                'carbohydrates_100g': 68,
                'fat_100g': 7,
              },
            },
          ],
        }),
        200,
      );
    });
    final repo = FoodSearchRepository(client);

    final results = await repo.search('oats');

    expect(results, hasLength(1));
    expect(results.first.name, 'Rolled Oats');
    expect(results.first.caloriesPer100g, 380);
    expect(results.first.proteinPer100g, 13);
  });

  test('search filters out products missing a nutriment field', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'products': [
            {
              'product_name': 'Mystery Item',
              'nutriments': {'proteins_100g': 13, 'carbohydrates_100g': 68, 'fat_100g': 7},
            },
            {
              'product_name': 'Rolled Oats',
              'nutriments': {
                'energy-kcal_100g': 380,
                'proteins_100g': 13,
                'carbohydrates_100g': 68,
                'fat_100g': 7,
              },
            },
          ],
        }),
        200,
      );
    });
    final repo = FoodSearchRepository(client);

    final results = await repo.search('oats');

    expect(results, hasLength(1));
    expect(results.first.name, 'Rolled Oats');
  });

  test('search filters out products with a missing or blank name', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'products': [
            {
              'product_name': '',
              'nutriments': {
                'energy-kcal_100g': 100,
                'proteins_100g': 1,
                'carbohydrates_100g': 1,
                'fat_100g': 1,
              },
            },
          ],
        }),
        200,
      );
    });
    final repo = FoodSearchRepository(client);

    final results = await repo.search('x');

    expect(results, isEmpty);
  });

  test('search throws FoodSearchException on a non-200 response', () async {
    final client = MockClient((request) async => http.Response('Server error', 500));
    final repo = FoodSearchRepository(client);

    expect(() => repo.search('oats'), throwsA(isA<FoodSearchException>()));
  });

  test('search sends a descriptive User-Agent header', () async {
    http.BaseRequest? capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(jsonEncode({'products': []}), 200);
    });
    final repo = FoodSearchRepository(client);

    await repo.search('oats');

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.headers['User-Agent'], isNotNull);
    expect(capturedRequest!.headers['User-Agent'], isNotEmpty);
  });

  test('search throws FoodSearchException when the request times out', () async {
    final client = MockClient((request) async {
      // Simulate a slow/unresponsive network without a real HTTP call.
      await Future.delayed(const Duration(milliseconds: 200));
      return http.Response(jsonEncode({'products': []}), 200);
    });
    final repo = FoodSearchRepository(client, timeout: const Duration(milliseconds: 20));

    expect(() => repo.search('oats'), throwsA(isA<FoodSearchException>()));
  });

  test('FoodSearchResult.scaledEntry scales per-100g figures by the given quantity', () {
    const result = FoodSearchResult(
      name: 'Rolled Oats',
      caloriesPer100g: 380,
      proteinPer100g: 13,
      carbsPer100g: 68,
      fatPer100g: 7,
    );

    final entry = result.scaledEntry(50);

    expect(entry.name, 'Rolled Oats');
    expect(entry.calories, 190);
    expect(entry.protein, 6.5);
    expect(entry.carbs, 34);
    expect(entry.fat, 3.5);
    expect(entry.quantity, 50);
    expect(entry.unit, 'g');
    expect(entry.source, FoodEntrySource.openFoodFacts);
  });
}
