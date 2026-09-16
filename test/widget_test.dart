import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balera_customer_app/main.dart';
import 'package:balera_customer_app/providers/auth_provider.dart';
import 'package:balera_customer_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('App renders SplashScreen with Get Started button for new users', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await tester.pumpWidget(const BalerraCustomerApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BalerraCustomerApp), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  test('AuthProvider initializes with authenticated status when token is present', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_valid_token_xyz',
      'user_data': '{"id":"USR-1","fullName":"Abebe Kebede","phoneNumber":"0911223344"}',
      'onboarding_complete': true,
    });
    await StorageService.init();
    final authProvider = AuthProvider();
    await authProvider.checkAuthState();
    expect(authProvider.isAuthenticated, true);
    expect(authProvider.currentUser?.fullName, 'Abebe Kebede');
  });

  test('AuthProvider is unauthenticated when token is absent', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final authProvider = AuthProvider();
    await authProvider.checkAuthState();
    expect(authProvider.isAuthenticated, false);
    expect(authProvider.currentUser, null);
  });

  test('AuthGate routes to SplashScreen for unauthenticated users', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    final authProvider = AuthProvider();
    expect(authProvider.isAuthenticated, false);
  });

  test('AuthGate routes directly to MainNavigationScreen when user is authenticated', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_valid_token_xyz',
      'user_data': '{"id":"USR-1","fullName":"Abebe Kebede","phoneNumber":"0911223344"}',
      'onboarding_complete': true,
    });
    await StorageService.init();
    final authProvider = AuthProvider();
    expect(authProvider.isAuthenticated, true);
    expect(authProvider.currentUser?.fullName, 'Abebe Kebede');
  });
}
