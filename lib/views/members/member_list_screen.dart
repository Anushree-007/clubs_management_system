import 'package:flutter/material.dart'; // import the Flutter Material widgets
import 'package:get/get.dart'; // import GetX for state management and navigation

import 'package:club_management_app/controllers/auth_controller.dart'; // import AuthController to check user role
import 'package:club_management_app/controllers/club_controller.dart'; // import ClubController to read club data
import 'package:club_management_app/controllers/member_controller.dart'; // import MemberController for member state

// This screen shows the list of members for the selected club and tenure
class MemberListScreen extends GetView<MemberController> {
  // ignore: prefer_const_constructors_in_immutables
  MemberListScreen({super.key});

  // Track whether member data has already been loaded
  final RxBool _hasInitialized = false.obs; // reactive bool set to false initially

  @override
  Widget build(BuildContext context) {
    // Find the club controller so we can read the selected club details
    final ClubController clubController = Get.find<ClubController>();

    // Find the auth controller so we can check if the user is a chairperson
    final AuthController authController = Get.find<AuthController>();

    // Read the club ID from the selected club, or empty string if none
    final String clubId = clubController.selectedClub.value?.id ?? '';

    // Read the tenure ID from the selected club, or empty string if none
    final String tenureId = clubController.selectedClub.value?.currentTenureId ?? '';

    // After the first frame, fetch members once if we have valid club and tenure IDs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized.value && clubId.isNotEmpty && tenureId.isNotEmpty) {
        controller.fetchMembers(clubId, tenureId); // load member list
        _hasInitialized.value = true; // remember that we already fetched once
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // align title text to the left
          children: [
            const Text('Members'), // main title text
            Text(
              clubController.selectedClub.value?.shortCode ?? 'Club', // club short code or fallback
              style: const TextStyle(fontSize: 14, color: Colors.white70), // subtitle style
            ),
          ],
        ),
      ),
      body: Obx(
        () {
          // If the controller is still loading, show a spinner
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // If there are no members, show an empty state message
          if (controller.members.isEmpty) {
            return const Center(
              child: Text('No members added yet'),
            );
          }

          // Otherwise, show the member count and the member cards
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start, // align children to left
            children: [
              Padding(
                padding: const EdgeInsets.all(16), // spacing around the count text
                child: Text(
                  '${controller.members.length} Members this tenure', // count message
                  style: const TextStyle(
                    fontSize: 16, // text size
                    fontWeight: FontWeight.bold, // bold text
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // list padding
                  itemCount: controller.members.length, // number of items to build
                  itemBuilder: (context, index) {
                    final member = controller.members[index]; // get the member at this index

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12), // card spacing
                      child: Padding(
                        padding: const EdgeInsets.all(16), // card padding
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // align top
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // align text to left
                                children: [
                                  Text(
                                    member.name, // member name text
                                    style: const TextStyle(
                                      fontSize: 16, // name text size
                                      fontWeight: FontWeight.bold, // bold name
                                    ),
                                  ),
                                  const SizedBox(height: 8), // spacing after name
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10, // horizontal badge padding
                                      vertical: 4, // vertical badge padding
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50, // badge background color
                                      borderRadius: BorderRadius.circular(12), // rounded corners
                                    ),
                                    child: Text(
                                      member.position, // position badge text
                                      style: TextStyle(
                                        fontSize: 12, // badge text size
                                        color: Colors.blue.shade800, // badge text color
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8), // spacing after badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10, // horizontal badge padding
                                      vertical: 4, // vertical badge padding
                                    ),
                                    decoration: BoxDecoration(
                                      color: member.isActive ? Colors.green.shade50 : Colors.red.shade50, // badge background color based on active status
                                      borderRadius: BorderRadius.circular(12), // rounded corners
                                    ),
                                    child: Text(
                                      member.isActive ? 'Active' : 'Inactive', // status badge text
                                      style: TextStyle(
                                        fontSize: 12, // badge text size
                                        color: member.isActive ? Colors.green.shade800 : Colors.red.shade800, // badge text color based on active status
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${member.department} • Year ${member.year}', // department and year text
                                    style: const TextStyle(fontSize: 14), // text style
                                  ),
                                  const SizedBox(height: 8), // spacing after department/year
                                  Text(
                                    'PRN: ${member.prn}', // PRN number text
                                    style: const TextStyle(fontSize: 14), // text style
                                  ),
                                  const SizedBox(height: 8), // spacing after PRN
                                  Text(
                                    member.phone, // phone text
                                    style: const TextStyle(
                                      fontSize: 13, // smaller text size
                                      // color: Colors.black54, // muted text color
                                    ),
                                  ),
                                  const SizedBox(height: 4), // small spacing between phone and email
                                  Text(
                                    member.email, // email text
                                    style: const TextStyle(
                                      fontSize: 13, // smaller text size
                                      // color: Colors.black54, // muted text color
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Show edit and delete buttons only for chairperson
                            if (authController.isChairperson)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  // Edit button — opens the member form in edit mode
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => controller.selectMember(member),
                                  ),

                                  // Delete button — removes the member after confirmation
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      // Show a confirmation dialog before deleting
                                      // This prevents accidental deletions
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Member?'),
                                          content: Text(
                                            'Are you sure you want to remove ${member.name} from this club?',
                                          ),
                                          actions: [

                                            // Cancel button — closes dialog without doing anything
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),

                                            // Confirm delete button
                                            TextButton(
                                              onPressed: () {
                                                // Close the dialog first
                                                Navigator.pop(ctx);

                                                // Get the club ID from ClubController
                                                final clubId = Get.find<ClubController>()
                                                    .selectedClub
                                                    .value
                                                    ?.id ?? '';

                                                // Call the delete method in the controller
                                                controller.deleteMember(clubId, member.id);
                                              },
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Obx(
        () {
          // Only show the FAB if the current user is a chairperson
          if (!authController.isChairperson) {
            return const SizedBox.shrink(); // show nothing if user cannot add members
          }

          return FloatingActionButton(
            onPressed: controller.goToAddMember, // navigate to add member form
            child: const Icon(Icons.add), // plus icon for adding a member
          );
        },
      ),
    );
  }
}