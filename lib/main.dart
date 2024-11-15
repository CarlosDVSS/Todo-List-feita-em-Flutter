import 'package:flutter/material.dart';
import 'package:todo_app/screens/homescreen.dart';

// Função principal para rodar o app
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // Desativa o banner de debug
      theme: _buildAppTheme(),  // Usar um tema centralizado
      home: const HomeScreenPage(),  // Tela inicial
    );
  }

  // Função para construir o tema do app
  ThemeData _buildAppTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: Colors.purple, // Paleta de cores
      scaffoldBackgroundColor: Colors.black, // Cor de fundo das telas
      appBarTheme: const AppBarTheme(
        color: Colors.black, // Cor personalizada da AppBar
      ),
    );
  }
}
