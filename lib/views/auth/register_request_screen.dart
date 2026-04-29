// RegisterRequestScreen
// Allows a new teacher or chairperson to request access to the app.
// The admin reviews and approves/rejects from AdminRequestsScreen.
//
// KEY ADDITIONS vs previous version:
//   1. Chairpersons can now pick "Register a new club" if their club
//      is not yet in the system. Extra fields (club name, domain,
//      short code) appear and are stored in newClubData on the request.
//      On admin approval, the controller creates the club first, then
//      creates the user profile with the new club's Firestore ID.
//
//   2. A "Check my request status" link at the bottom navigates to
//      RequestStatusScreen where the user can see pending/approved/
//      rejected status and retrieve their temp password or rejection reason.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:club_management_app/controllers/user_request_controller.dart';
import 'package:club_management_app/controllers/club_controller.dart';

// Sentinel value — when the chairperson picks this, we show new-club fields
const String _newClubSentinel = '__new_club__';

class RegisterRequestScreen extends StatefulWidget {
  const RegisterRequestScreen({super.key});

  @override
  State<RegisterRequestScreen> createState() => _RegisterRequestScreenState();
}

class _RegisterRequestScreenState extends State<RegisterRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late UserRequestController _requestController;
  late ClubController _clubController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();

  // New-club fields — only visible when chairperson picks "Register a new club"
  final _newClubNameController = TextEditingController();
  final _newClubShortCodeController = TextEditingController();

  String _selectedRole = 'teacher';
  String? _selectedClubId;   // null means nothing selected yet
  String? _selectedClubName;
  String _selectedDomain = 'technical'; // default domain for new club
  bool _isNewClub = false;   // true when sentinel value is chosen
  bool _submitted = false;

  // Available club domains
  static const List<String> _domains = [
    'technical', 'cultural', 'social', 'sports', 'other',
  ];

  @override
  void initState() {
    super.initState();
    _requestController = Get.find<UserRequestController>();
    _clubController = Get.find<ClubController>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _newClubNameController.dispose();
    _newClubShortCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Chairperson must have either selected a club or filled in a new club name
    if (_selectedRole == 'chairperson') {
      if (_selectedClubId == null) {
        Get.snackbar('Club Required',
            'Please select your club or choose "Register a new club".',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      if (_isNewClub && _newClubNameController.text.trim().isEmpty) {
        Get.snackbar('Club Name Required',
            'Please enter the name of the new club.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    // Build newClubData only when a new club is being registered
    Map<String, dynamic>? newClubData;
    if (_selectedRole == 'chairperson' && _isNewClub) {
      newClubData = {
        'name': _newClubNameController.text.trim(),
        'shortCode': _newClubShortCodeController.text.trim().toUpperCase(),
        'domain': _selectedDomain,
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
      };
    }

    final success = await _requestController.submitRequest(
      name: _nameController.text,
      email: _emailController.text,
      role: _selectedRole,
      phone: _phoneController.text,
      employeeId: _employeeIdController.text,
      // For existing club: pass the ID and name directly
      // For new club: pass null IDs — the controller fills them after creating the club
      clubId: (_isNewClub || _selectedClubId == null) ? null : _selectedClubId,
      clubName: _isNewClub
          ? _newClubNameController.text.trim()
          : _selectedClubName,
      newClubData: newClubData,
    );

    if (success && mounted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Request Access'), centerTitle: true),
      body: _submitted ? _buildSuccess(cs) : _buildForm(cs),
    );
  }

  // -------------------------------------------------------
  // Success screen shown after request is submitted
  // -------------------------------------------------------
  Widget _buildSuccess(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0F6E56).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF0F6E56), size: 40),
            ),
            const SizedBox(height: 24),
            Text('Request Submitted',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            Text(
              'Your request has been sent to the admin for review. '
              'Use "Check Request Status" on the login screen to track progress.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14,
                  color: cs.onSurface.withOpacity(0.6), height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Get.back(),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // Main form
  // -------------------------------------------------------
  Widget _buildForm(ColorScheme cs) {
    return SingleChildScrollView(
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
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.info_outline_rounded,
                        color: Color(0xFF1565C0), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your request will be reviewed by the admin before your account is created. '
                      'You can track its status from the login screen.',
                      style: TextStyle(fontSize: 12,
                          color: cs.onSurface.withOpacity(0.7), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal details
            _field(controller: _nameController, label: 'Full Name',
                hint: 'As on your ID card', icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Full name is required' : null),
            const SizedBox(height: 16),

            _field(controller: _emailController, label: 'VIT Email',
                hint: 'yourname@vit.ac.in', icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.'))
                    return 'Enter a valid email';
                  return null;
                }),
            const SizedBox(height: 16),

            _field(controller: _phoneController, label: 'Phone Number',
                hint: '10-digit mobile number', icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone is required';
                  if (v.trim().length < 10) return 'Enter a valid phone number';
                  return null;
                }),
            const SizedBox(height: 16),

            _field(controller: _employeeIdController, label: 'Employee ID / PRN',
                hint: 'Your VIT staff ID', icon: Icons.badge_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Employee ID is required' : null),
            const SizedBox(height: 20),

            // Role selector
            _label(cs, 'ROLE'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _roleChip('teacher', 'Faculty / Teacher',
                    Icons.school_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _roleChip('chairperson', 'Chairperson',
                    Icons.groups_outlined)),
              ],
            ),

            // ---- Club section — only for chairpersons ----
            if (_selectedRole == 'chairperson') ...[
              const SizedBox(height: 20),
              _label(cs, 'YOUR CLUB'),
              const SizedBox(height: 8),

              // Club dropdown — existing clubs + "Register a new club" at bottom
              Obx(() {
                final clubs = _clubController.clubs;
                return DropdownButtonFormField<String>(
                  value: _selectedClubId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select your club',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: [
                    // Existing clubs
                    ...clubs.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name,
                              overflow: TextOverflow.ellipsis),
                        )),

                    // Divider item (non-selectable visual separator)
                    if (clubs.isNotEmpty)
                      const DropdownMenuItem(
                        enabled: false,
                        value: '__divider__',
                        child: Divider(height: 1),
                      ),

                    // "Register a new club" option
                    DropdownMenuItem(
                      value: _newClubSentinel,
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline_rounded,
                              size: 16, color: Color(0xFF1565C0)),
                          const SizedBox(width: 8),
                          Text(
                            'Register a new club',
                            style: TextStyle(
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (id) {
                    if (id == '__divider__') return;
                    setState(() {
                      _selectedClubId = id;
                      _isNewClub = (id == _newClubSentinel);
                      if (!_isNewClub) {
                        _selectedClubName = clubs
                            .firstWhereOrNull((c) => c.id == id)
                            ?.name;
                      } else {
                        _selectedClubName = null;
                      }
                    });
                  },
                  validator: (_) {
                    if (_selectedRole == 'chairperson' &&
                        _selectedClubId == null) {
                      return 'Please select a club or register a new one';
                    }
                    return null;
                  },
                );
              }),

              // ---- New club fields — shown only when "Register a new club" is picked ----
              if (_isNewClub) ...[
                const SizedBox(height: 16),

                // Blue info box explaining what happens
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF1565C0).withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 15, color: Color(0xFF1565C0)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The admin will create this club in the system when they approve your request.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.65),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Club name
                _field(
                  controller: _newClubNameController,
                  label: 'Club Name',
                  hint: 'e.g. IEEE Student Branch, Rotaract Club',
                  icon: Icons.groups_2_outlined,
                  validator: (v) {
                    if (_isNewClub && (v == null || v.trim().isEmpty)) {
                      return 'Club name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Short code
                _field(
                  controller: _newClubShortCodeController,
                  label: 'Short Code (optional)',
                  hint: 'e.g. IEEE, ROTARACT',
                  icon: Icons.tag_rounded,
                  validator: null,
                ),
                const SizedBox(height: 14),

                // Domain picker
                _label(Theme.of(context).colorScheme, 'CLUB DOMAIN'),
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
                              : Theme.of(context).colorScheme.surface,
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
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],

            const SizedBox(height: 32),

            // Submit button
            Obx(() => _requestController.isSubmitting.value
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Submit Request',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  )),

            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text('Back to Login'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------
  Widget _label(ColorScheme cs, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: cs.onSurface.withOpacity(0.45), letterSpacing: 0.8,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _roleChip(String value, String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRole = value;
        if (value == 'teacher') {
          _selectedClubId = null;
          _selectedClubName = null;
          _isNewClub = false;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1565C0).withOpacity(0.1)
              : cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1565C0)
                : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16,
                color: isSelected
                    ? const Color(0xFF1565C0)
                    : cs.onSurface.withOpacity(0.5)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF1565C0)
                        : cs.onSurface.withOpacity(0.6),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}