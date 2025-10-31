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

import 'package:seat_sync_v2/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  //String? _profileImageUrl;
  final List<String> _titles = ['Seat Map', 'Bookings', 'My Profile'];
  late List<Widget> _page;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imagePath;
  var _imageKey;
  //final _auth = FirebaseAuth.instance;

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
    //returive profile pic path from shared preferences if it present, otherwise null will be retured
    if (_imagePath == null) {
      final prefs = await SharedPreferences.getInstance();
      _imagePath = prefs.getString('profile_pic_path');
    }
    //retiving document from 'users' collection from firebstore
    var uid = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        _profileName = data['username'] ?? "profileName";
        //_profileImageUrl = data.containsKey('profileImageUrl')
        //     ? data['profileImageUrl']
        //     : null;
      });
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
                    //await _uploadAndSetProfilePicture();
                  },
                  icon: Icon(Icons.file_copy_sharp),
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: 50,
                ),
                SizedBox(width: 20),
                IconButton(
                  onPressed: () async {
                    await _setProfilePictureFromCamera();
                    //await _uploadAndSetProfilePicture();
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

  // Future<void> _uploadAndSetProfilePicture() async {
  //   if (_imageFile != null) {
  //     String? imageUrl = await _uploadImageToFireStorage(_imageFile!);

  //     if (_auth.currentUser != null && imageUrl != null) {
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(FirebaseAuth.instance.currentUser!.uid)
  //           .update({'profileImageUrl': imageUrl});
  //       setState(() {
  //         _profileImageUrl = imageUrl;
  //       });
  //       Utils.showToast('Profile picture updated');
  //     } else {
  //       Utils.showToast('Error uploading image');
  //     }
  //   } else {
  //     Utils.showToast('No image selected');
  //   }
  // }

  // Future<String?> _uploadImageToFireStorage(File imageFile) async {
  //   try {
  //     final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  //     final ref = FirebaseStorage.instance.ref().child(
  //       'profile_pics/$fileName.jpg',
  //     );

  //     await ref.putFile(imageFile); //fire storage pay upload kar dia image

  //     // Get download URL
  //     final url = await ref.getDownloadURL();
  //     return url;
  //   } catch (e) {
  //     debugPrint("------Upload error: $e");
  //     return null;
  //   }
  // }

  Future<void> _setProfilePictureFromCamera() async {
    Navigator.pop(context);
    // Implement camera functionality here
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;
      // permanent directory
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = '${directory.path}/profile_pic.jpg';

      // copy file
      final File newImage = await File(picked.path).copy(newPath);

      setState(() {
        //_imageFile = newImage;
        _imagePath = newImage.path;
        _imageKey = UniqueKey();
      });
      //saving image in local storage using shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('profile_pic_path', _imagePath!);
    } catch (e) {
      debugPrint('-----Camera pick error: $e');
    }
  }

  Future<void> _setProfilePictureFromGallery() async {
    Navigator.pop(context);
    // Implement camera functionality here
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;
      // permanent directory
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = '${directory.path}/profile_pic.jpg';

      // copy file
      final File newImage = await File(picked.path).copy(newPath);

      setState(() {
        //_imageFile = newImage;
        _imagePath = newImage.path;
        _imageKey = UniqueKey();
      });

      debugPrint('-----newimage path: $_imagePath');
      debugPrint('-----new path: $newPath');

      //saving image in local storage using shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('profile_pic_path', _imagePath!);
    } catch (e) {
      debugPrint('-----galary pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object> profileImage;
    if (_imagePath != null) {
      // Add a unique key using the last modified timestamp to bust the cache.
      // This is an alternative to the ValueKey on the CircleAvatar itself.
      profileImage = FileImage(File(_imagePath!));
    } else {
      profileImage = const AssetImage('assets/profile_image.png');
    }
    //if not logged in, set default profile name and pic
    if (_selectedPageIndex == 2 && FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _profileName = "profileName";
        _imagePath = null;
      });
    }
    //agar login ho chuka hai to profile name and pic initialize karo
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
                      ).colorScheme.inversePrimary.withOpacity(0.95),
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings),
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
        style: TabStyle.react, // options: fixed, react, flip, textIn, textOut
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
