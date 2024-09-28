import 'package:flutter/material.dart';


Scaffold loadScreen() {
    return  Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Fruteira"),
      ),
      body: const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 139, 36, 36),
        ),
      ),
    );
  }