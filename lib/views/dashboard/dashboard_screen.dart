import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:club_management_app/controllers/auth_controller.dart';
import 'package:club_management_app/controllers/club_controller.dart';
import 'package:club_management_app/controllers/user_request_controller.dart';
import 'package:club_management_app/models/club_model.dart';


class DashboardScreen extends GetView<ClubController> {
const DashboardScreen({super.key});


// Returns a color specific to each club domain
// This is what makes each club card feel distinct and branded
Color _domainColor(String domain) {
switch (domain.toLowerCase()) {
case 'technical':
return const Color(0xFF1565C0);
case 'cultural':
return const Color(0xFFE24B4A);
case 'social':
return const Color(0xFF0F6E56);
case 'sports':
return const Color(0xFF7B1FA2);
default:
return const Color(0xFF888780);
}
}


// Returns a light background tint for the domain color
// In dark mode we darken the tint so it doesn't look washed out
Color _domainTint(String domain, bool isDark) {
if (isDark) {
switch (domain.toLowerCase()) {
case 'technical':
return const Color(0xFF1565C0).withOpacity(0.2);
case 'cultural':
return const Color(0xFFE24B4A).withOpacity(0.2);
case 'social':
return const Color(0xFF0F6E56).withOpacity(0.2);
case 'sports':
return const Color(0xFF7B1FA2).withOpacity(0.2);
default:
return const Color(0xFF888780).withOpacity(0.2);
}
}
switch (domain.toLowerCase()) {
case 'technical':
return const Color(0xFFE3EFFE);
case 'cultural':
return const Color(0xFFFCEBEB);
case 'social':
return const Color(0xFFE1F5EE);
case 'sports':
return const Color(0xFFF0EBF8);
default:
return const Color(0xFFF1EFE8);
}
}


// Returns a greeting based on current time of day
String _greeting() {
final hour = DateTime.now().hour;
if (hour < 12) return 'Good morning';
if (hour < 17) return 'Good afternoon';
return 'Good evening';
}


@override
Widget build(BuildContext context) {
final authController = Get.find<AuthController>();
final isDark = Theme.of(context).brightness == Brightness.dark;
final colorScheme = Theme.of(context).colorScheme;
// AnnotatedRegion correctly sets status bar brightness based on theme
return AnnotatedRegion<SystemUiOverlayStyle>(
  value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
  child: Scaffold(
    // Let the theme control the scaffold background
    body: Obx(() {
      final user = authController.currentUser.value;
      final firstName = user?.name.split(' ').first ?? 'there';
      final isChairperson = authController.isChairperson;

      // Chairpersons only see their own club everywhere on the dashboard.
      // Teachers see every club.
      // Replace the visibleClubs logic:
      final visibleClubs = isChairperson
          ? controller.clubs
              .where((c) => c.id == Get.find<AuthController>().myClubIdReactive)
              .toList()
          : controller.clubs.toList();

      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // =============================================
          // TOP HEADER — surface card with name + stats
          // =============================================
          SliverToBoxAdapter(
            child: Container(
              color: colorScheme.surface,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Top row — college label + action icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // College name — branding color stays fixed
                      const Text(
                        'VIT CLUB MANAGER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                          letterSpacing: 1.2,
                        ),
                      ),
                      // Action buttons — settings and logout
                      Row(
                        children: [
                          // Admin-only: pending requests badge
                          if (!authController.isChairperson)
                            Obx(() {
                              final count = Get.find<UserRequestController>().pendingCount.value;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _iconButton(
                                    context: context,
                                    icon: Icons.how_to_reg_outlined,
                                    onTap: () => Get.toNamed('/admin-requests'),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE24B4A),
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          count > 9 ? '9+' : '$count',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }),
                          if (!authController.isChairperson)
                            const SizedBox(width: 6),
  //                         _iconButton(
  //                         context: context,
  //                         icon: Icons.add_business_outlined,
  //                         onTap: () => Get.toNamed('/admin-club-form'),
  // ),
                          _iconButton(
                            context: context,
                            icon: Icons.settings_outlined,
                            onTap: () => Get.toNamed('/settings'),
                          ),
                          const SizedBox(width: 6),
                          _iconButton(
                            context: context,
                            icon: Icons.logout_rounded,
                            onTap: () => _confirmLogout(context, authController),
                          ),
                          
                          if (authController.isTeacher) ...[
                            const SizedBox(width: 6),
                            _iconButton(
                              context: context,
                              icon: Icons.add_business_outlined,
                              onTap: () => Get.toNamed('/admin-club-form'),
                            ),
                          ],
                                                  ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Greeting — muted
                  Text(
                    _greeting(),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Name — full emphasis
                  Text(
                    firstName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Role pill — small and understated
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Blue for teacher, teal for chairperson
                            color: isChairperson
                                ? const Color(0xFF0F6E56)
                                : const Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isChairperson
                              ? 'Chairperson — Staff Portal'
                              : 'Faculty — Staff Portal',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Stat cards — 3 in a row
                  controller.isLoading.value
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            _statCard(
                              context: context,
                              value: visibleClubs.length.toString(),
                              label: 'Total clubs',
                              valueColor: const Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 8),
                            _statCard(
                              context: context,
                              value: visibleClubs
                                  .where((c) => c.status == 'active')
                                  .length
                                  .toString(),
                              label: 'Active',
                              valueColor: const Color(0xFF0F6E56),
                            ),
                            const SizedBox(width: 8),
                            _statCard(
                              context: context,
                              value: visibleClubs
                                  .where((c) => c.status == 'inactive')
                                  .length
                                  .toString(),
                              label: 'Inactive',
                              valueColor: const Color(0xFF854F0B),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // =============================================
          // CLUB SELECTOR DROPDOWN
          // =============================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(context, isChairperson ? 'Your club' : 'Browse clubs'),
                  const SizedBox(height: 8),

                  // Styled dropdown — theme-aware
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Obx(() => DropdownButton<String>(
                      value: controller.selectedClubId.value.isEmpty ||
                              !visibleClubs.any((c) => c.id == controller.selectedClubId.value)
                          ? null
                          : controller.selectedClubId.value,
                            hint: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              child: Text(
                                isChairperson
                                    ? 'Your club'
                                    : 'Search or select a club...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface
                                      .withOpacity(0.45),
                                ),
                              ),
                            ),
                            isExpanded: true,
                            dropdownColor: colorScheme.surface,
                            icon: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: colorScheme.onSurface.withOpacity(0.5),
                                size: 18,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            items: visibleClubs
                                .map((club) => DropdownMenuItem<String>(
                                      value: club.id,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        child: Row(
                                          children: [
                                            // Tiny domain color dot
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _domainColor(
                                                    club.domain),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                club.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  // Theme-aware — visible in both light and dark
                                                  color: colorScheme.onSurface,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (clubId) {
                              if (clubId != null) {
                                controller.selectClub(clubId);
                              }
                            },
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // =============================================
          // QUICK ACCESS — 2x2 grid
          // =============================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(context, 'Quick access'),
                  const SizedBox(height: 8),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.7,
                    children: [
                      _quickAction(
                        context: context,
                        label: 'Events',
                        sub: 'View event history',
                        iconColor: const Color(0xFF1565C0),
                        tintColor: isDark
                            ? const Color(0xFF1565C0).withOpacity(0.2)
                            : const Color(0xFFE3EFFE),
                        icon: Icons.event_note_rounded,
                        onTap: () =>
                            _requireClub(() => Get.toNamed('/events')),
                      ),
                      _quickAction(
                        context: context,
                        label: 'Members',
                        sub: 'Manage club roster',
                        iconColor: const Color(0xFF0F6E56),
                        tintColor: isDark
                            ? const Color(0xFF0F6E56).withOpacity(0.2)
                            : const Color(0xFFE1F5EE),
                        icon: Icons.people_alt_rounded,
                        onTap: () =>
                            _requireClub(() => Get.toNamed('/members')),
                      ),
                      _quickAction(
                        context: context,
                        label: 'Resources',
                        sub: 'Book halls and rooms',
                        iconColor: const Color(0xFF533896),
                        tintColor: isDark
                            ? const Color(0xFF533896).withOpacity(0.2)
                            : const Color(0xFFF0EBF8),
                        icon: Icons.meeting_room_rounded,
                        onTap: () => Get.toNamed('/resources'),
                      ),
                      _quickAction(
                        context: context,
                        label: 'Reports',
                        sub: 'Generate PDF reports',
                        iconColor: const Color(0xFF854F0B),
                        tintColor: isDark
                            ? const Color(0xFF854F0B).withOpacity(0.2)
                            : const Color(0xFFFEF3E2),
                        icon: Icons.picture_as_pdf_rounded,
                        onTap: () =>
                            _requireClub(() => Get.toNamed('/reports')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // =============================================
          // ALL CLUBS LIST
          // =============================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _sectionLabel(
                context,
                'All clubs  ·  ${controller.clubs.length}',
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Empty state
          if (visibleClubs.isEmpty && !controller.isLoading.value)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.groups_2_outlined,
                      size: 40,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No clubs found',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // The actual clubs list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == visibleClubs.length) {
                  return const SizedBox(height: 32);
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _clubCard(context, visibleClubs[index]),
                );
              },
              childCount: visibleClubs.length + 1,
            ),
          ),
        ],
      );
    }),
  ), // end Scaffold
); // end AnnotatedRegion

}


// -------------------------------------------------------
// Shows confirmation dialog before logging out
// -------------------------------------------------------
void _confirmLogout(
BuildContext context, AuthController authController) {
showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: const Text('Sign out?'),
content: const Text('You will be returned to the login screen.'),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx),
child: const Text('Cancel'),
),
TextButton(
onPressed: () {
Navigator.pop(ctx);
authController.logout();
},
child: const Text(
'Sign out',
style: TextStyle(color: Colors.red),
),
),
],
),
);
}


// -------------------------------------------------------
// Shows a snackbar if no club is selected yet
// -------------------------------------------------------
void _requireClub(VoidCallback action) {
if (controller.selectedClub.value != null) {
action();
} else {
Get.snackbar(
'Select a club first',
'Use the dropdown above to choose a club',
snackPosition: SnackPosition.BOTTOM,
margin: const EdgeInsets.all(16),
borderRadius: 10,
duration: const Duration(seconds: 2),
);
}
}


// -------------------------------------------------------
// HELPER: Small section label — theme-aware muted text
// -------------------------------------------------------
Widget _sectionLabel(BuildContext context, String text) {
return Text(
text.toUpperCase(),
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w600,
color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
letterSpacing: 0.8,
),
);
}


// -------------------------------------------------------
// HELPER: Circular icon button in the header
// -------------------------------------------------------
Widget _iconButton({
required BuildContext context,
required IconData icon,
required VoidCallback onTap,
}) {
final colorScheme = Theme.of(context).colorScheme;
return GestureDetector(
onTap: onTap,
child: Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: colorScheme.surfaceContainerHighest,
borderRadius: BorderRadius.circular(8),
border: Border.all(
color: Theme.of(context).dividerColor,
width: 0.5,
),
),
child: Icon(
icon,
size: 16,
color: colorScheme.onSurface.withOpacity(0.6),
),
),
);
}


// -------------------------------------------------------
// HELPER: Stat card in the header
// -------------------------------------------------------
Widget _statCard({
required BuildContext context,
required String value,
required String label,
required Color valueColor,
}) {
final colorScheme = Theme.of(context).colorScheme;
return Expanded(
child: Container(
padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
decoration: BoxDecoration(
color: colorScheme.surfaceContainerHighest,
borderRadius: BorderRadius.circular(8),
border: Border.all(
color: Theme.of(context).dividerColor,
width: 0.5,
),
),
child: Column(
children: [
Text(
value,
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w600,
color: valueColor,
height: 1,
),
),
const SizedBox(height: 3),
Text(
label,
style: TextStyle(
fontSize: 9,
color: colorScheme.onSurface.withOpacity(0.5),
letterSpacing: 0.2,
),
textAlign: TextAlign.center,
),
],
),
),
);
}


// -------------------------------------------------------
// HELPER: Quick action card
// -------------------------------------------------------
Widget _quickAction({
required BuildContext context,
required String label,
required String sub,
required Color iconColor,
required Color tintColor,
required IconData icon,
required VoidCallback onTap,
}) {
final colorScheme = Theme.of(context).colorScheme;
return GestureDetector(
onTap: onTap,
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: colorScheme.surface,
borderRadius: BorderRadius.circular(10),
border: Border.all(
color: Theme.of(context).dividerColor,
width: 0.5,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
width: 28,
height: 28,
decoration: BoxDecoration(
color: tintColor,
borderRadius: BorderRadius.circular(6),
),
child: Icon(icon, color: iconColor, size: 15),
),
const SizedBox(height: 7),
Text(
label,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: colorScheme.onSurface,
),
),
Text(
sub,
style: TextStyle(
fontSize: 9,
color: colorScheme.onSurface.withOpacity(0.5),
),
),
],
),
),
);
}


// -------------------------------------------------------
// HELPER: Club card in the list
// Domain color left accent + short code badge + status
// -------------------------------------------------------
Widget _clubCard(BuildContext context, ClubModel club) {
final isDark = Theme.of(context).brightness == Brightness.dark;
final colorScheme = Theme.of(context).colorScheme;
final dColor = _domainColor(club.domain);
final dTint = _domainTint(club.domain, isDark);
final isActive = club.status == 'active';

return GestureDetector(
  onTap: () => controller.selectClub(club.id),
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
    ),
    child: Row(
      children: [

        // Left domain accent — 3px colored bar
        Container(
          width: 3,
          height: 44,
          decoration: BoxDecoration(
            color: dColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(width: 12),

        // Club name, domain, faculty
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + short code on same line
              Row(
                children: [
                  Expanded(
                    child: Text(
                      club.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Short code badge — uses domain color
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: dTint,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      club.shortCode,
                      style: TextStyle(
                        color: dColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Domain and faculty in small muted text
              Row(
                children: [
                  Text(
                    club.domain[0].toUpperCase() +
                        club.domain.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                  Text(
                    '  ·  ',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      club.facultyName,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.55),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Right side — status pill + arrow
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                // Status pill tints adapt to dark mode
                color: isActive
                    ? const Color(0xFF0F6E56).withOpacity(isDark ? 0.25 : 0.12)
                    : const Color(0xFF854F0B).withOpacity(isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF0F6E56)
                      : const Color(0xFF854F0B),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ],
    ),
  ),
);

}
}