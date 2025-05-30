import 'package:flutter/material.dart';

class MyRowIII extends StatefulWidget {
  final String title;
  final String image;
  final double availableWidth; // Pass available width

  const MyRowIII({
    super.key,
    required this.title,
    required this.image,
    required this.availableWidth,
  });

  @override
  State<MyRowIII> createState() => _MyRowIIIState();
}

class _MyRowIIIState extends State<MyRowIII> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F1), // Cream color
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
        children: [
          Row(
            children: [
              Image.asset(
                widget.image,
                height: 54,
              ),
              const Expanded(
                child: SizedBox(
                  height: 8,
                ),
              ),
             
            ],
          ),
          const SizedBox(
            width: 8,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(widget.title,
                style: TextStyle(
                  color: const Color(0xff0288D1),
                  fontWeight: FontWeight.bold,
                  fontSize: widget.availableWidth * 0.08,
                )),
          ),
        ],
      ),
    );
  }
}
