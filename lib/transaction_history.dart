import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionsPage extends StatefulWidget {
  final String senderMobile;
  const TransactionsPage({required this.senderMobile, Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final url = Uri.parse(
        'http://192.168.1.9:3000/transactions/${widget.senderMobile}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          transactions = jsonDecode(response.body);
        });
      } else {
        print("Failed to load transactions.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _releaseManually(int transactionId) async {
    // ✅ Fix 1: Corrected endpoint
    final url = Uri.parse('http://192.168.1.9:3000/release-transfer');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // ✅ Fix 2: Renamed key to match backend
          'transferId': transactionId,
          'senderMobile': widget.senderMobile,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showAlert("Success", data['message']);
        _fetchTransactions(); // Refresh list
      } else {
        _showAlert("Failed", data['error']);
      }
    } catch (e) {
      _showAlert("Error", e.toString());
    }
  }


  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: Text("OK"))
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transaction History")),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isHeld = tx['status'] == 'held';
         //final statusText = tx['status'] ?? 'unknown';

          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text("${tx['description']} - Rs ${tx['amount']}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status: ${tx['status']}"),
                  if (isHeld) Text("Hold Until: ${tx['created_at']}"),
                ],
              ),
              isThreeLine: true,
              trailing: isHeld
                  ? ElevatedButton(
                onPressed: () => _releaseManually(tx['id']),
                child: Text("Release"),
              )
                  : null,

            ),
          );
        },
      ),
    );
  }


}
