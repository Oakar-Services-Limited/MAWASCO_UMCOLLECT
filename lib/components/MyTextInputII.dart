// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class MyTextInputII extends StatefulWidget {
  String hint;
  String value;
  int lines;
  var type;
  Color mycolor;
  Color iconcolor;
  IconData customIcon;
  Function(String) onSubmit;

  MyTextInputII(
      {super.key,
      required this.hint,
      required this.lines,
      required this.value,
      required this.type,
      required this.mycolor,
      required this.iconcolor,
      required this.customIcon,
      required this.onSubmit});

  @override
  State<StatefulWidget> createState() => _MyTextInputIIState();
}

class _MyTextInputIIState extends State<MyTextInputII> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MyTextInputII oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != "") {
      setState(() {
        _controller.value = TextEditingValue(
          text: widget.value,
          selection: TextSelection.fromPosition(
            TextPosition(offset: widget.value.length),
          ),
        );
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
              setState(() {
                _controller.value = TextEditingValue(
                  text: value,
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: value.length),
                  ),
                );
              });
              widget.onSubmit(value);
            },
            keyboardType: widget.type,
            controller: _controller,
            maxLines: widget.lines,
            obscureText:
                widget.type == TextInputType.visiblePassword ? true : false,
            enableSuggestions: false,
            autocorrect: false,
            style:
                TextStyle(color: widget.mycolor), // Set the text color to white

            decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                ),
                contentPadding: const EdgeInsets.all(12),
                border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xff0288D1))),
                filled: false,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                prefixIcon: Icon(
                  widget.customIcon,
                  color: widget.iconcolor,
                )),
          ),
        ));
  }
}
