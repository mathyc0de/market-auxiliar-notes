import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

SpeedDial themedSpeedDial({
  required BuildContext context,
  required List<SpeedDialChild> children,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return SpeedDial(
    animatedIcon: AnimatedIcons.menu_close,
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    overlayColor: colorScheme.scrim,
    children: children,
  );
}

SizedBox textFormFieldPers(
  TextEditingController controller,
  String labelText, {
  Widget? prefix,
  TextInputType keyboardType = TextInputType.name,
  bool expands = false,
  double? height,
  int maxLength = 25,
  bool enabled = true,
  void Function(String value)? onChanged,
  FocusNode? focusNode,
}) {
  return SizedBox(
    width: double.infinity,
    child: TextFormField(
      onChanged: onChanged,
      expands: expands,
      enabled: enabled,
      maxLength: maxLength,
      controller: controller,
      keyboardType: keyboardType,
      focusNode: focusNode,
      minLines: null,
      maxLines: null,
      decoration: InputDecoration(
        prefix: prefix,
        labelText: labelText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );
}
