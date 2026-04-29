// This screen shows all finance information for a selected event
// It shows budget, expenses, sponsors, ticket sales, and balance summary
// The user gets here by tapping "View Finance Details" on the Event Detail screen

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import controllers we need
import 'package:club_management_app/controllers/finance_controller.dart';
import 'package:club_management_app/controllers/event_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

class FinanceDetailScreen extends GetView<FinanceController> {
  const FinanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get EventController to access the currently selected event
    final eventController = Get.find<EventController>();

    // Get AuthController to check if user is chairperson
    final authController = Get.find<AuthController>();

    // Get the current event ID safely
    final eventId = eventController.selectedEvent.value?.id ?? '';

    // Load all finance data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (eventId.isNotEmpty) {
        controller.loadFinanceData(eventId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Details'),
        actions: [
          // Show edit button only for chairperson
          if (authController.isChairperson)
            IconButton(
              icon: const Icon(Icons.edit),
              // Navigate to finance form screen
              onPressed: () => Get.toNamed('/finance-form'),
            ),
        ],
      ),

      body: Obx(() {
        // Show spinner while data is loading
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // =============================================
              // CARD 1 — Summary Box
              // Shows total income, expenses, and balance
              // at a glance in colored boxes
              // =============================================
              _buildSectionTitle('Financial Summary'),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Total Income box — green
                  _buildSummaryBox(
                    label: 'Total Income',
                    // Format number as rupees like ₹12,500
                    value: '₹${controller.totalIncome.toStringAsFixed(0)}',
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),

                  const SizedBox(width: 10),

                  // Total Expenses box — red
                  _buildSummaryBox(
                    label: 'Total Expenses',
                    value:
                        '₹${(controller.finance.value?.totalExpenses ?? 0).toStringAsFixed(0)}',
                    color: Colors.red,
                    icon: Icons.arrow_upward,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Balance box — full width, blue
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Label on the left
                    const Text(
                      'Remaining Balance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    // Balance amount on the right
                    Text(
                      '₹${controller.remainingBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =============================================
              // CARD 2 — Budget Details
              // Shows total budget and expense breakdown
              // =============================================
              _buildSectionTitle('Budget Details'),
              const SizedBox(height: 10),

              // Show message if no finance record exists yet
              if (controller.finance.value == null)
                _buildEmptyCard('No budget details added yet.')
              else
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Total budget row
                      _buildInfoRow(
                        label: 'Total Budget',
                        value:
                            '₹${controller.finance.value!.totalBudget.toStringAsFixed(0)}',
                      ),

                      const Divider(height: 20),

                      // Total expenses row
                      _buildInfoRow(
                        label: 'Total Expenses',
                        value:
                            '₹${controller.finance.value!.totalExpenses.toStringAsFixed(0)}',
                      ),

                      const Divider(height: 20),

                      // Expense breakdown list
                      // Each entry shows category, amount, and description
                      if (controller.finance.value!.breakdown.isNotEmpty) ...[
                        const Text(
                          'Expense Breakdown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Loop through each breakdown item and show it
                        ...controller.finance.value!.breakdown.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // Category and description on the left
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['category'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      // Show description in grey if it exists
                                      if (item['description'] != null &&
                                          item['description']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                          item['description'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Amount on the right
                                Text(
                                  '₹${(item['amount'] ?? 0).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Notes section if there are any notes
                      if (controller.finance.value!.notes.isNotEmpty) ...[
                        const Divider(height: 20),
                        const Text(
                          'Notes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.finance.value!.notes,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                context: context  
                ),

              const SizedBox(height: 20),

              // =============================================
              // CARD 3 — Sponsors
              // Shows list of all sponsors and their amounts
              // =============================================
              _buildSectionTitle('Sponsors'),
              const SizedBox(height: 10),

              // Show message if no sponsors added yet
              if (controller.sponsors.isEmpty)
                _buildEmptyCard('No sponsors added yet.')
              else
                _buildCard(
                  child: Column(
                    children: [
                      // Loop through each sponsor and show their details
                      ...controller.sponsors.map(
                        (sponsor) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Sponsor icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.business,
                                  color: Colors.purple,
                                  size: 18,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Sponsor name and notes
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sponsor.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    // Show notes in grey if they exist
                                    if (sponsor.notes.isNotEmpty)
                                      Text(
                                        sponsor.notes,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Sponsor amount on the right
                              Text(
                                '₹${sponsor.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                  fontSize: 15,
                                ),
                              ),

                              // Delete button only for chairperson
                              if (authController.isChairperson)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () => controller.deleteSponsor(
                                      eventId, sponsor.id),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                context: context
                ),

              const SizedBox(height: 20),

              // =============================================
              // CARD 4 — Ticket Sales
              // Shows ticket price, sold count, and revenue
              // =============================================
              _buildSectionTitle('Ticket Sales'),
              const SizedBox(height: 10),

              // Show message if no ticket info added yet
              if (controller.ticket.value == null)
                _buildEmptyCard('No ticket information added yet.')
              else
                _buildCard(
                  child: Column(
                    children: [

                      _buildInfoRow(
                        label: 'Ticket Price',
                        value:
                            '₹${controller.ticket.value!.ticketPrice.toStringAsFixed(0)}',
                      ),

                      const Divider(height: 20),

                      _buildInfoRow(
                        label: 'Tickets Sold',
                        value:
                            controller.ticket.value!.ticketsSold.toString(),
                      ),

                      const Divider(height: 20),

                      _buildInfoRow(
                        label: 'Total Revenue',
                        value:
                            '₹${controller.ticket.value!.totalRevenue.toStringAsFixed(0)}',
                      ),

                      const Divider(height: 20),

                      // VIERP verification status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VIERP Verified',
                              style: TextStyle(color: Colors.grey)),
                          // Green tick if verified, orange cross if not
                          Icon(
                            controller.ticket.value!.vierpVerified
                                ? Icons.verified
                                : Icons.cancel_outlined,
                            color: controller.ticket.value!.vierpVerified
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),

                      // Show manual note if it exists
                      if (controller.ticket.value!.manualNote.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Note: ${controller.ticket.value!.manualNote}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                context: context
                ),

              const SizedBox(height: 20),

              // =============================================
              // CLOSE BUDGET BUTTON
              // Only visible for chairperson
              // Only shown if budget is not already closed
              // =============================================
              Obx(() {
                // Get the budget closed status from event controller
                final isClosed =
                    eventController.selectedEvent.value?.budgetClosed ?? false;

                // Only show if chairperson AND budget not yet closed
                if (authController.isChairperson && !isClosed) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('Close Budget'),
                      style: ElevatedButton.styleFrom(
                        // Red color to signal this is a final action
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // Show a confirmation dialog before closing
                        // We don't want accidental closes
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Close Budget?'),
                            content: const Text(
                              'This will mark the budget as finalized. Are you sure?',
                            ),
                            actions: [
                              // Cancel button
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              // Confirm button
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  controller.closeBudget(eventId);
                                },
                                child: const Text(
                                  'Yes, Close',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }

                // If budget already closed show a closed badge instead
                if (isClosed) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Budget Closed and Finalized',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // For teachers, show nothing here
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  // -------------------------------------------------------
  // HELPER: Section Title
  // Shows a bold heading above each section
  // -------------------------------------------------------
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Card wrapper
  // Wraps content in a white card with shadow
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
  // HELPER: Empty Card
  // Shows a grey message when no data exists yet
  // -------------------------------------------------------
  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  // -------------------------------------------------------
  // HELPER: Info Row
  // Shows a label on the left and value on the right
  // -------------------------------------------------------
  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // -------------------------------------------------------
  // HELPER: Summary Box
  // The colored boxes at the top showing income and expenses
  // -------------------------------------------------------
  Widget _buildSummaryBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon at the top
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            // Amount in bold
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            // Label below
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}