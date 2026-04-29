// This screen handles adding and editing finance details for an event
// It has 3 sections — Budget, Sponsors, and Tickets
// All in one scrollable form

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import controllers
import 'package:club_management_app/controllers/finance_controller.dart';
import 'package:club_management_app/controllers/event_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

// Import models
import 'package:club_management_app/models/finance_model.dart';
import 'package:club_management_app/models/sponsor_model.dart';
import 'package:club_management_app/models/ticket_model.dart';

class FinanceFormScreen extends GetView<FinanceController> {
  const FinanceFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the event controller to access current event
    final eventController = Get.find<EventController>();

    // Get auth controller to access current user info
    final authController = Get.find<AuthController>();

    // Get the current event ID safely
    final eventId = eventController.selectedEvent.value?.id ?? '';

    // Get the current club ID safely
    final clubId = eventController.selectedEvent.value?.clubId ?? '';

    // GlobalKey for the main budget form validation
    final budgetFormKey = GlobalKey<FormState>();

    // GlobalKey for the sponsor form validation
    final sponsorFormKey = GlobalKey<FormState>();

    // GlobalKey for the ticket form validation
    final ticketFormKey = GlobalKey<FormState>();

    // Check if finance data already exists
    // If yes we are in edit mode, if no we are in add mode
    final existingFinance = controller.finance.value;

    // -------------------------------------------------------
    // BUDGET SECTION TEXT CONTROLLERS
    // Pre-fill with existing values if editing
    // -------------------------------------------------------
    final budgetController = TextEditingController(
      text: existingFinance != null
          ? existingFinance.totalBudget.toStringAsFixed(0)
          : '',
    );
    final expensesController = TextEditingController(
      text: existingFinance != null
          ? existingFinance.totalExpenses.toStringAsFixed(0)
          : '',
    );
    final notesController = TextEditingController(
      text: existingFinance != null ? existingFinance.notes : '',
    );

    // -------------------------------------------------------
    // EXPENSE BREAKDOWN
    // This is a reactive list of breakdown items
    // Each item has category, amount, description
    // -------------------------------------------------------
    final breakdown = RxList<Map<String, dynamic>>(
      // Pre-fill with existing breakdown if editing
      existingFinance != null
          ? List<Map<String, dynamic>>.from(existingFinance.breakdown)
          : [],
    );

    // Controllers for the breakdown add form
    final breakdownCategoryController = TextEditingController();
    final breakdownAmountController = TextEditingController();
    final breakdownDescController = TextEditingController();

    // -------------------------------------------------------
    // SPONSOR SECTION TEXT CONTROLLERS
    // These are for adding a new sponsor
    // -------------------------------------------------------
    final sponsorNameController = TextEditingController();
    final sponsorAmountController = TextEditingController();
    final sponsorNotesController = TextEditingController();

    // -------------------------------------------------------
    // TICKET SECTION TEXT CONTROLLERS
    // Pre-fill with existing ticket data if it exists
    // -------------------------------------------------------
    final existingTicket = controller.ticket.value;

    final ticketPriceController = TextEditingController(
      text: existingTicket != null
          ? existingTicket.ticketPrice.toStringAsFixed(0)
          : '',
    );
    final ticketsSoldController = TextEditingController(
      text: existingTicket != null
          ? existingTicket.ticketsSold.toString()
          : '',
    );
    final ticketNoteController = TextEditingController(
      text: existingTicket != null ? existingTicket.manualNote : '',
    );

    // Reactive bool for VIERP verified toggle
    final vierpVerified = (existingTicket?.vierpVerified ?? false).obs;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          existingFinance != null ? 'Edit Finance' : 'Add Finance Details',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =============================================
            // SECTION 1 — BUDGET DETAILS
            // =============================================
            _buildSectionHeader(
              icon: Icons.account_balance_wallet,
              title: 'Budget Details',
              color: Colors.blue,
            ),

            const SizedBox(height: 12),

            // Budget form wrapped in a card
            Form(
              key: budgetFormKey,
              child: _buildCard(
                child: Column(
                  children: [

                    // Total Budget field
                    _buildLabel('Total Budget (₹)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: budgetController,
                      decoration: _inputDecoration('e.g. 50000'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Total budget is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Total Expenses field
                    _buildLabel('Total Expenses (₹)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: expensesController,
                      decoration: _inputDecoration('e.g. 43000'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Total expenses is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Expense Breakdown section
                    _buildLabel('Expense Breakdown (optional)'),
                    const SizedBox(height: 8),

                    // Show existing breakdown items
                    Obx(() => Column(
                          children: breakdown.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Category name
                                        Text(
                                          item['category'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        // Description if exists
                                        if (item['description'] != null &&
                                            item['description']
                                                .toString()
                                                .isNotEmpty)
                                          Text(
                                            item['description'],
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Amount
                                  Text(
                                    '₹${item['amount']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  // Remove button
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 18, color: Colors.red),
                                    // Remove this item from the breakdown list
                                    onPressed: () => breakdown.remove(item),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )),

                    // Small form to add a new breakdown item
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Breakdown Item',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue),
                          ),
                          const SizedBox(height: 8),

                          // Category field
                          TextFormField(
                            controller: breakdownCategoryController,
                            decoration:
                                _inputDecoration('Category e.g. Food'),
                          ),
                          const SizedBox(height: 8),

                          // Amount field
                          TextFormField(
                            controller: breakdownAmountController,
                            decoration: _inputDecoration('Amount e.g. 5000'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),

                          // Description field
                          TextFormField(
                            controller: breakdownDescController,
                            decoration:
                                _inputDecoration('Description (optional)'),
                          ),
                          const SizedBox(height: 8),

                          // Add Item button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                              onPressed: () {
                                // Only add if category and amount are filled
                                if (breakdownCategoryController
                                        .text.isNotEmpty &&
                                    breakdownAmountController
                                        .text.isNotEmpty) {
                                  // Add new item to the reactive breakdown list
                                  breakdown.add({
                                    'category': breakdownCategoryController
                                        .text
                                        .trim(),
                                    'amount': double.tryParse(
                                            breakdownAmountController.text
                                                .trim()) ??
                                        0,
                                    'description': breakdownDescController
                                        .text
                                        .trim(),
                                  });
                                  // Clear the input fields after adding
                                  breakdownCategoryController.clear();
                                  breakdownAmountController.clear();
                                  breakdownDescController.clear();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notes field
                    _buildLabel('Notes (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: notesController,
                      decoration:
                          _inputDecoration('Any extra finance notes...'),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),

                    // Save Budget button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Obx(() => ElevatedButton(
                            // Disable while loading
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    // Validate the budget form first
                                    if (!budgetFormKey.currentState!
                                        .validate()) return;

                                    // Calculate net balance
                                    final budget = double.tryParse(
                                            budgetController.text.trim()) ??
                                        0;
                                    final expenses = double.tryParse(
                                            expensesController.text
                                                .trim()) ??
                                        0;

                                    // Total sponsorship from sponsors list
                                    final totalSponsor = controller.sponsors
                                        .fold(
                                            0.0,
                                            (sum, s) =>
                                                sum + s.amount);

                                    // Build the FinanceModel to save
                                    final financeData = FinanceModel(
                                      id: existingFinance?.id ?? '',
                                      eventId: eventId,
                                      clubId: clubId,
                                      totalBudget: budget,
                                      totalExpenses: expenses,
                                      // Net balance = budget - expenses
                                      netBalance: budget - expenses,
                                      totalSponsorship: totalSponsor,
                                      notes: notesController.text.trim(),
                                      breakdown: breakdown.toList(),
                                    );

                                    // Call controller to save
                                    controller.saveFinance(
                                        eventId, financeData);
                                  },
                            child: controller.isLoading.value
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Save Budget Details'),
                          )),
                    ),
                  ],
                ),
              context: context
              ),
            ),

            const SizedBox(height: 24),

            // =============================================
            // SECTION 2 — SPONSORS
            // =============================================
            _buildSectionHeader(
              icon: Icons.business,
              title: 'Add Sponsor',
              color: Colors.purple,
            ),

            const SizedBox(height: 12),

            // Show existing sponsors
            Obx(() => controller.sponsors.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No sponsors added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Column(
                    children: controller.sponsors
                        .map((sponsor) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.purple.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  // Sponsor name and notes
                                  Expanded(
                                    child: Text(
                                      sponsor.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  // Amount
                                  Text(
                                    '₹${sponsor.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 18),
                                    onPressed: () => controller
                                        .deleteSponsor(eventId, sponsor.id),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  )),

            // Sponsor add form
            Form(
              key: sponsorFormKey,
              child: _buildCard(
                child: Column(
                  children: [

                    // Sponsor name
                    _buildLabel('Sponsor Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: sponsorNameController,
                      decoration:
                          _inputDecoration('e.g. TechCorp Pvt Ltd'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Sponsor name is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Sponsor amount
                    _buildLabel('Amount Contributed (₹)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: sponsorAmountController,
                      decoration: _inputDecoration('e.g. 10000'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Amount is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Sponsor notes
                    _buildLabel('Notes (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: sponsorNotesController,
                      decoration: _inputDecoration(
                          'e.g. In kind sponsor, provided equipment'),
                    ),

                    const SizedBox(height: 16),

                    // Add Sponsor button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Sponsor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Validate sponsor form
                          if (!sponsorFormKey.currentState!.validate()) {
                            return;
                          }

                          // Build SponsorModel
                          final sponsor = SponsorModel(
                            id: '',
                            eventId: eventId,
                            clubId: clubId,
                            name: sponsorNameController.text.trim(),
                            amount: double.tryParse(
                                    sponsorAmountController.text.trim()) ??
                                0,
                            notes: sponsorNotesController.text.trim(),
                          );

                          // Call controller to save sponsor
                          controller.addSponsor(eventId, sponsor);

                          // Clear the sponsor fields after adding
                          sponsorNameController.clear();
                          sponsorAmountController.clear();
                          sponsorNotesController.clear();
                        },
                      ),
                    ),
                  ],
                ),
                context: context
              ),
            ),

            const SizedBox(height: 24),

            // =============================================
            // SECTION 3 — TICKET SALES
            // =============================================
            _buildSectionHeader(
              icon: Icons.confirmation_number,
              title: 'Ticket Sales',
              color: Colors.orange,
            ),

            const SizedBox(height: 12),

            Form(
              key: ticketFormKey,
              child: _buildCard(
                child: Column(
                  children: [

                    // Ticket price
                    _buildLabel('Ticket Price (₹)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ticketPriceController,
                      decoration: _inputDecoration('e.g. 100'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ticket price is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Tickets sold
                    _buildLabel('Number of Tickets Sold'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ticketsSoldController,
                      decoration: _inputDecoration('e.g. 85'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Tickets sold count is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // VIERP verified toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'VIERP Verified',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        // Obx watches vierpVerified and rebuilds toggle
                        Obx(() => Switch(
                              value: vierpVerified.value,
                              // Toggle the value when switched
                              onChanged: (val) =>
                                  vierpVerified.value = val,
                            )),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Manual note
                    _buildLabel('Manual Note (if not VIERP verified)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ticketNoteController,
                      decoration: _inputDecoration(
                          'e.g. Verified manually via attendance sheet'),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),

                    // Save Ticket button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Obx(() => ElevatedButton.icon(
                            icon: const Icon(Icons.confirmation_number),
                            label: controller.isLoading.value
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Save Ticket Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    // Validate ticket form
                                    if (!ticketFormKey.currentState!
                                        .validate()) return;

                                    // Parse values
                                    final price = double.tryParse(
                                            ticketPriceController.text
                                                .trim()) ??
                                        0;
                                    final sold = int.tryParse(
                                            ticketsSoldController.text
                                                .trim()) ??
                                        0;

                                    // Build TicketModel
                                    final ticketData = TicketModel(
                                      id: existingTicket?.id ?? '',
                                      eventId: eventId,
                                      clubId: clubId,
                                      ticketPrice: price,
                                      ticketsSold: sold,
                                      // Calculate revenue automatically
                                      totalRevenue: price * sold,
                                      vierpVerified: vierpVerified.value,
                                      manualNote:
                                          ticketNoteController.text.trim(),
                                    );

                                    // Save ticket data
                                    controller.saveTicket(
                                        eventId, ticketData);
                                  },
                          )),
                    ),
                  ],
                ),
              context : context
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Section Header with icon and color
  // -------------------------------------------------------
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        // Colored icon in a circle
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        // Section title
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // HELPER: Card wrapper
  // -------------------------------------------------------
  Widget _buildCard({required Widget child, required BuildContext context}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cs.surface,            // ← theme-aware
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}
  // -------------------------------------------------------
  // HELPER: Field Label
  // -------------------------------------------------------
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  // -------------------------------------------------------
  // HELPER: Input Decoration
  // Consistent style for all text fields
  // -------------------------------------------------------
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }
}