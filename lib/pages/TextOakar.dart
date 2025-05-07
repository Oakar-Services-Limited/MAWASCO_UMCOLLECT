import 'package:flutter/material.dart';

class TextOakar extends StatefulWidget {
  final String label;
  final bool issuccessful;

  const TextOakar({
    super.key,
    required this.label,
    this.issuccessful = false,
  });

  @override
  State<StatefulWidget> createState() => _TextOakarState();
}

class _TextOakarState extends State<TextOakar> {
  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.deepOrange; // Default color

    // Update text color based on success or error states
    if (widget.issuccessful) {
      textColor = Colors.green;
    } else {
      textColor = Colors.red;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor, // Apply the determined text color
        ),
      ),
    );
  }
}
