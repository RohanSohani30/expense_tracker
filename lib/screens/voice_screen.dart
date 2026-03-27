import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/expense_model.dart';
import '../utils/db_helper.dart';
import '../utils/expense_extractor.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key, required this.title});
  final String title;

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
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

  void _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult && _lastWords.isNotEmpty) {
      _processAndSaveExpense(_lastWords);
      _lastWords = ''; // clear to avoid double save
    }
  }

  Future<void> _processAndSaveExpense(String text) async {
    final newExpense = ExpenseExtractor.extract(text);
    setState(() {
      _currentExpense = newExpense;
    });
    try {
      await DBHelper().insertExpense(newExpense);
      await _loadExpenses();
    } catch (e) {
      debugPrint("Error saving to DB: $e");
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (_lastWords.isNotEmpty) {
      await _processAndSaveExpense(_lastWords);
      _lastWords = ''; // clear to avoid double save
    }
    setState(() {});
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
                      const SizedBox(height: 4),
                      _buildDataRow('Category', _currentExpense!.category),
                      const SizedBox(height: 4),
                      _buildDataRow('Date/Time', _dateFormat.format(_currentExpense!.date)),
                      const SizedBox(height: 4),
                      _buildDataRow('Description', _currentExpense!.description),
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
                  : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    columns: const [
                      DataColumn(label: Text('Date / Time')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Amount')),
                    ],
                    rows: _expensesList.map((exp) {
                      return DataRow(cells: [
                        DataCell(Text(_dateFormat.format(exp.date))),
                        DataCell(Text(exp.description)),
                        DataCell(Text(exp.category)),
                        DataCell(
                          Text(
                            '\$${exp.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          if (_speechToText.isNotListening) {
            _startListening();
          } else {
            _stopListening();
          }
        },
        tooltip: 'Listen',
        backgroundColor: _speechToText.isListening ? Colors.red : Theme.of(context).colorScheme.primary,
        child: Icon(
          _speechToText.isNotListening ? Icons.mic : Icons.mic_off,
          color: Colors.white,
        ),
      ),
    );
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
