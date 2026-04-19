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

// Import the ComingSoonScreen - this is a placeholder for not yet implemented features
import 'package:club_management_app/views/clubs/coming_soon_screen.dart';

// Import the event screens we just built
import 'package:club_management_app/views/events/event_list_screen.dart';
import 'package:club_management_app/views/events/event_detail_screen.dart';
import 'package:club_management_app/views/events/event_form_screen.dart';

// Import the EventController
import 'package:club_management_app/controllers/event_controller.dart';

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
  }
}

// This is the main App widget - it sets up the entire Flutter application
// 'StatelessWidget' means this widget doesn't change over time
class App extends StatelessWidget {
  // The constructor - this is called when the app is created
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // 'GetMaterialApp' is like MaterialApp but with GetX features
    // It provides routing, navigation, and dependency injection
    return GetMaterialApp(
      // 'title' is the name of the app shown in the device switcher
      title: 'Club Management App',

      // 'debugShowCheckedModeBanner' hides the debug banner in debug mode
      // Set to false to remove the "DEBUG" banner in the top right corner
      debugShowCheckedModeBanner: false,

      // 'theme' controls the overall look and feel of the app
      theme: ThemeData(
        // 'primarySwatch' sets the main color scheme of the app
        primarySwatch: Colors.blue,

        // 'useMaterial3' enables Material Design 3 (the latest design system)
        useMaterial3: true,
      ),

      // 'initialRoute' is the first screen shown when the app starts
      // '/login' means it will show the login screen first
      initialRoute: '/login',

      // 'getPages' defines all the named routes in the app
      // Each route has a name (like '/login') and a page (the screen widget)
      getPages: [
        // This is the login route
        // 'name' is the route name used for navigation
        GetPage(
          name: '/login',
          // 'page' is the widget (screen) to show for this route
          page: () => LoginScreen(),
        ),

        // This is the dashboard route
        GetPage(
          name: '/dashboard',
          // 'page' is the widget (screen) to show for this route
          page: () => DashboardScreen(),
        ),

        // This is the club profile route
        GetPage(
          name: '/club-profile',
          page: () => ClubProfileScreen(),
        ),

        // This is the club edit route
        GetPage(
          name: '/club-edit',
          page: () => ClubEditScreen(),
        ),

        // Placeholder routes for club sub-features
        GetPage(
          name: '/club-members',
          page: () => ComingSoonScreen(title: 'Club Members'),
        ),

        GetPage(
          name: '/club-events',
          page: () => ComingSoonScreen(title: 'Club Events'),
        ),

        GetPage(
          name: '/club-documents',
          page: () => ComingSoonScreen(title: 'Club Documents'),
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
      ],

      // 'initialBinding' sets up the initial dependencies when the app starts
      // This puts the AuthController and ClubController into memory so they can be used throughout the app
      initialBinding: InitialBindings(),
    );
  }
}