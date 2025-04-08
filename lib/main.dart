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
      appBar: AppBar(
        title: Text('Трекер витрат', style: GoogleFonts.coiny(fontWeight: FontWeight.w700),),
         centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); 
            },
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QuickViewPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Введіть суму',
              ),
              keyboardType: TextInputType.number,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => addTransaction('income'),
                  child: Text('Додати дохід'),
                ),
                ElevatedButton(
                  onPressed: () => addTransaction('expense'),
                  child: Text('Додати витрату'),
                ),
              ],
            ),
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

                  snapshot.data!.docs.forEach((doc) {
                    final amount = (doc['amount'] as num).toDouble();
                    if (doc['type'] == 'income') {
                      income += amount;
                    } else if (doc['type'] == 'expense') {
                      expenses += amount;
                    }
                  });

                  double balance = income - expenses;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Доходи: \$${income.toStringAsFixed(2)}'),
                      Text('Витрати: \$${expenses.toStringAsFixed(2)}'),
                      Text('Залишок: \$${balance.toStringAsFixed(2)}'),
                      Divider(),
                      Expanded(
                        child: ListView(
                          children: snapshot.data!.docs.map((doc) {
                            final id = doc.id;
                            final type = doc['type'];
                            final amount = doc['amount'];
                            final timestamp = doc['timestamp'];

                            return Card(
                              color: type == 'income' ? Colors.green[100] : Colors.red[100],
                              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Text(
                                  '${type == 'income' ? 'Дохід' : 'Витрата'}: \$${amount}',
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
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickViewPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTransactions() {
    return _firestore.collection('transactions').orderBy('timestamp').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Швидкий перегляд')),
      body: StreamBuilder<QuerySnapshot>(
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
                    '${type == 'income' ? 'Дохід' : 'Витрата'}: \$${amount}',
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
    );
  }
}
