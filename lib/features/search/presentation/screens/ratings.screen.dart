import 'package:flutter/material.dart';
import '../../../../core/constants/appColors.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  final List<String> ratings = List.generate(5, (index) => '${5 - index} star${(5 - index) == 1 ? '' : 's'}');


  late List<bool> isSelected;

  @override
  void initState() {
    isSelected = List.generate(5, (_) => false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const figmaWidth = 338.0;
    const figmaHeight = 598.0;

    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = dialogWidth * (figmaHeight / figmaWidth);
    final maxHeight = screenSize.height * 0.8;
    final finalHeight = dialogHeight > maxHeight ? maxHeight : dialogHeight;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: (screenSize.width - dialogWidth) / 2,
        vertical: (screenSize.height - finalHeight) / 2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: dialogWidth,
        height: finalHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: const Text("Ratings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: ratings.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1, color: AppColors.borderColor),
                      color: isSelected[index] ? AppColors.borderColor : Colors.white,
                    ),
                    child: ListTile(
                      title: Text(
                        ratings[index],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                      trailing: Icon(
                        isSelected[index] ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected[index] ? Colors.black : Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          isSelected[index] = !isSelected[index];
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.buttonColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
