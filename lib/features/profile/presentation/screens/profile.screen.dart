import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../../../home/presentation/screens/home.screen.dart';

// class AppUser {
//   final String uid;
//   final String name;
//   final String? phone;
//   final int? age;
//   final String? gender;
//   final String? email;
//   final String? profileImageUrl;
//   final List<dynamic>? savedSites;
//   final List<dynamic>? uploadedSites;
//   final String? fcmToken;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;
//
//   const AppUser({
//     required this.uid,
//     required this.name,
//     this.phone,
//     this.age,
//     this.gender,
//     this.savedSites,
//     this.uploadedSites,
//     this.email,
//     this.fcmToken,
//     this.profileImageUrl,
//     this.createdAt,
//     this.updatedAt,
//   });
//
//   factory AppUser.fromMap(Map<String, dynamic> map) {
//     try {
//       return AppUser(
//         uid: map['uid'] as String,
//         name: map['name'] as String,
//         phone: map['phone'] as String,
//         age: (map['age'] as num).toInt(),
//         gender: map['gender'] as String,
//         savedSites: map['savedSites'],
//         uploadedSites: map['uploadedSites'],
//         email: map['email'] as String?,
//         fcmToken: map['fcmToken'],
//         profileImageUrl: map['profileImageUrl'] as String?,
//         createdAt: map['createdAt']?.toDate(),
//         updatedAt: map['updatedAt']?.toDate(),
//       );
//     } catch (e) {
//       throw FormatException('Failed to parse AppUser: $e');
//     }
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'name': name,
//       'phone': phone,
//       'age': age,
//       'gender': gender,
//       'fcmToken': fcmToken,
//       'savedSites': savedSites,
//       'uploadedSites': uploadedSites,
//       if (email != null) 'email': email,
//       if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
//       'createdAt': createdAt ?? FieldValue.serverTimestamp(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     };
//   }
//
//   AppUser copyWith({
//     String? name,
//     String? phone,
//     int? age,
//     String? gender,
//     String? email,
//     String? profileImageUrl,
//     List<dynamic>? savedSites,
//     List<dynamic>? uploadedSites,
//     DateTime? updatedAt,
//   }) {
//     return AppUser(
//       uid: uid,
//       name: name ?? this.name,
//       phone: phone ?? this.phone,
//       age: age ?? this.age,
//       gender: gender ?? this.gender,
//       email: email ?? this.email,
//       fcmToken: fcmToken ?? this.fcmToken,
//       profileImageUrl: profileImageUrl ?? this.profileImageUrl,
//       savedSites: savedSites ?? this.savedSites,
//       uploadedSites: uploadedSites ?? this.uploadedSites,
//       createdAt: createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }
//
//   @override
//   String toString() {
//     return 'AppUser(uid: $uid, name: $name, phone: $phone, age: $age, gender: $gender)';
//   }
//
//   String get initials {
//     final nameParts = name.split(' ');
//     if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
//     return '${nameParts[0][0]}${nameParts.last[0]}'.toUpperCase();
//   }
//
//   static bool isValidAge(int age) => age > 0 && age < 120;
//
//   static bool isValidGender(String gender) {
//     return ['male', 'female', 'other'].contains(gender.toLowerCase());
//   }
//
//   static bool isValidPhone(String phone) {
//     return phone.startsWith('+') && phone.length > 8;
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String? profileImageUrl;
  final String? fcmToken;
  final List<dynamic>? savedSites;
  final List<dynamic>? uploadedSites;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.name,
    this.profileImageUrl,
    this.fcmToken,
    this.savedSites,
    this.uploadedSites,
    this.createdAt,
    this.updatedAt,
  });

  AppUser copyWith({
    String? name,
    String? profileImageUrl,
    String? fcmToken,
    List<dynamic>? savedSites,
    List<dynamic>? uploadedSites,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid, // keep uid fixed
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      savedSites: savedSites ?? this.savedSites,
      uploadedSites: uploadedSites ?? this.uploadedSites,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Guest',
      profileImageUrl: map['profileImageUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      savedSites: map['savedSites'] ?? [],
      uploadedSites: map['uploadedSites'] ?? [],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'fcmToken': fcmToken,
      'savedSites': savedSites ?? [],
      'uploadedSites': uploadedSites ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get initials {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  AppUser? _user;
  File? _imageFile;


  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    if (doc.exists) {
      _user = AppUser.fromMap(doc.data()!);
      _nameController.text = _user?.name ?? '';
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _showLoadingDialog();

    try {
      String? imageUrl = _user?.profileImageUrl;
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (_imageFile != null) {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${currentUser.uid}.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final updatedUser = AppUser(
        uid: currentUser.uid,
        name: _nameController.text.trim(),
        fcmToken: fcmToken,
        profileImageUrl: imageUrl,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(updatedUser.toMap(), SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context); // dismiss dialog
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss dialog
      // _showErrorDialog(e.toString());
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => WillPopScope(
            onWillPop: () async => false,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const Dialog(
                backgroundColor: Colors.white,
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Saving profile...")],
                  ),
                ),
              ),
            ),
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_user?.profileImageUrl != null ? NetworkImage(_user!.profileImageUrl!) : null)
                            as ImageProvider?,
                child:
                    (_imageFile == null && _user?.profileImageUrl == null)
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProfile, child: const Text("Save Profile")),
          ],
        ),
      ),
    );
  }
}
