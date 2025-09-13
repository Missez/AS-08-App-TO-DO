import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'providers/todo_provider.dart'; 
import 'screens/home_screen.dart'; 
 
void main() { 
  runApp( 
    ChangeNotifierProvider( 
      create: (_) => TodoProvider()..loadTodos(), 
      child: const MyApp(), 
    ), 
  ); 
} 
 
class MyApp extends StatelessWidget { 
  const MyApp({super.key}); 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      title: 'Todo App - งานของฉัน', 
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: const Color(0xFF6366F1), // Indigo color
        textTheme: GoogleFonts.kanitTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ), 
      home: const HomeScreen(), 
    ); 
  } 
} 