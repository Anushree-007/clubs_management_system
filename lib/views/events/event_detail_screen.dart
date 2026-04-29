// This screen shows all the details of one selected event.
// The user gets here by tapping an event card in the Event List screen.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:club_management_app/controllers/event_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';
import 'package:club_management_app/models/event_model.dart';
import 'package:club_management_app/services/firestore_service.dart';

// EventDetailScreen uses GetView<EventController> so we get `controller`
// for free without a manual Get.find call.
class EventDetailScreen extends GetView<EventController> {
  const EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.selectedEvent.value?.name ?? 'Event Detail',
            )),
        centerTitle: true,
        actions: [
          // Edit button only visible to chairpersons
          if (authController.isChairperson)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit event',
              onPressed: controller.goToEditEvent,
            ),
        ],
      ),

      body: Obx(() {
        if (controller.selectedEvent.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final event = controller.selectedEvent.value!;

        final attendancePercent = event.totalRegistrations > 0
            ? (event.totalAttendees / event.totalRegistrations * 100)
                .toStringAsFixed(1)
            : '0.0';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── CARD 1: Basic Info ───────────────────────────────────────
              _card(
                cs: cs,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(cs, 'Basic Info'),
                    const SizedBox(height: 10),
                    Text(
                      event.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _typeBadge(event.type),
                    const SizedBox(height: 12),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withOpacity(0.75),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── CARD 2: Date & Venue ────────────────────────────────────
              _card(
                cs: cs,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(cs, 'Date and Venue'),
                    const SizedBox(height: 12),
                    _infoRow(cs, Icons.calendar_today_outlined, 'Start Date',
                        _formatDate(event.date)),
                    const SizedBox(height: 8),
                    _infoRow(cs, Icons.calendar_month_outlined, 'End Date',
                        _formatDate(event.endDate)),
                    const SizedBox(height: 8),
                    _infoRow(cs, Icons.access_time_outlined, 'Duration',
                        '${event.durationHours} hours'),
                    const SizedBox(height: 8),
                    _infoRow(cs, Icons.location_on_outlined, 'Venue',
                        event.venue),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── CARD 3: Attendance ──────────────────────────────────────
              _card(
                cs: cs,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(cs, 'Attendance'),
                    const SizedBox(height: 12),
                    _infoRow(cs, Icons.people_outline_rounded, 'Registered',
                        event.totalRegistrations.toString()),
                    const SizedBox(height: 8),
                    _infoRow(cs, Icons.how_to_reg_outlined, 'Attended',
                        event.totalAttendees.toString()),
                    const SizedBox(height: 8),
                    _infoRow(cs, Icons.percent_rounded, 'Attendance Rate',
                        '$attendancePercent% attended'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── CARD 4: Finance Status ──────────────────────────────────
              _card(
                cs: cs,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(cs, 'Finance Status'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          event.budgetClosed
                              ? Icons.check_circle_outline_rounded
                              : Icons.access_time_rounded,
                          color: event.budgetClosed
                              ? const Color(0xFF0F6E56)
                              : const Color(0xFF854F0B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.budgetClosed
                              ? 'Budget closed'
                              : 'Budget pending',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: event.budgetClosed
                                ? const Color(0xFF0F6E56)
                                : const Color(0xFF854F0B),
                          ),
                        ),
                      ],
                    ),
                    if (event.budgetClosed && event.budgetClosedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Closed on ${_formatDate(event.budgetClosedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.account_balance_wallet_outlined,
                            size: 16),
                        label: const Text('View Finance Details'),
                        onPressed: () {
                          Get.find<EventController>().selectedEvent.value =
                              event;
                          Get.toNamed('/finance-detail');
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── CARD 5: Report Status (chairperson only) ────────────────
              // if (authController.isChairperson)
              //   _card(
              //     cs: cs,
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         _sectionLabel(cs, 'Report Status'),
              //         const SizedBox(height: 12),
              //         _reportSection(context, cs, event),
              //       ],
              //     ),
              //   ),

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // ── Report section widget ───────────────────────────────────────────────
  // Extracted from the Builder so logic is easy to follow top-to-bottom.
  Widget _reportSection(
      BuildContext context, ColorScheme cs, EventModel event) {
    final status =
        event.reportStatus.isEmpty ? 'draft' : event.reportStatus;
    final revisionNote = event.reportRevisionNote;

    // NEEDS REVISION
    if (status == 'needs_revision') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF854F0B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF854F0B).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        color: Color(0xFF854F0B), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Revision requested by admin',
                      style: TextStyle(
                        color: Color(0xFF854F0B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  revisionNote.isNotEmpty
                      ? revisionNote
                      : 'Please review and resubmit.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // SizedBox(
          //   width: double.infinity,
          //   height: 46,
          //   child: FilledButton.icon(
          //     icon: const Icon(Icons.send_rounded, size: 16),
          //     label: const Text('Resubmit for Review'),
          //     onPressed: () => _submitForReview(event.id),
          //   ),
          // ),
        ],
      );
    }

    // PENDING REVIEW
    if (status == 'pending_review') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF185FA5).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF185FA5).withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded,
                color: Color(0xFF185FA5), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Report submitted — pending admin review',
                style: TextStyle(
                  color: Color(0xFF185FA5),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // APPROVED
    if (status == 'approved') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F6E56).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF0F6E56).withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_rounded,
                color: Color(0xFF0F6E56), size: 16),
            SizedBox(width: 8),
            Text(
              'Report approved by admin',
              style: TextStyle(
                color: Color(0xFF0F6E56),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // DRAFT (default — not yet submitted)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This report has not been submitted for review yet.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 12),
        // SizedBox(
        //   width: double.infinity,
        //   height: 46,
        //   child: FilledButton.icon(
        //     icon: const Icon(Icons.send_rounded, size: 16),
        //     label: const Text('Submit Report for Review'),
        //     onPressed: () => _submitForReview(event.id),
        //   ),
        // ),
      ],
    );
  }

  // ── Submit / resubmit report ─────────────────────────────────────────────
  Future<void> _submitForReview(String eventId) async {
    try {
      await FirestoreService().submitReportForReview(eventId);

      // Refresh selectedEvent so the UI reflects the new status instantly
      final updated =
          await FirestoreService().getEventById(eventId);
      if (updated != null) {
        controller.selectedEvent.value = updated;
      }

      Get.snackbar(
        'Submitted',
        'Your report has been sent to the admin for review.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F6E56),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not submit report: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required ColorScheme cs, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(ColorScheme cs, String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: cs.onSurface.withOpacity(0.45),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _infoRow(
      ColorScheme cs, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.4)),
        const SizedBox(width: 8),
        Text(
          '$label:  ',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeBadge(String type) {
    final Color color;
    switch (type) {
      case 'workshop':
        color = const Color(0xFF185FA5);
        break;
      case 'hackathon':
        color = const Color(0xFF533AB7);
        break;
      case 'cultural':
        color = const Color(0xFF854F0B);
        break;
      case 'seminar':
        color = const Color(0xFF0F6E56);
        break;
      case 'sports':
        color = const Color(0xFF3B6D11);
        break;
      default:
        color = const Color(0xFF5F5E5A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}