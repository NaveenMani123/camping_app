import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/constants/appColors.dart';

class CategoryScreen extends StatefulWidget {
  final List<String>? preSelectedCategories;
  const CategoryScreen({super.key, this.preSelectedCategories});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late List<bool> isSelected;
  final List<Map<String, String>> categories = [
    {'name': 'Shaded', 'icon': 'assets/icons/shaded.svg'},
    {'name': 'Fire Pit', 'icon': 'assets/icons/fire_pit.svg'},
    {'name': 'Fishing', 'icon': 'assets/icons/fishing.svg'},
    {'name': 'Camping', 'icon': 'assets/icons/camping.svg'},
  ];
  List<int> selectedCategoryIndices = [];

  @override
  void initState() {
    if (widget.preSelectedCategories != null) {
      selectedCategoryIndices = [];
      for (var i = 0; i < categories.length; i++) {
        if (widget.preSelectedCategories!.contains(categories[i]['name'])) {
          selectedCategoryIndices.add(i);
        }
      }
    }
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
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: const Text("Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: SingleChildScrollView(child: _buildCategorySection())),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    final selectedCategories =
                        selectedCategoryIndices
                            .map((i) => categories[i]['name'])
                            .whereType<String>()
                            .toList();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.of(context).pop(selectedCategories);
                      }
                    });
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

  Widget _buildCategorySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          width: screenWidth,
          child: CategoriesGrid(
            categories: categories,
            initialSelectedIndices: selectedCategoryIndices,
            onSelectionChanged: (indices) {
              selectedCategoryIndices = indices;
            },
          ),
        ),
      ],
    );
  }
}

class CategoriesGrid extends StatefulWidget {
  final List<Map<String, String>> categories;
  final List<int> initialSelectedIndices;
  final Function(List<int>) onSelectionChanged;

  const CategoriesGrid({
    super.key,
    required this.categories,
    this.initialSelectedIndices = const [],
    required this.onSelectionChanged,
  });

  @override
  State<CategoriesGrid> createState() => _CategoriesGridState();
}

class _CategoriesGridState extends State<CategoriesGrid> {
  late Set<int> selectedIndices;
  @override
  void initState() {
    selectedIndices = widget.initialSelectedIndices.toSet();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseDesignWidth = 390.0; // Figma base width
    final containerWidth = screenWidth * (142.5 / baseDesignWidth);
    final containerHeight = screenWidth * (58 / baseDesignWidth);

    final isWide = screenWidth > 600;
    final crossAxisCount = isWide ? 3 : 2;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.categories.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 3.5 : 2.5,
      ),
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        final name = category['name'] ?? 'Category';
        final iconPath = category['icon'] ?? '';

        final isSelected = selectedIndices.contains(index);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedIndices.remove(index);
              } else {
                selectedIndices.add(index);
              }
              widget.onSelectionChanged(selectedIndices.toList());
            });
          },
          child: Container(
            width: containerWidth,
            height: containerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.borderColor : Colors.transparent,
              border: Border.all(color: const Color(0xFFDBE5DE), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: Colors.black,
                  placeholderBuilder: (context) => const SizedBox(width: 24, height: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
