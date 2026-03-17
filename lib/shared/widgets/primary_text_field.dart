import 'package:flutter/material.dart';

class PrimaryTextField extends StatelessWidget {
  const PrimaryTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffix,
    this.maxLines = 1,
    this.helperText,
    this.enabled = true,
    this.focusNode,
    this.formFieldKey,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffix;
  final int maxLines;
  final String? helperText;
  final bool enabled;
  final FocusNode? focusNode;
  final Key? formFieldKey;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: formFieldKey,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        helperText: helperText,
      ),
    );
  }
}
