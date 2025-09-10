import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class PublisherInfoPage extends StatelessWidget {
  final String content;
  const PublisherInfoPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Html(data: content),
      ),
    );
  }
}
