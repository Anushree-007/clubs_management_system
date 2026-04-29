// Import the Firebase Auth package - this gives us access to Firebase authentication features
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// This is the AuthService class - it handles all user authentication (login/logout) operations
// We put all auth-related code here to keep it organized and reusable across the app
class AuthService {
  // This is a private variable that holds a reference to Firebase Authentication
  // The underscore (_) at the start means it's private - only this class can use it
  // We use 'late' keyword because we'll initialize it immediately after declaring it
  late final FirebaseAuth _auth;

  // This is the constructor - it runs when we create a new AuthService object
  // The constructor initializes Firebase Auth when the class is first created
  AuthService() {
    // 'FirebaseAuth.instance' gets the Firebase Authentication instance
    // This is a singleton, meaning there's only one instance for the whole app
    _auth = FirebaseAuth.instance;
  }

  // This method allows someone to sign in with email and password
  // It takes two parameters: email and password (both are Strings)
  // 'Future<UserCredential>' means this method takes time to complete (it's async)
  // and will eventually return a UserCredential object when done
  Future<UserCredential> signIn(String email, String password) async {
    // The 'async' keyword means this method can do slow operations without blocking the UI
    // 'try' block - we attempt to do something that might fail (like network request)
    try {
      // This calls Firebase to sign in the user with their email and password
      // It sends the credentials to Firebase servers to verify them
      // The 'await' keyword waits for Firebase to respond before continuing
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        // 'email:' - we pass the email parameter that was provided
        email: email,
        // 'password:' - we pass the password parameter that was provided
        password: password,
      );
      // If sign in was successful, return the UserCredential object
      // This object contains information about the signed-in user
      return userCredential;
    }
    // 'catch' block - if something goes wrong in the try block, we catch the error
    catch (e) {
      // If there's any error (wrong password, user not found, network error, etc.)
      // we re-throw it so the calling code can handle it
      // 're-throw' means we throw the error again for the caller to catch
      rethrow;
    }
  }

  // This method signs out the currently logged-in user
  // 'Future<void>' means this takes time to complete but doesn't return any value
  Future<void> signOut() async {
    // The 'async' keyword means this can do slow operations
    // 'try' block - attempt to sign out (which might fail for some reason)
    try {
      // This calls Firebase to sign out the current user
      // It clears the user's authentication token and session
      // 'await' waits for Firebase to complete the sign out operation
      await _auth.signOut();
    }
    // 'catch' block - if sign out fails for some reason, handle the error
    catch (e) {
      // If there's any error during sign out, re-throw it
      rethrow;
    }
  }

  // This method returns the currently logged-in user
  // 'User?' means this returns either a User object or null (nothing)
  // The '?' is called a "nullable type" - it means the value can be null
  User? getCurrentUser() {
    // 'FirebaseAuth.instance.currentUser' gets the currently logged-in user
    // If nobody is logged in, this returns null
    // If someone is logged in, it returns their User object with info like email, uid, etc.
    return _auth.currentUser;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // createUser — called by the admin when approving a registration request.
  //
  // WHY we use a secondary FirebaseAuth instance:
  //   FirebaseAuth.createUserWithEmailAndPassword() signs in the newly
  //   created user immediately, which would boot the admin out of their
  //   own session.  By initialising a separate Firebase App just for this
  //   operation and deleting it afterward, the admin's session is completely
  //   unaffected.
  //
  // The returned uid is stored on the Firestore user profile document so
  // getUser(uid) works as soon as the new user logs in.
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> createUser(String email, String password) async {
    // Import is at the top of the file (firebase_auth already imported).
    // We use a secondary app so the admin's current session is not replaced.
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!.uid;
    } finally {
      // Always delete the temporary app — even if creation failed —
      // to avoid accumulating leaked Firebase app instances.
      await secondaryApp.delete();
    }
  }
}