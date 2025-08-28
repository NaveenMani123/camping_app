import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../constants/appColors.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final String text;
  const CustomLoadingIndicator({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 0.8,
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.appColor)),
          ),
          SizedBox(height: 16),
          Text(text, style: TextStyle(color: AppColors.appColor)),
        ],
      ),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const CustomSearchBar({super.key, this.onTap, required this.controller, this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 1),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8), // adjust as needed
            child: SvgPicture.asset('assets/icons/search.svg', width: 20, height: 20),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 30, // shrink default 48 → smaller
            minHeight: 30,
          ),
          filled: true,
          fillColor: const Color(0xFFF0F5F2),
          hintText: 'Where to?',
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF638773), fontWeight: FontWeight.w400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onTap: onTap,
      ),
    );
  }
}

class LocationErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String title;
  final String message;

  const LocationErrorState({
    super.key,
    required this.onRetry,
    this.title = 'Location Error',
    this.message = 'Unable to get your location',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64, color: Color(0xFF638773)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF638773), foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;
  final Color iconColor;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: iconColor), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF638773), foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;

  const EmptyStateView({super.key, required this.message, this.icon = Icons.search_off, this.iconColor = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: iconColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFF00897B),
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF0F5F2),
        contentPadding: const EdgeInsets.symmetric(vertical: 1, horizontal: 16),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF638773),
          fontWeight: FontWeight.w400,
        ),
      ),
      validator: validator,
    );
  }
}

class CustomDropdownField extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String labelText;
  final ValueChanged<String?> onChanged;

  const CustomDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
  });

  @override
  State<CustomDropdownField> createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: widget.value,
      items: widget.items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) {
        widget.onChanged(val);
        setState(() => _isExpanded = false);
      },
      icon: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
      decoration: InputDecoration(
        hintText: widget.labelText,
        filled: true,
        fillColor: const Color(0xFFF0F5F2),
        contentPadding: const EdgeInsets.symmetric(vertical: 1, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF638773),
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
    );
  }
}

