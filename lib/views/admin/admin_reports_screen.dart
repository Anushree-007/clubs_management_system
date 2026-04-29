// This screen is for the admin to review submitted event reports.
// Admin can approve a report or send it back for revision with a note.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:club_management_app/models/event_model.dart';
import 'package:club_management_app/services/firestore_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _firestoreService = FirestoreService();
  List<EventModel> _pendingReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _firestoreService.getPendingReportEvents();
      setState(() => _pendingReports = reports);
    } catch (e) {
      Get.snackbar('Error', 'Could not load reports: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve report?'),
        content: Text(
            'Are you sure you want to approve the report for "${event.name}"? '
            'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E56)),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.approveEventReport(event.id);
      await _loadReports();
      if (mounted) {
        Get.snackbar(
          'Approved',
          'Report for "${event.name}" has been approved.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F6E56),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not approve: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _requestRevision(EventModel event) async {
    final noteController = TextEditingController();

    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request revision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event: ${event.name}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Write specific revision notes for the chairperson. '
              'Be clear about exactly what needs to be fixed.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'e.g. Budget breakdown is incomplete. '
                    'Please add expense details for food and decorations.',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (noteController.text.trim().isEmpty) {
                Get.snackbar(
                    'Note required',
                    'Please write what needs to be revised.',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              Navigator.pop(ctx, noteController.text.trim());
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF854F0B)),
            child: const Text('Send for revision'),
          ),
        ],
      ),
    );

    noteController.dispose();
    if (note == null || note.isEmpty) return;

    try {
      await _firestoreService.requestReportRevision(event.id, note);
      await _loadReports();
      if (mounted) {
        Get.snackbar(
          'Revision requested',
          'Notes have been sent to the chairperson.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not send revision: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Reports Review'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingReports.isEmpty
              ? _emptyState(cs)
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingReports.length,
                    itemBuilder: (context, index) =>
                        _reportCard(_pendingReports[index], cs),
                  ),
                ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded,
              size: 48, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No pending reports',
            style: TextStyle(
                color: cs.onSurface.withOpacity(0.5), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'All submitted reports have been reviewed.',
            style: TextStyle(
                color: cs.onSurface.withOpacity(0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(EventModel event, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event name + status pill
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF854F0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Pending review',
                        style: TextStyle(
                          color: Color(0xFF854F0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Text(
                  'Club: ${event.clubId}  ·  ${_formatDate(event.date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  'Registrations: ${event.totalRegistrations}  ·  '
                  'Attended: ${event.totalAttendees}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          Divider(
              height: 1, color: Theme.of(context).dividerColor),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Needs revision',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF854F0B),
                      side: const BorderSide(
                          color: Color(0xFF854F0B), width: 0.5),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _requestRevision(event),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve',
                        style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6E56),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _approve(event),
                  ),
                ),
              ],
            ),
          ),
        ],
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