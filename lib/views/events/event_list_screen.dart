// This is the screen that shows all events for a selected club
// It displays event cards in a list with key info on each card

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import controllers we need
import 'package:club_management_app/controllers/event_controller.dart';
import 'package:club_management_app/controllers/club_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

// EventListScreen extends GetView<EventController>
// This automatically gives us access to EventController via "controller"
class EventListScreen extends GetView<EventController> {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the ClubController so we can read the currently selected club
    final clubController = Get.find<ClubController>();

    // Get the AuthController so we can check if user is chairperson
    final authController = Get.find<AuthController>();

    // Fetch events when the screen first builds
    // We use addPostFrameCallback so it runs AFTER the screen finishes drawing
    // This avoids errors from calling setState during build
    // Fetch events when the screen first builds
    // addPostFrameCallback runs AFTER the screen finishes drawing
    WidgetsBinding.instance.addPostFrameCallback((_) {

      // Get the selected club safely
      final club = clubController.selectedClub.value;

      // Get the current tenure safely  
      final tenure = clubController.currentTenure.value;

      // Only fetch if BOTH club AND tenure are not null
      // This prevents the null crash
      if (club != null && tenure != null) {
        controller.fetchEvents(club.id, tenure.id);
      } else {
        // If tenure is null, show a message instead of crashing
        Get.snackbar(
          'Notice',
          'Could not load events. Please go back and select the club again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });

    return Scaffold(
      // AppBar at the top of the screen
      appBar: AppBar(
        // Show the club short code as the title
        title: Obx(() => Text(
              clubController.selectedClub.value?.shortCode ?? 'Events',
            )),
        // Show "Events" as a smaller subtitle below the title
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Event History',
              // Use a lighter color for the subtitle
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),

      // The main body of the screen
      // Obx rebuilds this widget automatically when controller values change
      body: Obx(() {
        // If data is loading, show a spinner in the center
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [

            // ---- STAT CARDS ROW ----
            // Two small cards showing total and past event counts
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Total Events card
                  _buildStatCard(
                    label: 'Total Events',
                    value: controller.totalEvents.toString(),
                    color: Colors.blue,
                  ),

                  const SizedBox(width: 12), // Space between cards

                  // Past Events card
                  _buildStatCard(
                    label: 'Past Events',
                    value: controller.pastEvents.length.toString(),
                    color: Colors.orange,
                  ),

                  const SizedBox(width: 12),

                  // Upcoming Events card
                  _buildStatCard(
                    label: 'Upcoming',
                    value: controller.upcomingEvents.length.toString(),
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            // ---- EVENT LIST ----
            // Expanded makes the list take up all remaining screen space
            Expanded(
              child: controller.events.isEmpty
                  // Show this if there are no events yet
                  ? const Center(
                      child: Text(
                        'No events yet for this tenure',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  // Show the list of event cards
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      // How many items in the list
                      itemCount: controller.events.length,
                      // Build each item one by one
                      itemBuilder: (context, index) {
                        // Get the event at this position
                        final event = controller.events[index];

                        // Each event is shown as a tappable card
                        return GestureDetector(
                          // When tapped, select this event and go to detail screen
                          onTap: () => controller.selectEvent(event),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            // Slight elevation gives a shadow effect
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // ---- TOP ROW: Name + Type Badge ----
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Event name in bold
                                      Expanded(
                                        child: Text(
                                          event.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      // Colored badge showing event type
                                      _buildTypeBadge(event.type),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // ---- DATE AND VENUE ----
                                  Row(
                                    children: [
                                      // Calendar icon
                                      const Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      // Formatted date like "15 Jan 2025"
                                      Text(
                                        _formatDate(event.date),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      const SizedBox(width: 16),
                                      // Location pin icon
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      // Venue name
                                      Expanded(
                                        child: Text(
                                          event.venue,
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 13),
                                          // If venue is too long, cut it off with ...
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // ---- ATTENDANCE ROW ----
                                  Row(
                                    children: [
                                      // Registered count
                                      const Icon(Icons.people,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Registered: ${event.totalRegistrations}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 16),
                                      // Attended count
                                      const Icon(Icons.check_circle,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Attended: ${event.totalAttendees}',
                                        style: const TextStyle(fontSize: 13),
                                      ),

                                      // Push the budget status icon to the right
                                      const Spacer(),

                                      // Budget closed = green tick, not closed = orange clock
                                      Icon(
                                        event.budgetClosed
                                            ? Icons.check_circle
                                            : Icons.access_time,
                                        size: 18,
                                        color: event.budgetClosed
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),

      // ---- FLOATING ACTION BUTTON ----
      // Only show the + button if the user is a chairperson
      floatingActionButton: authController.isChairperson
          ? FloatingActionButton(
              // When tapped, go to the Add Event form
              onPressed: controller.goToAddEvent,
              child: const Icon(Icons.add),
            )
          : null, // null means no button shown for teachers
    );
  }

  // -------------------------------------------------------
  // HELPER WIDGET: Stat Card
  // Builds one small colored card showing a number and label
  // -------------------------------------------------------
  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // Light version of the passed color as background
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // The big number
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            // The label below the number
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER WIDGET: Type Badge
  // Shows a small colored pill with the event type text
  // Different event types get different colors
  // -------------------------------------------------------
  Widget _buildTypeBadge(String type) {
    // Pick a color based on the event type
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
        // For "other" or anything unexpected
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20), // Makes it a pill shape
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        // Capitalize first letter of the type
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER FUNCTION: Format Date
  // Converts a DateTime like 2025-01-15 into "15 Jan 2025"
  // -------------------------------------------------------
  String _formatDate(DateTime date) {
    // List of month names so we can convert month number to name
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    // Return formatted string like "15 Jan 2025"
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}