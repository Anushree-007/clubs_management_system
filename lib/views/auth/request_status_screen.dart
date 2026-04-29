import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:club_management_app/controllers/request_status_controller.dart';

class RequestStatusScreen extends StatefulWidget {
  const RequestStatusScreen({super.key});

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final RequestStatusController _controller = Get.put(RequestStatusController());

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _checkStatus() { // ✅ MOVED UP - was at bottom
    if (_formKey.currentState!.validate()) {
      _controller.checkStatus(_emailController.text.trim().toLowerCase());
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
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 
                  AppBar().preferredSize.height - 
                  MediaQuery.of(context).padding.top - 40,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ✅ FORM FIELDS - WERE MISSING!
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: const Color(0xFF1565C0), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter the email you used to submit your request',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (_) => _checkStatus(),
                  decoration: InputDecoration(
                    labelText: 'Your Email',
                    hintText: 'yourname@vit.ac.in',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Obx(() => _controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : FilledButton(
                        onPressed: _checkStatus,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Check Status',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      )),

                // ✅ STATUS RESULT
                Expanded(
                  child: Obx(() {
                    if (_controller.statusResult.isEmpty) {
                      return const Spacer();
                    }

                    final status = _controller.statusResult;
                    Color iconColor;
                    IconData icon;
                    String title;
                    String message;

                    switch (status['status']) {
                      case 'pending':
                        iconColor = const Color(0xFF854F0B);
                        icon = Icons.hourglass_empty_rounded;
                        title = 'Pending Review';
                        message = 'Your request is waiting for admin approval.';
                        break;
                      case 'approved':
                        iconColor = const Color(0xFF0F6E56);
                        icon = Icons.check_circle_rounded;
                        title = 'Approved!';
                        message = 'Your account is ready.\n\n'
                            'Email: ${status['email']}\n'
                            'Temporary Password: ${status['tempPassword']}\n\n'
                            '⚠️ Change your password after first login.';
                        break;
                      case 'rejected':
                        iconColor = Colors.red.shade600;
                        icon = Icons.cancel_rounded;
                        title = 'Request Rejected';
                        message = 'Reason: ${status['rejectionReason']}\n\n'
                            'Please contact the admin or submit a new request.';
                        break;
                      default:
                        iconColor = cs.onSurface.withOpacity(0.3);
                        icon = Icons.help_outline;
                        title = 'No Request Found';
                        message = 'No request found for this email.';
                    }

                    return Card(
                      margin: const EdgeInsets.only(top: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: iconColor, size: 36),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: cs.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ),
                            if (status['status'] == 'approved') ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => Get.back(),
                                  icon: const Icon(Icons.login_rounded, size: 18),
                                  label: const Text('Go to Login'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F6E56),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
  );
  }
}