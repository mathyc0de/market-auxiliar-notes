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




SizedBox textFormFieldPers(TextEditingController controller, String labelText, {TextInputType keyboardType = TextInputType.name, double? height}){
  return SizedBox(
    width: 300,
    child: Padding(
      padding: const EdgeInsets.all(5), 
      child: 
    TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: null,
      maxLines: null,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5))
          )
        ),
      ),
    )
  );
}