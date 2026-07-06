import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nokhchiin/data/datasources/local_storage_datasource.dart';
import 'package:nokhchiin/features/onboarding/onboarding_screen.dart';
import 'helpers/test_app.dart';

void main() {
  final hiveDir = Directory('test/.hive_onboarding');

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
    hiveDir.createSync(recursive: true);
    Hive.init(hiveDir.path);
    await LocalProgressDataSource().init();
    await LocalUserDataSource().init();
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  testWidgets('onboarding shows title and learning modes', (tester) async {
    await tester.pumpWidget(testApp(const OnboardingScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Нохчийн'), findsOneWidget);
    expect(find.text('Детский режим'), findsOneWidget);
    expect(find.text('Взрослый режим'), findsOneWidget);
    expect(find.text('Сайн дог ду хьуна'), findsOneWidget);
    expect(find.text('Рады тебя видеть!'), findsOneWidget);
  });
}
