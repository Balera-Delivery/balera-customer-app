import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/delivery_model.dart';
import '../services/delivery_service.dart';

class DeliveryProvider extends ChangeNotifier {
  final DeliveryService _deliveryService = DeliveryService();

  DeliveryService get deliveryService => _deliveryService;
  final List<DeliveryModel> _deliveries = [];
  DeliveryModel? _activeDelivery;
  LiveTrackingData? _liveTrackingData;
  String? _currentOtp;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Pending creation draft state (clean with no default pre-fills)
  String? draftPickup;
  String? draftDestination;
  String? draftItemType;
  String? draftItemDescription;
  String? draftReceiverName;
  String? draftReceiverPhone;
  String? draftInstructions;
  double? draftFoodPrice;
  String? draftRestaurantName;
  String? draftRestaurantId;
  String? draftPaymentMethod;
  String? draftReceiptUrl;
  double draftPickupLat = 7.0083;
  double draftPickupLng = 39.9833;
  double draftDestinationLat = 7.0125;
  double draftDestinationLng = 39.9789;

  List<DeliveryModel> get deliveries => _deliveries;
  DeliveryModel? get activeDelivery =>
      _activeDelivery ?? (ongoingDeliveries.isNotEmpty ? ongoingDeliveries.first : null);
  LiveTrackingData? get liveTrackingData => _liveTrackingData;
  String? get currentOtp => _currentOtp;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  DeliveryProvider() {
    fetchDeliveries();
  }

  // Filtered lists matching screen 17 using backend status enums
  List<DeliveryModel> get ongoingDeliveries =>
      _deliveries.where((d) => AppConstants.isOngoing(d.status)).toList();

  List<DeliveryModel> get completedDeliveries =>
      _deliveries.where((d) => AppConstants.isCompleted(d.status)).toList();

  List<DeliveryModel> get cancelledDeliveries =>
      _deliveries.where((d) => AppConstants.isCancelled(d.status)).toList();

  Future<void> fetchDeliveries({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _deliveryService.getDeliveries(
      status: status,
      search: search,
    );

    if (response.success && response.data != null) {
      _deliveries.clear();
      _deliveries.addAll(response.data!);
      if (_activeDelivery != null) {
        final found = _deliveries.where((d) => d.id == _activeDelivery!.id);
        if (found.isNotEmpty) {
          _activeDelivery = found.first;
        }
      } else if (ongoingDeliveries.isNotEmpty) {
        _activeDelivery = ongoingDeliveries.first;
      }
      _errorMessage = null;
    } else {
      _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load deliveries.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setDraftDetails({
    String? pickup,
    String? destination,
    String? itemType,
    String? itemDescription,
    String? receiverName,
    String? receiverPhone,
    String? instructions,
    double? foodPrice,
    String? restaurantName,
    String? restaurantId,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
    String? paymentMethod,
    String? receiptUrl,
  }) {
    if (pickup != null) draftPickup = pickup;
    if (destination != null) draftDestination = destination;
    if (itemType != null) draftItemType = itemType;
    if (itemDescription != null) draftItemDescription = itemDescription;
    if (receiverName != null) draftReceiverName = receiverName;
    if (receiverPhone != null) draftReceiverPhone = receiverPhone;
    if (instructions != null) draftInstructions = instructions;
    if (foodPrice != null) draftFoodPrice = foodPrice;
    if (restaurantName != null) draftRestaurantName = restaurantName;
    if (restaurantId != null) draftRestaurantId = restaurantId;
    if (pickupLat != null) draftPickupLat = pickupLat;
    if (pickupLng != null) draftPickupLng = pickupLng;
    if (destinationLat != null) draftDestinationLat = destinationLat;
    if (destinationLng != null) draftDestinationLng = destinationLng;
    if (paymentMethod != null) draftPaymentMethod = paymentMethod;
    if (receiptUrl != null) draftReceiptUrl = receiptUrl;
    notifyListeners();
  }

  // Clear draft
  void clearDraft() {
    draftPickup = null;
    draftDestination = null;
    draftItemType = null;
    draftItemDescription = null;
    draftReceiverName = null;
    draftReceiverPhone = null;
    draftInstructions = null;
    draftFoodPrice = null;
    draftRestaurantName = null;
    draftRestaurantId = null;
    draftPaymentMethod = null;
    draftReceiptUrl = null;
    notifyListeners();
  }

  // Create new delivery request (POST /api/v1/customer/deliveries)
  Future<DeliveryModel> createDeliveryFromDraft() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final pickup = (draftPickup != null && draftPickup!.trim().isNotEmpty) ? draftPickup!.trim() : 'Pickup Location';
    final destination = (draftDestination != null && draftDestination!.trim().isNotEmpty) ? draftDestination!.trim() : 'Destination';
    final itemDesc = (draftItemDescription != null && draftItemDescription!.trim().isNotEmpty) ? draftItemDescription!.trim() : 'Item';
    final itemT = (draftItemType != null && draftItemType!.trim().isNotEmpty) ? draftItemType!.trim() : 'Package';
    final receiverN = (draftReceiverName != null && draftReceiverName!.trim().isNotEmpty) ? draftReceiverName!.trim() : 'Receiver';
    final receiverP = (draftReceiverPhone != null && draftReceiverPhone!.trim().isNotEmpty) ? draftReceiverPhone!.trim() : '0911000000';

    final response = await _deliveryService.createDelivery(
      pickupLocation: pickup,
      destination: destination,
      itemType: itemT,
      itemDescription: itemDesc,
      receiverName: receiverN,
      receiverPhone: receiverP,
      instructions: draftInstructions,
      paymentMethod: draftPaymentMethod,
      receiptUrl: draftReceiptUrl,
      pickupLat: draftPickupLat,
      pickupLng: draftPickupLng,
      destinationLat: draftDestinationLat,
      destinationLng: draftDestinationLng,
    );

    _isSubmitting = false;

    if (response.success && response.data != null) {
      final newDelivery = response.data!;
      _deliveries.insert(0, newDelivery);
      _activeDelivery = newDelivery;
      _currentOtp = newDelivery.otpCode;
      clearDraft();
      notifyListeners();
      return newDelivery;
    } else {
      _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to submit delivery request.';
      notifyListeners();
      // Fallback local delivery so user flow isn't completely broken if offline
      final fallback = DeliveryModel(
        id: 'DLV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        customerId: 'LOCAL_USR',
        pickupLocation: pickup,
        destination: destination,
        itemType: itemT,
        itemDescription: itemDesc,
        receiverName: receiverN,
        receiverPhone: receiverP,
        instructions: draftInstructions,
        status: AppConstants.statusPending,
        paymentMethod: draftPaymentMethod,
        paymentStatus: draftReceiptUrl != null ? 'PAID_PENDING_VERIFICATION' : 'PENDING',
        receiptUrl: draftReceiptUrl,
        otpCode: '482913',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pickupLat: draftPickupLat,
        pickupLng: draftPickupLng,
        destinationLat: draftDestinationLat,
        destinationLng: draftDestinationLng,
      );
      _deliveries.insert(0, fallback);
      _activeDelivery = fallback;
      clearDraft();
      notifyListeners();
      return fallback;
    }
  }

  // Cancel delivery request (POST /api/v1/customer/deliveries/{id}/cancel)
  Future<bool> cancelDelivery(String deliveryId, {String? reason}) async {
    final response = await _deliveryService.cancelDelivery(deliveryId, reason: reason);
    if (response.success) {
      final index = _deliveries.indexWhere((d) => d.id == deliveryId);
      if (index != -1) {
        final updated = DeliveryModel(
          id: _deliveries[index].id,
          trackingCode: _deliveries[index].trackingCode,
          customerId: _deliveries[index].customerId,
          riderId: _deliveries[index].riderId,
          rider: _deliveries[index].rider,
          pickupLocation: _deliveries[index].pickupLocation,
          destination: _deliveries[index].destination,
          itemType: _deliveries[index].itemType,
          itemDescription: _deliveries[index].itemDescription,
          receiverName: _deliveries[index].receiverName,
          receiverPhone: _deliveries[index].receiverPhone,
          instructions: _deliveries[index].instructions,
          status: AppConstants.statusCancelled,
          otpCode: _deliveries[index].otpCode,
          cancellationReason: reason ?? 'Cancelled by customer',
          createdAt: _deliveries[index].createdAt,
          updatedAt: DateTime.now(),
          pickupLat: _deliveries[index].pickupLat,
          pickupLng: _deliveries[index].pickupLng,
          destinationLat: _deliveries[index].destinationLat,
          destinationLng: _deliveries[index].destinationLng,
        );
        _deliveries[index] = updated;
        if (_activeDelivery?.id == deliveryId) {
          _activeDelivery = updated;
        }
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // Fetch real-time live map tracking (GET /api/v1/customer/deliveries/{id}/track)
  Future<LiveTrackingData?> fetchTracking(String deliveryId) async {
    final response = await _deliveryService.getLiveTracking(deliveryId);
    if (response.success && response.data != null) {
      _liveTrackingData = response.data;
      notifyListeners();
      return response.data;
    }
    return null;
  }

  // Fetch delivery OTP (GET /api/v1/customer/deliveries/{id}/otp)
  Future<String?> fetchDeliveryOtp(String deliveryId) async {
    final response = await _deliveryService.getDeliveryOtp(deliveryId);
    if (response.success && response.data != null && response.data!.isNotEmpty) {
      _currentOtp = response.data;
      notifyListeners();
      return response.data;
    }
    return null;
  }

  // Progress Active Delivery Status for preview / testing
  void updateActiveStatus(String status) {
    if (_activeDelivery != null) {
      final index = _deliveries.indexWhere((d) => d.id == _activeDelivery!.id);
      final updated = DeliveryModel(
        id: _activeDelivery!.id,
        trackingCode: _activeDelivery!.trackingCode,
        customerId: _activeDelivery!.customerId,
        riderId: _activeDelivery!.riderId ?? 'RDR-0042',
        rider: _activeDelivery!.rider,
        pickupLocation: _activeDelivery!.pickupLocation,
        destination: _activeDelivery!.destination,
        itemType: _activeDelivery!.itemType,
        itemDescription: _activeDelivery!.itemDescription,
        receiverName: _activeDelivery!.receiverName,
        receiverPhone: _activeDelivery!.receiverPhone,
        instructions: _activeDelivery!.instructions,
        status: status,
        otpCode: _activeDelivery!.otpCode ?? '482913',
        createdAt: _activeDelivery!.createdAt,
        updatedAt: DateTime.now(),
        pickupLat: _activeDelivery!.pickupLat,
        pickupLng: _activeDelivery!.pickupLng,
        destinationLat: _activeDelivery!.destinationLat,
        destinationLng: _activeDelivery!.destinationLng,
      );

      if (index != -1) {
        _deliveries[index] = updated;
      }
      _activeDelivery = updated;
      notifyListeners();
    }
  }

  Future<void> fetchDeliveryDetails(String id) async {
    final res = await _deliveryService.getDeliveryDetails(id);
    if (res.success && res.data != null) {
      _activeDelivery = res.data;
      final index = _deliveries.indexWhere((d) => d.id == id);
      if (index != -1) {
        _deliveries[index] = res.data!;
      }
    } else {
      final item = _deliveries.firstWhere((d) => d.id == id, orElse: () => _deliveries.first);
      _activeDelivery = item;
    }
    notifyListeners();
  }

  void setActiveDelivery(DeliveryModel? delivery) {
    _activeDelivery = delivery;
    notifyListeners();
  }
}
