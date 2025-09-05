// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class PorterCaseDetailScreen extends StatefulWidget {
  const PorterCaseDetailScreen({super.key});

  @override
  _PorterCaseDetailScreen createState() => _PorterCaseDetailScreen();
}

class _PorterCaseDetailScreen extends State<PorterCaseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดเคส'),
        automaticallyImplyLeading: false,
      ),
      body: Center(child: Text('รายละเอียดเคสเปลคนไข้')),
    );
  }
}
