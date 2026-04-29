// This screen shows all college resources and their availability
// Each resource shows its booked time slots so users can see
// exactly when it is occupied and when it is free
// Teachers can approve/reject booking requests
// Chairpersons can request a new booking

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:club_management_app/controllers/resource_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';
import 'package:club_management_app/models/resource_model.dart';
import 'package:club_management_app/models/booking_model.dart';

class ResourceListScreen extends GetView<ResourceController> {
  const ResourceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final colorScheme = Theme.of(context).colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchResources();
      controller.fetchBookings();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---- STAT CARDS ----
              Row(
                children: [
                  _buildStatCard(
                    context: context,
                    label: 'Free',
                    value: controller.freeResources.length.toString(),
                    color: const Color(0xFF0F6E56),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context: context,
                    label: 'Occupied',
                    value: controller.occupiedResources.length.toString(),
                    color: const Color(0xFFE24B4A),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context: context,
                    label: 'Pending',
                    value: controller.pendingBookings.length.toString(),
                    color: const Color(0xFF854F0B),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---- RESOURCES LIST ----
              Text(
                'ALL RESOURCES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.45),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              if (controller.resources.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No resources found',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                )
              else
                ...controller.resources.map((resource) {
                  // Get all APPROVED bookings for this specific resource
                  final resourceBookings = controller.bookings
                      .where((b) =>
                          b.resourceId == resource.id &&
                          b.status == 'approved')
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  return _buildResourceCard(
                    context: context,
                    resource: resource,
                    approvedBookings: resourceBookings,
                  );
                }),

              const SizedBox(height: 24),

              // ---- BOOKING REQUESTS SECTION ----
              Text(
                'BOOKING REQUESTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.45),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              if (controller.bookings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No booking requests yet',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                )
              else
                ...controller.bookings.map((booking) {
                  return _buildBookingCard(
                    context: context,
                    booking: booking,
                    authController: authController,
                  );
                }),

              const SizedBox(height: 80),
            ],
          ),
        );
      }),

      floatingActionButton: Get.find<AuthController>().isChairperson
          ? FloatingActionButton.extended(
              onPressed: () => Get.toNamed('/booking-request'),
              icon: const Icon(Icons.add),
              label: const Text('Request Booking'),
            )
          : null,
    );
  }

  // -------------------------------------------------------
  // RESOURCE CARD — shows the resource + all its booked slots
  // -------------------------------------------------------
  Widget _buildResourceCard({
    required BuildContext context,
    required ResourceModel resource,
    required List<BookingModel> approvedBookings,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // A resource is truly "occupied right now" only if there is an
    // approved booking whose time window covers the current moment
    final now = DateTime.now();
    final isCurrentlyOccupied = approvedBookings.any(
      (b) => b.startTime.isBefore(now) && b.endTime.isAfter(now),
    );

    final statusColor = isCurrentlyOccupied
        ? const Color(0xFFE24B4A)
        : const Color(0xFF0F6E56);
    final statusLabel = isCurrentlyOccupied ? 'Occupied now' : 'Free now';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ---- Resource header ----
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getResourceIcon(resource.type),
                    color: statusColor,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // Name + capacity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (resource.capacity > 0)
                        Text(
                          'Capacity: ${resource.capacity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Booked slots section ----
          if (approvedBookings.isNotEmpty) ...[
            Divider(
              height: 1,
              color: colorScheme.onSurface.withOpacity(0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text(
                'BOOKED SLOTS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ...approvedBookings.map((booking) {
              final slotNow = DateTime.now();
              final isActive = booking.startTime.isBefore(slotNow) &&
                  booking.endTime.isAfter(slotNow);
              final isPast = booking.endTime.isBefore(slotNow);

              final slotColor = isActive
                  ? const Color(0xFFE24B4A)
                  : isPast
                      ? colorScheme.onSurface.withOpacity(0.3)
                      : const Color(0xFF854F0B);

              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                child: Row(
                  children: [
                    // Timeline dot
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slotColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Time range
                    Expanded(
                      child: Text(
                        '${_formatDateTime(booking.startTime)}  →  ${_formatDateTime(booking.endTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPast
                              ? colorScheme.onSurface.withOpacity(0.35)
                              : colorScheme.onSurface.withOpacity(0.75),
                          decoration: isPast
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Club name pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: slotColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        booking.clubName,
                        style: TextStyle(
                          fontSize: 10,
                          color: slotColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE24B4A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NOW',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFFE24B4A),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ] else ...[
            // No booked slots — show "Available all day" message
            Divider(
              height: 1,
              color: colorScheme.onSurface.withOpacity(0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: const Color(0xFF0F6E56).withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'No bookings — available for any slot',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0F6E56).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // BOOKING REQUEST CARD
  // -------------------------------------------------------
  Widget _buildBookingCard({
    required BuildContext context,
    required BookingModel booking,
    required AuthController authController,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    switch (booking.status) {
      case 'approved':
        statusColor = const Color(0xFF0F6E56);
        break;
      case 'rejected':
        statusColor = const Color(0xFFE24B4A);
        break;
      default:
        statusColor = const Color(0xFF854F0B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Top row — resource name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.resourceName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            '${booking.clubName} · ${booking.eventName}',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.55),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatDateTime(booking.startTime)}  →  ${_formatDateTime(booking.endTime)}',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),

          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              booking.notes,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Approve/Reject buttons for teachers on pending bookings
          if (authController.isTeacher && booking.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6E56),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => controller.approveBooking(booking),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE24B4A),
                      side: const BorderSide(color: Color(0xFFE24B4A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => controller.rejectBooking(booking),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Stat Card
  // -------------------------------------------------------
  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Icon for resource type
  // -------------------------------------------------------
  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'hall':
        return Icons.meeting_room_rounded;
      case 'classroom':
        return Icons.school_rounded;
      case 'equipment':
        return Icons.settings_rounded;
      default:
        return Icons.room_rounded;
    }
  }

  // -------------------------------------------------------
  // HELPER: Format DateTime nicely
  // -------------------------------------------------------
  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, $hour:$minute $amPm';
  }
}