import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:club_management_app/controllers/user_request_controller.dart';
import 'package:club_management_app/controllers/club_controller.dart';

class RegisterRequestScreen extends StatefulWidget {
  const RegisterRequestScreen({super.key});

  @override
  State<RegisterRequestScreen> createState() => _RegisterRequestScreenState();
}

class _RegisterRequestScreenState extends State<RegisterRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Use late + initState, NOT field initialisation.
  // Get.find() at field-init time runs before the widget tree is built and
  // before GetX guarantees controllers are registered — causing null crashes.
  late UserRequestController _requestController;
  late ClubController _clubController;

  final _nameController       = TextEditingController();
  final _emailController      = TextEditingController();
  final _phoneController      = TextEditingController();
  final _employeeIdController = TextEditingController();

  // FIX: added _unlistedClubController for chairpersons whose club is not yet
  // in the system.  Without this, those users are completely blocked from
  // submitting a request.
  final _unlistedClubController = TextEditingController();

  String  _selectedRole     = 'teacher';
  String? _selectedClubId;
  String? _selectedClubName;

  // When true the club dropdown is replaced by a free-text field
  bool _clubNotListed = false;

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Safe here — InitialBindings has already run before any route widget
    // reaches initState().
    _requestController = Get.find<UserRequestController>();
    _clubController    = Get.find<ClubController>();

    // Force-refresh clubs when this screen opens.
    // This screen is reachable before login, so clubs may not be loaded yet.
    if (_clubController.clubs.isEmpty) {
      _clubController.fetchAllClubs();
    }
  } // ← FIX: this closing brace was missing in the previous version, causing
    //   dispose(), _submit(), build(), and all helper methods to be accidentally
    //   nested inside initState() as local functions instead of class methods.

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _unlistedClubController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Chairperson must either select a club OR fill in the unlisted club name
    if (_selectedRole == 'chairperson' &&
        _selectedClubId == null &&
        _unlistedClubController.text.trim().isEmpty) {
      Get.snackbar(
        'Club Required',
        'Please select your club or enter its name if it is not listed.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final success = await _requestController.submitRequest(
      name:       _nameController.text,
      email:      _emailController.text,
      role:       _selectedRole,
      phone:      _phoneController.text,
      employeeId: _employeeIdController.text,
      clubId:     _selectedClubId,
      clubName:   _selectedClubName,
      // Pass the free-text unlisted club name when the dropdown was bypassed
      unlisted: _clubNotListed ? _unlistedClubController.text : null,
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

  // ── Success screen ────────────────────────────────────────────────────────
  Widget _buildSuccess(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                // FIX: withOpacity() deprecated → withValues(alpha:)
                color: const Color(0xFF0F6E56).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF0F6E56), size: 40),
            ),
            const SizedBox(height: 24),
            Text('Request Submitted',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            Text(
              'Your request has been sent to the admin for review.\n'
              'Use "Check My Request Status" on the login screen to '
              'see whether it has been approved or rejected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  // FIX: withOpacity() deprecated → withValues(alpha:)
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Back to Login')),
          ],
        ),
      ),
    );
  }

  // ── Main form ─────────────────────────────────────────────────────────────
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
                // FIX: withOpacity() deprecated → withValues(alpha:)
                color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
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
                      'Your request will be reviewed by the admin before '
                      'your account is created.',
                      style: TextStyle(
                          fontSize: 12,
                          // FIX: withOpacity() deprecated → withValues(alpha:)
                          color: cs.onSurface.withValues(alpha: 0.7),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _field(
                controller: _nameController,
                label: 'Full Name',
                hint: 'As on your ID card',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Full name is required'
                    : null),
            const SizedBox(height: 16),

            _field(
                controller: _emailController,
                label: 'VIT Email',
                hint: 'yourname@vit.ac.in',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.'))
                    return 'Enter a valid email';
                  return null;
                }),
            const SizedBox(height: 16),

            _field(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '10-digit mobile number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone is required';
                  if (v.trim().length < 10)
                    return 'Enter a valid phone number';
                  return null;
                }),
            const SizedBox(height: 16),

            _field(
                controller: _employeeIdController,
                label: 'Employee ID / PRN',
                hint: 'Your VIT staff ID',
                icon: Icons.badge_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Employee ID is required'
                    : null),
            const SizedBox(height: 20),

            // Role selector
            Text('ROLE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    // FIX: withOpacity() deprecated → withValues(alpha:)
                    color: cs.onSurface.withValues(alpha: 0.45),
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),

            // FIX: Expanded lives HERE in the Row, not inside _roleChip().
            // Returning Expanded from a helper and placing it inside a Column
            // causes a "RenderFlex overflowed" crash at runtime.
            Row(
              children: [
                Expanded(
                    child: _roleChip(
                        'teacher', 'Faculty / Teacher', Icons.school_outlined)),
                const SizedBox(width: 10),
                Expanded(
                    child: _roleChip(
                        'chairperson', 'Chairperson', Icons.groups_outlined)),
              ],
            ),

            // Club section — only shown for chairpersons
            if (_selectedRole == 'chairperson') ...[
              const SizedBox(height: 20),
              Text('YOUR CLUB',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),

              // FIX: Instead of just showing "No clubs — contact the admin"
              // (which completely blocks submission), we now show:
              //   • If clubs exist: a dropdown PLUS a "My club isn't listed" toggle
              //   • If no clubs exist OR toggle is on: a free-text field
              // The unlisted club name is stored on the request so the admin
              // knows which club to create before approving.
              Obx(() {
                final clubs = _clubController.clubs;
                final hasClubs = clubs.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dropdown — visible when clubs exist and not toggled off
                    if (hasClubs && !_clubNotListed)
                      DropdownButtonFormField<String>(
                        value: _selectedClubId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select your club',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        items: clubs
                            .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          setState(() {
                            _selectedClubId = id;
                            _selectedClubName = clubs
                                .firstWhereOrNull((c) => c.id == id)
                                ?.name;
                          });
                        },
                        validator: (_) {
                          if (_selectedRole == 'chairperson' &&
                              !_clubNotListed &&
                              _selectedClubId == null) {
                            return 'Please select your club';
                          }
                          return null;
                        },
                      ),

                    // "My club isn't listed" toggle
                    if (hasClubs) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _clubNotListed = !_clubNotListed;
                          if (_clubNotListed) {
                            // Clear the dropdown selection when switching to free-text
                            _selectedClubId   = null;
                            _selectedClubName = null;
                          } else {
                            _unlistedClubController.clear();
                          }
                        }),
                        child: Row(
                          children: [
                            Icon(
                              _clubNotListed
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: const Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'My club isn\'t listed',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Free-text field — shown when no clubs exist OR toggle is on
                    if (!hasClubs || _clubNotListed) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _unlistedClubController,
                        decoration: InputDecoration(
                          labelText: 'Club name',
                          hintText: 'Type the name of your club',
                          prefixIcon:
                              const Icon(Icons.groups_outlined, size: 18),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          // Helper tells the admin what to expect
                          helperText:
                              'The admin will create this club if it doesn\'t exist yet.',
                          helperMaxLines: 2,
                        ),
                        validator: (v) {
                          if (_selectedRole == 'chairperson' &&
                              _clubNotListed &&
                              (v == null || v.trim().isEmpty)) {
                            return 'Please enter your club name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                );
              }),
            ],

            const SizedBox(height: 32),

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
                  child: const Text('Back to Login')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Reusable text field ───────────────────────────────────────────────────
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
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: validator,
    );
  }

  // ── Role chip — returns a plain Container, NOT Expanded ───────────────────
  // Expanded is only valid as a direct child of Row/Column/Flex.
  // The Expanded wrapper lives in the Row above, not here.
  Widget _roleChip(String value, String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRole = value;
        if (value == 'teacher') {
          _selectedClubId   = null;
          _selectedClubName = null;
          _clubNotListed    = false;
          _unlistedClubController.clear();
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          // FIX: withOpacity() deprecated → withValues(alpha:)
          color: isSelected
              ? const Color(0xFF1565C0).withValues(alpha: 0.10)
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
            Icon(icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF1565C0)
                    // FIX: withOpacity() deprecated → withValues(alpha:)
                    : cs.onSurface.withValues(alpha: 0.5)),
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
                        // FIX: withOpacity() deprecated → withValues(alpha:)
                        : cs.onSurface.withValues(alpha: 0.6),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}