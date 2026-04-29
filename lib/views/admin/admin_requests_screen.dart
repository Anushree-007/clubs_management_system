import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:club_management_app/controllers/auth_controller.dart';
import 'package:club_management_app/controllers/user_request_controller.dart';
import 'package:club_management_app/models/user_request_model.dart';
import 'package:intl/intl.dart';

// AdminRequestsScreen — accessible only by teachers (admin).
//
// Shows every user registration request grouped by status.
// For each pending request the admin can:
//   Approve → Firebase Auth account created, Firestore profile written.
//   Reject  → A reason dialog appears before the request is declined.
//
// Reviewed requests are shown below as a log with the temp password visible
// for approved ones so the admin can copy it and share it with the user.

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  // FIX: was `final _controller = Get.find<UserRequestController>();` at field
  // level.  Field initialisation runs before the widget tree is built and
  // before GetX guarantees registration → crash.  Use late + initState instead.
  late UserRequestController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<UserRequestController>();

    // FIX: Role guard — only teachers (admins) may see this screen.
    // A chairperson who somehow navigates here is sent back immediately.
    final auth = Get.find<AuthController>();
    if (!auth.isTeacher) {
      // Schedule the redirect after the first frame so the widget tree is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/dashboard');
        Get.snackbar('Access Denied', 'This screen is for admins only.',
            snackPosition: SnackPosition.BOTTOM);
      });
      return;
    }

    // Always reload from Firestore when this screen opens
    _controller.fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.fetchRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final all      = _controller.requests;
        final pending  = all.where((r) => r.status == 'pending').toList();
        final reviewed = all.where((r) => r.status != 'pending').toList();

        if (all.isEmpty) return _emptyState(cs);

        return RefreshIndicator(
          onRefresh: _controller.fetchRequests,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader(
                    'Pending  ·  ${pending.length}', const Color(0xFF854F0B)),
                const SizedBox(height: 8),
                ...pending.map((r) => _requestCard(context, r)),
              ],
              if (reviewed.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionHeader(
                    'Reviewed  ·  ${reviewed.length}',
                    // FIX: withOpacity() deprecated → withValues(alpha:)
                    cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                ...reviewed.map((r) => _requestCard(context, r)),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48,
              // FIX: withOpacity() deprecated → withValues(alpha:)
              color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('No requests yet',
              style: TextStyle(
                  // FIX: withOpacity() deprecated → withValues(alpha:)
                  color: cs.onSurface.withValues(alpha: 0.5), fontSize: 15)),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _sectionHeader(String label, Color color) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.8),
    );
  }

  // ── Request card ───────────────────────────────────────────────────────────
  Widget _requestCard(BuildContext context, UserRequestModel request) {
    final cs        = Theme.of(context).colorScheme;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final isPending  = request.status == 'pending';
    final isApproved = request.status == 'approved';

    final statusColor = isPending
        ? const Color(0xFF854F0B)
        : isApproved
            ? const Color(0xFF0F6E56)
            : Colors.red.shade700;

    // FIX: withOpacity() deprecated → withValues(alpha:)
    final statusBg = statusColor.withValues(alpha: isDark ? 0.2 : 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — avatar + name/email + status pill
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    // FIX: withOpacity() deprecated → withValues(alpha:)
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      request.name.isNotEmpty
                          ? request.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      Text(request.email,
                          style: TextStyle(
                              fontSize: 11,
                              // FIX: withOpacity() deprecated → withValues(alpha:)
                              color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    request.status[0].toUpperCase() +
                        request.status.substring(1),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details
            _detail(context, 'Role',
                request.role[0].toUpperCase() + request.role.substring(1)),
            if (request.clubName != null && request.clubName!.isNotEmpty)
              _detail(context, 'Club', request.clubName!),
            // Show the unlisted club name if provided
            if (request.unlistedClubName != null &&
                request.unlistedClubName!.isNotEmpty)
              _detail(context, 'Club (unlisted)', request.unlistedClubName!),
            _detail(context, 'Employee ID', request.employeeId),
            _detail(context, 'Phone', request.phone),
            _detail(context, 'Submitted',
                DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt)),

            // Rejection reason
            if (request.status == 'rejected' &&
                request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // FIX: withOpacity() deprecated → withValues(alpha:)
                  color: Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_outlined,
                        color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${request.rejectionReason}',
                        style: TextStyle(
                            fontSize: 12,
                            // FIX: withOpacity() deprecated → withValues(alpha:)
                            color: cs.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Approved — show temp password with a copy button
            // FIX: old code just showed "Account created — share securely"
            // with no way to actually see or copy the password.  Now we
            // display the stored tempPassword and a copy-to-clipboard button.
            if (isApproved && request.tempPassword != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // FIX: withOpacity() deprecated → withValues(alpha:)
                  color: const Color(0xFF0F6E56).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF0F6E56).withValues(alpha: 0.2),
                      width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Color(0xFF0F6E56), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Account created — share credentials securely',
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Temp password row with copy button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Theme.of(context).dividerColor, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.key_rounded,
                              size: 14, color: Color(0xFF0F6E56)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              request.tempPassword!,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: cs.onSurface),
                            ),
                          ),
                          // Copy to clipboard button
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            color: const Color(0xFF1565C0),
                            tooltip: 'Copy password',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: request.tempPassword!));
                              Get.snackbar(
                                'Copied',
                                'Temporary password copied to clipboard.',
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask the user to change this password on first login.',
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons — only for pending requests
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(request),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _showApproveDialog(request),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6E56),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Detail row ─────────────────────────────────────────────────────────────
  Widget _detail(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    // FIX: withOpacity() deprecated → withValues(alpha:)
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 12, color: cs.onSurface))),
        ],
      ),
    );
  }

  // ── Approve confirmation dialog ────────────────────────────────────────────
  void _showApproveDialog(UserRequestModel request) {
    Get.dialog(AlertDialog(
      title: const Text('Approve Request'),
      content: Text(
        'Create an account for ${request.name} as ${request.role}?\n\n'
        'A temporary password will be generated and shown on this screen '
        'so you can share it with the user.',
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: const Color(0xFF0F6E56)),
          onPressed: () {
            Get.back();
            _controller.approveRequest(request);
          },
          child: const Text('Approve'),
        ),
      ],
    ));
  }

  // ── Reject dialog with reason field ───────────────────────────────────────
  void _showRejectDialog(UserRequestModel request) {
    final reasonController = TextEditingController();

    // FIX: dispose the reasonController after the dialog closes so the
    // native text buffer is released and doesn't leak on every rejection.
    Get.dialog(
      AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting request from ${request.name}.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'e.g. Invalid employee ID, already has an account…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose(); // dispose on cancel
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final reason = reasonController.text;
              reasonController.dispose(); // dispose before navigating away
              Get.back();
              _controller.rejectRequest(request, reason);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}