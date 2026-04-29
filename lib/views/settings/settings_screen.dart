import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:club_management_app/controllers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // isDarkMode is created OUTSIDE build() so it persists correctly
  // This is the fix — creating it here means it is created once only
  static final _box = GetStorage();
  static final RxBool isDarkMode =
      RxBool(_box.read('isDarkMode') ?? false);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Obx(() {
        final user = authController.currentUser.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ---- USER INFO CARD ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            user?.role.toUpperCase() ?? '',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'APPEARANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              // Obx here watches isDarkMode correctly now
              child: Obx(() => SwitchListTile(
                    secondary: Icon(
                      isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
                      color:
                          isDarkMode.value ? Colors.indigo : Colors.orange,
                    ),
                    title: const Text('Dark Mode'),
                    subtitle: Text(
                      isDarkMode.value
                          ? 'Dark theme is on'
                          : 'Light theme is on',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isDarkMode.value,
                    onChanged: (value) {
                      // Update reactive variable
                      isDarkMode.value = value;
                      // Save to local storage
                      _box.write('isDarkMode', value);
                      // Change app theme immediately
                      Get.changeThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  )),
            ),

            const SizedBox(height: 24),

            const Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Sign out of your account'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout?'),
                      content: const Text(
                          'Are you sure you want to sign out?'),
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
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            const Center(
              child: Text(
                'Club Manager v1.0.0\nVishwakarma Institute of Technology',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }),
    );
  }
}