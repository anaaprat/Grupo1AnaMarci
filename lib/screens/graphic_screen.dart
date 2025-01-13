import 'package:flutter/material.dart';

class GraphicsScreen extends StatelessWidget {
  const GraphicsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphics'),
        backgroundColor: Colors.purple,
      ),
      body: const Center(
        child: Text(
          'Graphic logic',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
