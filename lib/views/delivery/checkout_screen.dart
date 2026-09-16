import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/delivery_provider.dart';
import 'request_submitted_screen.dart';

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

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod? _selectedMethod;
  UploadedReceipt? _uploadedReceipt;
  bool _isPickingFile = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _receiptSectionKey = GlobalKey();

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      _selectedMethod = account.method;
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
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
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
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        account.accountNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
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
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.45),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: const Text('Help'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showHelpSupportSheet();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  },
                  child: const Text('OK, Got It', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelpSupportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Assistance & Help',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'If you encounter any issues sending payments or verifying your transaction slip, our support team is available 24/7:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildSupportRow(Icons.phone_rounded, 'Call Support Hotline', '0911 000 000'),
            const SizedBox(height: 10),
            _buildSupportRow(Icons.send_rounded, 'Telegram Support Channel', '@balera_support'),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Close Help',
              type: ButtonType.outlined,
              height: 44,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }

  // ONLY 2 REAL OPTIONS: Camera & Gallery/File
  void _showReceiptPickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Upload Payment Receipt',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Please attach your actual transfer receipt image or document:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // Option 1: Take Photo via Camera
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Take Photo via Camera', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Capture direct photo of the transaction slip', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              const SizedBox(height: 10),

              // Option 2: Choose from Photo Gallery or Local File
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Choose from Gallery / Files', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text('Select saved screenshot, JPG, PNG or PDF', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pick Real Photo via Camera
  Future<void> _pickFromCamera() async {
    setState(() => _isPickingFile = true);
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
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  // Pick Real Image from Gallery / Photos
  Future<void> _pickFromGallery() async {
    setState(() => _isPickingFile = true);
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
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  // Process Real Image Bytes and Create Base64 Payload
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
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Receipt attached! You can check and review it before ordering.')),
          ],
        ),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Interactive Receipt Full-Screen Zoom & Inspection Modal
  void _showReceiptPreviewDialog() {
    if (_uploadedReceipt == null) return;

    final selectedMethodTitle = _selectedMethod != null
        ? _paymentAccounts.firstWhere((a) => a.method == _selectedMethod).title
        : 'Telebirr';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                              'Verify Receipt Before Order',
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

              // Image Preview Area with Interactive Pinch-to-Zoom
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
                      : (_uploadedReceipt!.receiptUrl != null && _uploadedReceipt!.receiptUrl!.startsWith('http'))
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

              // Metadata & Action Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    Row(
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
                              const SizedBox(height: 2),
                              Text(
                                '${_uploadedReceipt!.fileSize} • Uploaded ${_uploadedReceipt!.uploadedAt}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Change Image'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showReceiptPickerModal();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Looks Good!'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                      ],
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

  void _removeReceipt() {
    setState(() {
      _uploadedReceipt = null;
    });
  }

  void _handleSubmitDelivery() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a payment option (Telebirr, CBE, or Awash Bank) first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_uploadedReceipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your payment receipt before submitting.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final deliveryProvider = context.read<DeliveryProvider>();
    final found = _paymentAccounts.firstWhere((a) => a.method == _selectedMethod);
    final paymentMethodName = found.title;

    final receiptUrl = _uploadedReceipt?.receiptUrl ?? '';

    deliveryProvider.draftPaymentMethod = paymentMethodName;
    deliveryProvider.draftReceiptUrl = receiptUrl;

    final newDelivery = await deliveryProvider.createDeliveryFromDraft();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RequestSubmittedScreen(
            deliveryId: newDelivery.id,
            trackingCode: newDelivery.trackingCode,
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = context.watch<DeliveryProvider>();
    final isFood = deliveryProvider.draftItemType == 'Food & Groceries' ||
        (deliveryProvider.draftItemDescription?.toLowerCase().contains('burger') ?? false) ||
        (deliveryProvider.draftItemDescription?.toLowerCase().contains('doro') ?? false) ||
        (deliveryProvider.draftItemDescription?.toLowerCase().contains('coffee') ?? false) ||
        (deliveryProvider.draftItemDescription?.toLowerCase().contains('salad') ?? false);

    final double foodPrice = isFood ? (deliveryProvider.draftFoodPrice ?? 350.00) : 0.00;
    final double deliveryFee = isFood ? 100.00 : 120.00;
    final double serviceFee = isFood ? 20.00 : 0.00;
    final double totalPrice = foodPrice + deliveryFee + serviceFee;

    final isPaymentSelected = _selectedMethod != null;
    final isReceiptUploaded = _uploadedReceipt != null;
    final isReadyToSubmit = isPaymentSelected && isReceiptUploaded;
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout & Payment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Delivery Summary
              _buildDeliverySummaryCard(deliveryProvider),

              const SizedBox(height: 16),

              // 2. POS Invoice Breakdown
              _buildPosInvoiceCard(
                isFood: isFood,
                foodPrice: foodPrice,
                deliveryFee: deliveryFee,
                serviceFee: serviceFee,
                totalPrice: totalPrice,
                currencyFormatter: currencyFormatter,
                deliveryProvider: deliveryProvider,
              ),

              const SizedBox(height: 24),

              // 3. Payment Method Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Manual Transfer',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Transfer the exact total amount and upload your real payment receipt.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 14),

              // 4. Payment Option Cards (Telebirr, Commercial Bank of Ethiopia, Awash Bank)
              ..._paymentAccounts.map((account) {
                final isSelected = _selectedMethod == account.method;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildPaymentOptionCard(
                    account: account,
                    isSelected: isSelected,
                    onTap: () => _onSelectPaymentMethod(account, totalPrice),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // 5. Verification Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Payment Verification',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Please upload the genuine receipt of your transfer. Our admin team will verify it immediately on the dashboard before dispatching your order.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB45309),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6. Real Receipt Upload Section
              Container(
                key: _receiptSectionKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upload Transaction Receipt',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isReceiptUploaded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'Receipt Attached',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Take a photo or choose your transfer screenshot from your device gallery.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    // Receipt Upload Box
                    if (!isReceiptUploaded) ...[
                      InkWell(
                        onTap: _isPickingFile ? null : _showReceiptPickerModal,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedMethod != null ? AppColors.primary.withValues(alpha: 0.6) : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: _isPickingFile
                                    ? const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                                      )
                                    : const Icon(
                                        Icons.add_a_photo_rounded,
                                        color: AppColors.primary,
                                        size: 26,
                                      ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isPickingFile ? 'Processing image...' : 'Tap to Upload Real Receipt',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Camera photo or Gallery image (JPG, PNG, PDF)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Uploaded Real Receipt Card Preview with Check Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Thumbnail Image
                                InkWell(
                                  onTap: _showReceiptPreviewDialog,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: (_uploadedReceipt!.fileBytes != null)
                                        ? Image.memory(
                                            _uploadedReceipt!.fileBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.receipt_long_rounded,
                                            color: Color(0xFF16A34A),
                                            size: 26,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _uploadedReceipt!.fileName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_uploadedReceipt!.fileSize} • Uploaded ${_uploadedReceipt!.uploadedAt}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primary),
                                  tooltip: 'Replace receipt',
                                  onPressed: _showReceiptPickerModal,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFDC2626)),
                                  tooltip: 'Remove receipt',
                                  onPressed: _removeReceipt,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 8),

                            // Prominent Check/Preview Receipt Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.visibility_rounded, size: 16),
                                label: const Text('Check / View Full Receipt Preview'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _showReceiptPreviewDialog,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 7. Submit Delivery Request Button (Active ONLY after BOTH choosing payment option AND uploading receipt)
              if (isReadyToSubmit) ...[
                CustomButton(
                  text: 'Submit Delivery Request 🚀',
                  isLoading: deliveryProvider.isSubmitting,
                  onPressed: _handleSubmitDelivery,
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                        SizedBox(width: 8),
                        Text(
                          'Submit Delivery Request',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    !isPaymentSelected
                        ? '👉 Step 1: Select your preferred payment option above'
                        : '👉 Step 2: Upload your payment receipt above to activate submit',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliverySummaryCard(DeliveryProvider deliveryProvider) {
    final pickup = (deliveryProvider.draftPickup != null && deliveryProvider.draftPickup!.isNotEmpty)
        ? deliveryProvider.draftPickup!
        : 'Not specified';
    final destination = (deliveryProvider.draftDestination != null && deliveryProvider.draftDestination!.isNotEmpty)
        ? deliveryProvider.draftDestination!
        : 'Not specified';
    final item = (deliveryProvider.draftItemDescription != null && deliveryProvider.draftItemDescription!.isNotEmpty)
        ? deliveryProvider.draftItemDescription!
        : 'General Item';
    final instructions = deliveryProvider.draftInstructions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
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
              const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Order & Delivery Details',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked_rounded, size: 15, color: Color(0xFF10B981)),
                  Container(
                    width: 2,
                    height: 24,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: const Color(0xFFE2E8F0),
                  ),
                  const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickup,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      destination,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          Row(
            children: [
              const Text(
                'Item: ',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (instructions != null && instructions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Note: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
                Expanded(
                  child: Text(
                    instructions,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPosInvoiceCard({
    required bool isFood,
    required double foodPrice,
    required double deliveryFee,
    required double serviceFee,
    required double totalPrice,
    required NumberFormat currencyFormatter,
    required DeliveryProvider deliveryProvider,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
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
              const Row(
                children: [
                  Icon(Icons.receipt_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Order Pricing & Invoice',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Text(
                  'Standard Rate',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          if (isFood) ...[
            _buildInvoiceRow(
              'Food / Order Items',
              '${currencyFormatter.format(foodPrice)} Birr',
              subtitle: deliveryProvider.draftItemDescription,
            ),
            const SizedBox(height: 8),
          ],

          _buildInvoiceRow(
            'Delivery Fee (Standard Trip)',
            '${currencyFormatter.format(deliveryFee)} Birr',
          ),
          const SizedBox(height: 8),

          if (isFood) ...[
            _buildInvoiceRow(
              'Platform Service & Packaging',
              '${currencyFormatter.format(serviceFee)} Birr',
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Payable Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Includes all delivery & handling charges',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                '${currencyFormatter.format(totalPrice)} Birr',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String title, String amount, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required PaymentAccountInfo account,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? account.brandBgColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? account.brandColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: account.brandColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: account.brandBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: account.brandColor.withValues(alpha: 0.2)),
              ),
              child: Icon(account.fallbackIcon, color: account.brandColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? account.brandColor : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Acc: ${account.accountNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? account.brandColor : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? account.brandColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
