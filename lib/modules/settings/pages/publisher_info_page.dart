import 'package:flutter/material.dart';

class PublisherInfoPage extends StatelessWidget {
  const PublisherInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Publisher Info")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Publisher name, contact details, and description."),
      ),
    );
  }
}
