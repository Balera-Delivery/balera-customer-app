import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balera_customer_app/services/storage_service.dart';
import 'package:balera_customer_app/views/delivery/delivery_tracking_screen.dart';
import 'package:balera_customer_app/models/delivery_model.dart';
import 'package:balera_customer_app/providers/delivery_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('DeliveryTrackingScreen renders modern map-on-top layout with horizontal tracking stepper', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testDelivery = DeliveryModel(
      id: 'DEL-87952264',
      trackingCode: 'M87952264',
      customerId: 'CUST-001',
      pickupLocation: 'Palm Springs, Bale Robe',
      destination: 'Diriyah, Bale Robe',
      itemType: 'Food & Groceries',
      itemDescription: 'Full Menu Special Pizza & Juice',
      receiverName: 'Amelia',
      receiverPhone: '0911223344',
      status: 'ON_THE_WAY',
      otpCode: '482913',
      paymentMethod: 'Telebirr',
      paymentStatus: 'Paid',
      rider: RiderInfo(
        id: 'RIDER-001',
        fullName: 'Dana Reid',
        phoneNumber: '0988776655',
        vehicleInfo: 'TVS Apache • Plate 3-12845',
        currentLatitude: 7.0090,
        currentLongitude: 39.9850,
      ),
    );

    final deliveryProvider = DeliveryProvider();
    deliveryProvider.setActiveDelivery(testDelivery);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DeliveryProvider>.value(value: deliveryProvider),
        ],
        child: MaterialApp(
          home: DeliveryTrackingScreen(
            initialDelivery: testDelivery,
            enablePolling: false,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Verify Top Floating Header Bar
    expect(find.text('Track Package'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    // 2. Verify Rider Header Row
    expect(find.text('Dana Reid'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.byIcon(Icons.phone_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);

    // 3. Verify Dynamic Status Banner Pill
    expect(find.textContaining('In transit'), findsOneWidget);

    // 4. Verify Booking Card & ID
    expect(find.text('Booking'), findsOneWidget);
    expect(find.text('#M87952264'), findsOneWidget);
    expect(find.text('Transit'), findsOneWidget);

    // 5. Verify 6-step flow stepper without minutes
    expect(find.text('1. Order submitted'), findsOneWidget);
    expect(find.text('2. Rider assigned'), findsOneWidget);
    expect(find.text('3. Item picked up'), findsOneWidget);
    expect(find.text('4. On the way'), findsOneWidget);
    expect(find.text('5. Rider arrived'), findsOneWidget);
    expect(find.text('6. Delivered & complete'), findsOneWidget);
    expect(find.textContaining('min'), findsNothing);

    // 6. Verify Summary Details (From, To, Order Cost, Customer as logged-in user)
    expect(find.text('From'), findsOneWidget);
    expect(find.text('Palm Springs, Bale Robe'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Diriyah, Bale Robe'), findsOneWidget);
    expect(find.text('Order Cost'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Faisa Mohammed'), findsOneWidget);
    expect(find.text('Amelia'), findsNothing);

    // 7. Verify Order & Item Details card has been removed
    expect(find.text('Order & Item Details'), findsNothing);

    // Clean up timer by disposing widget
    await tester.pumpWidget(const SizedBox());
  });
}
