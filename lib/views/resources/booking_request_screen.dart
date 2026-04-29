// This screen is for chairpersons to request a resource booking
// They pick a resource (or type "Other" for unlisted ones),
// choose start and end time, view existing slots, and submit
// The request then shows up for teachers to approve or reject

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:club_management_app/controllers/resource_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';
import 'package:club_management_app/controllers/club_controller.dart';
import 'package:club_management_app/controllers/event_controller.dart';
import 'package:club_management_app/models/booking_model.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  // Sentinel value used when user picks "Other"
  static const String _otherResourceId = '__other__';

  final _formKey = GlobalKey<FormState>();

  // Selected resource
  String _selectedResourceId = '';
  String _selectedResourceName = '';

  // When user picks "Other", they type the name here
  final _otherResourceController = TextEditingController();

  // Date and time
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;

  // Notes field
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _otherResourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Unfocuses any active text field before showing a date/time picker.
  /// The Scaffold uses resizeToAvoidBottomInset:false so the keyboard
  /// does not shrink the window — this is just good UX hygiene so the
  /// keyboard doesn't sit behind the picker dialog.
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final resourceController = Get.find<ResourceController>();
    final authController = Get.find<AuthController>();
    final clubController = Get.find<ClubController>();
    final eventController = Get.find<EventController>();
    final colorScheme = Theme.of(context).colorScheme;

    // Approved bookings for the currently selected resource
    final bookedSlots = _selectedResourceId.isEmpty ||
            _selectedResourceId == _otherResourceId
        ? <BookingModel>[]
        : resourceController.bookings
            .where((b) =>
                b.resourceId == _selectedResourceId &&
                b.status == 'approved')
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      // Prevent the scaffold from shrinking when the keyboard opens.
      // If this is true (the default), the available height for any
      // dialog launched while the keyboard is open becomes less than
      // the dialog's own minimum size — producing the
      // "BoxConstraints has non-normalized height constraints" crash.
      // The SingleChildScrollView handles its own inset avoidance.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Request Resource Booking'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---- SELECT RESOURCE ----
              _sectionLabel(context, 'Select Resource'),
              const SizedBox(height: 8),

              Obx(() => DropdownButtonFormField<String>(
                decoration: _inputDecoration(context, 'Choose a resource'),
                value: _selectedResourceId.isEmpty ? null : _selectedResourceId,
                items: [
                  // All known resources with status dots
                  ...resourceController.resources.map((resource) {
                    return DropdownMenuItem(
                      value: resource.id,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: resource.status == 'free'
                                  ? const Color(0xFF0F6E56)
                                  : const Color(0xFFE24B4A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(resource.name),
                        ],
                      ),
                    );
                  }),

                  // "Other" option — lets user type any resource name
                  DropdownMenuItem(
                    value: _otherResourceId,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onSurface.withOpacity(0.35),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Other (specify below)',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.65),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedResourceId = value;
                      if (value == _otherResourceId) {
                        _selectedResourceName = '';
                      } else {
                        final resource = resourceController.resources
                            .firstWhere((r) => r.id == value);
                        _selectedResourceName = resource.name;
                      }
                    });
                  }
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a resource'
                    : null,
              )),

              // ---- "OTHER" NAME FIELD — shown only when Other is selected ----
              if (_selectedResourceId == _otherResourceId) ...[
                const SizedBox(height: 14),
                _sectionLabel(context, 'Resource Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otherResourceController,
                  decoration: _inputDecoration(
                    context,
                    'e.g. Basketball Court, Recording Studio...',
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedResourceName = val.trim();
                    });
                  },
                  validator: (value) {
                    if (_selectedResourceId == _otherResourceId &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please enter the resource name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'This will be sent to the faculty along with your request.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ],

              // ---- EXISTING BOOKED SLOTS for the selected resource ----
              if (bookedSlots.isNotEmpty) ...[
                const SizedBox(height: 20),
                _bookedSlotsSection(context, bookedSlots),
              ] else if (_selectedResourceId.isNotEmpty &&
                  _selectedResourceId != _otherResourceId) ...[
                const SizedBox(height: 14),
                _availabilityBanner(context),
              ],

              const SizedBox(height: 20),

              // ---- START DATE AND TIME ----
              _sectionLabel(context, 'Start Date and Time'),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {
                  _dismissKeyboard();
                  if (!mounted) return;

                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    useRootNavigator: true,
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      useRootNavigator: true,
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _selectedStartTime = DateTime(
                          date.year, date.month, date.day,
                          time.hour, time.minute,
                        );
                        // Reset end time if it's now before the new start time
                        if (_selectedEndTime != null &&
                            !_selectedEndTime!.isAfter(_selectedStartTime!)) {
                          _selectedEndTime = null;
                        }
                      });
                    }
                  }
                },
                child: _buildDateTimeContainer(
                  context,
                  _selectedStartTime,
                  'Tap to select start date and time',
                ),
              ),

              const SizedBox(height: 16),

              // ---- END DATE AND TIME ----
              _sectionLabel(context, 'End Date and Time'),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {
                  _dismissKeyboard();
                  if (!mounted) return;

                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedStartTime ?? DateTime.now(),
                    firstDate: _selectedStartTime ?? DateTime.now(),
                    lastDate: DateTime(2030),
                    useRootNavigator: true,
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedStartTime != null
                          ? TimeOfDay(
                              hour: _selectedStartTime!.hour,
                              minute: _selectedStartTime!.minute)
                          : TimeOfDay.now(),
                      useRootNavigator: true,
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _selectedEndTime = DateTime(
                          date.year, date.month, date.day,
                          time.hour, time.minute,
                        );
                      });
                    }
                  }
                },
                child: _buildDateTimeContainer(
                  context,
                  _selectedEndTime,
                  'Tap to select end date and time',
                ),
              ),

              // Warn if selected slot overlaps with an existing booking
              if (_selectedStartTime != null &&
                  _selectedEndTime != null &&
                  bookedSlots.isNotEmpty)
                _overlapWarning(
                  context,
                  bookedSlots,
                  _selectedStartTime!,
                  _selectedEndTime!,
                ),

              const SizedBox(height: 16),

              // ---- NOTES ----
              _sectionLabel(context, 'Notes (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration(
                  context,
                  'e.g. Need projector and whiteboard setup',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 28),

              // ---- SUBMIT BUTTON ----
              Obx(() {
                final isLoading = resourceController.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () => _submitBooking(
                              resourceController,
                              authController,
                              clubController,
                              eventController,
                            ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Booking Request',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                );
              }),

              const SizedBox(height: 32),
            ],
          ),        // Column
        ),          // Form
        ),          // SingleChildScrollView
      ),            // SafeArea
    );              // Scaffold
  }

  // -------------------------------------------------------
  // SUBMIT LOGIC — extracted from build for clarity
  // -------------------------------------------------------
  void _submitBooking(
    ResourceController resourceController,
    AuthController authController,
    ClubController clubController,
    EventController eventController,
  ) {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStartTime == null || _selectedEndTime == null) {
      Get.snackbar(
        'Missing Time',
        'Please select both start and end date/time',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!_selectedEndTime!.isAfter(_selectedStartTime!)) {
      Get.snackbar(
        'Invalid Time',
        'End time must be after start time',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final isOther = _selectedResourceId == _otherResourceId;
    final finalResourceId = isOther ? '' : _selectedResourceId;
    final finalResourceName = isOther
        ? '${_otherResourceController.text.trim()} (Other)'
        : _selectedResourceName;

    final user = authController.currentUser.value;
    final club = clubController.selectedClub.value;
    final event = eventController.selectedEvent.value;

    final booking = BookingModel(
      id: '',
      resourceId: finalResourceId,
      resourceName: finalResourceName,
      clubId: user?.clubId ?? '',
      clubName: club?.name ?? '',
      eventId: event?.id ?? '',
      eventName: event?.name ?? '',
      requestedBy: user?.id ?? '',
      startTime: _selectedStartTime!,
      endTime: _selectedEndTime!,
      status: 'pending',
      approvedBy: '',
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    resourceController.submitBooking(booking).then((_) {
      // submitBooking calls Get.back() on success, so only show dialog
      // if the widget is still mounted (i.e., navigation hasn't happened yet)
      if (mounted) {
        _showConfirmationDialog(finalResourceName);
      }
    });
  }

  // -------------------------------------------------------
  // SUCCESS CONFIRMATION DIALOG
  // -------------------------------------------------------
  void _showConfirmationDialog(String resourceName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0F6E56).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF0F6E56),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Request Submitted!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your booking request for "$resourceName" has been submitted. The faculty advisor will review and respond shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.back();
              },
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Booked slots info panel shown under the dropdown
  // -------------------------------------------------------
  Widget _bookedSlotsSection(BuildContext context, List<BookingModel> slots) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE24B4A).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE24B4A).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy_rounded,
                  size: 14, color: Color(0xFFE24B4A)),
              const SizedBox(width: 6),
              Text(
                'This resource has ${slots.length} booked slot${slots.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE24B4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...slots.map((b) {
            final isPast = b.endTime.isBefore(now);
            final isActive =
                b.startTime.isBefore(now) && b.endTime.isAfter(now);
            final slotColor = isActive
                ? const Color(0xFFE24B4A)
                : isPast
                    ? colorScheme.onSurface.withOpacity(0.3)
                    : const Color(0xFF854F0B);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 8, top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slotColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_formatDateTime(b.startTime)}  →  ${_formatDateTime(b.endTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPast
                            ? colorScheme.onSurface.withOpacity(0.35)
                            : colorScheme.onSurface.withOpacity(0.75),
                        decoration:
                            isPast ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
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
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Pick a time slot that does not overlap with the above.',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withOpacity(0.45),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Green banner when no bookings exist for selected resource
  // -------------------------------------------------------
  Widget _availabilityBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F6E56).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0F6E56).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 16, color: Color(0xFF0F6E56)),
          SizedBox(width: 8),
          Text(
            'No existing bookings — all slots are free',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF0F6E56),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Overlap warning — shown when chosen slot clashes
  // -------------------------------------------------------
  Widget _overlapWarning(
    BuildContext context,
    List<BookingModel> slots,
    DateTime start,
    DateTime end,
  ) {
    final hasOverlap = slots.any(
      (b) => start.isBefore(b.endTime) && end.isAfter(b.startTime),
    );
    if (!hasOverlap) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE24B4A).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: const Color(0xFFE24B4A).withOpacity(0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 16, color: Color(0xFFE24B4A)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your selected slot overlaps with an existing booking. The faculty will still review the request.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE24B4A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Section label
  // -------------------------------------------------------
  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: DateTime container
  // -------------------------------------------------------
  Widget _buildDateTimeContainer(
      BuildContext context, DateTime? value, String placeholder) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded,
              size: 18,
              color: colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(width: 8),
          Text(
            value != null ? _formatDateTime(value) : placeholder,
            style: TextStyle(
              color: value != null
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Input decoration
  // -------------------------------------------------------
  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withOpacity(0.4),
        fontSize: 13,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: colorScheme.onSurface.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE24B4A)),
      ),
    );
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $amPm';
  }
}