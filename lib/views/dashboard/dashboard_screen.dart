// Import Flutter material widgets so we can build the UI
import 'package:flutter/material.dart';

// Import GetX so we can use GetView, Get.find, Obx, and routing
import 'package:get/get.dart';

// Import the AuthController so we can access current user and logout
import 'package:club_management_app/controllers/auth_controller.dart';

// Import the ClubController so this screen can use club data and actions
import 'package:club_management_app/controllers/club_controller.dart';

// This is the DashboardScreen widget class
// It extends GetView<ClubController> which means it can access a ClubController instance
class DashboardScreen extends GetView<ClubController> {
  const DashboardScreen({super.key});

  // This builds the UI for the Dashboard screen
  @override
  Widget build(BuildContext context) {
    // Find the AuthController instance using GetX so we can access the current user
    final AuthController authController = Get.find<AuthController>();

    // The Scaffold widget provides the basic visual layout structure for the screen
    return Scaffold(
      // AppBar displays a top bar with a title and a logout button
      appBar: AppBar(
        // Title of the top app bar
        title: const Text('Club Manager'),
        // Add a logout icon on the right side of the app bar
        actions: [
          IconButton(
            // The logout icon button uses the exit_to_app icon
            icon: const Icon(Icons.logout),
            // When pressed, call the logout method on the AuthController
            onPressed: () {
              authController.logout();
            },
          ),
        ],
      ),
      // Body of the screen contains the dashboard content
      body: Padding(
        // Add padding around the content so it does not touch the screen edges
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // Align children to the start (left side)
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show a welcome message using the current user's name
            Obx(
              () => Text(
                // Use the currentUser from AuthController to show the name
                'Welcome, ${authController.currentUser.value?.name ?? 'Guest'}',
                // Styling for the welcome text
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // The dropdown to select a club from the list
            Obx(
              () => DropdownButtonFormField<String>(
                // The current selected club ID from the controller
                value: controller.selectedClubId.value.isEmpty
                    ? null
                    : controller.selectedClubId.value,
                // The hint shown when no club is selected
                hint: const Text('Select a club'),
                // Build the dropdown menu items from the list of clubs
                items: controller.clubs
                    .map(
                      (club) => DropdownMenuItem<String>(
                        // Use the club ID as the dropdown value
                        value: club.id,
                        // Show the club's full name in the dropdown
                        child: Text(club.name),
                      ),
                    )
                    .toList(),
                // When the user selects a new club, call controller.selectClub()
                onChanged: (String? clubId) {
                  if (clubId != null) {
                    controller.selectClub(clubId);
                  }
                },
                // Add a border and padding around the dropdown field
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Show a loading indicator when the controller is loading data
            Obx(
              () => controller.isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row to display the three stat cards
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Total Clubs card
                            _buildStatCard(
                              label: 'Total Clubs',
                              value: controller.clubs.length.toString(),
                            ),
                            // Active clubs card
                            _buildStatCard(
                              label: 'Active',
                              value: controller.clubs
                                  .where((club) => club.status == 'active')
                                  .length
                                  .toString(),
                            ),
                            // Inactive clubs card
                            _buildStatCard(
                              label: 'Inactive',
                              value: controller.clubs
                                  .where((club) => club.status == 'inactive')
                                  .length
                                  .toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // This helper method builds a simple stat card widget with a value and label
  Widget _buildStatCard({required String label, required String value}) {
    return Expanded(
      child: Card(
        // Add a small elevation to make the card stand out from the background
        elevation: 2,
        child: Padding(
          // Add padding inside the card so the text has breathing room
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Center the number and label inside the card
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the numeric value in large text
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Display the label below the number
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
