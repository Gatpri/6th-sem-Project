import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pin_code_fields/pin_code_fields.dart';

class SettingsPage extends StatefulWidget {
  final String userMobile;
  final String userName;

  const SettingsPage({
    Key? key,
    required this.userMobile,
    required this.userName,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _currentPinController = TextEditingController();

  bool _hasPin = false;
  bool _showPinForm = false;
  bool _obscurePin = true;

  // Dynamic PIN field colors
  Color _currentPinColor = Colors.blue;
  Color _newPinColor = Colors.blue;
  Color _confirmPinColor = Colors.blue;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _currentPinController.dispose();
    super.dispose();
  }

  Future<void> _checkIfPinExists() async {
    final response = await http.post(
      Uri.parse("http://192.168.1.9:3000/check-transaction-pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile": widget.userMobile}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _hasPin = data['hasPin'] ?? false;
        _showPinForm = true;
      });
    }
  }

  Future<void> _createTransactionPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || confirmPin.length != 4) {
      _showDialog("Error", "PIN must be 4 digits.");
      return;
    }
    if (pin != confirmPin) {
      _showDialog("Error", "PINs do not match.");
      return;
    }

    final response = await http.post(
      Uri.parse("http://192.168.1.9:3000/set-transaction-pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile": widget.userMobile, "pin": pin}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      _showDialog("Success", data['message']);
      _pinController.clear();
      _confirmPinController.clear();
      setState(() {
        _hasPin = true;
        _showPinForm = false;
      });
    } else {
      _showDialog("Error", data['message'] ?? 'Something went wrong');
    }
  }

  Future<void> _changeTransactionPin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _pinController.text.trim();
    final confirmNewPin = _confirmPinController.text.trim();

    if ([currentPin, newPin, confirmNewPin].any((p) => p.length != 4)) {
      _showDialog("Error", "All PINs must be 4 digits.");
      return;
    }

    if (newPin != confirmNewPin) {
      _showDialog("Error", "New PINs do not match.");
      return;
    }

    final response = await http.post(
      Uri.parse("http://192.168.1.9:3000/change-transaction-pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "mobile": widget.userMobile,
        "currentPin": currentPin,
        "newPin": newPin,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      _showDialog("Success", data['message']);
      _currentPinController.clear();
      _pinController.clear();
      _confirmPinController.clear();
      setState(() => _showPinForm = false);
    } else {
      _showDialog("Error", data['message'] ?? 'Failed to change PIN');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Logged in as: ${widget.userName} (${widget.userMobile})",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: _checkIfPinExists,
              child: Text("Transaction PIN Settings"),
            ),
            SizedBox(height: 15),

            if (_showPinForm)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasPin ? "Change Transaction PIN" : "Create Transaction PIN",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  SizedBox(height: 15),

                  if (_hasPin) ...[
                    Text("Enter Current PIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    PinCodeTextField(
                      appContext: context,
                      length: 4,
                      obscureText: _obscurePin,
                      controller: _currentPinController,
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 40,
                        activeColor: _currentPinColor,
                        selectedColor: _currentPinColor,
                        inactiveColor: _currentPinColor,
                      ),

                      onChanged: (value) {
                        setState(() {
                          _currentPinColor = value.length < 4 ? Colors.red : Colors.green;
                        });
                      },
                    ),
                  ],

                  Text(_hasPin ? "Enter New PIN" : "Enter 4-digit PIN",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    obscureText: _obscurePin,
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeColor: _newPinColor,
                      selectedColor: _newPinColor,
                      inactiveColor: _newPinColor,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _newPinColor = value.length < 4 ? Colors.red : Colors.green;
                      });
                    },
                  ),

                  Text(_hasPin ? "Confirm New PIN" : "Confirm PIN",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    obscureText: _obscurePin,
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeColor: _confirmPinColor,
                      selectedColor: _confirmPinColor,
                      inactiveColor: _confirmPinColor,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _confirmPinColor = value.length < 4 ? Colors.red : Colors.green;
                      });
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePin = !_obscurePin;
                        });
                      },
                    ),
                  ),

                  ElevatedButton(
                    onPressed: _hasPin ? _changeTransactionPin : _createTransactionPin,
                    child: Text(_hasPin ? "Change PIN" : "Create PIN"),
                  ),
                ],
              ),

            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }
}









/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pin_code_fields/pin_code_fields.dart';
//import 'package:crypto/crypto.dart'; // for hashing PIN if needed

class SettingsPage extends StatefulWidget {
  final String userMobile;
  final String userName;

  const SettingsPage({
    Key? key,
    required this.userMobile,
    required this.userName,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _currentPinController = TextEditingController();

  bool _hasPin = false;
  bool _showPinForm = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _currentPinController.dispose();
    super.dispose();
  }

  Future<void> _checkIfPinExists() async {
    final response = await http.post(
      Uri.parse("http://192.168.1.9:3000/check-transaction-pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile": widget.userMobile}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _hasPin = data['hasPin'] ?? false;
        _showPinForm = true; // Show the form once we know the state
      });
    }
  }

  Future<void> _createTransactionPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || confirmPin.length != 4) {
      _showDialog("Error", "PIN must be 4 digits.");
      return;
    }
    if (pin != confirmPin) {
      _showDialog("Error", "PINs do not match.");
      return;
    }

    final response = await http.post(
      Uri.parse("http://192.168.1.9:3000/set-transaction-pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile": widget.userMobile, "pin": pin}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      _showDialog("Success", data['message']);
      _pinController.clear();
      _confirmPinController.clear();
      setState(() {
        _hasPin = true;
        _showPinForm = false;
      });
    } else {
      _showDialog("Error", data['message'] ?? 'Something went wrong');
    }
  }

  Future<void> _changeTransactionPin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _pinController.text.trim();
    final confirmNewPin = _confirmPinController.text.trim();

    if ([currentPin, newPin, confirmNewPin].any((p) => p.length != 4)) {
      _showDialog("Error", "All PINs must be 4 digits.");
      return;
    }

    if (newPin != confirmNewPin) {
      _showDialog("Error", "New PINs do not match.");
      return;
    }

    final response = await http.post(
      Uri.parse("http://192.168.1.9:3000/change-transaction-pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "mobile": widget.userMobile,
        "currentPin": currentPin,
        "newPin": newPin,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      _showDialog("Success", data['message']);
      _currentPinController.clear();
      _pinController.clear();
      _confirmPinController.clear();
      setState(() => _showPinForm = false);
    } else {
      _showDialog("Error", data['message'] ?? 'Failed to change PIN');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Logged in as: ${widget.userName} (${widget.userMobile})", style: TextStyle(fontSize: 16)),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: _checkIfPinExists,
              child: Text("Transaction PIN Settings"),
            ),
            SizedBox(height: 10),



            if (_showPinForm)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasPin ? "Create Transaction PIN" : "Create Transaction PIN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  if (_hasPin)
                    PinCodeTextField(
                      appContext: context,
                      length: 4,
                      obscureText: true,
                      controller: _currentPinController,
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 40,
                        activeFillColor: Colors.white,
                      ),
                      onChanged: (_) {},
                    ),
                  Text(
                    _hasPin ? "Enter New Transaction PIN" : "Enter New Transaction PIN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    obscureText: true,
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                    ),
                    onChanged: (_) {},
                  ),
                  Text(
                    _hasPin ? "Confirm Transaction PIN" : "Confirm Transaction PIN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    obscureText: true,
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                    ),
                    onChanged: (_) {},
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _hasPin ? _changeTransactionPin : _createTransactionPin,
                    child: Text(_hasPin ? "Change PIN" : "Create PIN"),
                  ),
                ],
              ),





/*
            if (_showPinForm)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasPin ? "Change Transaction PIN" : "Create Transaction PIN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  if (_hasPin)
                    TextField(
                      controller: _currentPinController,
                      obscureText: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Enter Current PIN"),
                    ),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: _hasPin ? "Enter New PIN" : "Enter 4-digit PIN"),
                  ),
                  TextField(
                    controller: _confirmPinController,
                    obscureText: true,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: _hasPin ? "Confirm New PIN" : "Confirm PIN"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _hasPin ? _changeTransactionPin : _createTransactionPin,
                    child: Text(_hasPin ? "Change PIN" : "Create PIN"),
                  ),
                ],
              ),*/

            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }
}

*/
