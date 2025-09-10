import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AboutPage extends StatelessWidget {
  final String content;

  const AboutPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // appBar: AppBar(title: const Text("About")),
      body: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Brightness.light == theme.brightness
                  ? Colors.white
                  : const Color.fromARGB(255, 15, 18, 32),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "About the App",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Text(content, style: TextStyle(fontSize: 14, height: 1.5)),
            Html(data: content),
          ],
        ),
      ),
    );
  }
}
