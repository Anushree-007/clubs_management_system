// Import Flutter material widgets so we can build the UI
import 'package:flutter/material.dart';

// Import GetX so we can use GetView, Get.find, Obx, and navigation
import 'package:get/get.dart';

// Import the ClubController so this screen can access club state and actions
import 'package:club_management_app/controllers/club_controller.dart';

// Import the AuthController so we can check the user's role for edit permission
import 'package:club_management_app/controllers/auth_controller.dart';

// This is the ClubProfileScreen widget class
// It extends GetView<ClubController> which gives easy access to the registered controller
class ClubProfileScreen extends GetView<ClubController> {
  const ClubProfileScreen({super.key});

  // This helper method converts a DateTime object into a readable string
  // Example output: "2024-05-10"
  String _formatDate(DateTime date) {
    // Use the year, month, and day from the DateTime object
    // Convert each item to a string and pad month/day with a leading zero if needed
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // This builds the UI for the club profile screen
  @override
  Widget build(BuildContext context) {
    // Find the AuthController instance using GetX to check the user's role
    final AuthController authController = Get.find<AuthController>();

    // Scaffold is the top-level widget for a basic screen structure
    return Scaffold(
      // The app bar shows the club shortCode as the title and a back button automatically
      appBar: AppBar(
        // The title is reactive because selectedClub can change
        title: Obx(
          () => Text(
            controller.selectedClub.value?.shortCode ?? 'Club',
          ),
        ),
      ),
      // Floating action button is shown only for chairperson users
      floatingActionButton: Obx(
        () {
          // Show the edit FAB only when the current user actually has
          // write permission for THIS specific club.
          // Teachers → yes for all clubs.
          // Chairpersons → only for their own club (canManageClub checks both).
          final clubId = controller.selectedClub.value?.id ?? '';
          return authController.canManageClub(clubId)
              ? FloatingActionButton(
                  onPressed: () => Get.toNamed('/club-edit'),
                  child: const Icon(Icons.edit),
                )
              : const SizedBox.shrink();
        },
      ),
      // The body is wrapped in Obx so it updates when controller state changes
      body: Obx(
        () {
          // If there is no selected club yet, show a loading spinner
          if (controller.selectedClub.value == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Retrieve the selected club from the controller
          final club = controller.selectedClub.value!;
          final tenure = controller.currentTenure.value;

          // Display the club profile details inside a scroll view
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show the club's full name in large text
                Text(
                  club.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Show a status badge for active/inactive status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: club.status == 'active'
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    club.status == 'active' ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Info card with club details like domain, description, and faculty info
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Club Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Domain / Category', club.domain),
                        const SizedBox(height: 8),
                        _infoRow('Description', club.description),
                        const SizedBox(height: 8),
                        _infoRow('Faculty In Charge', club.facultyName),
                        const SizedBox(height: 8),
                        _infoRow('Faculty Email', club.facultyEmail),
                        const SizedBox(height: 8),
                        _infoRow('Faculty Phone', club.facultyPhone),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Tenure card showing start, end, and hierarchy information
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Tenure',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start Date: ${_formatDate(tenure?.startDate ?? DateTime.now())}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'End Date: ${tenure?.endDate != null ? _formatDate(tenure!.endDate!) : 'Present'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hierarchy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Show a message if no hierarchy data is available
                        if (tenure == null || tenure.hierarchy.isEmpty)
                          const Text(
                            'No hierarchy data available.',
                            style: TextStyle(fontSize: 16),
                          )
                        else
                          // Build a list of hierarchy entries from the tenure data
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: tenure.hierarchy
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      '${entry['position']}: ${entry['memberName']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                      
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Row of navigation buttons for related club sections
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the member list screen when this button is tapped
                          Get.toNamed('/members');
                        },
                        child: const Text('Members'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.toNamed('/events');
                        },
                        child: const Text('Events'),
                      ),
                    ),
                    const SizedBox(width: 12),

                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Report button on club profile screen
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generate Report'),
                      onPressed: () => Get.toNamed('/reports'),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.toNamed('/club-documents');
                        },
                        child: const Text('Documents'),
                      ),
                    ),
                  ]
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // This helper widget builds a single row of label and value text
  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label text on the left side, bold so it is easy to read
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Value text on the right side shows the detail
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}