// ignore_for_file: file_names

import 'package:flutter/material.dart';

class FootNote extends StatelessWidget {
  const FootNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(40), // Circular right side
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.5),
              spreadRadius: 0, // Spread radius set to 0
              blurRadius: 7,
              offset: const Offset(4, 4), // Shadow offset for bottom and right
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Text(
                'Powered By',
                style: TextStyle(
                    color: Color(0xff0288D1),
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
              ),
              Text(
                'Oakar Services Ltd',
                style: TextStyle(
                    color: Color(0xff0288D1),
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
