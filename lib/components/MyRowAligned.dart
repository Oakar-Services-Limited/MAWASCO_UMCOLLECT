import 'package:flutter/material.dart';

class MyRowAligned extends StatefulWidget {
  final String no;
  final String title;
  final String image;
  final double availableWidth; // Pass available width

  const MyRowAligned({
    super.key,
    required this.no,
    required this.title,
    required this.image,
    required this.availableWidth,
  });

  @override
  State<MyRowAligned> createState() => _MyRowAlignedState();
}

class _MyRowAlignedState extends State<MyRowAligned> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(82, 158, 158, 158),
            offset: Offset(2.0, 2.0),
            blurRadius: 5.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            widget.image,
            height: widget.availableWidth * 0.5, // Keep consistent scaling
            width: widget.availableWidth * 0.5, // Maintain aspect ratio
          ),
          const SizedBox(height: 20), // Space between image and text
          Text(
            widget.title,
            textAlign: TextAlign.center, // Center the text
            style: TextStyle(
              color: const Color(0xff0288D1),
              fontWeight: FontWeight.bold,
              fontSize: widget.availableWidth * 0.12, // Scale text size
            ),
          ),
        ],
      ),
    );
  }
}
