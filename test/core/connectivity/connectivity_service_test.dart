import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zeus/core/connectivity/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  test('isOffline emits true when the connectivity result is none', () async {
    final mockConnectivity = MockConnectivity();
    when(() => mockConnectivity.onConnectivityChanged).thenAnswer(
      (_) => Stream.value([ConnectivityResult.none]),
    );

    final service = ConnectivityService(mockConnectivity);

    expect(await service.isOffline.first, true);
  });

  test('isOffline emits false when a real connection is present', () async {
    final mockConnectivity = MockConnectivity();
    when(() => mockConnectivity.onConnectivityChanged).thenAnswer(
      (_) => Stream.value([ConnectivityResult.wifi]),
    );

    final service = ConnectivityService(mockConnectivity);

    expect(await service.isOffline.first, false);
  });
}
