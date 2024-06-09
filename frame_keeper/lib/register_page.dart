import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedMuseum;
  String? _selectedRole;
  List<DropdownMenuItem<String>> _museumItems = [];

  @override
  void initState() {
    super.initState();
    _fetchMuseums();
  }

  Future<void> _fetchMuseums() async {
    DatabaseReference ref = FirebaseDatabase.instance.reference().child('museums');
    DatabaseEvent event = await ref.once();
    DataSnapshot snapshot = event.snapshot;
    List<DropdownMenuItem<String>> items = [];
    Map<dynamic, dynamic> museums = snapshot.value as Map<dynamic, dynamic>;

    museums.forEach((key, value) {
      items.add(DropdownMenuItem<String>(
        value: value['name'],
        child: Text(value['name']),
      ));
    });

    setState(() {
      _museumItems = items;
    });
  }

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
                SizedBox(height: 20.0),
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
                SizedBox(height: 20.0),
                SizedBox(
                  width: 500.0,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                SizedBox(
                  width: 500.0,
                  child: DropdownButtonFormField<String>(
                    value: _selectedMuseum,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMuseum = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Museum',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    ),
                    items: _museumItems,
                  ),
                ),
                SizedBox(height: 20.0),
                SizedBox(
                  width: 500.0,
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Administrator',
                        child: Text('Administrator'),
                      ),
                      DropdownMenuItem(
                        value: 'Worker',
                        child: Text('Worker'),
                      ),
                      DropdownMenuItem(
                        value: 'Novice',
                        child: Text('Novice'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.0),
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
                    await _registerUser(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Register',
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
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text(
                    'Already Have an Account? Click here',
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

  Future<void> _registerUser(BuildContext context) async {
    if (!_areAllFieldsFilled()) {
      _showMissingFieldsDialog(context);
      return;
    }

    try {
      String emailLowerCase = _emailController.text.toLowerCase();
      if (await _doesUserExist(emailLowerCase)) {
        _showEmailAlreadyExistsDialog(context);
      } else {
        await _registerNewUser(emailLowerCase);
        _showSuccessDialog(context);
      }
    } catch (e) {
      print('Failed to register user: $e');
    }
  }

  bool _areAllFieldsFilled() {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _selectedMuseum != null &&
        _selectedRole != null;
  }

  void _showMissingFieldsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Missing Information'),
          content: Text('Please fill in all fields.'),
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

  Future<bool> _doesUserExist(String email) async {
    final databaseRef = FirebaseDatabase.instance.reference().child('users').child(email);
    DatabaseEvent event = await databaseRef.once();
    DataSnapshot snapshot = event.snapshot;
    return snapshot.value != null;
  }

  void _showEmailAlreadyExistsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Email Already Exists'),
          content: Text('The email address provided is already in use. Please choose a different email.'),
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

  Future<void> _registerNewUser(String email) async {
    String hashedPassword = hashPassword(_passwordController.text);
    final databaseRef = FirebaseDatabase.instance.reference().child('users').child(email);
    await databaseRef.set({
      'email': email,
      'password': hashedPassword,
      'name': _nameController.text,
      'museum': _selectedMuseum,
      'role': _selectedRole,
    });
    print('User registered successfully!');
    _clearFields();
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('User registered successfully.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearFields() {
    _emailController.clear();
    _nameController.clear();
    _passwordController.clear();
    setState(() {
      _selectedMuseum = null;
      _selectedRole = null;
    });
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var hashedPassword = sha256.convert(bytes).toString();
    return hashedPassword;
  }
}
