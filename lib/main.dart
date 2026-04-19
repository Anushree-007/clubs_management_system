// Import Flutter's Material Design package for UI components and widgets
import 'package:flutter/material.dart';

// Import Firebase Core for initializing Firebase services
import 'package:firebase_core/firebase_core.dart';

// Import Firebase options file (contains your Firebase configuration)
import 'firebase_options.dart';

// Import the App widget from the app.dart file in the lib/app directory
// This is the main app widget that sets up routing and dependencies
import 'app/app.dart';

// ============================================================================
// MAIN FUNCTION - Entry point of the Flutter application
// ============================================================================

// This is the entry point of your Flutter app. It must be async because
// Firebase initialization is an asynchronous operation (takes time to complete).
void main() async {
  // Ensure that the Flutter engine is fully initialized before Firebase starts.
  // This is required before calling Firebase.initializeApp() to avoid crashes.
  // 'WidgetsFlutterBinding.ensureInitialized()' tells Flutter to set up properly first.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with your project configuration from firebase_options.dart.
  // This connects your app to Firebase services like Firestore, Authentication, etc.
  // The 'await' keyword makes the app wait for Firebase to finish initializing.
  // Without 'await', the app might try to use Firebase before it's ready.
  await Firebase.initializeApp(
    // Pass the Firebase options for the current platform (iOS, Android, web, etc.)
    // 'DefaultFirebaseOptions.currentPlatform' automatically picks the right config
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the App widget once Firebase is fully initialized.
  // The app will now display the App widget on the screen.
  // 'runApp()' is Flutter's function that starts the app and shows the root widget.
  runApp(
    // Create an instance of App (the root widget of the entire application)
    // 'const' means this widget never changes, so Flutter can optimize it
    const App(),
  );
}
