import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

SpeedDial multipleFloatingActionButtons() {
  return SpeedDial(
    animatedIcon: AnimatedIcons.menu_close,
    children: [
      SpeedDialChild(
        child: const Icon(Icons.add),
        label: 'Adicionar nova lista',
        onTap: () {},
      ),
      SpeedDialChild(
        child: const Icon(Icons.delete),
        label: 'Deletar lista',
        onTap: () {},
      ),
    ],
  );
}




SizedBox textFormFieldPers(TextEditingController controller, String labelText, {
  Widget? prefix,
  TextInputType keyboardType = TextInputType.name, 
  bool expands = false,
  double? height, 
  int maxLength = 21,
  bool enabled = true,
  void Function(String)? onChanged
  }){
    
  return SizedBox(
    width: 300,
    child: Padding(
      padding: const EdgeInsets.all(5), 
      child: 
    TextFormField(
      onChanged: onChanged,
      expands: expands,
      enabled: enabled,
      maxLength: maxLength,
      controller: controller,
      keyboardType: keyboardType,
      minLines: null,
      maxLines: null,
      decoration: InputDecoration(
        prefix: prefix,
        labelText: labelText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5))
          )
        ),
      ),
    )
  );
}