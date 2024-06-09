import 'package:flutter/material.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:localstorage/localstorage.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(30.0),
            child: Column(
              children: <Widget>[
                Image(
                  image: NetworkImage('https://i.ibb.co/crWgb2V/Captura-de-ecr-2024-05-10-121307-removebg-preview.png'),
                ),
                SizedBox(
                  height: 30.0,
                ),
                SizedBox(
                  width: 500.0,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  width: 500.0,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    await _loginUser(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: Text(
                    'Dont have an Account? Click here',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginUser(BuildContext context) async {
    String emailLowerCase = _emailController.text.toLowerCase();
    String hashedPassword = hashPassword(_passwordController.text);

    try {
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(emailLowerCase);
      DataSnapshot userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        var userData = userSnapshot.value as Map<dynamic, dynamic>;
        String storedPassword = userData['password'];

        if (storedPassword == hashedPassword) {
          await _saveLoginInfo(userData);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(username: userData['name'], museum: userData['museum'], role: userData['role'])),
          );
        } else {
          _showErrorDialog(context, 'Invalid Credentials');
        }
      } else {
        _showErrorDialog(context, 'Invalid Credentials');
      }
    } catch (e) {
      print('Failed to login user: $e');
    }
  }

  Future<void> _saveLoginInfo(Map<dynamic, dynamic> userData) async {
    localStorage.setItem('username', userData?['name']);
    localStorage.setItem('museum', userData?['museum']);
    localStorage.setItem('role', userData?['role']);
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var hashedPassword = sha256.convert(bytes).toString();
    return hashedPassword;
  }
}
