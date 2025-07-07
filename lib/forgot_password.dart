import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgetPasswordPage extends StatefulWidget {
  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitRequest() async {
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();

    if (mobile.isEmpty || email.isEmpty) {
      _showDialog("Input Error", "Please enter both mobile number and email.");
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse("http://192.168.1.9:3000/forgot-password");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showDialog("Success", data['message']);
      } else {
        _showDialog("Error", data['error'] ?? 'Failed to process request.');
      }
    } catch (e) {
      _showDialog("Error", "Failed to connect to server: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _mobileController,
              decoration: InputDecoration(labelText: "Mobile Number"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email Address"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Send Reset Link / OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
