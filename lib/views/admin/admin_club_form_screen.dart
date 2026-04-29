// This screen is only for the admin.
// It allows adding an existing college club to the portal.
// Only the admin can do this — no random user can add clubs.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:club_management_app/services/firestore_service.dart';
import 'package:club_management_app/controllers/club_controller.dart';

class AdminClubFormScreen extends StatefulWidget {
  const AdminClubFormScreen({super.key});

  @override
  State<AdminClubFormScreen> createState() => _AdminClubFormScreenState();
}

class _AdminClubFormScreenState extends State<AdminClubFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _nameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _descController = TextEditingController();
  final _facultyNameController = TextEditingController();
  final _facultyEmailController = TextEditingController();
  final _facultyPhoneController = TextEditingController();

  String _selectedDomain = 'technical';
  String _selectedStatus = 'active';
  bool _isSaving = false;

  static const List<String> _domains = [
    'technical', 'cultural', 'social', 'sports', 'other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _shortCodeController.dispose();
    _descController.dispose();
    _facultyNameController.dispose();
    _facultyEmailController.dispose();
    _facultyPhoneController.dispose();
    super.dispose();
  }

Future<void> _save() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;

  setState(() => _isSaving = true);

  try {
    await _firestoreService.createClub({
      'name': _nameController.text.trim(),
      'shortCode': _shortCodeController.text.trim().toUpperCase(),
      'domain': _selectedDomain,
      'status': _selectedStatus,
      'description': _descController.text.trim(),
      'facultyName': _facultyNameController.text.trim(),
      'facultyEmail': _facultyEmailController.text.trim().toLowerCase(),
      'facultyPhone': _facultyPhoneController.text.trim(),
      'currentTenureId': '',   // ← ADD THIS — required by ClubModel.fromJson
      'logoUrl': null,
    });

    // Use the permanent ClubController instance from GetX
    final clubController = Get.find<ClubController>();
    await clubController.fetchAllClubs();

    // Go back AFTER the list is refreshed
    Get.back();

    Get.snackbar(
      'Club added',
      '${_nameController.text.trim()} has been added to the portal.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F6E56),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  } catch (e) {
    Get.snackbar(
      'Error',
      'Could not add club: $e',
      snackPosition: SnackPosition.BOTTOM,
    );
  } finally {
    setState(() => _isSaving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Club to Portal'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF1565C0).withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        color: Color(0xFF1565C0), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You are adding an existing VIT club to the portal. '
                        'This club must already exist in the college. '
                        'Only you as the admin can perform this action.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Club Information ─────────────────────────────────────────
              _sectionLabel(cs, 'CLUB INFORMATION'),
              const SizedBox(height: 12),

              _field(
                controller: _nameController,
                label: 'Full Club Name',
                hint: 'e.g. Computer Society of India — Student Chapter',
                icon: Icons.groups_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Club name is required'
                    : null,
              ),
              const SizedBox(height: 12),

              _field(
                controller: _shortCodeController,
                label: 'Short Code',
                hint: 'e.g. CSSI, NSS, ROTARACT',
                icon: Icons.tag_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Short code is required'
                    : null,
              ),
              const SizedBox(height: 12),

              _field(
                controller: _descController,
                label: 'Description',
                hint: 'Brief description of what this club does',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: null,
              ),

              const SizedBox(height: 16),

              // ── Domain picker ────────────────────────────────────────────
              _sectionLabel(cs, 'DOMAIN'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _domains.map((domain) {
                  final isSelected = _selectedDomain == domain;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDomain = domain),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1565C0).withOpacity(0.1)
                            : cs.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1565C0)
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        domain[0].toUpperCase() + domain.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF1565C0)
                              : cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Status picker ────────────────────────────────────────────
              _sectionLabel(cs, 'STATUS'),
              const SizedBox(height: 8),
              Row(
                children: ['active', 'inactive'].map((status) {
                  final isSelected = _selectedStatus == status;
                  final color = status == 'active'
                      ? const Color(0xFF0F6E56)
                      : const Color(0xFF854F0B);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedStatus = status),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(
                            right: status == 'active' ? 8 : 0),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.1)
                              : cs.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Theme.of(context).dividerColor,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Text(
                          status[0].toUpperCase() +
                              status.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? color
                                : cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Faculty in Charge ────────────────────────────────────────
              _sectionLabel(cs, 'FACULTY IN CHARGE'),
              const SizedBox(height: 12),

              _field(
                controller: _facultyNameController,
                label: 'Faculty Name',
                hint: 'e.g. Prof. Sharma',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Faculty name is required'
                    : null,
              ),
              const SizedBox(height: 12),

              _field(
                controller: _facultyEmailController,
                label: 'Faculty Email',
                hint: 'faculty@vit.ac.in',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: null,
              ),
              const SizedBox(height: 12),

              _field(
                controller: _facultyPhoneController,
                label: 'Faculty Phone',
                hint: '10-digit number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: null,
              ),

              const SizedBox(height: 32),

              // ── Save button ──────────────────────────────────────────────
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Add Club to Portal',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: cs.onSurface.withOpacity(0.45),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }
}