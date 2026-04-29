// Import Flutter Material Design - this gives us widgets like TextField, Button, etc.
import 'package:flutter/material.dart';

// Import GetX - this lets us use Get.find and reactive state management
import 'package:get/get.dart';

// Import the AuthController - this manages login logic and state
import 'package:club_management_app/controllers/auth_controller.dart';
import 'package:club_management_app/controllers/request_status_controller.dart';
import 'package:club_management_app/views/auth/request_status_screen.dart';




// ============================================================================
// WHY StatefulWidget instead of GetView?
//
// GetView is a StatelessWidget under the hood.  StatelessWidgets have no
// lifecycle — specifically, they have no dispose() method.
//
// TextEditingController is a resource that holds a native text-editing
// buffer.  If it is never disposed, that buffer is never released — this is
// a memory leak that accumulates every time the login screen is shown.
//
// By using StatefulWidget we gain a dispose() method in the State class,
// which is called automatically by Flutter when the screen is removed from
// the widget tree.  We dispose both controllers there to release their
// native resources immediately.
//
// We still reach AuthController via Get.find<AuthController>() so we keep
// all the GetX reactive goodness without the lifecycle problem.
// ============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Look up the already-registered AuthController from GetX
  // This is equivalent to what GetView<AuthController>.controller gives us
  final AuthController _authController = Get.find<AuthController>();

  // TextEditingController manages the text buffer for the email field.
  // Creating it here (in State) ensures it lives exactly as long as the
  // screen does and is disposed when the screen is removed.
  final TextEditingController _emailController = TextEditingController();

  // Same as above for the password field
  final TextEditingController _passwordController = TextEditingController();

  // _formKey lets us call _formKey.currentState!.validate() to trigger all
  // TextFormField validators at once before submitting to Firebase
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // -----------------------------------------------------------------------
  // dispose() — called automatically by Flutter when this screen is removed
  // from the widget tree (e.g. after successful login, or back navigation).
  // Releasing these controllers here prevents the memory leak described above.
  // -----------------------------------------------------------------------
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // _submit() — validates inputs locally before hitting Firebase.
  //
  // Without validation the login button fires a network request even if
  // both fields are empty, which wastes bandwidth and returns a confusing
  // Firebase error message instead of a clear inline hint to the user.
  // -----------------------------------------------------------------------
  void _submit() {
    // validate() calls every TextFormField validator in the Form.
    // Returns true only when ALL validators return null (no errors).
    if (_formKey.currentState!.validate()) {
      _authController.login(
        _emailController.text.trim(), // trim() removes accidental leading/trailing spaces
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the theme's scaffold background so dark mode is respected.
    // The old code had backgroundColor: Colors.white which forced a white
    // background even when the user had dark mode switched on.
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            // Form widget wraps all TextFormFields so validate() works
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // --- TOP SECTION: App Title and Subtitle ---
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Club Manager',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          // Use the theme's onSurface color so the text is
                          // readable in both light and dark mode
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'VIT College — Staff Portal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),

                  // --- MIDDLE SECTION: Login Form in a Card ---
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // --- EMAIL FIELD ---
                          // TextFormField adds a validator callback that is
                          // triggered automatically by _formKey.currentState!.validate()
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next, // moves focus to password field
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            // Validator runs when _formKey.currentState!.validate() is called.
                            // Returning a String shows it as a red error below the field.
                            // Returning null means the field is valid.
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              // Basic email format check — catches obvious typos before
                              // sending a request to Firebase
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null; // valid
                            },
                          ),

                          const SizedBox(height: 16),

                          // --- PASSWORD FIELD ---
                          // Obx wraps only the password field so it rebuilds when
                          // showPassword toggles — the rest of the screen stays stable
                          Obx(
                            () => TextFormField(
                              controller: _passwordController,
                              obscureText: !_authController.showPassword.value,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(), // submit on keyboard "Done"
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      _authController.showPassword.toggle(),
                                  icon: Icon(
                                    _authController.showPassword.value
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null; // valid
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // --- LOGIN BUTTON / LOADING SPINNER ---
                          Obx(
                            () => _authController.isLoading.value
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- REQUEST ACCESS LINK ---
                  // New teachers or chairpersons who don't have an account yet
                  // can submit a request that the admin reviews before approving.
                    Column(
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // 1️⃣ REQUEST ACCESS (new users)
                        GestureDetector(
                          onTap: () => Get.toNamed('/register-request'),
                          child: const Text(
                            'Request Access',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 2️⃣ CHECK STATUS (existing requests)
                        Text(
                          'Already requested?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            Get.put(RequestStatusController());
                            Get.to(() => const RequestStatusScreen());
                          },
                          child: const Text(
                            'Check My Request Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}