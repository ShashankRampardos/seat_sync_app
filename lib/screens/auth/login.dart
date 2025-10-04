import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seat_sync_v2/screens/auth/signup.dart';
import 'package:seat_sync_v2/screens/tabs.dart';
import 'package:seat_sync_v2/utils/utils.dart';

final _formKey = GlobalKey<FormState>();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  void _submit() {
    if (_formKey.currentState!.validate()) {
      //when validate() run, all validators in TextFormField will run and if all return null then it returns true
      if (_auth.currentUser != null &&
          _auth.currentUser!.email == _emailController.text) {
        // User already logged in
        Utils.showToast(
          "Already logged in with same account, try signing out.",
        );
        return;
      } else if (_auth.currentUser != null) {
        Utils.showToast(
          'You are logged in with another account, please logout first.',
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      _auth
          .signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          )
          .then((value) {
            setState(() {
              _isLoading = false;
            });
            Utils.showToast('Logged in successfully');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TabsScreen()),
            );
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            Utils.showToast(error.message);
          });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Login'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),

        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                Form(
                  key: _formKey, // ye jaruru ha, i forgot this last time
                  child: Column(
                    children: [
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
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: 'please enter your password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          if (value.length < 6) {
                            return 'Password too short';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Login'),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Text('Don\'t hava an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignupScreen(),
                                ),
                              );
                            },
                            child: Text('Signup'),
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
