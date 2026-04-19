// Import Flutter Material Design - this gives us widgets like TextField, Button, etc.
import 'package:flutter/material.dart';

// Import GetX - this lets us use GetView and reactive state management
import 'package:get/get.dart';

// Import the AuthController - this manages login logic and state
import 'package:club_management_app/controllers/auth_controller.dart';

// This is the LoginScreen widget - it's a GetX View for the login page
// 'GetView<AuthController>' means this screen automatically gets access to AuthController
// We don't need to manually create or pass the controller - GetX handles it
class LoginScreen extends GetView<AuthController> {
  // The constructor - this is called when the screen is created
  LoginScreen({super.key});

  // TextEditingController for the email field - this stores whatever the user types
  // We make it final because we don't change it after creating it
  final TextEditingController _emailController = TextEditingController();

  // TextEditingController for the password field - this stores the password text
  final TextEditingController _passwordController = TextEditingController();

  // This boolean tracks whether the password is visible or hidden
  // We start with false (password is hidden) - but actually this needs to be reactive
  // Let me reconsider - for this simple screen, we might need to use state
  // Actually, GetView can work with a StatelessWidget that uses controllers
  // But we need a way to toggle password visibility
  // Let me use the controller's reactive variables or create a local one

  @override
  Widget build(BuildContext context) {
    // 'Scaffold' is the basic structure of a Flutter screen
    // It provides app bars, floating buttons, drawers, and body layout
    return Scaffold(
      // Set the background color to white
      backgroundColor: Colors.white,

      // 'body' is the main content area of the screen
      body: SingleChildScrollView(
        // 'SingleChildScrollView' allows the content to scroll if it's too big
        // This is important if the keyboard pops up and covers content

        // 'SafeArea' adds padding to avoid system elements like status bar and notches
        child: SafeArea(
          // 'Padding' adds space around all sides of the content
          child: Padding(
            // 'EdgeInsets.all(20)' adds 20 pixels of padding on all sides
            padding: const EdgeInsets.all(20),

            // 'Column' arranges children vertically (top to bottom)
            child: Column(
              // 'mainAxisAlignment' controls vertical alignment
              // 'spaceBetween' spreads content to top and bottom
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              // 'crossAxisAlignment' controls horizontal alignment
              // 'center' centers content horizontally
              crossAxisAlignment: CrossAxisAlignment.center,

              // These are the children (widgets) inside the column
              children: [
                // --- TOP SECTION: App Title and Subtitle ---

                // 'Column' to hold title and subtitle together
                Column(
                  // Space children vertically with some gap between them
                  mainAxisSize: MainAxisSize.min,

                  // Center align all children
                  children: [
                    // App Name - "Club Manager"
                    // 'Text' widget displays text on screen
                    const Text(
                      'Club Manager', // The text to display
                      // 'style' controls how the text looks
                      style: TextStyle(
                        fontSize: 32, // Make the text big (32 pixels)
                        fontWeight: FontWeight.bold, // Make it bold (thick)
                        color: Colors.black87, // Dark color for contrast
                      ),
                    ),

                    // Add vertical space between title and subtitle
                    // 'SizedBox' is an invisible box that takes up space
                    const SizedBox(height: 8),

                    // Subtitle - "VIT College — Staff Portal"
                    const Text(
                      'VIT College — Staff Portal', // The subtitle text
                      style: TextStyle(
                        fontSize: 14, // Smaller text for subtitle
                        color: Colors.grey, // Grey color for subtle appearance
                        fontStyle: FontStyle.italic, // Italicize to make it distinct
                      ),
                    ),

                    // Add more space between header and login form
                    const SizedBox(height: 40),
                  ],
                ),

                // --- MIDDLE SECTION: Login Form in a Card ---

                // 'Card' creates a nice elevated white box with shadow
                Card(
                  // 'elevation' controls the shadow depth (higher = more shadow)
                  elevation: 2,

                  // 'shape' controls the corners of the card
                  shape: RoundedRectangleBorder(
                    // 'borderRadius' makes the corners rounded
                    borderRadius: BorderRadius.circular(12),
                  ),

                  // 'child' is the content inside the card
                  child: Padding(
                    // Add padding inside the card
                    padding: const EdgeInsets.all(24),

                    // 'Column' to arrange form fields vertically
                    child: Column(
                      // Space fields apart
                      mainAxisSize: MainAxisSize.min,

                      // Center fields horizontally
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      // Form fields go here
                      children: [
                        // --- EMAIL TEXT FIELD ---

                        // 'TextField' allows users to type text input
                        TextField(
                          // Link this field to the email controller
                          // The controller stores what the user types
                          controller: _emailController,

                          // Decorate the text field with borders, labels, etc.
                          decoration: InputDecoration(
                            // Label text appears above or inside the field
                            labelText: 'Email', // Label for the field

                            // Hint text appears as placeholder text
                            hintText: 'Enter your email', // Placeholder

                            // Border when field is not focused (not tapped)
                            border: OutlineInputBorder(
                              // Rounded corners for the border
                              borderRadius: BorderRadius.circular(8),
                            ),

                            // Border when field is focused (user is typing)
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              // Blue border when focused
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),

                            // Padding inside the text field
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),

                          // Keyboard type - show email keyboard
                          keyboardType: TextInputType.emailAddress,
                        ),

                        // Space between email and password fields
                        const SizedBox(height: 16),

                        // --- PASSWORD TEXT FIELD ---

                        // We need to track password visibility
                        // Since this is a StatelessWidget, we'll use a simpler approach
                        // Actually, GetView needs to be used with a controller or with State
                        // Let me make this work by using the controller for state management
                        // For now, I'll use a Obx to make it reactive with a controller variable

                        // First, let me assume the controller has a showPassword variable
                        // If not, we'll create it

                        Obx(
                          // 'Obx' watches reactive variables and rebuilds when they change
                          () => TextField(
                            // Link to the password controller
                            controller: _passwordController,

                            // 'obscureText' hides the text with dots/bullets
                            // If showPassword is true, show text; if false, show dots
                            obscureText: !controller.showPassword.value,
                            // We use '!' (not) because obscureText means "hide the text"
                            // So if showPassword is true, we want obscureText to be false (don't hide)

                            // Decoration for the password field
                            decoration: InputDecoration(
                              // Label text
                              labelText: 'Password',

                              // Hint text
                              hintText: 'Enter your password',

                              // Border when not focused
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),

                              // Border when focused
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),

                              // Padding inside the field
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),

                              // 'suffixIcon' is an icon button at the end of the field
                              // We use this for the show/hide password eye icon
                              suffixIcon: IconButton(
                                // When tapped, toggle password visibility
                                onPressed: () {
                                  // Toggle the showPassword state
                                  // '.toggle()' switches between true and false
                                  controller.showPassword.toggle();
                                },

                                // 'icon' is the icon to display
                                // Show different icons based on visibility
                                icon: Icon(
                                  // If password is visible, show eye icon; if hidden, show eye-off icon
                                  controller.showPassword.value
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            // Keyboard type - don't show keyboard suggestions for passwords
                            keyboardType: TextInputType.visiblePassword,
                          ),
                        ),

                        // Space between password field and login button
                        const SizedBox(height: 24),

                        // --- LOGIN BUTTON OR LOADING SPINNER ---

                        // 'Obx' watches the isLoading state and rebuilds when it changes
                        Obx(
                          // This callback runs whenever isLoading changes
                          () =>
                              // Check if still loading
                              controller.isLoading.value
                                  ? // If loading, show a circular progress indicator (spinner)
                                  // 'CircularProgressIndicator' is a spinning loader
                                  const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : // If not loading, show the login button
                                  // 'ElevatedButton' is a clickable button with elevation (shadow)
                                  ElevatedButton(
                                      // Called when user taps the button
                                      onPressed: () {
                                        // Call the login method on the controller
                                        // Pass the email and password from the text controllers
                                        controller.login(
                                          _emailController.text, // Get email text
                                          _passwordController
                                              .text, // Get password text
                                        );
                                      },

                                      // Style of the button
                                      style: ElevatedButton.styleFrom(
                                        // Background color
                                        backgroundColor: Colors.blue,

                                        // Padding inside the button
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),

                                        // Shape with rounded corners
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),

                                      // Text inside the button
                                      child: const Text(
                                        'Login', // Button label
                                        style: TextStyle(
                                          fontSize: 16, // Text size
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white, // White text
                                        ),
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- BOTTOM SECTION: Empty space for layout ---
                // This pushes the form up and centers it vertically
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Note: We don't need a dispose method here because GetView works with StatelessWidget
  // The TextEditingControllers will be garbage collected when the screen is removed
}