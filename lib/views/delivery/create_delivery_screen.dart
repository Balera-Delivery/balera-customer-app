import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/food_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/restaurant_provider.dart';
import 'destination_location_screen.dart';
import 'pickup_location_screen.dart';
import 'request_submitted_screen.dart';
import 'request_submitted_dialog.dart';

enum DeliveryCategory { food, other }

enum PaymentMethod { telebirr, cbe, awash }

class PaymentAccountInfo {
  final PaymentMethod method;
  final String title;
  final String accountNumber;
  final String accountHolder;
  final String iconAsset;
  final IconData fallbackIcon;
  final Color brandColor;
  final Color brandBgColor;

  const PaymentAccountInfo({
    required this.method,
    required this.title,
    required this.accountNumber,
    required this.accountHolder,
    required this.iconAsset,
    required this.fallbackIcon,
    required this.brandColor,
    required this.brandBgColor,
  });
}

class UploadedReceipt {
  final String fileName;
  final String fileSize;
  final String uploadedAt;
  final String? previewType;
  final String? receiptUrl;
  final Uint8List? fileBytes;
  final String? filePath;

  const UploadedReceipt({
    required this.fileName,
    required this.fileSize,
    required this.uploadedAt,
    this.previewType,
    this.receiptUrl,
    this.fileBytes,
    this.filePath,
  });
}

class CreateDeliveryScreen extends StatefulWidget {
  final DeliveryCategory? initialCategory;
  final String? initialItemType;

  const CreateDeliveryScreen({
    super.key,
    this.initialCategory,
    this.initialItemType,
  });

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  // Step index: 0 = Service & Details, 1 = Pickup & Destination, 2 = Checkout & Payment
  int _currentStep = 0;

  DeliveryCategory _selectedCategory = DeliveryCategory.food;
  String _selectedItemType = 'Parcel / Box';

  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  final _itemDescriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _foodSearchController = TextEditingController();

  double? _selectedPickupLat;
  double? _selectedPickupLng;
  double? _selectedDestLat;
  double? _selectedDestLng;
  double? _selectedFoodPrice;
  String? _selectedRestaurantName;
  String? _selectedRestaurantId;
  bool _isLocating = false;

  // Checkout State
  PaymentMethod? _selectedPaymentMethod;
  UploadedReceipt? _uploadedReceipt;
  bool _isPickingReceipt = false;
  bool _isSubmitting = false;

  final List<PaymentAccountInfo> _paymentAccounts = const [
    PaymentAccountInfo(
      method: PaymentMethod.telebirr,
      title: 'Telebirr',
      accountNumber: '0911 234 567',
      accountHolder: 'Balera Delivery Service',
      iconAsset: 'assets/icons/telebirr.png',
      fallbackIcon: Icons.phone_android_rounded,
      brandColor: Color(0xFF0070BA),
      brandBgColor: Color(0xFFEFF6FF),
    ),
    PaymentAccountInfo(
      method: PaymentMethod.cbe,
      title: 'Commercial Bank of Ethiopia (CBE)',
      accountNumber: '1000 4829 1948 2',
      accountHolder: 'Balera Logistics PLC',
      iconAsset: 'assets/icons/cbe.png',
      fallbackIcon: Icons.account_balance_rounded,
      brandColor: Color(0xFF6B21A8),
      brandBgColor: Color(0xFFFAF5FF),
    ),
    PaymentAccountInfo(
      method: PaymentMethod.awash,
      title: 'Awash Bank',
      accountNumber: '0130 4829 1048 00',
      accountHolder: 'Balera Logistics PLC',
      iconAsset: 'assets/icons/awash.png',
      fallbackIcon: Icons.savings_rounded,
      brandColor: Color(0xFF0D9488),
      brandBgColor: Color(0xFFF0FDFA),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final deliveryProvider = context.read<DeliveryProvider>();
    _pickupController = TextEditingController(text: deliveryProvider.draftPickup ?? '');
    _destinationController = TextEditingController(text: deliveryProvider.draftDestination ?? '');

    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    } else if (deliveryProvider.draftItemDescription != null &&
        deliveryProvider.draftItemDescription!.isNotEmpty) {
      _itemDescriptionController.text = deliveryProvider.draftItemDescription!;
      _selectedCategory = deliveryProvider.draftItemType == 'Food & Groceries'
          ? DeliveryCategory.food
          : DeliveryCategory.other;
    } else {
      _selectedCategory = DeliveryCategory.food;
    }

    if (widget.initialItemType != null) {
      _selectedItemType = widget.initialItemType!;
      deliveryProvider.draftItemType = widget.initialItemType;
    }

    if (deliveryProvider.draftInstructions != null) {
      _instructionsController.text = deliveryProvider.draftInstructions!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantProvider = context.read<RestaurantProvider>();
      restaurantProvider.fetchRestaurants().then((_) {
        if (mounted &&
            _selectedCategory == DeliveryCategory.food &&
            restaurantProvider.restaurants.isNotEmpty) {
          // If customer already selected a dish or has dishes in cart, DO NOT overwrite with Green Caffe!
          if (restaurantProvider.selectedRestaurant == null) {
            restaurantProvider.selectRestaurant(restaurantProvider.restaurants.first).then((_) {
              if (mounted) _syncFromRestaurantProvider(restaurantProvider);
            });
          } else {
            _syncFromRestaurantProvider(restaurantProvider);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _itemDescriptionController.dispose();
    _instructionsController.dispose();
    _foodSearchController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step > 2) return;
    setState(() => _currentStep = step);
  }

  // ---------------------------------------------------------------------------
  // Sync Data Helpers
  // ---------------------------------------------------------------------------
  void _syncFromRestaurantProvider(RestaurantProvider provider) {
    final restaurant = provider.selectedRestaurant;
    final food = provider.selectedFoodItem;
    final qty = provider.selectedQuantity;
    final cart = provider.cart;

    if (restaurant != null) {
      _selectedRestaurantName = restaurant.name;
      _selectedRestaurantId = restaurant.id;
      _selectedPickupLat = restaurant.latitude ?? 7.0083;
      _selectedPickupLng = restaurant.longitude ?? 39.9833;
      _pickupController.text = restaurant.address;

      if (cart.isNotEmpty) {
        _selectedFoodPrice = provider.totalCartPrice;
        _itemDescriptionController.text = provider.formattedDeliveryDescription;
      } else if (food != null) {
        _selectedFoodPrice = food.price * qty;
        final qtyPrefix = qty > 1 ? '${qty}x ' : '';
        _itemDescriptionController.text =
            '$qtyPrefix${food.name} (${(food.price * qty).toStringAsFixed(0)} Birr) - ${restaurant.name}';
      } else {
        _selectedFoodPrice = 0.0;
        _itemDescriptionController.text = 'Food Delivery from ${restaurant.name}';
      }
    } else {
      _selectedRestaurantName = null;
      _selectedRestaurantId = null;
      _selectedPickupLat = null;
      _selectedPickupLng = null;
      _selectedFoodPrice = null;
      _pickupController.clear();
      _itemDescriptionController.clear();
    }
    if (mounted) setState(() {});
  }

  void _onCategorySelected(DeliveryCategory category) {
    setState(() {
      _selectedCategory = category;
      if (category == DeliveryCategory.food) {
        final restaurantProvider = context.read<RestaurantProvider>();
        if (restaurantProvider.selectedRestaurant != null) {
          _syncFromRestaurantProvider(restaurantProvider);
        } else if (restaurantProvider.restaurants.isNotEmpty) {
          restaurantProvider.selectRestaurant(restaurantProvider.restaurants.first).then((_) {
            if (mounted) _syncFromRestaurantProvider(restaurantProvider);
          });
        } else {
          restaurantProvider.fetchRestaurants().then((_) {
            if (mounted && restaurantProvider.restaurants.isNotEmpty && restaurantProvider.selectedRestaurant == null) {
              restaurantProvider.selectRestaurant(restaurantProvider.restaurants.first).then((_) {
                if (mounted) _syncFromRestaurantProvider(restaurantProvider);
              });
            }
          });
        }
      } else {
        _itemDescriptionController.clear();
        _pickupController.clear();
        _selectedFoodPrice = null;
        _selectedRestaurantName = null;
        _selectedRestaurantId = null;
        _selectedPickupLat = null;
        _selectedPickupLng = null;
      }
    });
  }

  void _openRestaurantPicker(BuildContext context) {
    final restaurantProvider = context.read<RestaurantProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RestaurantPickerSheet(
        onSelected: (restaurant) {
          Navigator.pop(ctx);
          restaurantProvider.selectRestaurant(restaurant).then((_) {
            if (mounted) {
              _syncFromRestaurantProvider(restaurantProvider);
            }
          });
        },
      ),
    );
  }

  void _onFoodItemSelected(FoodItemModel foodItem) {
    final restaurantProvider = context.read<RestaurantProvider>();
    restaurantProvider.selectFoodItem(foodItem);
    _syncFromRestaurantProvider(restaurantProvider);
  }

  void _openPickupPicker() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PickupLocationScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _pickupController.text = result;
      });
    }
  }

  void _openDestinationPicker() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const DestinationLocationScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _destinationController.text = result;
      });
    }
  }

  Future<void> _useCurrentGpsForDestination() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission denied. Please enter destination manually.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _selectedDestLat = position.latitude;
          _selectedDestLng = position.longitude;
          _destinationController.text =
              'GPS Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Destination set from your current GPS location! 📍'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Step Navigation Validators
  // ---------------------------------------------------------------------------
  void _validateAndProceedFromStep1() {
    final isFood = _selectedCategory == DeliveryCategory.food;
    final restaurantProvider = context.read<RestaurantProvider>();

    if (isFood) {
      if (restaurantProvider.selectedRestaurant == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a partner hotel or restaurant before proceeding.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_itemDescriptionController.text.trim().isEmpty) {
        _itemDescriptionController.text =
            'Food order from ${restaurantProvider.selectedRestaurant!.name}';
      }
    } else {
      if (_itemDescriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please describe the item or package you wish to deliver.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    _goToStep(1);
  }

  void _validateAndProceedFromStep2() {
    final pickup = _pickupController.text.trim();
    final destination = _destinationController.text.trim();
    final itemDescription = _itemDescriptionController.text.trim();
    final instructions = _instructionsController.text.trim();

    if (_selectedCategory == DeliveryCategory.other && pickup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter or pick a pickup location on the map.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Destination is required! Please enter destination or tap "Use GPS".'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final deliveryProvider = context.read<DeliveryProvider>();
    deliveryProvider.setDraftDetails(
      pickup: pickup,
      destination: destination,
      itemType: _selectedCategory == DeliveryCategory.food ? 'Food & Groceries' : _selectedItemType,
      itemDescription: itemDescription,
      instructions: instructions.isNotEmpty ? instructions : null,
      foodPrice: _selectedFoodPrice,
      restaurantName: _selectedRestaurantName,
      restaurantId: _selectedRestaurantId,
      pickupLat: _selectedPickupLat ?? 7.0083,
      pickupLng: _selectedPickupLng ?? 39.9833,
      destinationLat: _selectedDestLat ?? 7.0125,
      destinationLng: _selectedDestLng ?? 39.9880,
    );

    _goToStep(2);
  }

  // ---------------------------------------------------------------------------
  // Step 3 Checkout Helpers (Payment & Receipt)
  // ---------------------------------------------------------------------------
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text.replaceAll(' ', '')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('$label copied to clipboard!')),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onSelectPaymentMethod(PaymentAccountInfo account, double totalAmount) {
    setState(() {
      _selectedPaymentMethod = account.method;
    });
    _showPaymentInstructionDialog(account, totalAmount);
  }

  void _showPaymentInstructionDialog(PaymentAccountInfo account, double totalAmount) {
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");
    final formattedAmount = '${currencyFormatter.format(totalAmount)} Birr';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: account.brandBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: account.brandColor.withValues(alpha: 0.3)),
              ),
              child: Icon(account.fallbackIcon, color: account.brandColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Manual Transfer Instructions',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transfer Target Account:',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SelectableText(
                          account.accountNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                        tooltip: 'Copy account number',
                        onPressed: () => _copyToClipboard(account.accountNumber, 'Account number'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Name: ${account.accountHolder}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: 'Please send '),
                  TextSpan(
                    text: formattedAmount,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const TextSpan(text: ' to '),
                  TextSpan(
                    text: '${account.title} (${account.accountNumber})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' and upload the transaction receipt below.'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, Got It', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isPickingReceipt = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _processPickedFile(photo.name, bytes, filePath: photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera unavailable: $e. Opening gallery instead...'),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
      }
      await _pickFromGallery();
    } finally {
      if (mounted) setState(() => _isPickingReceipt = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isPickingReceipt = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        await _processPickedFile(image.name, bytes, filePath: image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery selection cancelled or error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingReceipt = false);
    }
  }

  Future<void> _processPickedFile(String fileName, Uint8List bytes, {String? filePath}) async {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final mimeType = (ext == 'png')
        ? 'image/png'
        : (ext == 'webp')
            ? 'image/webp'
            : (ext == 'pdf')
                ? 'application/pdf'
                : 'image/jpeg';

    final base64String = 'data:$mimeType;base64,${base64Encode(bytes)}';

    final sizeKb = bytes.lengthInBytes / 1024;
    final sizeStr = sizeKb > 1024
        ? '${(sizeKb / 1024).toStringAsFixed(2)} MB'
        : '${sizeKb.toStringAsFixed(1)} KB';

    setState(() {
      _uploadedReceipt = UploadedReceipt(
        fileName: fileName,
        fileSize: sizeStr,
        uploadedAt: DateFormat('hh:mm a, dd MMM yyyy').format(DateTime.now()),
        previewType: ext == 'pdf' ? 'PDF' : 'IMAGE',
        receiptUrl: base64String,
        fileBytes: bytes,
        filePath: filePath,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Receipt attached! Ready to submit.'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReceiptPreviewDialog() {
    if (_uploadedReceipt == null) return;

    final selectedMethodTitle = _selectedPaymentMethod != null
        ? _paymentAccounts.firstWhere((a) => a.method == _selectedPaymentMethod).title
        : 'Telebirr';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Receipt',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Target Method: $selectedMethodTitle',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  color: const Color(0xFF0F172A),
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: (_uploadedReceipt!.fileBytes != null)
                      ? InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Image.memory(
                            _uploadedReceipt!.fileBytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : (_uploadedReceipt!.receiptUrl != null &&
                              _uploadedReceipt!.receiptUrl!.startsWith('http'))
                          ? InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.8,
                              maxScale: 4.0,
                              child: Image.network(
                                _uploadedReceipt!.receiptUrl!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : const Center(
                              child: Text(
                                'Receipt Document Ready',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _uploadedReceipt!.fileName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_uploadedReceipt!.fileSize} • ${_uploadedReceipt!.uploadedAt}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmitDelivery() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a payment method (Telebirr, CBE, or Awash Bank).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_uploadedReceipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload your payment receipt before submitting.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final deliveryProvider = context.read<DeliveryProvider>();
      final found = _paymentAccounts.firstWhere((a) => a.method == _selectedPaymentMethod);
      final paymentMethodName = found.title;

      final receiptUrl = _uploadedReceipt?.receiptUrl ?? '';

      deliveryProvider.draftPaymentMethod = paymentMethodName;
      deliveryProvider.draftReceiptUrl = receiptUrl;

      final newDelivery = await deliveryProvider.createDeliveryFromDraft();

      if (mounted) {
        showRequestSubmittedCardPopup(
          context,
          deliveryId: newDelivery.id,
          trackingCode: newDelivery.trackingCode,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit delivery: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build Screen
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Top Royal Blue Header with Back button, Title, Step Indicator & Progress Bar
            _buildCurvedHeader(),

            // Content below header
            if (_currentStep == 0) ...[
              // Step 1: Clean seamless scrollable form
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
                        child: _buildStep1ServiceAndDetails(),
                      ),
                    ),
                    _buildBottomActionBar(),
                  ],
                ),
              ),
            ] else if (_currentStep == 1) ...[
              // Step 2: Location selector
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
                        child: _buildStep2Locations(),
                      ),
                    ),
                    _buildBottomActionBar(),
                  ],
                ),
              ),
            ] else ...[
              // Step 3: Checkout Card
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildStep3Checkout(),
                    ),
                    _buildBottomActionBar(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Curved Royal Blue Top Header (Back Button, Title, Step Info & Progress Bar)
  // ---------------------------------------------------------------------------
  Widget _buildCurvedHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    final stepTitles = ['Service & Details', 'Pickup & Destination', 'Checkout & Payment'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 10,
        left: 18,
        right: 18,
        bottom: 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF004BE4),
            Color(0xFF005BF6),
            Color(0xFF1E67FF),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33005BF6),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with back circular button and 'Request Delivery' title
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (_currentStep > 0) {
                    _goToStep(_currentStep - 1);
                  } else {
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Request Delivery',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row with Step subtitle and pill badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                stepTitles[_currentStep],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Step ${_currentStep + 1} of 3',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-Segment Progress bar inside blue header
          Row(
            children: List.generate(3, (index) {
              final isCompleted = _currentStep > index;
              final isCurrent = _currentStep == index;

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 4.5,
                  margin: EdgeInsets.only(right: index < 2 ? 6.0 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: MERGED Service Type (Small Cards) + Order/Food Details
  // ---------------------------------------------------------------------------
  Widget _buildStep1ServiceAndDetails() {
    final isFood = _selectedCategory == DeliveryCategory.food;
    final isOther = _selectedCategory == DeliveryCategory.other;
    final restaurantProvider = context.watch<RestaurantProvider>();
    final selectedRestaurant = restaurantProvider.selectedRestaurant;
    final selectedFood = restaurantProvider.selectedFoodItem;
    final allHotels = restaurantProvider.restaurants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Choose Service Section Header
        const Text(
          'Choose service',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Select what you need delivered',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),

        // Service Type Option Cards (From Partners vs Order Anything)
        Row(
          children: [
            Expanded(
              child: _buildServiceOptionCard(
                title: 'From\nPartners',
                subtitle: 'Food and\nshops',
                icon: Icons.room_service_outlined,
                isSelected: isFood,
                iconBgColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                onTap: () => _onCategorySelected(DeliveryCategory.food),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildServiceOptionCard(
                title: 'Order\nAnything',
                subtitle: 'Parcels and\nmore',
                icon: Icons.inventory_2_outlined,
                isSelected: isOther,
                iconBgColor: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF0052EA),
                onTap: () => _onCategorySelected(DeliveryCategory.other),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // 2. ORDER DETAILS (FOOD vs OTHER)
        if (isFood) ...[
          // Header: Your partner + Change partner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Your partner',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: () => _openRestaurantPicker(context),
                child: const Text(
                  'Change partner',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0052EA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Partner Card
          if (selectedRestaurant == null) ...[
            InkWell(
              onTap: () => _openRestaurantPicker(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.storefront_rounded, color: Color(0xFF0052EA), size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Partner Restaurant',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap to choose partner in Bale Robe',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0052EA)),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: selectedRestaurant.avatar != null && selectedRestaurant.avatar!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                selectedRestaurant.avatar!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.storefront_rounded, color: Color(0xFF0052EA), size: 24),
                              ),
                            )
                          : const Icon(Icons.storefront_rounded, color: Color(0xFF0052EA), size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                selectedRestaurant.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, size: 11, color: Color(0xFF0052EA)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0052EA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selectedRestaurant.address,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          // Select dish section
          const Text(
            'Select dish',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Dish search input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: TextField(
              controller: _foodSearchController,
              onChanged: (val) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search dishes in this partner',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Horizontal Dish Cards List
          if (restaurantProvider.isLoadingMenu) ...[
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          ] else if (selectedRestaurant != null && selectedRestaurant.foods.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final query = _foodSearchController.text.trim().toLowerCase();
                final filteredFoods = selectedRestaurant.foods.where((f) {
                  if (query.isEmpty) return true;
                  return f.name.toLowerCase().contains(query);
                }).toList();

                return SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredFoods.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final food = filteredFoods[idx];
                      final isSelected = restaurantProvider.isFoodInCart(food.id) || selectedFood?.id == food.id;

                      return _buildDishItemCard(
                        food: food,
                        isSelected: isSelected,
                        quantityInCart: restaurantProvider.getFoodQuantityInCart(food.id),
                        onTap: () => _onFoodItemSelected(food),
                      );
                    },
                  ),
                );
              },
            ),

            if (restaurantProvider.cart.isNotEmpty) ...[
              const SizedBox(height: 14),
              // Multi-Item Cart Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF0052EA).withValues(alpha: 0.3), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052EA).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${restaurantProvider.totalCartCount} items',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0052EA),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Selected Dishes:',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${restaurantProvider.totalCartPrice.toStringAsFixed(0)} Birr',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0052EA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...restaurantProvider.cartItems.map((cartItem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cartItem.food.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${cartItem.totalPrice.toStringAsFixed(0)} Birr',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    restaurantProvider.removeFromCart(cartItem.food.id);
                                    _syncFromRestaurantProvider(restaurantProvider);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.remove, size: 14, color: Color(0xFF0052EA)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    restaurantProvider.addToCart(cartItem.food);
                                    _syncFromRestaurantProvider(restaurantProvider);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add, size: 14, color: Color(0xFF0052EA)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ] else if (selectedFood != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Portions: ${restaurantProvider.selectedQuantity} (${(_selectedFoodPrice ?? 0).toStringAsFixed(0)} Birr)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: Color(0xFF0052EA)),
                          onPressed: () {
                            restaurantProvider.decrementQuantity();
                            _syncFromRestaurantProvider(restaurantProvider);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${restaurantProvider.selectedQuantity}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, size: 22, color: Color(0xFF0052EA)),
                          onPressed: () {
                            restaurantProvider.incrementQuantity();
                            _syncFromRestaurantProvider(restaurantProvider);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  selectedRestaurant == null
                      ? 'Please select a partner above to see menu dishes'
                      : 'No dishes available for this partner right now',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ] else ...[
          // ---------------- ORDER ANYTHING SECTION ----------------
          const Text(
            'Item Category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.itemTypes.map((type) {
              final isSelected = _selectedItemType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _selectedItemType = type);
                },
                selectedColor: const Color(0xFFEFF6FF),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0052EA) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1.0,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0052EA) : const Color(0xFF64748B),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          const Text(
            'Item Description *',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: TextField(
              controller: _itemDescriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'What are you sending? (e.g. Laptop, legal documents, store purchase, keys)',
                hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],

        const SizedBox(height: 22),

        // Delivery instructions
        Row(
          children: const [
            Text(
              'Delivery instructions ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '(optional)',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: TextField(
            controller: _instructionsController,
            decoration: const InputDecoration(
              hintText: 'Call before arrival, leave at front gate',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Service Option Card matching screenshot
  Widget _buildServiceOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052EA) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0052EA).withValues(alpha: 0.12)
                  : const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFF0052EA) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0052EA) : const Color(0xFFCBD5E1),
                      width: 1.6,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, size: 14, color: Colors.white),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dish Item Card matching screenshot
  Widget _buildDishItemCard({
    required dynamic food,
    required bool isSelected,
    int quantityInCart = 0,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 142,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052EA) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0052EA).withValues(alpha: 0.10)
                  : const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soft blue placeholder or food image
                Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: food.image != null && food.image.toString().isNotEmpty
                        ? Image.network(
                            food.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_outlined, size: 28, color: Color(0xFF60A5FA)),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, size: 28, color: Color(0xFF60A5FA)),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${food.price.toStringAsFixed(0)} Birr',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0052EA),
                  ),
                ),
              ],
            ),
            // Select / Selected Pill Button
            Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0052EA) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isSelected
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            quantityInCart > 1 ? '${quantityInCart}x Added' : 'Selected',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Select',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0052EA),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Pickup Location & Destination
  // ---------------------------------------------------------------------------
  Widget _buildStep2Locations() {
    final isFood = _selectedCategory == DeliveryCategory.food;
    final restaurantProvider = context.watch<RestaurantProvider>();
    final selectedRestaurant = restaurantProvider.selectedRestaurant;

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Pickup & Destination Locations',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Set where the rider collects and delivers your order',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 1. PICKUP LOCATION
          if (isFood && selectedRestaurant != null) ...[
            // Automatic Hotel Pickup Point (tight wrap around text only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 16),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Automated Hotel Pickup Point',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Direct Pickup', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    selectedRestaurant.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    selectedRestaurant.address,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '✓ Rider collects directly from hotel kitchen when prepared.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Customer Custom Pickup Location
            const Text(
              'Pickup Location *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _pickupController,
              decoration: InputDecoration(
                hintText: 'Enter pickup address in Bale Robe',
                hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppColors.primary, size: 18),
                  tooltip: 'Pick on map',
                  onPressed: _openPickupPicker,
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // 2. DESTINATION LOCATION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Destination Address * (Required)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _isLocating ? null : _useCurrentGpsForDestination,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Row(
                    children: [
                      if (_isLocating)
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      else
                        const Icon(Icons.my_location_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      const Text(
                        'Use GPS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _destinationController,
            decoration: InputDecoration(
              hintText: 'Enter destination address (or tap GPS)',
              hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 18),
                    tooltip: 'Use current GPS location',
                    onPressed: _useCurrentGpsForDestination,
                  ),
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: AppColors.primary, size: 18),
                    tooltip: 'Pick on map',
                    onPressed: _openDestinationPicker,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Route & Item Summary Badge (tight wrap around text only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isFood ? 'Food Delivery' : 'Custom Courier Dispatch',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Bale Direct', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                if (_selectedFoodPrice != null && _selectedFoodPrice! > 0) ...[
                  const Divider(height: 10, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Food Items Subtotal:',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_selectedFoodPrice!.toStringAsFixed(0)} Birr',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: CHECKOUT CARD (The Final Step!)
  // Order & Delivery Details card is REMOVED as explicitly requested.
  // ---------------------------------------------------------------------------
  Widget _buildStep3Checkout() {
    final deliveryProvider = context.watch<DeliveryProvider>();
    final isFood = _selectedCategory == DeliveryCategory.food ||
        deliveryProvider.draftItemType == 'Food & Groceries';

    final double foodPrice = isFood ? (_selectedFoodPrice ?? deliveryProvider.draftFoodPrice ?? 0.00) : 0.00;
    final double deliveryFee = isFood ? 100.00 : 120.00;
    final double serviceFee = isFood ? 20.00 : 0.00;
    final double totalPrice = foodPrice + deliveryFee + serviceFee;
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header inside card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Checkout & Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Choose payment method & attach transaction receipt',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 1. POS INVOICE / PRICE BREAKDOWN CARD
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.point_of_sale_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Price Breakdown & POS Invoice',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (foodPrice > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Food Items Subtotal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('${currencyFormatter.format(foodPrice)} Birr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee (Bale direct)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('${currencyFormatter.format(deliveryFee)} Birr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),

                if (serviceFee > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Service & Packing Fee', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('${currencyFormatter.format(serviceFee)} Birr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                const Divider(height: 14, color: Color(0xFFE2E8F0)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Text(
                      '${currencyFormatter.format(totalPrice)} Birr',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. PAYMENT METHOD SELECTOR
          const Text(
            'Select Payment Method *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          Column(
            children: _paymentAccounts.map((account) {
              final isSelected = _selectedPaymentMethod == account.method;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => _onSelectPaymentMethod(account, totalPrice),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? account.brandBgColor : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? account.brandColor : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: account.brandColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(account.fallbackIcon, color: account.brandColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.title,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Account: ${account.accountNumber}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? account.brandColor : const Color(0xFFCBD5E1),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // 3. PAYMENT RECEIPT UPLOAD SECTION
          const Text(
            'Payment Receipt Slip *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Attach screenshot or camera photo of your transfer receipt',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          if (_uploadedReceipt == null) ...[
            // Upload Action Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_rounded, size: 28, color: AppColors.primary),
                  const SizedBox(height: 4),
                  const Text(
                    'No receipt attached yet',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPickingReceipt ? null : _pickFromCamera,
                          icon: const Icon(Icons.camera_alt_rounded, size: 14),
                          label: const Text('Camera', style: TextStyle(fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPickingReceipt ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library_rounded, size: 14),
                          label: const Text('Gallery', style: TextStyle(fontSize: 11.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Attached Receipt Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_rounded, color: Color(0xFF16A34A), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _uploadedReceipt!.fileName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_uploadedReceipt!.fileSize} • ${_uploadedReceipt!.uploadedAt}',
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('Verified', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showReceiptPreviewDialog,
                          icon: const Icon(Icons.visibility_rounded, size: 14),
                          label: const Text('Inspect / Zoom', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        tooltip: 'Remove receipt',
                        onPressed: () => setState(() => _uploadedReceipt = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pinned Bottom Action Bar (Fixed at the bottom of the screen)
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Action (Back button for Steps 2 and 3)
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () => _goToStep(_currentStep - 1),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Right Action
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_currentStep == 0) {
                        _validateAndProceedFromStep1();
                      } else if (_currentStep == 1) {
                        _validateAndProceedFromStep2();
                      } else {
                        _handleSubmitDelivery();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 2 ? const Color(0xFF16A34A) : const Color(0xFF0052EA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _currentStep == 0
                                ? 'Next'
                                : _currentStep == 1
                                    ? 'Go to Checkout'
                                    : 'Submit Delivery',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 2 ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Restaurant Picker Bottom Sheet (Browse all hotels in Bale Robe)
// ---------------------------------------------------------------------------
class _RestaurantPickerSheet extends StatefulWidget {
  final ValueChanged<RestaurantModel> onSelected;

  const _RestaurantPickerSheet({required this.onSelected});

  @override
  State<_RestaurantPickerSheet> createState() => _RestaurantPickerSheetState();
}

class _RestaurantPickerSheetState extends State<_RestaurantPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final restaurants = restaurantProvider.restaurants;

    final query = _searchCtrl.text.toLowerCase().trim();
    final filtered = restaurants.where((r) {
      return query.isEmpty ||
          r.name.toLowerCase().contains(query) ||
          r.address.toLowerCase().contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Hotels & Restaurants',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text('Verified partner establishments in Bale Robe', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search hotel name or address...',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: restaurantProvider.isLoading && filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text(
                          'Loading partner hotels in Bale Robe...',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storefront_outlined, size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            const Text('No hotels found.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => restaurantProvider.fetchRestaurants(),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reload Hotels'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final isCurrent = restaurantProvider.selectedRestaurant?.id == item.id;

                      return InkWell(
                        onTap: () => widget.onSelected(item),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFFF0F9FF) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent ? AppColors.primary : const Color(0xFFE2E8F0),
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  color: const Color(0xFFE0F2FE),
                                  child: item.avatar != null && item.avatar!.isNotEmpty
                                      ? Image.network(
                                          item.avatar!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 24),
                                        )
                                      : const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 24),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                          ),
                                        ),
                                        if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: const Text('Selected', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.address,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFEAB308)),
                                        const SizedBox(width: 2),
                                        Text('${item.rating}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 6),
                                        Text('• ${item.foods.length} dishes', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
