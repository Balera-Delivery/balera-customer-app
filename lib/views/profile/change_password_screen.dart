import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to update password'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  controller: _currentPasswordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                  validator: (val) => Validators.required(val, message: 'Current password is required'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'New Password',
                  hint: 'Minimum 6 characters',
                  controller: _newPasswordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm New Password',
                  hint: 'Re-enter new password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                  validator: (val) => Validators.confirmPassword(val, _newPasswordController.text),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Update Password',
                  isLoading: _isLoading,
                  onPressed: _handleChangePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
