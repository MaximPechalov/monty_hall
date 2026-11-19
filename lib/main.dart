import 'package:flutter/material.dart';
import 'game_page.dart';

void main() => runApp(const MontyHallApp());

class MontyHallApp extends StatelessWidget {
  const MontyHallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Монти Холл',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}