import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Help'),
        centerTitle: true,
        forceMaterialTransparency: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileSection(
              sectionHeading: "General",
              fields: [
                ProfileField(
                  heading: "How to list a campsite",
                  onPressed: () {
                  },
                ),
                ProfileField(
                  heading: "How to verify a campsite",
                  onPressed: () {
                  },
                ),
                ProfileField(
                  heading: "How to leave a review",
                  onPressed: () {

                  },
                ),
                ProfileField(
                  heading: "How to report to campsite",
                  onPressed: () {
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            ProfileSection(
              sectionHeading: 'Community',
              fields: [
                ProfileField(
                  heading: "Community guidelines",
                  onPressed: () {
                  },
                ),
                ProfileField(
                  heading: "Terms of service",
                  onPressed: () {
                  },
                ),
                ProfileField(
                  heading: "Privacy policy",
                  onPressed: () {
                    // Navigate or show dialog
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String sectionHeading;
  final List<ProfileField> fields;

  const ProfileSection({super.key, required this.sectionHeading, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sectionHeading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        const SizedBox(height: 8),
        ...fields.map((field) => ProfileTextRow(heading: field.heading, onPressed: field.onPressed)),
      ],
    );
  }
}

class ProfileTextRow extends StatelessWidget {
  final String heading;
  final VoidCallback? onPressed;

  const ProfileTextRow({super.key, required this.heading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(heading, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16))],
          ),
        ),

        if (onPressed != null) IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18), onPressed: onPressed),
      ],
    );
  }
}

class ProfileField {
  final String heading;
  final VoidCallback? onPressed;

  ProfileField({required this.heading, this.onPressed});
}
