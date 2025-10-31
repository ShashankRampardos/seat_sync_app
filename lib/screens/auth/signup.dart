import 'package:flutter/material.dart';
import 'package:seat_sync_v2/screens/auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seat_sync_v2/screens/tabs.dart';
import 'package:seat_sync_v2/utils/utils.dart';

final _formKey = GlobalKey<FormState>();

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      //when validate() run, all validators in TextFormField will run and if all return null then it returns true
      if (_auth.currentUser != null) {
        Utils.showToast(
          'You are logged in with another account, please logout first.',
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      try {
        final UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: _emailController.text.toString(),
              password: _passwordController.text.toString(),
            );

        await _firestore.collection("users").doc(userCredential.user!.uid).set({
          "username": _usernameController.text.trim(),
          "phone": _phoneController.text.trim(),
          "dob": _dobController.text.trim(),
          "email": _emailController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
          "userMode": "active", //active or banned, by default active user.
          "freeUsageCount": 0,
          "paidUsageCount": 0,
          "totalSpend": 0,
          "seatId": null,
        });
      } on FirebaseException catch (error) {
        setState(() {
          _isLoading = false;
        });

        Utils.showToast(error.message!);
      } finally {
        setState(() {
          _isLoading = false;
        });
        debugPrint("Created New Account");
        if (_auth.currentUser != null) {
          Utils.showToast('Siged up successfully');
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TabsScreen()),
        );
      }

      print("User Signed up");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Signup'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ListView(
              children: [
                Form(
                  key: _formKey, // ye jaruru ha, i forgot this last time
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          helperText: 'please set the username',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username cannot be empty';
                          }
                          if (value.length < 3) {
                            return 'Username too short';
                          }
                          return null; // null will be returned to validate() in _submit method if condition, null returned means true
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone number',
                          helperText: 'please set the phone number',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Number field cannot be empty';
                          }
                          if (value.length != 10) {
                            return 'Number must be 10 digit long';
                          }
                          return null; // null will be returned to validate() in _submit method if condition, null returned means true
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _dobController,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          helperText: 'please select your date of birth',
                        ),
                        readOnly: true,
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          _dobController.text =
                              "${pickedDate!.day}/${pickedDate.month}/${pickedDate.year}";
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Date of birth cannot be empty';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          helperText:
                              'please enter your email i.e, example@xyz.com',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }
                          if (!RegExp(
                            r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null; // null will be returned to validate() in _submit method if condition, null returned means true
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: 'please set your password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          if (value.length < 6) {
                            return 'Password too short';
                          }
                          return null; // null will be returned to validate() in _submit method if condition, null returned means true
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _submit(context);
                              },
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Signup'),
                      ),
                      Row(
                        children: [
                          Text('Already hava an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            child: Text('Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
