import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pin_code_fields/pin_code_fields.dart';

class SendMoneyPage extends StatefulWidget {
  final String senderMobile; // logged-in user's mobile
  final String userName;

  SendMoneyPage({
    required this.senderMobile,
    required this.userName,
  });

  @override
  _SendMoneyPageState createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  final TextEditingController _receiverMobileController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  void _sendMoney() async {
    final senderMobile = widget.senderMobile;
    final receiverMobile = _receiverMobileController.text.trim();
    final amount = _amountController.text.trim();

    if (receiverMobile.isEmpty || amount.isEmpty) {
      _showAlert("Error", "Please fill in all fields.");
      return;
    }

    // Show dialog to enter PIN
    final enteredPin = await _promptForPIN();
    if (enteredPin == null || enteredPin.isEmpty) {
      _showAlert("Cancelled", "Transaction was cancelled.");
      return;
    }

    final url = Uri.parse('http://192.168.1.9:3000/send-money');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderMobile': senderMobile,
          'receiverMobile': receiverMobile,
          'amount': amount,
          'transactionPin': enteredPin, // send raw PIN for backend bcrypt match
        }),
      );

      if (response.statusCode == 200) {
        _showAlert("Success", "Money sent successfully!");
        _receiverMobileController.clear();
        _amountController.clear();
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? response.body;
        _showAlert("Failed", "Error: $errorMsg");
      }
    } catch (e) {
      _showAlert("Connection Error", "Could not connect to the server.\n$e");
    }
  }

  Future<String?> _promptForPIN() async {
    final TextEditingController pinController = TextEditingController();
    bool obscurePin = true;
    Color pinFieldColor = Colors.blue;

    return await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enter Transaction PIN",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    obscureText: obscurePin,
                    animationType: AnimationType.fade,
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeColor: pinFieldColor,
                      selectedColor: pinFieldColor,
                      inactiveColor: pinFieldColor.withOpacity(0.5),
                    ),
                    onChanged: (value) {
                      setState(() {
                        pinFieldColor = value.length < 4 ? Colors.red : Colors.green;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          obscurePin ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[700],
                        ),
                        label: Text(obscurePin ? "Show PIN" : "Hide PIN"),
                        onPressed: () {
                          setState(() {
                            obscurePin = !obscurePin;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (pinController.text.length != 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Please enter a 4-digit PIN.")),
                            );
                            return;
                          }
                          Navigator.pop(context, pinController.text.trim());
                        },
                        child: Text("Confirm"),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _receiverMobileController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send Money")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _receiverMobileController,
              decoration: InputDecoration(labelText: "Receiver Mobile",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)

              ),
              keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 20)
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: "Amount",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 20)

            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sendMoney,
              child: Text("Send"),
            ),
          ],
        ),
      ),
    );
  }
}
