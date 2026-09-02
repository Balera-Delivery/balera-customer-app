import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balera_customer_app/main.dart';
import 'package:balera_customer_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('App renders SplashScreen with Get Started button', (WidgetTester tester) async {
    await tester.pumpWidget(const BalerraCustomerApp());
    expect(find.byType(BalerraCustomerApp), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
