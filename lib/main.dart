import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'models/expense_model.dart';
import 'utils/expense_extractor.dart';
import 'utils/db_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoiceExpenseApp());
}

class VoiceExpenseApp extends StatelessWidget {
  const VoiceExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExpenseHomePage(title: 'Voice Expense Tracker'),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key, required this.title});
  final String title;

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  Expense? _currentExpense;
  List<Expense> _expensesList = [];

  final DateFormat _dateFormat = DateFormat('MMM d, y - h:mm a');

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await DBHelper().getExpenses();
    setState(() {
      _expensesList = expenses;
    });
  }

  void _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => debugPrint("Speech error: $error"),
        onStatus: (status) => debugPrint("Speech status: $status"),
      );
    }
    setState(() {});
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _lastWords = '';
        _currentExpense = null;
      });
    } else {
      _initSpeech();
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult && _lastWords.isNotEmpty) {
      final newExpense = ExpenseExtractor.extract(_lastWords);
      setState(() {
        _currentExpense = newExpense;
      });
      // Save to database
      await DBHelper().insertExpense(newExpense);
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastWords.isEmpty
                    ? (_speechToText.isListening
                        ? 'Listening...'
                        : 'Tap the microphone to start recording an expense.')
                    : _lastWords,
                style: TextStyle(
                  fontStyle: _lastWords.isEmpty ? FontStyle.italic : FontStyle.normal,
                  color: _lastWords.isEmpty ? Colors.grey.shade600 : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentExpense != null) ...[
              const Text(
                'Just Saved:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Card(
                color: Colors.green.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildDataRow('Amount', '\$${_currentExpense!.amount.toStringAsFixed(2)}', highlight: true),
                      _buildDataRow('Category', _currentExpense!.category),
                    ],
                  ),
                ),
              ),
            ] else if (_speechToText.isListening && _lastWords.isNotEmpty) ...[
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            const Text(
              'Expense History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: _expensesList.isEmpty
                  ? const Center(child: Text("No expenses recorded yet."))
                  : ListView.builder(
                      itemCount: _expensesList.length,
                      itemBuilder: (context, index) {
                        final exp = _expensesList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(_getCategoryIcon(exp.category)),
                            ),
                            title: Text(exp.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${exp.category} • ${_dateFormat.format(exp.date)}'),
                            trailing: Text(
                              '\$${exp.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onLongPress: _startListening,
        onLongPressUp: _stopListening,
        child: FloatingActionButton.large(
          onPressed: _speechToText.isNotListening ? _startListening : _stopListening,
          tooltip: 'Listen',
          backgroundColor: _speechToText.isListening ? Colors.red : Theme.of(context).colorScheme.primary,
          child: Icon(
            _speechToText.isNotListening ? Icons.mic : Icons.mic_off,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.fastfood;
      case 'Travel': return Icons.flight;
      case 'Shopping': return Icons.shopping_bag;
      case 'Bills': return Icons.receipt;
      default: return Icons.money;
    }
  }

  Widget _buildDataRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
