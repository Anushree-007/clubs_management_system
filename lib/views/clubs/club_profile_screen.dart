// Import Flutter material widgets so we can build the UI
import 'package:flutter/material.dart';

// Import GetX so we can use GetView, Get.find, Obx, and navigation
import 'package:get/get.dart';

// Import the ClubController so this screen can access club state and actions
import 'package:club_management_app/controllers/club_controller.dart';

// Import the AuthController so we can check the user's role for edit permission
import 'package:club_management_app/controllers/auth_controller.dart';

class ClubProfileScreen extends GetView<ClubController> {
  const ClubProfileScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.selectedClub.value?.shortCode ?? 'Club',
          ),
        ),
      ),

      floatingActionButton: Obx(() {
        final clubId = controller.selectedClub.value?.id ?? '';
        return authController.canManageClub(clubId)
            ? FloatingActionButton(
                onPressed: () => Get.toNamed('/club-edit'),
                child: const Icon(Icons.edit),
              )
            : const SizedBox.shrink();
      }),

      body: Obx(() {
        if (controller.selectedClub.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final club = controller.selectedClub.value!;
        final tenure = controller.currentTenure.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                club.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                      if (tenure == null || tenure.hierarchy.isEmpty)
                        const Text(
                          'No hierarchy data available.',
                          style: TextStyle(fontSize: 16),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: tenure.hierarchy.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '${entry['position']}: ${entry['memberName']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed('/members'),
                      child: const Text('Members'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed('/events'),
                      child: const Text('Events'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generate Report'),
                      onPressed: () => Get.toNamed('/reports'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expanded(
                  //   child: ElevatedButton(
                  //     onPressed: () => Get.toNamed('/club-documents'),
                  //     child: const Text('Documents'),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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