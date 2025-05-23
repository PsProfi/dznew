import 'package:dz32/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Трекер витрат',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExpenseHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  @override
  _ExpenseHomePageState createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final _amountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String sorting = "by_date"; 

  Future<void> addTransaction(String type) async {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0) {
      await _firestore.collection('transactions').add({
        'type': type,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _amountController.clear();
      setState(() {});
    }
  }

  Stream<QuerySnapshot> getTransactions() {
    return _firestore.collection('transactions').orderBy('timestamp').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          'Трекер витрат',
          style: GoogleFonts.notoSansDeseret(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            
          ),
        ],
        
      ),
      
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/pexels-hngstrm-1939485.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.8),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, kToolbarHeight + 24, 16.0, 16.0),
            child: Column(
              children: [
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Введіть суму',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => addTransaction('income'),
                      icon: Icon(Icons.arrow_downward, color: Colors.white),
                      label: Text(
                        'Додати дохід',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => addTransaction('expense'),
                      icon: Icon(Icons.arrow_upward, color: Colors.white),
                      label: Text(
                        'Додати витрату',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),

                SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: getTransactions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Помилка при завантаженні даних'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('Немає транзакцій'));
                      }

                      double income = 0;
                      double expenses = 0;

                      final docs = snapshot.data!.docs;
                      docs.forEach((doc) {
                        final amount = (doc['amount'] as num).toDouble();
                        if (doc['type'] == 'income') {
                          income += amount;
                        } else if (doc['type'] == 'expense') {
                          expenses += amount;
                        }
                      });

                      double balance = income - expenses;

                     
                      if (sorting == "by_date") {
                        docs.sort(sortByTimestamp);
                      } else if (sorting == "by_amount") {
                        docs.sort(sortByAmount);
                      }

                      return Column(
                        children: [
                          _buildHorizontalSummaryCards(
                            income: income,
                            expenses: expenses,
                            balance: balance,
                          ),
                          SizedBox(height: 16),

                          

                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Сортування: ${sorting == "by_date" ? "за датою" : "за сумою"}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.sort),
                      onSelected: (value) {
                        setState(() {
                          sorting = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'by_date',
                          child: Text('Сортувати за датою'),
                        ),
                        PopupMenuItem(
                          value: 'by_amount',
                          child: Text('Сортувати за сумою'),
                        ),
                      ],
                    ),
                  ],
                ),

                          Expanded(
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: ListView(
                                
                                padding: EdgeInsets.all(0),
                                children: docs.map((doc) {
                                  final id = doc.id;
                                  final type = doc['type'];
                                  final amount = doc['amount'];
                                  final timestamp = doc['timestamp'];
                              
                                  return Card(
                                    color: type == 'income' ? Colors.green[100] : Colors.red[100],
                                    margin: EdgeInsets.only(top: 6, bottom: 6, left: 4, right: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      title: Text(
                                        '${type == 'income' ? 'Дохід' : 'Витрата'}: ${amount} грн',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        timestamp != null
                                            ? DateFormat.yMd().add_Hm().format((timestamp as Timestamp).toDate())
                                            : 'Очікуємо час...',
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.grey[800]),
                                        onPressed: () async {
                                          await _firestore.collection('transactions').doc(id).delete();
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSummaryCards({
    required double income,
    required double expenses,
    required double balance,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryTile(
          title: 'Доходи',
          amount: income,
          color: Colors.green,
          icon: Icons.arrow_downward,
        ),
        _buildSummaryTile(
          title: 'Витрати',
          amount: expenses,
          color: Colors.red,
          icon: Icons.arrow_upward,
        ),
        _buildSummaryTile(
          title: 'Залишок',
          amount: balance,
          color: Colors.blue,
          icon: Icons.account_balance_wallet,
        ),
      ],
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 275,
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(2)} грн',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTransactions() {
    return _firestore.collection('transactions').orderBy('timestamp').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Історія'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/pexels-hngstrm-1939485.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.8), 
          ),
          Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight + 24),
            child: StreamBuilder<QuerySnapshot>(
              stream: getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Помилка завантаження'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Немає транзакцій'));
                }

                return ListView(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: snapshot.data!.docs.map((doc) {
                    final id = doc.id;
                    final type = doc['type'];
                    final amount = doc['amount'];
                    final timestamp = doc['timestamp'];

                    return Card(
                      color: type == 'income' ? Colors.green[50] : Colors.red[50],
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                          '${type == 'income' ? 'Дохід' : 'Витрата'}: ${amount} грн',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          timestamp != null
                              ? DateFormat.yMd().add_Hm().format((timestamp as Timestamp).toDate())
                              : 'Час не вказано',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            await _firestore.collection('transactions').doc(id).delete();
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

int sortByTimestamp(d1, d2) {
  final timestamp1 = (d1['timestamp'] as Timestamp?)?.toDate();
  final timestamp2 = (d2['timestamp'] as Timestamp?)?.toDate();

  if (timestamp1 == null || timestamp2 == null) {
    return 0;
  }

  if (timestamp1.isBefore(timestamp2)) {
    return 1;
  } else {
    return -1;
  }
}

int sortByAmount(d1, d2) {
  final amount1 = d1['amount'] as double?;
  final amount2 = d2['amount'] as double?;

  if (amount1 == null || amount2 == null) {
    return 0;
  }

  if (amount1 < amount2) {
    return 1;
  } else {
    return -1;
  }
}

