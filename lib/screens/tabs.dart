import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seat_sync_v2/screens/booking.dart';
import 'package:seat_sync_v2/screens/profile.dart';
import 'package:seat_sync_v2/screens/seat_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seat_sync_v2/screens/settings.dart';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:seat_sync_v2/utils/utils.dart';
import 'package:seat_sync_v2/providers/revel_paid_unpaid.dart';

class TabsScreen extends ConsumerStatefulWidget {
  const TabsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  int _selectedPageIndex = 0;
  String _profileName = "profileName";
  String? _imagePath;
  var _imageKey;

  final List<String> _titles = ['Seat Map', 'Bookings', 'My Profile'];
  late List<Widget> _page;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _page = [
      SeatMapScreen(),
      BookingScreen(),
      ProfileScreen(refresh: setState),
    ];
    _initializeProfile();
  }

  void _initializeProfile() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    var uid = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        _profileName = data['username'] ?? "profileName";
        _imagePath = data['profilePic']; // stored network URL
      });
    }
  }

  Future<String?> uploadToCloudinary(File file) async {
    try {
      String cloudName = "daybeytsk";
      String uploadPreset = "gql8nhle"; // 1. PASTE YOUR PRESET NAME HERE

      // Note: Remove /v1_1/ from the URL logic if you want, but standard is:
      // https://api.cloudinary.com/v1_1/<cloud_name>/image/upload
      String url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      var request = http.MultipartRequest("POST", Uri.parse(url));

      // 2. Use the unsigned preset
      request.fields['upload_preset'] = uploadPreset;

      // 3. REMOVED the Authorization header (Not needed for unsigned uploads)

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: "profile_${DateTime.now().millisecondsSinceEpoch}.jpg",
        ),
      );

      var response = await request.send();
      var res = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(res);
        print("Upload Success: ${jsonData["secure_url"]}");
        return jsonData["secure_url"];
      } else {
        // This will print the exact error from Cloudinary in your console
        print("Upload error details: $res");
        print("Status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Cloudinary exception: $e");
      return null;
    }
  }

  Future<void> updateUserProfileUrl(String url) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "profilePic": url,
    });
  }

  Future<void> _setProfilePictureFromGallery() async {
    Navigator.pop(context);

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (picked == null) return;

      File imageFile = File(picked.path);

      Utils.showToast("Uploading...");

      String? imageUrl = await uploadToCloudinary(imageFile);

      if (imageUrl != null) {
        await updateUserProfileUrl(imageUrl);

        setState(() {
          _imagePath = imageUrl;
          _imageKey = UniqueKey();
        });

        Utils.showToast("Profile updated!");
      } else {
        Utils.showToast("Upload failed");
      }
    } catch (e) {
      debugPrint("Gallery pick error: $e");
    }
  }

  Future<void> _setProfilePictureFromCamera() async {
    Navigator.pop(context);

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (picked == null) return;

      File imageFile = File(picked.path);

      Utils.showToast("Uploading...");

      String? imageUrl = await uploadToCloudinary(imageFile);

      if (imageUrl != null) {
        await updateUserProfileUrl(imageUrl);

        setState(() {
          _imagePath = imageUrl;
          _imageKey = UniqueKey();
        });

        Utils.showToast("Profile updated!");
      } else {
        Utils.showToast("Upload failed");
      }
    } catch (e) {
      debugPrint("Camera pick error: $e");
    }
  }

  Future<void> _chooseImagePickerMethod() async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Choose image picking method (gallery or camera)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () async {
                    await _setProfilePictureFromGallery();
                  },
                  icon: Icon(Icons.file_copy_sharp),
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: 50,
                ),
                SizedBox(width: 20),
                IconButton(
                  onPressed: () async {
                    await _setProfilePictureFromCamera();
                  },
                  icon: Icon(Icons.camera_alt),
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: 50,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object> profileImage;

    if (_imagePath != null && _imagePath!.startsWith("http")) {
      profileImage = NetworkImage(_imagePath!);
    } else {
      profileImage = const AssetImage('assets/profile_image.png');
    }

    if (_selectedPageIndex == 2 && FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _profileName = "profileName";
        _imagePath = null;
      });
    }

    if (_selectedPageIndex == 2 && FirebaseAuth.instance.currentUser != null) {
      _initializeProfile();
    }

    final toRevelPaidUnpaid = ref.watch(toRevelPaidUnpaidProvider);

    return Scaffold(
      appBar: _selectedPageIndex != 2
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.inversePrimary.withAlpha(230),
                      Theme.of(context).colorScheme.primary.withAlpha(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              title: Text(
                _titles[_selectedPageIndex],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: (_selectedPageIndex == 0)
                  ? [
                      IconButton(
                        onPressed: () {
                          if (!toRevelPaidUnpaid) {
                            ref
                                    .watch(toRevelPaidUnpaidProvider.notifier)
                                    .state =
                                true;
                          } else {
                            ref
                                    .watch(toRevelPaidUnpaidProvider.notifier)
                                    .state =
                                false;
                          }
                        },
                        icon: const Icon(Icons.paid),
                      ),
                    ]
                  : [],
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(150),
              child: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.inversePrimary.withAlpha(200),
                        Theme.of(context).colorScheme.primary.withAlpha(175),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                toolbarHeight: 150,
                actions: [
                  Expanded(
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: () async {
                              // 1. Get the current user
                              final user = FirebaseAuth.instance.currentUser;

                              if (user != null) {
                                // Optional: Show a "Checking..." toast if it takes a moment
                                // Utils.showToast("Verifying access...");

                                // 2. Fetch the user document from Firestore
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .get();

                                // 3. Check if the document exists and the 'mode' is 'admin'
                                // (Make sure the field name in Firestore is actually 'mode' or 'role')
                                if (userDoc.exists &&
                                    userDoc.data()?['userMode'] == 'admin') {
                                  // ACCESS GRANTED: Go to Settings
                                  if (!context.mounted)
                                    return; // Safety check before using context after await
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SettingsScreen(),
                                    ),
                                  );
                                } else {
                                  // ACCESS DENIED
                                  Utils.showToast(
                                    "Access Denied: Admins only.",
                                  );
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.admin_panel_settings_sharp,
                              size: 30,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(50),
                                ),
                                onTap: () async {
                                  if (FirebaseAuth.instance.currentUser !=
                                      null) {
                                    await _chooseImagePickerMethod();
                                  } else {
                                    Utils.showToast(
                                      'You need to be logged in to change profile picture',
                                    );
                                  }
                                },
                                child: CircleAvatar(
                                  key: _imageKey,
                                  radius: 45,
                                  backgroundImage: profileImage,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _profileName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      body: _page[_selectedPageIndex],
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        items: const [
          TabItem(icon: Icons.chair, title: 'Seats'),
          TabItem(icon: Icons.list_alt, title: 'Bookings'),
          TabItem(icon: Icons.person, title: 'My'),
        ],
        initialActiveIndex: _selectedPageIndex,
        onTap: (index) {
          setState(() => _selectedPageIndex = index);
        },
      ),
    );
  }
}
