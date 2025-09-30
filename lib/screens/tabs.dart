import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seat_sync_v2/screens/booking.dart';
import 'package:seat_sync_v2/screens/profile.dart';
import 'package:seat_sync_v2/screens/seat_map.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:seat_sync_v2/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedPageIndex = 0;
  String _profileName = "profileName";
  //String? _profileImageUrl;
  final List<String> _titles = ['Seat Map', 'Bookings', 'My Profile'];
  late List<Widget> _page;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imagePath;
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
    final prefs = await SharedPreferences.getInstance();
    _imagePath = prefs.getString('profile_pic_path');

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
        _imageFile = newImage;
        _imagePath = newImage.path;
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
        _imageFile = newImage;
        _imagePath = newImage.path;
      });
      //saving image in local storage using shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('profile_pic_path', _imagePath!);
    } catch (e) {
      debugPrint('-----galary pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: _selectedPageIndex != 2
          ? AppBar(
              title: Text(
                _titles[_selectedPageIndex],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            )
          : AppBar(
              toolbarHeight: 150,
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: [
                Expanded(
                  child: Stack(
                    children: [
                      // Settings icon top-right
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.settings),
                        ),
                      ),
                      // Person icon center-right
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),

                              onTap: _chooseImagePickerMethod,
                              child: CircleAvatar(
                                radius: 45,
                                backgroundImage: _imagePath != null
                                    ? FileImage(File(_imagePath!))
                                    : AssetImage('assets/profile_image.png'),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _profileName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      body: _page[_selectedPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedPageIndex,
        onTap: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chair), label: 'Seats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My'),
        ],
      ),
    );
  }
}
