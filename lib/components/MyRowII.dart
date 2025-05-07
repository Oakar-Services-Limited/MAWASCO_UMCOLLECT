import 'package:flutter/material.dart';

class MyRowII extends StatefulWidget {
  final String no;
  final String title;
  final String image;
  final double availableWidth; // Pass available width

  const MyRowII({
    super.key,
    required this.no,
    required this.title,
    required this.image,
    required this.availableWidth,
  });

  @override
  State<MyRowII> createState() => _MyRowIIState();
}

class _MyRowIIState extends State<MyRowII> {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                widget.image,
                height: widget.availableWidth *
                    0.3, // Scale image size based on width
                width: widget.availableWidth * 0.5,
              ),
              const SizedBox(
                width: 8,
              ),
              if (widget.no.isNotEmpty)
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      widget.no,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0288D1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            widget.title,
            style: TextStyle(
              color: const Color(0xff0288D1),
              fontWeight: FontWeight.bold,
              fontSize: widget.availableWidth * 0.08, // Scale text size
            ),
          ),
        ],
      ),
    );
  }
}
