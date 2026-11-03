import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:balera_customer_app/views/delivery/create_delivery_screen.dart';
import 'package:balera_customer_app/providers/delivery_provider.dart';
import 'package:balera_customer_app/providers/restaurant_provider.dart';

void main() {
  testWidgets('CreateDeliveryScreen executes 3-step big card flow with compact cards & embedded checkout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final deliveryProvider = DeliveryProvider();
    final restaurantProvider = RestaurantProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DeliveryProvider>.value(value: deliveryProvider),
          ChangeNotifierProvider<RestaurantProvider>.value(value: restaurantProvider),
        ],
        child: const MaterialApp(
          home: CreateDeliveryScreen(
            initialCategory: DeliveryCategory.other,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. STEP 1: VERIFY COMPACT SERVICE OPTION CARDS & NEXT BUTTON
    expect(find.text('Choose Service & Customize Order'), findsOneWidget);
    expect(find.text('Hotels & Food'), findsOneWidget);
    expect(find.text('Order Anything'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    // Back button should NOT be in bottom bar on Step 1
    expect(find.text('Back'), findsNothing);

    // Enter item description
    final descriptionField = find.byType(TextField).first;
    await tester.enterText(descriptionField, 'Important office documents');
    await tester.pumpAndSettle();

    // Tap Next to proceed to Step 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // 2. STEP 2: VERIFY PICKUP & DESTINATION, BACK, AND GO TO CHECKOUT (SINGLE BOTTOM BAR)
    expect(find.text('Pickup & Destination Locations'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Go to Checkout'), findsOneWidget);

    // Enter pickup and destination
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Market Square, Bale Robe');
    await tester.enterText(textFields.at(1), 'Bale Robe Central Hospital');
    await tester.pumpAndSettle();

    // Tap "Go to Checkout" to proceed to Step 3
    await tester.tap(find.text('Go to Checkout'));
    await tester.pumpAndSettle();

    // 3. STEP 3: VERIFY EMBEDDED CHECKOUT WITHOUT "ORDER & DELIVERY DETAILS" (SINGLE BOTTOM BAR)
    expect(find.text('Checkout & Payment'), findsWidgets);
    expect(find.text('Price Breakdown & POS Invoice'), findsOneWidget);
    expect(find.text('Order & Delivery Details'), findsNothing); // Explicitly removed as requested!
    expect(find.text('Select Payment Method *'), findsOneWidget);
    expect(find.text('Payment Receipt Slip *'), findsOneWidget);
    expect(find.text('Submit Delivery'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // Test Back button on Step 3 returns to Step 2
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Pickup & Destination Locations'), findsOneWidget);
  });
}
