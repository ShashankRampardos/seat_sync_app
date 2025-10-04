import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seat_sync_v2/screens/auth/login.dart';
import 'package:seat_sync_v2/screens/splash.dart';
import 'package:seat_sync_v2/utils/utils.dart';

final _formKey = GlobalKey<FormState>();

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key, required this.refresh});
  final Function refresh;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool isLoading = false;

  void editProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              height: 700,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
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
                            return null;
                          }
                          if (value.length < 3) {
                            return 'Username too short';
                          }
                          return null;
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
                            return null;
                          }
                          if (value.length != 10) {
                            return 'Number is too short';
                          }
                          return null;
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
                          if (pickedDate != null) {
                            _dobController.text =
                                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_auth.currentUser == null) {
                                  Utils.showToast('No user logged in');
                                  return;
                                }
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }

                                if (_usernameController.text.isNotEmpty ||
                                    _dobController.text.isNotEmpty ||
                                    _phoneController.text.isNotEmpty) {
                                  setModalState(() {
                                    isLoading = true;
                                  });
                                  final uid = _auth.currentUser!.uid;
                                  FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(uid)
                                      .update({
                                        if (_usernameController.text.isNotEmpty)
                                          "username": _usernameController.text
                                              .trim(),
                                        if (_phoneController.text.isNotEmpty)
                                          "phone": _phoneController.text.trim(),
                                        if (_dobController.text.isNotEmpty)
                                          "DOB": _dobController.text.trim(),
                                      })
                                      .then((value) {
                                        Utils.showToast('Profile updated');
                                        widget.refresh(() {});
                                        setModalState(() {
                                          isLoading = false;
                                        });
                                        Navigator.pop(context);
                                      })
                                      .catchError((error) {
                                        Utils.showToast(
                                          'Failed to update profile: $error',
                                        );
                                        setModalState(() {
                                          isLoading = false;
                                        });
                                        Navigator.pop(context);
                                      });
                                } else {
                                  Utils.showToast('No changes made');
                                }
                              },
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Column(
      children: [
        ProfileItems(
          title: 'edit profile',
          icon: Icons.edit,
          onTap: () {
            if (_auth.currentUser == null) {
              Utils.showToast('Please login first');
              return;
            }
            editProfile(context);
          },
        ),
        ProfileItems(
          title: 'login',
          icon: Icons.input_rounded,
          onTap: () {
            if (_auth.currentUser != null) {
              Utils.showToast('Already logged in');
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            ).then((value) => widget.refresh(() {}));
          },
        ),
        ProfileItems(
          title: 'logout',
          icon: Icons.reset_tv_rounded,
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: Text(
                    'Confirm Logout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('NO'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_auth.currentUser == null) {
                          Utils.showToast('No user logged in');
                          return;
                        }
                        _auth.signOut();
                        Utils.showToast('Logged out successfully');
                        widget.refresh(() {});
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SplashScreen(),
                          ),
                          (Route<dynamic> route) =>
                              false, // saare purane routes hata dega
                        );
                      },
                      child: Text('Yes'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class ProfileItems extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const ProfileItems({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
