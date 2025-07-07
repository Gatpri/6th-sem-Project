import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'homepage.dart';
import 'assign_admin_page.dart';

class AdminReturnPage extends StatefulWidget {
  final String adminMobile;
  final String adminName;

  const AdminReturnPage({
    Key? key,
    required this.adminMobile,
    required this.adminName,
  }) : super(key: key);

  @override
  State<AdminReturnPage> createState() => _AdminReturnPageState();
}

class _AdminReturnPageState extends State<AdminReturnPage> {
  final _senderController = TextEditingController();
  final _receiverController = TextEditingController();

  List<Map<String, dynamic>> _heldTransactions = [];
  bool _isLoading = false;

  Future<void> _fetchHeldTransactions() async {
    final sender = _senderController.text.trim();
    final receiver = _receiverController.text.trim();

    if (sender.isEmpty || receiver.isEmpty) {
      _showDialog("Input Error", "Please enter both mobile numbers.");
      return;
    }

    setState(() {
      _isLoading = true;
      _heldTransactions = [];
    });

    final url = Uri.parse('http://192.168.1.9:3000/admin-return-list');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_mobile': sender,
          'receiver_mobile': receiver,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _heldTransactions = List<Map<String, dynamic>>.from(data['transactions']);
        });
      } else {
        _showDialog("Error", data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _returnSingleTransaction(int transferId) async {
    final url = Uri.parse('http://192.168.1.9:3000/admin-return-one');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transferId': transferId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showDialog("Success", data['message']);
        await _fetchHeldTransactions(); // refresh list after returning money
      } else {
        _showDialog("Error", data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    }
  }

  Future<void> _promptExtendHold(int transferId, dynamic amount) async {
    DateTime? _selectedDate;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Extend Hold Until"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Text("Pick release date"),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _selectedDate == null
                        ? "No date selected"
                        : "${_selectedDate!.toLocal()}".split(' ')[0],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (_selectedDate == null) {
                      _showDialog("Date Required", "Please select a date.");
                      return;
                    }
                    Navigator.pop(context);
                    await _extendHoldRequest(
                      transferId,
                      amount,
                      _selectedDate!.toIso8601String().split('T')[0],
                    );
                  },
                  child: Text("Extend"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _extendHoldRequest(int transferId, dynamic amount, String newDate) async {
    if (newDate.isEmpty) {
      _showDialog("Input Error", "Release date cannot be empty.");
      return;
    }

    final url = Uri.parse('http://192.168.1.9:3000/admin-extend-hold');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_mobile': _senderController.text.trim(),
          'receiver_mobile': _receiverController.text.trim(),
          'amount': amount,
          'new_release_date': newDate,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showDialog("Success", data['message']);
        await _fetchHeldTransactions(); // Refresh list
      } else {
        _showDialog("Error", data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _senderController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInputsEnabled = !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin - Return Held Money"),
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
              controller: _senderController,
              enabled: isInputsEnabled,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Sender Mobile"),
            ),
            TextField(
              controller: _receiverController,
              enabled: isInputsEnabled,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Receiver Mobile"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isInputsEnabled ? _fetchHeldTransactions : null,
              child: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Text("Fetch Held Transactions"),
            ),
            Divider(height: 30),
            Expanded(
              child: _heldTransactions.isEmpty
                  ? Center(child: Text(_isLoading ? "" : "No held transactions found."))
                  : ListView.builder(
                itemCount: _heldTransactions.length,
                itemBuilder: (context, index) {
                  final tx = _heldTransactions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text("Transaction ID: ${tx['id']}"),
                      subtitle: Text("Amount: Rs. ${tx['amount']}"),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => _returnSingleTransaction(tx['id']),
                            child: Text("Return"),
                          ),
                          ElevatedButton(
                            onPressed: () => _promptExtendHold(tx['id'], tx['amount']),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            child: Text("Extend"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignAdminPage(
                      adminMobile: widget.adminMobile,
                      adminName: widget.adminName,
                    ),
                  ),
                );
              },
              child: Text("Go to Assign Admin Page"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(
                      userMobile: widget.adminMobile,
                      userName: widget.adminName,
                    ),
                  ),
                );
              },
              child: Text("Go to Homepage"),
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
import 'homepage.dart';
import 'assign_admin_page.dart';

class AdminReturnPage extends StatefulWidget {
  final String adminMobile;
  final String adminName;

  const AdminReturnPage({
    Key? key,
    required this.adminMobile,
    required this.adminName,
  }) : super(key: key);

  @override
  State<AdminReturnPage> createState() => _AdminReturnPageState();
}

class _AdminReturnPageState extends State<AdminReturnPage> {
  final _senderController = TextEditingController();
  final _receiverController = TextEditingController();

  List<Map<String, dynamic>> _heldTransactions = [];
  bool _isLoading = false;

  Future<void> _fetchHeldTransactions() async {
    final sender = _senderController.text.trim();
    final receiver = _receiverController.text.trim();

    if (sender.isEmpty || receiver.isEmpty) {
      _showDialog("Input Error", "Please enter both mobile numbers.");
      return;
    }

    setState(() {
      _isLoading = true;
      _heldTransactions = [];
    });

    final url = Uri.parse('http://192.168.1.9:3000/admin-return-list');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_mobile': sender,
          'receiver_mobile': receiver,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _heldTransactions = List<Map<String, dynamic>>.from(data['transactions']);
        });
      } else {
        _showDialog("Error", data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _returnSingleTransaction(int transferId) async {
    final url = Uri.parse('http://192.168.1.9:3000/admin-return-one');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transferId': transferId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showDialog("Success", data['message']);
        await _fetchHeldTransactions(); // refresh list after returning money
      } else {
        _showDialog("Error", data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _senderController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInputsEnabled = !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin - Return Held Money"),
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
              controller: _senderController,
              enabled: isInputsEnabled,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Sender Mobile"),
            ),
            TextField(
              controller: _receiverController,
              enabled: isInputsEnabled,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Receiver Mobile"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isInputsEnabled ? _fetchHeldTransactions : null,
              child: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Text("Fetch Held Transactions"),
            ),
            Divider(height: 30),
            Expanded(
              child: _heldTransactions.isEmpty
                  ? Center(child: Text(_isLoading ? "" : ""))
                  : ListView.builder(
                itemCount: _heldTransactions.length,
                itemBuilder: (context, index) {
                  final tx = _heldTransactions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text("Transaction ID: ${tx['id']}"),
                      subtitle: Text("Amount: Rs. ${tx['amount']}"),
                      trailing: ElevatedButton(
                        onPressed: () => _returnSingleTransaction(tx['id']),
                        child: Text("Return"),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignAdminPage(
                      adminMobile: widget.adminMobile,
                      adminName: widget.adminName,
                    ),
                  ),
                );
              },
              child: Text("Go to Assign Admin Page"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomePage(
                      userMobile: widget.adminMobile,
                      userName: widget.adminName,
                    ),
                  ),
                );
              },
              child: Text("Go to Homepage"),
            ),
          ],
        ),
      ),
    );
  }
}
*/