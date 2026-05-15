// ignore_for_file: file_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextInput extends StatefulWidget {
  final String title;
  final String value;
  final int lines;
  final TextInputType type;
  final Function(dynamic) onSubmit;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const MyTextInput(
      {super.key,
      required this.title,
      required this.lines,
      required this.value,
      required this.type,
      required this.onSubmit,
      this.maxLength,
      this.inputFormatters});

  @override
  State<StatefulWidget> createState() => _MyTextInputState();
}

class _MyTextInputState extends State<MyTextInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _obscureText = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _debounceTimer?.cancel();
        widget.onSubmit(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MyTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync from parent when it's an external change (e.g. form reset),
    // not when parent has a stale value from a previous keystroke.
    if (widget.value != _controller.text) {
      final isExternal = widget.value.isEmpty ||
          widget.value.length >= _controller.text.length;
      if (isExternal) {
        _controller.text = widget.value;
      }
    }
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      widget.onSubmit(value);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
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
              focusNode: _focusNode,
              onChanged: _onChanged,
              keyboardType: widget.type,
              inputFormatters: widget.inputFormatters ??
                  (widget.type ==
                          const TextInputType.numberWithOptions(
                              decimal: false)
                      ? <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ]
                      : null),
              controller: _controller,
              maxLines: widget.lines,
              maxLength: widget.maxLength,
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
