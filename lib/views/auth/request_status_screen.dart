// This screen lets a user check if their registration request was approved or rejected
// They come here from the login screen by entering their email
// If approved: shows their temp password so they can login
// If rejected: shows the rejection reason

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:club_management_app/services/firestore_service.dart';


class RequestStatusScreen extends StatefulWidget {
  const RequestStatusScreen({super.key});

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> {
  final _emailController = TextEditingController();
  final _firestoreService = FirestoreService();
  
  // Holds the result after checking — null means not checked yet
  Map<String, dynamic>? _requestData;
  bool _isLoading = false;
  bool _hasChecked = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    // Validate email first
    if (_emailController.text.trim().isEmpty) {
      Get.snackbar('Email Required', 'Please enter your email address',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasChecked = false;
      _requestData = null;
    });

    try {
      // Look up the request by email in Firestore
      final result = await _firestoreService
          .getRequestByEmail(_emailController.text.trim());
      
      setState(() {
        _requestData = result;
        _hasChecked = true;
      });
    } catch (e) {
      Get.snackbar('Error', 'Could not check status. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Request Status'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Info banner at the top
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1565C0), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter the email address you used when submitting '
                      'your access request to check its current status.',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Your VIT Email',
                hintText: 'Enter the email from your request',
                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Check button
            FilledButton(
              onPressed: _isLoading ? null : _checkStatus,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Check Status',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 24),

            // Result section — only shown after checking
            if (_hasChecked) ...[
              if (_requestData == null)
                // No request found for this email
                _buildResultCard(
                  icon: Icons.search_off_rounded,
                  iconColor: Colors.grey,
                  title: 'No request found',
                  subtitle:
                      'We could not find a request with this email address. '
                      'Please check the email and try again, or submit a new request.',
                  bgColor: Colors.grey.withOpacity(0.1),
                  borderColor: Colors.grey.withOpacity(0.3),
                )
              else
                _buildStatusResult(_requestData!, cs),
            ],
          ],
        ),
      ),
    );
  }

  // Builds the appropriate result card based on request status
  Widget _buildStatusResult(Map<String, dynamic> data, ColorScheme cs) {
    final status = data['status'] as String? ?? 'pending';
    final name = data['name'] as String? ?? 'Unknown';

    switch (status) {
      case 'pending':
        return _buildResultCard(
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFF854F0B),
          title: 'Request Pending',
          subtitle:
              'Hi $name, your request is still under review. '
              'The admin will review it shortly. Please check back later.',
          bgColor: const Color(0xFFFEF3E2),
          borderColor: const Color(0xFF854F0B).withOpacity(0.3),
        );

      case 'approved':
        // Show temp password so user can login
        final tempPassword = data['tempPassword'] as String? ?? '';
        return Column(
          children: [
            _buildResultCard(
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF0F6E56),
              title: 'Request Approved!',
              subtitle:
                  'Hi $name, your access has been approved. '
                  'Use the credentials below to log in to the app.',
              bgColor: const Color(0xFFE1F5EE),
              borderColor: const Color(0xFF0F6E56).withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            // Credential card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR LOGIN CREDENTIALS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email row
                  _credentialRow(
                    label: 'Email',
                    value: data['email'] as String? ?? '',
                    onCopy: () => _copyToClipboard(
                        data['email'] as String? ?? '', 'Email'),
                  ),

                  const Divider(height: 20),

                  // Temp password row
                  _credentialRow(
                    label: 'Temporary Password',
                    value: tempPassword,
                    onCopy: () =>
                        _copyToClipboard(tempPassword, 'Password'),
                  ),

                  const SizedBox(height: 12),

                  // Warning to change password
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 14),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please change your password after your first login '
                            'for security.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Go to login button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Get.offAllNamed('/login'),
                      child: const Text('Go to Login'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'rejected':
        final reason = data['rejectionReason'] as String? ??
            'No reason provided.';
        return _buildResultCard(
          icon: Icons.cancel_rounded,
          iconColor: const Color(0xFFE24B4A),
          title: 'Request Rejected',
          subtitle:
              'Hi $name, unfortunately your request was not approved.\n\n'
              'Reason: $reason\n\n'
              'If you believe this is a mistake, please contact the admin directly.',
          bgColor: const Color(0xFFFCEBEB),
          borderColor: const Color(0xFFE24B4A).withOpacity(0.3),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // Generic result card widget
  Widget _buildResultCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Shows a label + value + copy button in a row
  Widget _credentialRow({
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        // Copy to clipboard button
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 18),
          color: const Color(0xFF1565C0),
          onPressed: onCopy,
        ),
      ],
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      '$label copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}