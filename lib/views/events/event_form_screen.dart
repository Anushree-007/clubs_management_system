// This screen handles BOTH adding a new event AND editing an existing one
// If controller.selectedEvent is null — it is ADD mode
// If controller.selectedEvent has a value — it is EDIT mode
// One screen, two purposes!

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import controllers
import 'package:club_management_app/controllers/event_controller.dart';
import 'package:club_management_app/controllers/club_controller.dart';

// Import EventModel so we can create a new one when saving
import 'package:club_management_app/models/event_model.dart';

class EventFormScreen extends GetView<EventController> {
  const EventFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get ClubController to access current club and tenure IDs
    final clubController = Get.find<ClubController>();

    // Check if we are in edit mode or add mode
    // If selectedEvent is not null, we are editing an existing event
    final isEditMode = controller.selectedEvent.value != null;

    // Get the existing event data if we are in edit mode
    // This is used to pre-fill the form fields
    final existingEvent = controller.selectedEvent.value;

    // GlobalKey is used to validate the form before saving
    // Think of it as a unique ID for this form
    final formKey = GlobalKey<FormState>();

    // TextEditingControllers hold the text typed in each field
    // If editing, we pre-fill them with existing values using TextEditingController(text: '...')
    final nameController = TextEditingController(
      text: isEditMode ? existingEvent!.name : '',
    );
    final descriptionController = TextEditingController(
      text: isEditMode ? existingEvent!.description : '',
    );
    final durationController = TextEditingController(
      text: isEditMode ? existingEvent!.durationHours.toString() : '',
    );
    final venueController = TextEditingController(
      text: isEditMode ? existingEvent!.venue : '',
    );
    final registrationsController = TextEditingController(
      text: isEditMode ? existingEvent!.totalRegistrations.toString() : '',
    );
    final attendeesController = TextEditingController(
      text: isEditMode ? existingEvent!.totalAttendees.toString() : '',
    );

    // These Rx variables hold the dropdown and date picker values
    // Rx means they are reactive — the UI updates when they change
    // Pre-fill with existing values if editing
    final selectedType = (isEditMode ? existingEvent!.type : 'workshop').obs;
    final selectedDate = Rx<DateTime?>(
      isEditMode ? existingEvent!.date : null,
    );
    final selectedEndDate = Rx<DateTime?>(
      isEditMode ? existingEvent!.endDate : null,
    );

    return Scaffold(
      appBar: AppBar(
        // Title changes based on mode
        title: Text(isEditMode ? 'Edit Event' : 'Add New Event'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        // Form widget wraps all fields — needed for validation to work
        child: Form(
          key: formKey, // Attach the GlobalKey to this form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---- EVENT NAME ----
              const Text('Event Name',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration('e.g. National Coding Hackathon'),
                // validator runs when we call formKey.currentState!.validate()
                // If it returns a string, that string is shown as an error below the field
                // If it returns null, the field is valid
                validator: (value) =>
                    value == null || value.isEmpty ? 'Event name is required' : null,
              ),

              const SizedBox(height: 16),

              // ---- DESCRIPTION ----
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: descriptionController,
                decoration: _inputDecoration('Brief description of the event'),
                // maxLines allows the field to expand to 3 lines
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Description is required' : null,
              ),

              const SizedBox(height: 16),

              // ---- EVENT TYPE DROPDOWN ----
              const Text('Event Type',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              // Obx watches selectedType and rebuilds when it changes
              Obx(() => DropdownButtonFormField<String>(
                    value: selectedType.value,
                    decoration: _inputDecoration('Select event type'),
                    // List of options in the dropdown
                    items: ['workshop', 'hackathon', 'cultural', 'seminar', 'sports', 'other']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              // Capitalize the first letter for display
                              child: Text(
                                  type[0].toUpperCase() + type.substring(1)),
                            ))
                        .toList(),
                    // When user picks an option, update selectedType
                    onChanged: (value) {
                      if (value != null) selectedType.value = value;
                    },
                    validator: (value) =>
                        value == null ? 'Please select event type' : null,
                  )),

              const SizedBox(height: 16),

              // ---- START DATE PICKER ----
              const Text('Start Date',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              // Obx watches selectedDate and rebuilds when it changes
              Obx(() => GestureDetector(
                    // When tapped, open the date picker dialog
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        // Default shown date is today
                        initialDate: selectedDate.value ?? DateTime.now(),
                        // Earliest selectable date
                        firstDate: DateTime(2020),
                        // Latest selectable date
                        lastDate: DateTime(2030),
                      );
                      // If user picked a date (didn't cancel), save it
                      if (picked != null) selectedDate.value = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          // Show selected date or placeholder text
                          Text(
                            selectedDate.value != null
                                ? _formatDate(selectedDate.value!)
                                : 'Tap to select start date',
                            style: TextStyle(
                              color: selectedDate.value != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 16),

              // ---- END DATE PICKER ----
              const Text('End Date',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Obx(() => GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedEndDate.value ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) selectedEndDate.value = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            selectedEndDate.value != null
                                ? _formatDate(selectedEndDate.value!)
                                : 'Tap to select end date',
                            style: TextStyle(
                              color: selectedEndDate.value != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 16),

              // ---- DURATION ----
              const Text('Duration (hours)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: durationController,
                decoration: _inputDecoration('e.g. 2.5'),
                // keyboardType shows a number keyboard with decimal
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Duration is required' : null,
              ),

              const SizedBox(height: 16),

              // ---- VENUE ----
              const Text('Venue',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: venueController,
                decoration: _inputDecoration('e.g. Seminar Hall A'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Venue is required' : null,
              ),

              const SizedBox(height: 16),

              // ---- TOTAL REGISTRATIONS ----
              const Text('Total Registrations',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: registrationsController,
                decoration: _inputDecoration('e.g. 120'),
                // Show number keyboard (no decimal needed)
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Registrations count is required' : null,
              ),

              const SizedBox(height: 16),

              // ---- TOTAL ATTENDEES ----
              const Text('Total Attendees',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: attendeesController,
                decoration: _inputDecoration('e.g. 98'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Attendees count is required' : null,
              ),

              const SizedBox(height: 28),

              // ---- SAVE BUTTON ----
              SizedBox(
                width: double.infinity, // Full width button
                height: 50,
                child: Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null // Disable button while loading
                          : () => _saveEvent(
                                formKey: formKey,
                                isEditMode: isEditMode,
                                existingEvent: existingEvent,
                                clubController: clubController,
                                nameController: nameController,
                                descriptionController: descriptionController,
                                durationController: durationController,
                                venueController: venueController,
                                registrationsController: registrationsController,
                                attendeesController: attendeesController,
                                selectedType: selectedType,
                                selectedDate: selectedDate,
                                selectedEndDate: selectedEndDate,
                              ),
                      child: controller.isLoading.value
                          // Show spinner inside button while saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditMode ? 'Update Event' : 'Save Event',
                              style: const TextStyle(fontSize: 16),
                            ),
                    )),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // SAVE EVENT FUNCTION
  // This runs when the Save button is tapped
  // It validates, builds the model, and calls the controller
  // -------------------------------------------------------
  void _saveEvent({
    required GlobalKey<FormState> formKey,
    required bool isEditMode,
    required EventModel? existingEvent,
    required ClubController clubController,
    required TextEditingController nameController,
    required TextEditingController descriptionController,
    required TextEditingController durationController,
    required TextEditingController venueController,
    required TextEditingController registrationsController,
    required TextEditingController attendeesController,
    required RxString selectedType,
    required Rx<DateTime?> selectedDate,
    required Rx<DateTime?> selectedEndDate,
  }) {
    // First validate all form fields
    // If any field fails validation, stop here and show errors
    if (!formKey.currentState!.validate()) return;

    // Check that both dates were selected
    // We do this separately because dates use a custom picker, not a TextFormField
    if (selectedDate.value == null || selectedEndDate.value == null) {
      Get.snackbar(
        'Missing Dates',
        'Please select both start and end dates',
        snackPosition: SnackPosition.BOTTOM,
      );
      return; // Stop here if dates are missing
    }

    // Get the current club and tenure IDs from ClubController
    final clubId = clubController.selectedClub.value!.id;
    final tenureId = clubController.currentTenure.value!.id;

    if (isEditMode) {
      // EDIT MODE — build a Map of only the updated fields
      // We don't create a full new EventModel, just update what changed
      final updatedData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'type': selectedType.value,
        'date': selectedDate.value,
        'endDate': selectedEndDate.value,
        // double.parse converts the text string to a decimal number
        'durationHours': double.parse(durationController.text.trim()),
        'venue': venueController.text.trim(),
        // int.parse converts the text string to a whole number
        'totalRegistrations': int.parse(registrationsController.text.trim()),
        'totalAttendees': int.parse(attendeesController.text.trim()),
      };

      // Call the controller to update the event in Firestore
      controller.updateEvent(existingEvent!.id, updatedData, clubId, tenureId);

    } else {
      // ADD MODE — build a complete new EventModel object
      final newEvent = EventModel(
        id: '', // Empty string — Firestore will generate the real ID automatically
        clubId: clubId,
        tenureId: tenureId,
        name: nameController.text.trim(), // .trim() removes any extra spaces
        description: descriptionController.text.trim(),
        date: selectedDate.value!,
        endDate: selectedEndDate.value!,
        durationHours: double.parse(durationController.text.trim()),
        venue: venueController.text.trim(),
        type: selectedType.value,
        totalRegistrations: int.parse(registrationsController.text.trim()),
        totalAttendees: int.parse(attendeesController.text.trim()),
        budgetClosed: false, // New events always start with budget not closed
        budgetClosedAt: null, // No close date yet
        createdAt: DateTime.now(), // Current time as creation timestamp
      );

      // Call the controller to add the new event to Firestore
      controller.addEvent(newEvent);
    }
  }

  // -------------------------------------------------------
  // HELPER: Input Decoration
  // Gives all text fields the same consistent style
  // -------------------------------------------------------
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, // Placeholder text shown when field is empty
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        // Blue border when the field is active/focused
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Format Date
  // Converts DateTime to readable string like "15 Jan 2025"
  // -------------------------------------------------------
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}