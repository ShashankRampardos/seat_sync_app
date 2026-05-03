import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:seat_sync_v2/screens/auth/login.dart';
import 'package:seat_sync_v2/screens/splash.dart';
import 'package:seat_sync_v2/utils/utils.dart';
import 'package:seat_sync_v2/widgets/prifile_item_tile.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

final _formKey = GlobalKey<FormState>();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.refresh});
  final Function refresh;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool isAdmin = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (_auth.currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (mounted) {
        setState(() {
          isAdmin = doc.data()?['userMode'] == 'admin';
        });
      }
    }
  }

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
                            return 'Number must be of 10 digit long';
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
                          _dobController.text =
                              "${pickedDate!.day}/${pickedDate.month}/${pickedDate.year}";
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

  void updateWifiCredential(BuildContext context) {
    final _ssidController = TextEditingController();
    final _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // 🔥 KEY FIX
              ),
              child: SingleChildScrollView(
                // 🔥 allows movement
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 🔥 no fixed height
                      children: [
                        TextFormField(
                          controller: _ssidController,
                          decoration: InputDecoration(labelText: "SSID"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "SSID required";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(labelText: "Password"),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return "Min 8 chars";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;

                                  setModalState(() => isLoading = true);

                                  try {
                                    final ssid = _ssidController.text.trim();
                                    final password = _passwordController.text
                                        .trim();

                                    await sendMQTT(
                                      '{"data":"$ssid|$password"}',
                                    );

                                    Navigator.pop(context);
                                  } catch (e) {
                                    Utils.showToast("Failed: $e");
                                  }

                                  setModalState(() => isLoading = false);
                                },
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text("Send"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // String encryptData(String data) { // for encrypting ssid and password but not using encryption for now, keeping it simple
  //   final key = encrypt.Key.fromUtf8('16charsecretkey!');
  //   final iv = encrypt.IV.fromLength(16);

  //   final encrypter = encrypt.Encrypter(encrypt.AES(key));
  //   final encrypted = encrypter.encrypt(data, iv: iv);

  //   return encrypted.base64;
  // }

  Future<void> sendMQTT(String message) async {
    final client = MqttServerClient('broker.hivemq.com', 'flutter_client');

    client.logging(on: false);
    client.keepAlivePeriod = 20;

    try {
      final connMess = MqttConnectMessage()
          .withClientIdentifier(
            'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
          )
          .startClean();

      client.connectionMessage = connMess;

      await client.connect(); //  IMPORTANT

      if (client.connectionStatus!.state != MqttConnectionState.connected) {
        throw Exception("MQTT connection failed");
      }

      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      client.publishMessage(
        'seat/all/admin/wifi/update',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      await Future.delayed(Duration(milliseconds: 500)); // allow send

      client.disconnect();
    } catch (e) {
      client.disconnect();
      throw e;
    }
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
        // ProfileItems( //login button is not required, it will always say already loggedin
        //   title: 'login',
        //   icon: Icons.input_rounded,
        //   onTap: () {
        //     if (_auth.currentUser != null) {
        //       Utils.showToast('Already logged in');
        //       return;
        //     }
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => LoginScreen()),
        //     ).then((value) => widget.refresh(() {}));
        //   },
        // ),
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
        if (isAdmin)
          ProfileItems(
            title: 'Change Wifi Credentials of all seats',
            icon: Icons.input_rounded,
            onTap: () {
              updateWifiCredential(context);
            },
          ),
      ],
    );
  }
}
