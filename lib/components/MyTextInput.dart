// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextInput extends StatefulWidget {
  final String title;
  final String value;
  final int lines;
  final TextInputType type;
  final Function(dynamic) onSubmit;

  const MyTextInput(
      {super.key,
      required this.title,
      required this.lines,
      required this.value,
      required this.type,
      required this.onSubmit});

  @override
  State<StatefulWidget> createState() => _MyTextInputState();
}

class _MyTextInputState extends State<MyTextInput> {
  final TextEditingController _controller = TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MyTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _controller.text =
            widget.value != "null" ? widget.value.toString() : '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          hintColor: Colors.white,
          inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff0288D1))),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue)))),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: TextField(
              onChanged: (value) {
                widget.onSubmit(value);
              },
              keyboardType: widget.type,
              inputFormatters: widget.type ==
                      const TextInputType.numberWithOptions(decimal: false)
                  ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                  : null,
              controller: _controller,
              maxLines: widget.lines,
              style: const TextStyle(color: Color(0xff0288D1)),
              cursorColor: const Color(0xff0288D1),
              obscureText: widget.type == TextInputType.visiblePassword
                  ? _obscureText
                  : false,
              enableSuggestions: true,
              autocorrect: false,
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8),
                  hintStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xff0288D1), width: 0.0),
                  ),
                  focusColor: Colors.blue,
                  border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0)),
                  filled: false,
                  label: Text(
                    widget.title.toString(),
                    style: const TextStyle(color: Color(0xff0288D1)),
                  ),
                  suffixIcon: widget.type == TextInputType.visiblePassword
                      ? IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        )
                      : null,
                  floatingLabelBehavior: FloatingLabelBehavior.auto))),
    );
  }
}
