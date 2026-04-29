// This screen shows all documents uploaded for a club
// Chairpersons can upload new files
// Everyone can view the list and open files

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening file URLs

import 'package:club_management_app/controllers/document_controller.dart';
import 'package:club_management_app/controllers/club_controller.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

class ClubDocumentsScreen extends GetView<DocumentController> {
  const ClubDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clubController = Get.find<ClubController>();
    final authController = Get.find<AuthController>();

    // Get the current club ID
    final clubId = clubController.selectedClub.value?.id ?? '';

    // Fetch documents when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (clubId.isNotEmpty) {
        controller.fetchDocuments(clubId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),

      body: Obx(() {
        // Show spinner while loading
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show empty state if no documents yet
        if (controller.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Big icon
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No documents uploaded yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                // Show upload hint for chairperson
                if (authController.isChairperson) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to upload a file',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ],
            ),
          );
        }

        // Show list of documents
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.documents.length,
          itemBuilder: (context, index) {
            final doc = controller.documents[index];

            // Pick icon and color based on file type
            IconData fileIcon;
            Color fileColor;
            switch (doc.fileType) {
              case 'pdf':
                fileIcon = Icons.picture_as_pdf;
                fileColor = Colors.red;
                break;
              case 'image':
                fileIcon = Icons.image;
                fileColor = Colors.blue;
                break;
              case 'docx':
                fileIcon = Icons.description;
                fileColor = Colors.indigo;
                break;
              case 'xlsx':
                fileIcon = Icons.table_chart;
                fileColor = Colors.green;
                break;
              default:
                fileIcon = Icons.insert_drive_file;
                fileColor = Colors.grey;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                // File type icon on the left
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: fileColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(fileIcon, color: fileColor),
                ),
                // File name
                title: Text(
                  doc.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                // Upload date
                subtitle: Text(
                  'Uploaded ${_formatDate(doc.uploadedAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                // Open button on the right
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Open file button
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.blue),
                      onPressed: () async {
                        // Open the file URL in the browser or file app
                        final uri = Uri.parse(doc.storageUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    // Delete button — only for chairperson
                    if (authController.isChairperson)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () {
                          // Confirm before deleting
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Document?'),
                              content: Text(
                                  'Are you sure you want to delete "${doc.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    controller.deleteDocument(doc, clubId);
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),

      // Upload button — only for chairperson
      floatingActionButton: Get.find<AuthController>().isChairperson
          ? FloatingActionButton(
              onPressed: () =>
                  controller.pickAndUploadFile(clubId),
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }

  // Format date nicely
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}