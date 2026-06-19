import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';

Widget buildTextField(
  TextEditingController controller,
  String label, {
  TextInputType inputType = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    keyboardType: inputType,
    decoration: InputDecoration(labelText: label),
  );
}

Widget buildDropdown<T>({
  required String label,
  required T value,
  required List<T> items,
  required String Function(T) getLabel,
  required void Function(T?) onChanged,
}) {
  return DropdownButtonFormField<T>(
    value: value,
    dropdownColor: AppColors.tertiary,
    borderRadius: BorderRadius.circular(12),
    decoration: InputDecoration(labelText: label),
    items:
        items
            .map((e) => DropdownMenuItem<T>(value: e, child: Text(getLabel(e))))
            .toList(),
    onChanged: onChanged,
  );
}
