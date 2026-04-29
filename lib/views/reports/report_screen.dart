// This screen lets teachers and chairpersons generate a PDF report
// The report contains club info, members, events all in one neat PDF

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:club_management_app/controllers/club_controller.dart';
import 'package:club_management_app/controllers/member_controller.dart';
import 'package:club_management_app/controllers/event_controller.dart';
import 'package:club_management_app/utils/pdf_generator.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get all the controllers we need
    final clubController = Get.find<ClubController>();
    final memberController = Get.find<MemberController>();
    final eventController = Get.find<EventController>();

    // Loading state for the generate button
    final isGenerating = false.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
      ),

      body: Obx(() {
        // Get current club and tenure
        final club = clubController.selectedClub.value;
        final tenure = clubController.currentTenure.value;

        // If no club selected, show message
        if (club == null) {
          return const Center(
            child: Text(
              'Please select a club first from the dashboard',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---- REPORT PREVIEW CARD ----
              // Shows what will be in the report
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report title
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: Colors.blue, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${club.name} — Club Report',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // What is included in this report
                    const Text(
                      'This report will include:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),

                    // Checklist of what is included
                    _buildCheckItem('Club information and description'),
                    _buildCheckItem('Faculty in charge details'),
                    _buildCheckItem('Current tenure dates'),
                    _buildCheckItem('Club hierarchy'),
                    _buildCheckItem(
                        'Members list (${memberController.members.length} members)'),
                    _buildCheckItem(
                        'Events history (${eventController.events.length} events)'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---- GENERATE BUTTON ----
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Obx(() => ElevatedButton.icon(
                      icon: isGenerating.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        isGenerating.value
                            ? 'Generating PDF...'
                            : 'Generate and Download PDF',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isGenerating.value
                          ? null
                          : () async {
                              // Only proceed if tenure is loaded
                              if (tenure == null) {
                                Get.snackbar(
                                  'Error',
                                  'Tenure data not loaded',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              isGenerating.value = true;

                              try {
                                // Generate the PDF with all club data
                                await PdfGenerator.generateClubReport(
                                  club: club,
                                  tenure: tenure,
                                  members: memberController.members.toList(),
                                  events: eventController.events.toList(),
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  'Could not generate PDF: $e',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } finally {
                                isGenerating.value = false;
                              }
                            },
                    )),
              ),

              const SizedBox(height: 16),

              // Small note below the button
              const Text(
                'The PDF will open in a preview where you can download or share it.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  // Small checkmark item for the report preview list
  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}