class RiderInfo {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? vehicleInfo;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? heading;

  RiderInfo({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.vehicleInfo,
    this.currentLatitude,
    this.currentLongitude,
    this.heading,
  });

  factory RiderInfo.fromJson(Map<String, dynamic> json) {
    // Current location can be a nested object or flat
    double? lat;
    double? lng;
    double? head;
    if (json['currentLocation'] is Map) {
      final loc = json['currentLocation'] as Map<String, dynamic>;
      lat = (loc['latitude'] as num?)?.toDouble();
      lng = (loc['longitude'] as num?)?.toDouble();
      head = (loc['heading'] as num?)?.toDouble();
    } else {
      lat = (json['currentLatitude'] as num? ?? json['latitude'] as num?)?.toDouble();
      lng = (json['currentLongitude'] as num? ?? json['longitude'] as num?)?.toDouble();
      head = (json['heading'] as num?)?.toDouble();
    }

    String? vehicle = json['vehicleInfo'] as String?;
    if (vehicle == null) {
      final type = json['vehicleType']?.toString();
      final plate = json['plateNumber']?.toString();
      if (type != null && plate != null) {
        vehicle = '$type • $plate';
      } else if (type != null) {
        vehicle = type;
      } else if (plate != null) {
        vehicle = plate;
      }
    }

    return RiderInfo(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      vehicleInfo: vehicle,
      currentLatitude: lat,
      currentLongitude: lng,
      heading: head,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'vehicleInfo': vehicleInfo,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'heading': heading,
    };
  }
}

class DeliveryModel {
  final String id;
  final String? trackingCode;
  final String customerId;
  final String? riderId;
  final RiderInfo? rider;
  final String pickupLocation;
  final String destination;
  final String itemType;
  final String itemDescription;
  final String receiverName;
  final String receiverPhone;
  final String? instructions;
  final String status;
  final String? otpCode;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;

  DeliveryModel({
    required this.id,
    this.trackingCode,
    required this.customerId,
    this.riderId,
    this.rider,
    required this.pickupLocation,
    required this.destination,
    required this.itemType,
    required this.itemDescription,
    required this.receiverName,
    required this.receiverPhone,
    this.instructions,
    required this.status,
    this.otpCode,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    // If wrapped in { delivery: { ... } }, unwrap
    final data = json['delivery'] is Map<String, dynamic> ? json['delivery'] as Map<String, dynamic> : json;

    // Handle rider extraction
    RiderInfo? riderObj;
    if (data['rider'] != null && data['rider'] is Map<String, dynamic>) {
      riderObj = RiderInfo.fromJson(data['rider'] as Map<String, dynamic>);
    } else if (data['riderId'] != null && data['riderId'] is Map<String, dynamic>) {
      riderObj = RiderInfo.fromJson(data['riderId'] as Map<String, dynamic>);
    }

    // Extract OTP code
    String? otp;
    if (data['otpCode'] != null) {
      otp = data['otpCode'].toString();
    } else if (data['otp'] != null && data['otp'] is Map) {
      otp = data['otp']['otpCode']?.toString();
    }

    return DeliveryModel(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      trackingCode: data['trackingCode'] as String?,
      customerId: data['customerId']?.toString() ?? '',
      riderId: data['riderId'] is Map ? data['riderId']['id']?.toString() : data['riderId']?.toString(),
      rider: riderObj,
      pickupLocation: data['pickupLocation'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      itemType: data['itemType'] as String? ?? 'General',
      itemDescription: data['itemDescription'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? '',
      receiverPhone: data['receiverPhone'] as String? ?? '',
      instructions: data['specialInstructions'] as String? ?? data['instructions'] as String?,
      status: data['status'] as String? ?? 'PENDING',
      otpCode: otp,
      cancellationReason: data['cancellationReason'] as String?,
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) : null,
      pickupLat: (data['pickupLatitude'] as num? ?? data['pickupLat'] as num?)?.toDouble(),
      pickupLng: (data['pickupLongitude'] as num? ?? data['pickupLng'] as num?)?.toDouble(),
      destinationLat: (data['destinationLatitude'] as num? ?? data['destinationLat'] as num?)?.toDouble(),
      destinationLng: (data['destinationLongitude'] as num? ?? data['destinationLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingCode': trackingCode,
      'customerId': customerId,
      'riderId': riderId,
      'rider': rider?.toJson(),
      'pickupLocation': pickupLocation,
      'destination': destination,
      'itemType': itemType,
      'itemDescription': itemDescription,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'specialInstructions': instructions,
      'instructions': instructions,
      'status': status,
      'otpCode': otpCode,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'pickupLatitude': pickupLat,
      'pickupLongitude': pickupLng,
      'destinationLatitude': destinationLat,
      'destinationLongitude': destinationLng,
    };
  }
}

class LiveTrackingData {
  final String deliveryId;
  final String? trackingCode;
  final String status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final RiderInfo? rider;

  LiveTrackingData({
    required this.deliveryId,
    this.trackingCode,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    this.rider,
  });

  factory LiveTrackingData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final pickup = data['pickup'] as Map<String, dynamic>? ?? {};
    final destination = data['destination'] as Map<String, dynamic>? ?? {};
    final assignedRider = data['assignedRider'] as Map<String, dynamic>?;

    return LiveTrackingData(
      deliveryId: data['deliveryId']?.toString() ?? '',
      trackingCode: data['trackingCode'] as String?,
      status: data['status'] as String? ?? 'PENDING',
      pickupAddress: pickup['address'] as String? ?? '',
      pickupLat: (pickup['latitude'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (pickup['longitude'] as num?)?.toDouble() ?? 0.0,
      destinationAddress: destination['address'] as String? ?? '',
      destinationLat: (destination['latitude'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (destination['longitude'] as num?)?.toDouble() ?? 0.0,
      rider: assignedRider != null ? RiderInfo.fromJson(assignedRider) : null,
    );
  }
}
