import 'package:flutter/material.dart';

class CommonSearchField extends StatelessWidget {
  final TextEditingController controller;
  final double width;
  final TextAlign textAlign;
  final VoidCallback? onSubmitted;
  final String? hintText;

  const CommonSearchField({
    super.key,
    required this.controller,
    this.width = 120,
    this.textAlign = TextAlign.start,
    this.onSubmitted,
    this.hintText = 'Search',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 30,
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 5.0,
            horizontal: 0.0,
          ),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2.0,
            ),
          ),
        ),
        onSubmitted: (_) => onSubmitted?.call(),
      ),
    );
  }
}