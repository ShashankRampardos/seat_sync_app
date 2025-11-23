import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_auth.currentUser != null &&
          _auth.currentUser!.email == _emailController.text) {
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
            email: _emailController.text.trim(),
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
            // error might be FirebaseAuthException
            final message = (error is FirebaseAuthException)
                ? error.message
                : error.toString();
            Utils.showToast(message ?? 'Login failed');
          });
    }
  }

  /// -----------------------
  /// Forgot password flow
  /// -----------------------
  void _showForgotPasswordDialog() {
    final TextEditingController _resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final _resetFormKey = GlobalKey<FormState>();
    bool _sending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Form(
                key: _resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter the email associated with your account. We will send you a password reset link.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _resetEmailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _sending
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _sending
                      ? null
                      : () async {
                          if (!(_resetFormKey.currentState?.validate() ??
                              false)) {
                            return;
                          }
                          final email = _resetEmailController.text.trim();
                          try {
                            setStateDialog(() {
                              _sending = true;
                            });
                            await _auth.sendPasswordResetEmail(email: email);
                            setStateDialog(() {
                              _sending = false;
                            });

                            Navigator.of(context).pop(); // close dialog
                            Utils.showToast(
                              'Password reset link sent to $email. Check your inbox.',
                            );
                          } on FirebaseAuthException catch (e) {
                            setStateDialog(() {
                              _sending = false;
                            });
                            // Common errors: user-not-found, invalid-email, etc.
                            Utils.showToast(
                              e.message ?? 'Failed to send reset email',
                            );
                          } catch (e) {
                            setStateDialog(() {
                              _sending = false;
                            });
                            Utils.showToast('Error: ${e.toString()}');
                          }
                        },
                  child: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
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
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
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
                      const SizedBox(height: 12),

                      // Forgot password button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('Forgot Password?'),
                        ),
                      ),

                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignupScreen(),
                                ),
                              );
                            },
                            child: const Text('Signup'),
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
