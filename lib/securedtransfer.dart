import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SecuredTransferPage extends StatefulWidget {
  final String senderMobile;
  final String userName;

  const SecuredTransferPage({
    required this.senderMobile,
    required this.userName,
    Key? key,
  }) : super(key: key);

  @override
  _SecuredTransferPageState createState() => _SecuredTransferPageState();
}

class _SecuredTransferPageState extends State<SecuredTransferPage> {
  final _receiverController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isHold = false;
  DateTime? _releaseDate;

  Future<void> _selectReleaseDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _releaseDate = picked;
      });
    }
  }

  Future<String?> _promptForPIN() async {
    final TextEditingController _pinController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enter Transaction PIN"),
        content: TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(letterSpacing: 32),
          decoration: InputDecoration(
            labelText: "Transaction PIN",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _pinController.text.trim()),
            child: Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _submitTransfer() async {
    final receiver = _receiverController.text.trim();
    final amount = _amountController.text.trim();

    if (receiver.isEmpty || amount.isEmpty) {
      _showAlert("Error", "Please fill in all fields.");
      return;
    }

    if (_isHold && _releaseDate == null) {
      _showAlert("Error", "Please select a release date for held transfer.");
      return;
    }

    final enteredPin = await _promptForPIN();
    if (enteredPin == null || enteredPin.isEmpty) {
      _showAlert("Cancelled", "Transaction was cancelled.");
      return;
    }

    final url = Uri.parse('http://192.168.1.9:3000/secure-transfer');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderMobile': widget.senderMobile,
          'receiverMobile': receiver,
          'amount': amount,
          'hold': _isHold,
          'releaseDate': _isHold ? _releaseDate!.toIso8601String() : null,
          'transactionPin': enteredPin,
        }),
      );

      if (response.statusCode == 200) {
        _showAlert("Success", "Money transferred securely.");
        _receiverController.clear();
        _amountController.clear();
        setState(() {
          _isHold = false;
          _releaseDate = null;
        });
      } else {
        final msg = jsonDecode(response.body)['error'] ?? "Unknown error";
        _showAlert("Failed", msg);
      }
    } catch (e) {
      _showAlert("Error", "Could not connect to server.\n$e");
    }
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
    _receiverController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Secure Transfer")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            TextField(
              controller: _receiverController,
              decoration: InputDecoration(
                labelText: "Receiver Mobile",
                labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: "Amount",
                labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hold Transfer",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _isHold,
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setState(() {
                        _isHold = value;
                        if (!_isHold) _releaseDate = null;
                      });
                    },
                  ),
                ],
              ),
            ),

            if (_isHold)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _selectReleaseDate(context),
                      child: Text("Pick release date"),
                    ),
                    SizedBox(width: 10),
                    Text(
                      _releaseDate == null
                          ? "No date selected"
                          : "${_releaseDate!.toLocal()}".split(' ')[0],
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitTransfer,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16),
              ),
              child: Text("Send Securely"),
            ),
          ],
        ),
      ),
    );
  }
}
