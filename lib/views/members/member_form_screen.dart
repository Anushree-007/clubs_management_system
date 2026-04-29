import 'package:flutter/material.dart'; // import Flutter widgets for UI building
import 'package:flutter/services.dart'; // import input formatters for numeric fields
import 'package:get/get.dart'; // import GetX for state management and routing

import 'package:club_management_app/controllers/club_controller.dart'; // import ClubController to read club and tenure IDs
import 'package:club_management_app/controllers/member_controller.dart'; // import MemberController for member actions
import 'package:club_management_app/models/member_model.dart'; // import MemberModel to build member objects

// This screen shows a form for adding or editing a club member
class MemberFormScreen extends GetView<MemberController> {

  // Form key to validate  form fields
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text controller for the full name field
  final TextEditingController _nameController = TextEditingController();

  // Text controller for the PRN field
  final TextEditingController _prnController = TextEditingController();

  // Text controller for the position field
  final TextEditingController _positionController = TextEditingController();

  // Text controller for the department field
  final TextEditingController _departmentController = TextEditingController();

  // Text controller for the phone field
  final TextEditingController _phoneController = TextEditingController();

  // Text controller for the email field
  final TextEditingController _emailController = TextEditingController();

  // Reactive integer for the year dropdown selection
  final RxInt _selectedYear = 1.obs;

  // Reactive boolean for whether the member is active
  final RxBool _isActive = true.obs;

  // Reactive flag to ensure we only initialize the form once
  final RxBool _hasInitialized = false.obs;

  @override
  Widget build(BuildContext context) {
    // Find the club controller so we can read the current club and tenure IDs
    final ClubController clubController = Get.find<ClubController>();

    // Read the current club ID from the selected club, or use an empty string if none
    final String clubId = clubController.selectedClub.value?.id ?? '';

    // Read the current tenure ID from the selected club, or use an empty string if none
    final String tenureId = clubController.selectedClub.value?.currentTenureId ?? '';

    // If we have not initialized the form fields yet, do it after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized.value) {
        _hasInitialized.value = true; // mark initialization as done

        final MemberModel? selected = controller.selectedMember.value; // current selected member

        if (selected != null) {
          // If editing, fill the form fields with the existing member values
          _nameController.text = selected.name;
          _prnController.text = selected.prn;
          _positionController.text = selected.position;
          _departmentController.text = selected.department;
          _phoneController.text = selected.phone;
          _emailController.text = selected.email;
          _selectedYear.value = selected.year;
          _isActive.value = selected.isActive;
        } else {
          // If adding, set default values for a new member
          _selectedYear.value = 1;
          _isActive.value = true;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.selectedMember.value == null
              ? 'Add New Member'
              : 'Edit Member', // choose title based on add or edit mode
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey, // assign the form key to this Form widget
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController, // bind controller to the full name field
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prnController, // bind controller to the PRN field
                decoration: const InputDecoration(labelText: 'PRN Number'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'PRN Number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _positionController, // bind controller to the position field
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Position is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<int>(
                  value: _selectedYear.value, // current selected year
                  decoration: const InputDecoration(labelText: 'Year of Study'),
                  items: [1, 2, 3, 4]
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text('Year $year'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _selectedYear.value = value; // update selected year
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Year of Study is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController, // bind controller to the department field
                decoration: const InputDecoration(labelText: 'Department'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Department is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController, // bind controller to the phone field
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone Number is required';
                  }
                  if (value.trim().length != 10) {
                    return 'Phone Number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController, // bind controller to the email field
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.trim().toLowerCase().endsWith('@vit.edu')) {
                    return 'Email must end with @vit.edu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Obx(
                () => SwitchListTile(
                  title: const Text('Active Status'),
                  subtitle: Text(
                    _isActive.value ? 'Active' : 'Inactive',
                  ),
                  value: _isActive.value,
                  onChanged: (value) {
                    _isActive.value = value; // update active status
                  },
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              // Build the member data from the form fields
                              final MemberModel member = MemberModel(
                                id: controller.selectedMember.value?.id ?? '',
                                clubId: clubId,
                                tenureId: tenureId,
                                name: _nameController.text.trim(),
                                prn: _prnController.text.trim(),
                                position: _positionController.text.trim(),
                                year: _selectedYear.value,
                                department: _departmentController.text.trim(),
                                phone: _phoneController.text.trim(),
                                email: _emailController.text.trim(),
                                isActive: _isActive.value,
                                createdAt: controller.selectedMember.value?.createdAt ?? DateTime.now(),
                              );

                              if (controller.selectedMember.value == null) {
                                await controller.addMember(clubId, member);
                              } else {
                                await controller.updateMember(
                                  clubId,
                                  member.id,
                                  {
                                    'name': member.name,
                                    'prn': member.prn,
                                    'position': member.position,
                                    'year': member.year,
                                    'department': member.department,
                                    'phone': member.phone,
                                    'email': member.email,
                                    'isActive': member.isActive,
                                  },
                                );
                              }

                            }
                          },
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            controller.selectedMember.value == null
                                ? 'Save'
                                : 'Update',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
