// This screen shows all the details of one selected event
// The user gets here by tapping an event card in the Event List screen

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import the controllers we need
import 'package:club_management_app/controllers/event_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

// EventDetailScreen extends GetView<EventController>
// This automatically gives us "controller" which is our EventController
class EventDetailScreen extends GetView<EventController> {
  const EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get AuthController to check if user is chairperson or teacher
    final authController = Get.find<AuthController>();

    return Scaffold(
      // AppBar at the top
      appBar: AppBar(
        // Show the event name as the title
        // Obx rebuilds this automatically if selectedEvent changes
        title: Obx(() => Text(
              controller.selectedEvent.value?.name ?? 'Event Detail',
            )),
        actions: [
          // Only show the Edit button if the user is a chairperson
          if (authController.isChairperson)
            IconButton(
              icon: const Icon(Icons.edit),
              // When tapped, go to the edit form
              // selectedEvent is already set so the form knows it's edit mode
              onPressed: controller.goToEditEvent,
            ),
        ],
      ),

      // Main body — Obx watches for changes in selectedEvent
      body: Obx(() {
        // If no event is selected yet, show a loading spinner
        if (controller.selectedEvent.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Store the selected event in a local variable for easy access
        final event = controller.selectedEvent.value!;

        // Calculate attendance percentage safely
        // We check if registrations is 0 to avoid dividing by zero
        final attendancePercent = event.totalRegistrations > 0
            ? (event.totalAttendees / event.totalRegistrations * 100)
                .toStringAsFixed(1)
            : '0.0';

        // SingleChildScrollView allows the page to scroll if content is long
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // =============================================
              // CARD 1 — Basic Info
              // Shows event name, type badge, and description
              // =============================================
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Card title label
                    _buildSectionLabel('Basic Info'),

                    const SizedBox(height: 10),

                    // Event name in big bold text
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Event type shown as a colored badge
                    _buildTypeBadge(event.type),

                    const SizedBox(height: 12),

                    // Event description
                    Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5, // Line spacing for readability
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // =============================================
              // CARD 2 — Date and Venue
              // Shows start date, end date, duration, venue
              // =============================================
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildSectionLabel('Date and Venue'),

                    const SizedBox(height: 12),

                    // Start date row
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Start Date',
                      value: _formatDate(event.date),
                    ),

                    const SizedBox(height: 8),

                    // End date row
                    _buildInfoRow(
                      icon: Icons.calendar_month,
                      label: 'End Date',
                      value: _formatDate(event.endDate),
                    ),

                    const SizedBox(height: 8),

                    // Duration row
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Duration',
                      // Show hours with one decimal place e.g. "2.5 hours"
                      value: '${event.durationHours} hours',
                    ),

                    const SizedBox(height: 8),

                    // Venue row
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Venue',
                      value: event.venue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // =============================================
              // CARD 3 — Attendance
              // Shows registrations, attendees, percentage
              // =============================================
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildSectionLabel('Attendance'),

                    const SizedBox(height: 12),

                    // Total registrations
                    _buildInfoRow(
                      icon: Icons.people,
                      label: 'Registered',
                      value: event.totalRegistrations.toString(),
                    ),

                    const SizedBox(height: 8),

                    // Total attendees
                    _buildInfoRow(
                      icon: Icons.how_to_reg,
                      label: 'Attended',
                      value: event.totalAttendees.toString(),
                    ),

                    const SizedBox(height: 8),

                    // Attendance percentage
                    _buildInfoRow(
                      icon: Icons.percent,
                      label: 'Attendance Rate',
                      // Show percentage like "81.6% attended"
                      value: '$attendancePercent% attended',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // =============================================
              // CARD 4 — Finance Status
              // Shows if budget is closed and a button to view finance
              // =============================================
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildSectionLabel('Finance Status'),

                    const SizedBox(height: 12),

                    // Budget closed status row
                    Row(
                      children: [
                        // Show green tick if closed, orange clock if not
                        Icon(
                          event.budgetClosed
                              ? Icons.check_circle
                              : Icons.access_time,
                          color: event.budgetClosed
                              ? Colors.green
                              : Colors.orange,
                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        // Show "Closed" or "Pending" text
                        Text(
                          event.budgetClosed
                              ? 'Budget Closed'
                              : 'Budget Pending',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: event.budgetClosed
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    // If budget was closed, show when it was closed
                    if (event.budgetClosed && event.budgetClosedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Closed on ${_formatDate(event.budgetClosedAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Button to go to Finance Detail screen
                    SizedBox(
                      // Make button full width
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text('View Finance Details'),
                        onPressed: () {
                          // Navigate to finance detail screen
                          Get.toNamed('/finance-detail');
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Some space at the bottom so content isn't too close to the edge
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  // -------------------------------------------------------
  // HELPER WIDGET: Card wrapper
  // Wraps any content in a styled card with shadow and rounded corners
  // -------------------------------------------------------
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity, // Full width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Subtle shadow to make the card look elevated
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // -------------------------------------------------------
  // HELPER WIDGET: Section Label
  // Shows a small grey label at the top of each card section
  // -------------------------------------------------------
  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(), // Convert to uppercase for a heading style
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 1.2, // Slight spacing between letters looks clean
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER WIDGET: Info Row
  // Shows one row with an icon, a label, and a value
  // Used for date, venue, attendance etc.
  // -------------------------------------------------------
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon on the left
        Icon(icon, size: 16, color: Colors.grey),

        const SizedBox(width: 8),

        // Label in grey
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),

        // Value in darker text, Expanded so it wraps if too long
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // HELPER WIDGET: Type Badge
  // Same colored pill badge as in the list screen
  // -------------------------------------------------------
  Widget _buildTypeBadge(String type) {
    // Pick color based on event type
    Color color;
    switch (type) {
      case 'workshop':
        color = Colors.blue;
        break;
      case 'hackathon':
        color = Colors.purple;
        break;
      case 'cultural':
        color = Colors.orange;
        break;
      case 'seminar':
        color = Colors.teal;
        break;
      case 'sports':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        // Capitalize first letter
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER FUNCTION: Format Date
  // Converts DateTime to a readable string like "15 Jan 2025"
  // -------------------------------------------------------
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}