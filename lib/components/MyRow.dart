import 'package:flutter/material.dart';

class MyRow extends StatefulWidget {
  final String no;
  final String title;
  final String image;

  const MyRow({
    super.key,
    required this.no,
    required this.title,
    required this.image,
  });

  @override
  State<MyRow> createState() => _MyRowState();
}

class _MyRowState extends State<MyRow> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F1), // Cream color
        borderRadius: BorderRadius.circular(15),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          right: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          top: BorderSide.none,
          left: BorderSide.none,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(82, 158, 158, 158),
            offset: Offset(2.0, 2.0),
            blurRadius: 5.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                Image.asset(
                  widget.image,
                  height: 80,
                ),
                const SizedBox(
                  width: 40,
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    softWrap: true,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0288D1),
                    ),
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.arrow_forward,
                color: Color(0xff0288D1),
              ),
            )
          ],
        ),
      ),
    );
  }
}
