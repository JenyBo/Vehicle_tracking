import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'login_screen.dart'; // Import the LoginScreen

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // Removed the const keyword from here
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // Removed the const keyword from here
    );
  }
}