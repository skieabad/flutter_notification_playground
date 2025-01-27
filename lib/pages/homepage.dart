import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Flutter Notification Playground'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Welcome to the Flutter Notification Playground!',
          ),
        ),
      ),
    );
  }
}
