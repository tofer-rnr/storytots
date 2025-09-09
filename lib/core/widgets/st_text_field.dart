import 'package:flutter/material.dart';

class STTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscured;
  final bool readOnly;
  final VoidCallback? onTap;

  final Widget? suffix; // NEW

  const STTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.obscured = false,
    this.readOnly = false,
    this.onTap,
    this.suffix, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscured,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        // keep your existing styling here (borders, fillColor, etc.)
        suffixIcon: suffix, // NEW
      ),
    );
  }
}
