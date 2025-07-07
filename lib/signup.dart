import 'package:flutter/material.dart';
import 'main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async{
  runApp(SignIn());
}

class SignIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignupPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmpasswordController = TextEditingController();

  //ADDED: Variables for hiding/showing passwords
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  void _signup() async {

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmpasswordController.text.trim();
    if (password != confirmPassword) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Password Mismatch"),
          content: Text("Passwords do not match. Please try again."),
        ),
      );
      return;
    }

    try {
      final url = Uri.parse("http://192.168.1.9:3000/register"); // 🔥 CHANGED: Replace with actual IP:PORT
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "mobile": mobile,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Signup Successful"),
            content: Text("Account created successfully."),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Signup Failed"),
            content: Text("Error: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Connection Error"),
          content: Text("Could not connect to the server.\n$e"),
        ),
      );
    }
  }





    /*
    // No backend logic here — just showing a dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Signup Info"),
        content: Text("Mobile: $mobile\nEmail: $email\nPassword: $password\nPassword: $password"),
      ),
    );
  }*/
  void _existingAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // ✅ NEW: Navigates to LoginPage from main.dart
    );
  }
/*
    // Call the Firestore function to save data
    await BackendService.saveUserDataToFirestore(firstName, lastName, mobile, email, password);

    // showing a dialog
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: Text("Signup Info"),
            content: Text("User data saved to Firestore!"),
          ),
    );
  }

  void _existingAccount() {
    // Logic to handle "Already Have An Account" (for now just show a dialog)
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: Text("Already Have An Account?"),
            content: Text("Redirecting To Signup Page..."),
          ),
    );
  }
*/

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Opacity(
            opacity: 1, // Adjust this as needed
            child: Image.asset(
              "assets/images/digital.png",
              fit: BoxFit.cover,

            ),
          ),
        ),


        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight + 200),
            // Increase height slightly
            child: SafeArea(
              top: false, // Prevent SafeArea from pushing it back up
              child: Container(
                margin: EdgeInsets.only(top: 180), // Move AppBar down
                child: AppBar(
                  centerTitle: true,
                  backgroundColor: Colors.deepPurpleAccent,
                  title: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    // Push text a bit downward
                    child: Text(
                      "SM WALLET",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 50,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Padding(

            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameController,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                        decoration: InputDecoration(
                          labelText: "First Name",
                          labelStyle: TextStyle(fontSize: 25),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _lastNameController,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                        decoration: InputDecoration(
                          labelText: "Last Name",
                          labelStyle: TextStyle(fontSize: 25),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _mobileController,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                  decoration: InputDecoration(
                    labelText: "Number",
                    labelStyle: TextStyle(fontSize: 25), // Bigger label
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                  decoration: InputDecoration(
                    labelText: "example@gmail.com",
                    labelStyle: TextStyle(fontSize: 25), // Bigger label
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(fontSize: 25), // Bigger label
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                ),
                SizedBox(height: 16),
                TextField(
                  controller: _confirmpasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    labelStyle: TextStyle(fontSize: 25), // Bigger label
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                        });
                      },
                    ),

                  ),
                ),
                SizedBox(height: 16),
                // Add some space between password and button
                TextButton(
                  onPressed: _existingAccount, // Show Existing Account dialog
                  child: Text(
                    "Already Have An account?",
                    style: TextStyle(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline, // Underline the text
                    ),
                  ),
                ),
                SizedBox(height: 10),


                ElevatedButton(
                  onPressed: _signup,
                  child: Text("Continue"),
                ),

              ],
            ),
          ),
        ),
      ],
    );
  }
}