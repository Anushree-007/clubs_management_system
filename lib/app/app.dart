// Import Flutter Material Design - this gives us the MaterialApp and other UI components
import 'package:flutter/material.dart';

// Import GetX - this provides GetMaterialApp, routing, and dependency injection
import 'package:get/get.dart';

// Import the AuthController - this manages authentication state and logic
import 'package:club_management_app/controllers/auth_controller.dart';

// Import the ClubController - this manages club data and actions
import 'package:club_management_app/controllers/club_controller.dart';

// Import the MemberController - this manages member list and form state
import 'package:club_management_app/controllers/member_controller.dart';

// Import the LoginScreen - this is the screen users see when they need to log in
import 'package:club_management_app/views/auth/login_screen.dart';

// Import the DashboardScreen - this is the main app screen after login
import 'package:club_management_app/views/dashboard/dashboard_screen.dart';

// Import the ClubProfileScreen - this shows details for a selected club
import 'package:club_management_app/views/clubs/club_profile_screen.dart';

// Import the ClubEditScreen - this is the screen for editing club information
import 'package:club_management_app/views/clubs/club_edit_screen.dart';

// Import the MemberListScreen - this shows members for the current club and tenure
import 'package:club_management_app/views/members/member_list_screen.dart';

// Import the MemberFormScreen - this is the add/edit member form screen
import 'package:club_management_app/views/members/member_form_screen.dart';


// Import the event screens we just built
import 'package:club_management_app/views/events/event_list_screen.dart';
import 'package:club_management_app/views/events/event_detail_screen.dart';
import 'package:club_management_app/views/events/event_form_screen.dart';

// Import the EventController
import 'package:club_management_app/controllers/event_controller.dart';

import 'package:club_management_app/views/finance/finance_detail_screen.dart';
import 'package:club_management_app/views/finance/finance_form_screen.dart';
import 'package:club_management_app/controllers/finance_controller.dart';

import 'package:club_management_app/views/resources/resource_list_screen.dart';
import 'package:club_management_app/views/resources/booking_request_screen.dart';
import 'package:club_management_app/controllers/resource_controller.dart';

import 'package:get_storage/get_storage.dart';
// import 'package:club_management_app/views/clubs/club_documents_screen.dart';
import 'package:club_management_app/views/reports/report_screen.dart';
import 'package:club_management_app/views/settings/settings_screen.dart';
import 'package:club_management_app/views/auth/register_request_screen.dart';
import 'package:club_management_app/views/admin/admin_requests_screen.dart';
import 'package:club_management_app/views/admin/admin_club_form_screen.dart';
import 'package:club_management_app/views/auth/request_status_screen.dart';
// import 'package:club_management_app/controllers/document_controller.dart';
import 'package:club_management_app/controllers/user_request_controller.dart';
import 'package:club_management_app/theme/app_theme.dart';

// This is the InitialBindings class - it sets up dependencies when the app starts
// 'Bindings' is a GetX class that helps put controllers into memory
class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // 'Get.put()' puts the AuthController into GetX's dependency injection system
    // This means the AuthController is created once and can be accessed anywhere in the app
    // 'permanent: true' means it stays in memory even when not being used
    Get.put(AuthController(), permanent: true);

    // Also put the ClubController into GetX so it is available when the app starts
    Get.put(ClubController(), permanent: true);

    // Also put the MemberController into GetX so member screens can use it
    Get.put(MemberController(), permanent: true);

    // This registers EventController so GetX can find it anywhere in the app
    // It is created once when the app starts and stays alive throughout
    Get.put(EventController());

    // Register FinanceController so GetX can find it anywhere
    Get.put(FinanceController());

    // Register ResourceController so GetX can find it anywhere
    Get.put(ResourceController());

    // Register DocumentController so GetX can find it anywhere
    // Get.put(DocumentController());

    // Register UserRequestController so the registration request flow and
    // admin approval screen can both access it from anywhere in the app.
    // permanent: true keeps it alive for the full app session so the pending
    // badge count on the dashboard stays accurate without re-fetching.
    Get.put(UserRequestController(), permanent: true);
  }
}

// This is the main App widget - it sets up the entire Flutter application
// 'StatelessWidget' means this widget doesn't change over time
class App extends StatelessWidget {
  // The constructor - this is called when the app is created
  const App({super.key});

  // Read the saved theme preference ONCE at class level, not inside build().
  //
  // When this was inside build(), GetStorage was read on every rebuild
  // (e.g. every time the theme changed or a dependency updated).  A
  // class-level static field is initialized once when the class is first
  // loaded and the value never changes after that — because Get.changeThemeMode()
  // in SettingsScreen handles all live theme changes from that point on.
  static final _savedTheme =
      GetStorage().read<bool>('isDarkMode') ?? false;

  @override
  Widget build(BuildContext context) {
    // 'GetMaterialApp' is like MaterialApp but with GetX features
    // It provides routing, navigation, and dependency injection
    return GetMaterialApp(
      title: 'Club Management App',
  debugShowCheckedModeBanner: false,

theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,

  // Set the theme mode based on saved preference
  // If user had dark mode on last time, start with dark mode
  themeMode: _savedTheme ? ThemeMode.dark : ThemeMode.light,

  initialRoute: '/login',

      // 'getPages' defines all the named routes in the app
      // Each route has a name (like '/login') and a page (the screen widget)
      getPages: [
        // This is the login route
        // 'name' is the route name used for navigation
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
        ),

        // This is the dashboard route
        GetPage(
          name: '/dashboard',
          // 'page' is the widget (screen) to show for this route
          page: () => const DashboardScreen(),
        ),

        // This is the club profile route
        GetPage(
          name: '/club-profile',
          page: () => const ClubProfileScreen(),
        ),

        // This is the club edit route
        GetPage(
          name: '/club-edit',
          page: () => ClubEditScreen(),
        ),

        // Member screens for listing and adding/editing members
        GetPage(
          name: '/members',
          page: () => MemberListScreen(),
        ),
        GetPage(
          name: '/member-form',
          page: () => MemberFormScreen(),
        ),

        // Event List — shows all events for a club
        GetPage(
          name: '/events',
          page: () => const EventListScreen(),
        ),

        // Event Detail — shows full info of one selected event
        GetPage(
          name: '/event-detail',
          page: () => const EventDetailScreen(),
        ),

        // Event Form — handles both add and edit event
        GetPage(
          name: '/event-form',
          page: () => const EventFormScreen(),
        ),

        


        GetPage(
        name: '/finance-detail',
        page: () => const FinanceDetailScreen(),
      ),

      GetPage(
        name: '/finance-form', 
        page: () => const FinanceFormScreen()
      ),

      GetPage(
        name: '/resources', 
        page: () => const ResourceListScreen()
        ),
      
      GetPage(
        name: '/booking-request', 
        page: () => const BookingRequestScreen()
    ),

      // GetPage(
      //   name: '/club-documents', 
      //   page: () => const ClubDocumentsScreen()
      //   ),

      GetPage(
        name: '/reports', 
        page: () => const ReportScreen()
        ),

      GetPage(
        name: '/settings', 
        page: () => const SettingsScreen()
        ),

      // Registration request — accessible before login so new users can apply
      GetPage(
        name: '/register-request',
        page: () => const RegisterRequestScreen(),
      ),

      // Admin requests panel — teachers only (role guard is inside the screen)
      GetPage(
        name: '/admin-requests',
        page: () => const AdminRequestsScreen(),
      ),

      // Check request status — accessible before login so applicants can
      // see whether they were approved or rejected without contacting the admin
      GetPage(
        name: '/check-status',
        page: () => const RequestStatusScreen(),  // was CheckStatusScreen
      ),

      GetPage(
      name: '/admin-club-form',
      page: () => const AdminClubFormScreen(),
    ),
      ],

      // 'initialBinding' sets up the initial dependencies when the app starts
      // This puts the AuthController and ClubController into memory so they can be used throughout the app
      initialBinding: InitialBindings(),
    );
  }
}