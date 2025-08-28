import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:campign_project/features/sites/provider/site.provider.dart';
import 'package:campign_project/features/profile/presentation/providers/user.provider.dart';
import 'package:campign_project/core/widgets/resuable_widgets.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import '../../../../core/constants/appColors.dart';
import '../../../../main.dart';
import '../../../users/repository/user.repository.dart';
import '../models/site.model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data' as typed_data;

import '../../../auth/repository/auth.repository.dart';

class AddFormScreen extends StatefulWidget {
  final SiteModel? existingSite;
  const AddFormScreen({super.key, this.existingSite});

  @override
  State<AddFormScreen> createState() => _AddFormScreenState();
}

class _AddFormScreenState extends State<AddFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  final descController = TextEditingController();
  final addrController = TextEditingController();
  List<String> selectedCategory = [];

  List<File> _imageFiles = [];
  List<File> _videoFiles = [];
  bool _isLoading = false;

  double? _latitude;
  double? _longitude;

  final _picker = ImagePicker();
  final userRepo = UserRepository();
  final allCategories = ["Shaded", "Fire Pit", "Fishing", "Camping"];

  @override
  void initState() {
    _loadExistingData();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    addrController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    if (widget.existingSite != null) {
      final s = widget.existingSite!;
      nameController.text = s.siteName;
      descController.text = s.description;
      addrController.text = s.address;
      selectedCategory = List<String>.from(s.category ?? []);
      _latitude = s.latitude;
      _longitude = s.longitude;
    }
  }

  Future<void> pickVideos() async {
    final pickedList = await _picker.pickMultipleMedia();

    if (pickedList.isNotEmpty) {
      for (final media in pickedList) {
        final List<File> temp = [];
        final ext = extension(media.path).toLowerCase();
        if (ext != '.mp4' && ext != '.mov') continue;
        final videoFile = File(media.path);
        temp.add(videoFile);
        setState(() {
          _videoFiles = temp;
        });
      }
    }
  }

  Future<typed_data.Uint8List?> _compressImageBytes(File file) async {
    final ext = extension(file.path).toLowerCase();
    if (ext == '.png') {
      debugPrint("PNG format not supported for compression");
      return null;
    }
    return await FlutterImageCompress.compressWithFile(file.absolute.path, quality: 80, format: CompressFormat.jpeg);
  }

  Future<void> pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      final List<File> temp = [];

      for (final image in picked) {
        final path = image.path;
        final ext = extension(path).toLowerCase();
        if (ext == '.png') {
          debugPrint('Skipping PNG: $path');
          continue;
        }
        final originalFile = File(path);
        temp.add(originalFile);
      }

      setState(() => _imageFiles = temp);
    }
  }

  Future<String?> _uploadToStorage(typed_data.Uint8List bytes, String siteId, String fileName, String ext) async {
    try {
      final isVideo = ext == '.mp4' || ext == '.mov';
      final isImage = ext == '.jpg' || ext == '.jpeg';

      if (!isVideo && !isImage) return null;

      String? contentType;
      if (isVideo) {
        contentType = 'video/mp4';
      } else {
        contentType = 'image/jpeg';
      }

      final path = isVideo ? 'site_videos/$siteId/$fileName' : 'site_images/$siteId/$fileName';
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putData(bytes, SettableMetadata(contentType: contentType));

      final snap = await uploadTask;
      return await snap.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _getCurrentLocation(BuildContext context) async {
    try {
      _showLoadingDialog(context);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Location permission is required')));
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Dialog(
              backgroundColor: Colors.black.withOpacity(0.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Please wait...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _saveForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthRepository>();
    final currentUser = user.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please Login First')));
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location is required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final siteRef =
          widget.existingSite != null
              ? FirebaseFirestore.instance.collection('sites').doc(widget.existingSite!.id)
              : FirebaseFirestore.instance.collection('sites').doc();

      final siteData = {
        'id': siteRef.id,
        'siteName': nameController.text.trim(),
        'userId': currentUser.uid,
        'description': descController.text.trim(),
        'address': addrController.text.trim(),
        'category': selectedCategory,
        'latitude': _latitude,
        'longitude': _longitude,
        'geohash': GeoHash.fromDecimalDegrees(_latitude!, _longitude!).geohash,
        'coverImages': <String>[],
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (widget.existingSite != null) {
        await siteRef.update(siteData);
      } else {
        await siteRef.set(siteData);
      }
      await Provider.of<SiteProvider>(context, listen: false).addUploadedSite(siteRef.id);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.existingSite != null ? "Site updated!" : "Site added!")));
      if (_imageFiles.isEmpty) return;
      await _saveFormAndUpload(
        siteRef.id,
        currentUser.uid,
        context.read<UserProvider>().user?.name ?? 'Guest',
        _imageFiles.map((f) => f.path).toList(),
        _videoFiles.map((f) => f.path).toList(),
      );

      _uploadMediaInBackground(siteRef, currentUser.uid, context.read<UserProvider>().user?.name ?? 'Guest');
    } catch (e) {
      debugPrint("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFormAndUpload(
    String siteId,
    String userId,
    String userName,
    List<String> imagePaths,
    List<String> videoPaths,
  ) async {
    await Workmanager().registerOneOffTask(
      'upload-task-$siteId',
      'mediaUpload',
      inputData: {
        'siteId': siteId,
        'userId': userId,
        'userName': userName,
        'imagePathsJson': jsonEncode(imagePaths),
        'videoPathsJson': jsonEncode(videoPaths),
      },
      constraints: Constraints(networkType: NetworkType.connected, requiresCharging: false),
      existingWorkPolicy: ExistingWorkPolicy.keep, // optional
    );
  }

  Future<void> _uploadMediaInBackground(DocumentReference siteRef, String userId, String userName) async {
    if (_imageFiles.isEmpty) return;
    final commentRef = await siteRef.collection('comments').add({
      'userId': userId,
      'userName': userName,
      'text': '',
      'likes': [],
      'dislikes': [],
      'timestamp': FieldValue.serverTimestamp(),
    });
    String? coverImageUrl;
    for (final file in _imageFiles) {
      final ext = extension(file.path).toLowerCase();
      if (ext == '.png') continue;

      final bytes = await _compressImageBytes(file);
      if (bytes == null) continue;

      final fileName = "${DateTime.now().millisecondsSinceEpoch}$ext";
      final url = await _uploadToStorage(bytes, siteRef.id, fileName, ext);

      if (url != null) {
        await commentRef.collection('commentImages').add({
          'imageUrl': url,
          'commentId': commentRef.id,
          'timestamp': FieldValue.serverTimestamp(),
          'uploaderName': userName,
          'uploaderId': userId,
        });
        coverImageUrl ??= url;
      }
    }
    if (coverImageUrl != null) {
      await siteRef.set({
        'coverImages': [coverImageUrl],
      }, SetOptions(merge: true));
    }
    for (final file in _videoFiles) {
      try {
        final bytes = await file.readAsBytes();
        final ext = extension(file.path).toLowerCase();
        final fileName = "${DateTime.now().millisecondsSinceEpoch}$ext";
        final url = await _uploadToStorage(bytes, siteRef.id, fileName, ext);

        if (url != null) {
          await siteRef.collection('siteVideos').add({
            'videoUrl': url,
            'uploaderId': userId,
            'uploaderName': userName,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint("Video upload failed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSite != null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(isEditing ? "Edit Site" : "Add Site", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CustomTextFormField(controller: nameController, hintText: 'Site name'),
                SizedBox(height: 20),
                CustomTextFormField(controller: descController, hintText: 'Description'),
                SizedBox(height: 20),
                CustomTextFormField(controller: addrController, hintText: 'Address'),
                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      allCategories.map((category) {
                        return CheckboxListTile(
                          title: Text(category),
                          value: selectedCategory.contains(category),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedCategory.add(category);
                              } else {
                                selectedCategory.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pickImages,
                  icon: const Icon(Icons.image),
                  label: const Text("Select Images"),
                ),
                if (_videoFiles.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        _videoFiles
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text("📹 ${basename(f.path)}", style: const TextStyle(fontSize: 14)),
                              ),
                            )
                            .toList(),
                  ),

                if (_imageFiles.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          _imageFiles
                              .map(
                                (f) => Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Image.file(f, width: 100, height: 100, fit: BoxFit.cover),
                                ),
                              )
                              .toList(),
                    ),
                  ),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _getCurrentLocation(context),
                  icon: const Icon(Icons.my_location),
                  label: const Text("Get Current Location"),
                ),
                if (_latitude != null && _longitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text("Location: ($_latitude, $_longitude)", style: const TextStyle(fontSize: 16)),
                  ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        _saveForm(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.buttonColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        isEditing ? 'Update Site' : 'Submit',
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
