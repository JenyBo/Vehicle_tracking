import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<bool> checkCredentials() async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    String data = await rootBundle.loadString('assets/credentials.txt');
    List<String> credentials = data.split('\n');

    for (var line in credentials) {
      List<String> loginInfo = line.trim().split(','); // Trim whitespace before splitting
      if (loginInfo[0].trim() == username && loginInfo[1].trim() == password) { // Trim whitespace before comparing
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            FractionallySizedBox(
              widthFactor: 0.7, // 80% of the available width
              child: Image.asset(
                'assets/login_image.png',
                fit: BoxFit.scaleDown, // Maintain aspect ratio while fitting within bounds
              ),
            ),
            SizedBox(height: 20.0), // Add some spacing
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.0), // Add some spacing
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10.0), // Add some spacing
            ElevatedButton(
              child: const Text('Login'),
              onPressed: () async {
                if (await checkCredentials()) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid username or password')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}