import 'package:flutter/material.dart';
import 'package:sm_wallets/securedtransfer.dart';
import 'sendmoney.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'transaction_history.dart';
import 'setting_page.dart';

class HomePage extends StatefulWidget {
  final String userMobile; // ✅ ADDED
  final String userName;

  const HomePage({
    super.key,
    required this.userMobile,
    required this.userName,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _availableBalance = 0;
  double _heldAmount = 0;
  bool isLoading = true;
  String error = '';
  bool _showBalance = true;
  @override
  void initState() {
    super.initState();
    fetchBalances();// ✅ FETCH ON START
  }







  // ✅ Fetch real-time balance
  Future<void> fetchBalances() async {
    setState(() {
      isLoading = true;    // <<< Added: show loading indicator on each fetch
      error = '';          // <<< Added: clear previous error on fetch start
    });

    //final url = 'http://192.168.1.9:3000/user-balances?mobile=${widget.userMobile}';
    final url = 'http://192.168.1.9:3000/user-balances/${widget.userMobile}';
    try {
      final response = await http.get(Uri.parse(url));
          //print('🛰️ Status code: ${response.statusCode}');
          // print('📦 Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _availableBalance = double.tryParse(data['availableBalance'].toString()) ?? 0.0;
          _heldAmount = double.tryParse(data['heldAmount'].toString()) ?? 0.0;
          //_availableBalance = data['availableBalance'];
          // _heldAmount = data['heldAmount'];
          isLoading = false;
        });
      } else {
        error = 'Failed to load balance';
        isLoading = false;
      }
    } catch (e) {
      error = 'Error: ${e.toString()}';
      isLoading = false;
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("SM Wallet"),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator( // Enables pull-to-refresh for real-time balance
        onRefresh: fetchBalances,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
//****************************************************************************************
          child: Column(
            children: [
              // Greeting and balance card
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.deepPurpleAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, ${widget.userName}👋",
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
//************************************************************************************************
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //const Text("Your Balances", style: TextStyle(fontSize: 18)),
                            //const SizedBox(height: 10),

                            if (isLoading)
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 10),
                                  Text("Loading...", style: TextStyle(fontSize: 16)),
                                ],
                              )
                            else if (error.isNotEmpty)
                              Text(error, style: const TextStyle(color: Colors.red))
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
//******************************************************************************************************
                                  // Available Balance
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Available Balance", style: TextStyle(fontSize: 17, color: Colors.green)),
                                        Text(
                                          _showBalance
                                              ? "Rs. ${_availableBalance.toStringAsFixed(2)}"
                                              : "Rs. ****",
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

 //**************************************************************************************************
                                  Column(
                                    children: [
                                      //Shade vertical line above the toggle button
                                      Container(
                                        width: 3,
                                        height: 20, // You can adjust this height
                                        color: Colors.grey,
                                      ),

                                      //  Toggle Eye Button
                                      IconButton(
                                        icon: Icon(
                                          _showBalance ? Icons.visibility : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showBalance = !_showBalance;
                                          });
                                        },
                                      ),
                                      //Shaded vertical line below the toggle button
                                      Container(
                                        width: 3,
                                        height: 20, // You can adjust this height
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
//********************************************************************************************************


                                  // Held Balance
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text("Blocked Amount", style: TextStyle(fontSize: 17, color: Colors.red)),
                                        Text(
                                          _showBalance
                                              ? "Rs. ${_heldAmount.toStringAsFixed(2)}"
                                              : "Rs. ****",
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
//**************************************************************************************************************
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),



                  ],
                ),
              ),

              const SizedBox(height: 30),

//*****✅ Updated Menu grid with navigation******************************************************
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
//********************************************************************************************
                  children: [
                    _buildMenuItem(Icons.send, "Send Money", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SendMoneyPage(
                           // userMobile: userData['mobile'],
                           // userName: userData['name'],
                           senderMobile: widget.userMobile, // ✅ CORRECTED
                           userName: widget.userName,
                          ),
                        ),
                      );
                    }),
                   // _buildMenuItem(Icons.account_balance_wallet, "Load Money", () {}),
                    _buildMenuItem(Icons.security, "Secured Transfer", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecuredTransferPage(
                            senderMobile: widget.userMobile, // ✅ CORRECTED
                            userName: widget.userName,
                          ),
                        ),
                      );
                    }),
                    _buildMenuItem(Icons.history, "Transactions", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionsPage(
                            senderMobile: widget.userMobile,
                          ),
                        ),
                      );
                    }),

                    _buildMenuItem(Icons.qr_code_scanner, "QR Scanner", () {}),
                    _buildMenuItem(Icons.qr_code, "My QR Code", () {}),
                    _buildMenuItem(Icons.support_agent, "Support", () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  userMobile: widget.userMobile,
                  userName: widget.userName,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: "Notification"),

        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: Colors.deepPurple),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
