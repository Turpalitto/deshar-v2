import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nokhchiin/core/router/app_router.dart';

void main() {
  test('paywall route is registered before premium is enabled', () {
    final paths = appRouter.configuration.routes.whereType<GoRoute>().map(
      (route) => route.path,
    );

    expect(paths, contains('/paywall'));
  });
}
