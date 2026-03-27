import 'package:flutter/material.dart';
import 'package:voice_expense/screens/voice_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Voice Expense Tracker',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const VoiceScreen(title: 'Voice Expense Tracker'),
  ));
}



