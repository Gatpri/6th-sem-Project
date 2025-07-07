import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'signup.dart';
import 'admin_return_page.dart';
import 'package:http/http.dart' as http; //For calling your Node.js backend
import 'dart:convert'; //For encoding JSON
import 'forgot_password.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SigninApp());
}

class SigninApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void _login() async {
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.9:3000/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mobile": mobile,
          "password": password,
        }),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        //final userName = jsonData['firstname'];
        print('👤 Login response: $jsonData');

        // Clear text fields here
        _mobileController.clear();
        _passwordController.clear();


        if (context.mounted) {
          final userRole = jsonData['role'];
          final userName = jsonData['userName'] ?? '';
          final userMobile = jsonData['userMobile'] ?? '';

          if (context.mounted) {
            if (userRole == 'admin' || mobile == '9818091358') {
              // Navigate to AdminReturnPage with parameters
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminReturnPage(
                    adminMobile: userMobile,
                    adminName: userName,
                  ),
                ),
              );
            } else {
              // Regular user goes to HomePage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    userName: userName,
                    userMobile: userMobile,

                  /*  userName: jsonData['name'] ?? '',
                    userMobile: jsonData['mobile'] ?? '',*/
                  ),
                ),
              );
            }
          }


        }

        /*  if (context.mounted) {
            if (mobile == '9818091358') {
              // Navigate to AdminReturnPage for admin
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminReturnPage()),
              );
            } else {
              // Regular user goes to HomePage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage(
                  userName: jsonData['name'] ?? '',
                  userMobile: jsonData['mobile'] ?? '',
                )),
              );
            }
          }*/

      }

      /*tespachi ko
        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
  */
      /* yo saabai vanda suruko   if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Login Successful"),
              content: Text("Welcome, ${data['user']['firstName']}!"),
            ),
          );
          // Optionally navigate to homepage.dart
        }*/ else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Login Failed"),
            content: Text("Invalid credentials or user not found."),
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



  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ForgetPasswordPage()),
    );
  }


/*
  void _forgotPassword() {
    // Logic to handle "Forgot Password?" (for now just show a dialog)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Forgot Password"),
        content: Text("A password reset link has been sent to your email."),
      ),
    );
  }*/
  void _registerAccount() {
    // Logic to handle "Forgot Password?"
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignIn()),
    );
  }


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
                  TextField(
                    controller: _mobileController,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                    decoration: InputDecoration(
                      labelText: "Mobile Number",
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
                  SizedBox(height: 16), // Add some space between password and button
                  TextButton(
                    onPressed: _forgotPassword, // Show forgot password dialog
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.white70, // Link color
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline, // Underline the text
                      ),
                    ),
                  ),
                  SizedBox(height: 10),


                  ElevatedButton(
                    onPressed: _login,
                    child: Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,

                        )),
                  ),

                  TextButton(
                    onPressed: _registerAccount,

                    child: Text(
                      "Register For Free",
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),

                  ),

                ],

              ),
            ),
          ),
        ]
    );
  }
}






