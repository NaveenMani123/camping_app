import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

//
// class SiteImagesCarousel extends StatelessWidget {
//   final String siteId;
//   final PageController pageController;
//   final void Function(int)? onPageChanged;
//
//   const SiteImagesCarousel({
//     super.key,
//     required this.siteId,
//     required this.pageController,
//     this.onPageChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('sites')
//           .doc(siteId)
//           .collection('siteImages')
//           .orderBy('timeStamp', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         final allUrls = snapshot.data!.docs.expand((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           final urls = data['imageUrl'];
//           if (urls is List) {
//             return List<String>.from(urls);
//           } else if (urls is String) {
//             return [urls];
//           } else {
//             return [];
//           }
//         }).toList();
//
//         if (allUrls.isEmpty) {
//           return const Center(child: Text('No images yet.'));
//         }
//
//         return PageView(
//           controller: pageController,
//           onPageChanged: onPageChanged,
//           children: allUrls.map((url) {
//             return Image.network(
//               url,
//               fit: BoxFit.cover,
//               width: double.infinity,
//               errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
//               loadingBuilder: (context, child, progress) {
//                 if (progress == null) return child;
//                 return const Center(child: CircularProgressIndicator());
//               },
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
// }
// class SiteImagesCarousel extends StatelessWidget {
//   final String siteId;
//   final PageController pageController;
//   final void Function(int)? onPageChanged;
//
//   const SiteImagesCarousel({super.key, required this.siteId, required this.pageController, this.onPageChanged});
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
//
//     return StreamBuilder<QuerySnapshot>(
//       stream:
//           FirebaseFirestore.instance
//               .collection('sites')
//               .doc(siteId)
//               .collection('siteImages')
//               .orderBy('timeStamp', descending: true)
//               .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         final docs = snapshot.data!.docs;
//
//         if (docs.isEmpty) {
//           return const Center(child: Text('No images yet.'));
//         }
//
//         return PageView(
//           controller: pageController,
//           onPageChanged: onPageChanged,
//           children:
//               docs.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 final imageUrl = data['imageUrl'] as String?;
//                 final uploaderId = data['uploaderId'] as String?;
//                 return Stack(
//                   children: [
//                     Positioned.fill(
//                       child: Image.network(
//                         imageUrl ?? '',
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
//                         loadingBuilder: (context, child, progress) {
//                           if (progress == null) return child;
//                           return const Center(child: CircularProgressIndicator());
//                         },
//                       ),
//                     ),
//                     if (uploaderId == currentUser?.uid)
//                       Positioned(
//                         top: 10,
//                         right: 10,
//                         child: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () async {
//                             final confirm = await showDialog<bool>(
//                               context: context,
//                               builder:
//                                   (ctx) => AlertDialog(
//                                     title: const Text("Delete Image?"),
//                                     content: const Text("Are you sure you want to delete this image?"),
//                                     actions: [
//                                       TextButton(
//                                         onPressed: () => Navigator.pop(ctx, false),
//                                         child: const Text("Cancel"),
//                                       ),
//                                       TextButton(
//                                         onPressed: () => Navigator.pop(ctx, true),
//                                         child: const Text("Delete"),
//                                       ),
//                                     ],
//                                   ),
//                             );
//
//                             if (confirm == true) {
//                               // Delete from Storage (optional, if you have imageRef stored)
//                               try {
//                                 final ref = FirebaseStorage.instance.refFromURL(imageUrl!);
//                                 await ref.delete();
//                               } catch (_) {}
//
//                               // Delete from Firestore
//                               await doc.reference.delete();
//                             }
//                           },
//                         ),
//                       ),
//                   ],
//                 );
//               }).toList(),
//         );
//       },
//     );
//   }
// }
// class SiteImagesSection extends StatelessWidget {
//   final String siteId;
//
//   const SiteImagesSection({super.key, required this.siteId});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream:
//           FirebaseFirestore.instance
//               .collection('sites')
//               .doc(siteId)
//               .collection('siteImages')
//               .orderBy('timeStamp', descending: true)
//               .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         final docs = snapshot.data!.docs;
//
//         if (docs.isEmpty) {
//           return const Center(child: Text("No images yet."));
//         }
//
//         final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//
//         return PageView(
//           children:
//               docs.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 final imageUrl = data['imageUrl'] as String?;
//                 final uploaderId = data['uploaderId'] as String?;
//                 final docId = doc.id;
//
//                 return Stack(
//                   children: [
//                     if (imageUrl != null) Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
//                     if (currentUserId != null && currentUserId == uploaderId)
//                       Positioned(
//                         top: 10,
//                         right: 10,
//                         child: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () async {
//                             await FirebaseFirestore.instance
//                                 .collection('sites')
//                                 .doc(siteId)
//                                 .collection('siteImages')
//                                 .doc(docId)
//                                 .delete();
//                           },
//                         ),
//                       ),
//                   ],
//                 );
//               }).toList(),
//         );
//       },
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SiteImagesSection extends StatefulWidget {
  final String siteId;

  const SiteImagesSection({super.key, required this.siteId});

  @override
  State<SiteImagesSection> createState() => _SiteImagesSectionState();
}

class _SiteImagesSectionState extends State<SiteImagesSection> {
  final PageController _pageController = PageController();
  int currentIndex = 0;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('sites')
              .doc(widget.siteId)
              .collection('siteImages')
              .orderBy('timeStamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(height: 250, child: Center(child: Text('No images found.')));
        }

        final docs = snapshot.data!.docs;

        final List<_ImageItem> imageItems = [];
        for (var doc in docs) {
          final List<dynamic> urls = doc['imageUrl'] ?? [];
          final uploaderId = doc['uploaderId'];
          final uploaderName = doc['uploaderName'] ?? "Unknown";
          final docId = doc.id;

          for (var url in urls) {
            imageItems.add(_ImageItem(url: url, uploaderId: uploaderId, uploaderName: uploaderName, docId: docId));
          }
        }

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                itemCount: imageItems.length,
                onPageChanged: (i) => setState(() => currentIndex = i),
                itemBuilder: (context, index) {
                  final image = imageItems[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {}, // Empty gesture to ensure gestures are detected
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: image.url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'Uploaded by: ${image.uploaderName}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        if (image.uploaderId == currentUserId)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () async {
                                await _deleteImage(image.docId, image.url);
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildDotsIndicator(imageItems.length),
          ],
        );
      },
    );
  }

  Widget _buildDotsIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == i ? 12 : 8,
          height: currentIndex == i ? 12 : 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: currentIndex == i ? Colors.blue : Colors.grey),
        ),
      ),
    );
  }

  Future<void> _deleteImage(String docId, String urlToRemove) async {
    final docRef = FirebaseFirestore.instance
        .collection('sites')
        .doc(widget.siteId)
        .collection('siteImages')
        .doc(docId);

    final doc = await docRef.get();
    if (doc.exists) {
      final List<dynamic> urls = doc['imageUrl'] ?? [];
      urls.remove(urlToRemove);
      await docRef.update({'imageUrl': urls});
    }
  }
}

class _ImageItem {
  final String url;
  final String uploaderId;
  final String uploaderName;
  final String docId;

  _ImageItem({required this.url, required this.uploaderId, required this.uploaderName, required this.docId});
}
