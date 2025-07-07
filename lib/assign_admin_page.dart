import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssignAdminPage extends StatefulWidget {
  final String adminMobile;
  final String adminName;

  const AssignAdminPage({
    Key? key,
    required this.adminMobile,
    required this.adminName,
  }) : super(key: key);

  @override
  State<AssignAdminPage> createState() => _AssignAdminPageState();
}

class _AssignAdminPageState extends State<AssignAdminPage> {
  final _targetMobileController = TextEditingController();

  Future<void> _assignAdmin() async {
    final target = _targetMobileController.text.trim();
    if (target.isEmpty) {
      _showDialog("Error", "Enter target mobile number.");
      return;
    }

    final response = await http.post(
      Uri.parse('http://192.168.1.9:3000/assign-admin'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "requesterMobile": widget.adminMobile,
        "targetMobile": target,
      }),
    );

    final data = jsonDecode(response.body);
    _showDialog("Assign Admin", data['message']);
  }

  Future<void> _removeAdmin() async {
    final target = _targetMobileController.text.trim();
    if (target.isEmpty) {
      _showDialog("Error", "Enter target mobile number.");
      return;
    }

    final response = await http.post(
      Uri.parse('http://192.168.1.9:3000/remove-admin'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "requesterMobile": widget.adminMobile,
        "targetMobile": target,
      }),
    );

    final data = jsonDecode(response.body);
    _showDialog("Remove Admin", data['message']);
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _targetMobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assign or Remove Admin"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Logged in as: ${widget.adminName} (${widget.adminMobile})',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _targetMobileController,
              decoration: InputDecoration(labelText: "Target Mobile Number"),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _assignAdmin,
                    child: Text("Assign Admin"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _removeAdmin,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("Remove Admin"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to AdminReturnPage
              },
              child: Text("Back to Admin Return Page"),
            ),
          ],
        ),
      ),
    );
  }
}
