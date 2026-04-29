// Import Flutter material widgets so we can build the UI
import 'package:flutter/material.dart';

// Import GetX so we can use GetView, Obx, and Get utilities
import 'package:get/get.dart';

// Import the ClubController so this screen can access club state and actions
import 'package:club_management_app/controllers/club_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

// This widget displays a form for editing the selected club information
class ClubEditScreen extends GetView<ClubController> {
  // Create a GlobalKey for the form so we can validate it later
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // These controllers hold the current text values for each text field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _facultyNameController = TextEditingController();
  final TextEditingController _facultyEmailController = TextEditingController();
  final TextEditingController _facultyPhoneController = TextEditingController();

  // The selected domain and status values are stored in reactive variables
  final RxString _selectedDomain = ''.obs;
  final RxString _selectedStatus = ''.obs;

  // This method fills the form fields with the current selected club values
  void _populateFields() {
    // If there is no selected club, skip the fill step
    if (controller.selectedClub.value == null) return;

    final club = controller.selectedClub.value!;

    // Set each text controller to the current club value
    _nameController.text = club.name;
    _shortCodeController.text = club.shortCode;
    _descriptionController.text = club.description;
    _facultyNameController.text = club.facultyName;
    _facultyEmailController.text = club.facultyEmail;
    _facultyPhoneController.text = club.facultyPhone;

    // Set the dropdown values to the current domain and status
    _selectedDomain.value = club.domain;
    _selectedStatus.value = club.status;
  }

  // Build the user interface for the screen
  @override
  Widget build(BuildContext context) {
    // Populate fields whenever the screen builds to ensure current data is shown
    _populateFields();

    // ── Ownership guard ──────────────────────────────────────────────────
    // Verify the current user is allowed to edit this club.
    // This catches anyone who navigates directly to /club-edit without going
    // through the normal FAB (which already hides itself for unauthorised users).
    final authController = Get.find<AuthController>();
    final clubId = controller.selectedClub.value?.id ?? '';
    if (clubId.isNotEmpty && !authController.canManageClub(clubId)) {
      // Schedule the navigation away for after this build frame completes.
      // Calling Get.back() synchronously inside build() would cause a
      // "setState() or markNeedsBuild() called during build" error.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar(
          'Access Denied',
          'You can only edit your own club.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
      // Return an empty scaffold for this frame while navigation completes
      return const Scaffold(body: SizedBox.shrink());
    }
    // ─────────────────────────────────────────────────────────────────────

    return Scaffold(
      // AppBar shows the title at the top of the screen
      appBar: AppBar(
        title: const Text('Edit Club Info'),
      ),
      // Body contains the editable form fields
      body: Obx(
        () {
          // If no club is selected yet, show a loading spinner
          if (controller.selectedClub.value == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Build the form when a club is available
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              // Attach the key to the Form widget
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Club Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Club Name',
                      border: OutlineInputBorder(),
                    ),
                    // All fields are required, so we validate non-empty text
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Club Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Short Code field
                  TextFormField(
                    controller: _shortCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Short Code',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Short Code is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Domain dropdown field
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: _selectedDomain.value.isEmpty
                          ? null
                          : _selectedDomain.value,
                      decoration: const InputDecoration(
                        labelText: 'Domain',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'technical',
                          child: Text('technical'),
                        ),
                        DropdownMenuItem(
                          value: 'cultural',
                          child: Text('cultural'),
                        ),
                        DropdownMenuItem(
                          value: 'social',
                          child: Text('social'),
                        ),
                        DropdownMenuItem(
                          value: 'sports',
                          child: Text('sports'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _selectedDomain.value = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Domain is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Faculty Name field
                  TextFormField(
                    controller: _facultyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Faculty Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Faculty Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Faculty Email field
                  TextFormField(
                    controller: _facultyEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Faculty Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Faculty Email is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Faculty Phone field
                  TextFormField(
                    controller: _facultyPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Faculty Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Faculty Phone is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Status dropdown field
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: _selectedStatus.value.isEmpty
                          ? null
                          : _selectedStatus.value,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('active'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _selectedStatus.value = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Status is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Save button at the bottom of the form
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              // Validate the form fields before saving
                              if (_formKey.currentState?.validate() ?? false) {
                                // Build the update data map from all fields
                                final updatedData = {
                                  'name': _nameController.text.trim(),
                                  'shortCode': _shortCodeController.text.trim(),
                                  'domain': _selectedDomain.value.trim(),
                                  'description': _descriptionController.text.trim(),
                                  'facultyName': _facultyNameController.text.trim(),
                                  'facultyEmail': _facultyEmailController.text.trim(),
                                  'facultyPhone': _facultyPhoneController.text.trim(),
                                  'status': _selectedStatus.value.trim(),
                                };

                                // Call the controller updateClub method to save the data
                                await controller.updateClub(
                                  controller.selectedClub.value!.id,
                                  updatedData,
                                );
                              }
                            },
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14.0),
                              child: Text('Save'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}