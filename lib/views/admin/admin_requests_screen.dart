// the admin approval/rejection panel


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:club_management_app/controllers/user_request_controller.dart';
import 'package:club_management_app/models/user_request_model.dart';
import 'package:intl/intl.dart';

// AdminRequestsScreen — accessible only by teachers (admin).
//
// It shows every user registration request grouped by status.
// For each pending request, the admin can:
//   - Approve  → Firebase Auth account is created, Firestore profile written.
//   - Reject   → A reason dialog appears before the request is declined.
//
// Already-reviewed requests (approved/rejected) are shown below as a log.

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  final _controller = Get.find<UserRequestController>();

  @override
  void initState() {
    super.initState();
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
          // Manual refresh button
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

        final all = _controller.requests;
        final pending = all.where((r) => r.status == 'pending').toList();
        final reviewed = all.where((r) => r.status != 'pending').toList();

        if (all.isEmpty) {
          return _emptyState(cs);
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchRequests,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader(context, 'Pending  ·  ${pending.length}',
                    const Color(0xFF854F0B)),
                const SizedBox(height: 8),
                ...pending.map((r) => _requestCard(context, r)),
              ],

              if (reviewed.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionHeader(context, 'Reviewed  ·  ${reviewed.length}',
                    cs.onSurface.withOpacity(0.4)),
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

  // ─── Empty state ─────────────────────────────────────────────────────────
  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'No requests yet',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section header ───────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String label, Color color) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }

  // ─── Request card ─────────────────────────────────────────────────────────
  Widget _requestCard(BuildContext context, UserRequestModel request) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = request.status == 'pending';
    final isApproved = request.status == 'approved';

    // Status colors
    final statusColor = isPending
        ? const Color(0xFF854F0B)
        : isApproved
            ? const Color(0xFF0F6E56)
            : Colors.red.shade700;

    final statusBg = statusColor.withOpacity(isDark ? 0.2 : 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — name + status pill
            Row(
              children: [
                // Avatar circle with initials
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
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
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        request.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status[0].toUpperCase() +
                        request.status.substring(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details grid
            _detail(context, 'Role',
                request.role[0].toUpperCase() + request.role.substring(1)),
            if (request.clubName != null && request.clubName!.isNotEmpty)
              _detail(context, 'Club', request.clubName!),
            _detail(context, 'Employee ID', request.employeeId),
            _detail(context, 'Phone', request.phone),
            _detail(
              context,
              'Submitted',
              DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt),
            ),

            // Rejection reason — shown when rejected
            if (request.status == 'rejected' &&
                request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.red.withOpacity(0.2), width: 0.5),
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
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Temp password hint — shown when approved
            if (request.status == 'approved') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6E56).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF0F6E56).withOpacity(0.2),
                      width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF0F6E56), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Account created — share login credentials securely.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
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
                  // Reject button
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Approve button
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
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  // ─── Detail row inside a card ─────────────────────────────────────────────
  Widget _detail(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Approve confirmation dialog ──────────────────────────────────────────
  void _showApproveDialog(UserRequestModel request) {
    Get.dialog(
      AlertDialog(
        title: const Text('Approve Request'),
        content: Text(
          'Create an account for ${request.name} as ${request.role}?\n\n'
          'A temporary password will be generated. '
          'Share it securely with the user — they should change it on first login.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F6E56),
            ),
            onPressed: () {
              Get.back();
              _controller.approveRequest(request);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  // ─── Reject dialog with reason field ─────────────────────────────────────
  void _showRejectDialog(UserRequestModel request) {
    final reasonController = TextEditingController();

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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _controller.rejectRequest(request, reasonController.text);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}