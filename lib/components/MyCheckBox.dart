import 'package:flutter/material.dart';

class MyCheckBox extends StatefulWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onSubmit;

  const MyCheckBox({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onSubmit,
  });

  @override
  State<StatefulWidget> createState() => _MyCheckBoxState();
}

class _MyCheckBoxState extends State<MyCheckBox> {
  late List<bool> _isSelectedList;

  @override
  void initState() {
    super.initState();
    _isSelectedList = List.generate(widget.options.length, (index) {
      return widget.selectedOptions.contains(widget.options[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.options.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                setState(() {
                  _isSelectedList[index] = !_isSelectedList[index];
                  _updateSelectedOptions();
                });
              },
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align top for long text
                    children: <Widget>[
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xff0288D1), // Border color
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _isSelectedList[index]
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Color(0xff0288D1), // Tick color
                              )
                            : null,
                      ),
                      Expanded(
                        // Expanded allows the text to take available space
                        child: Text(
                          widget.options[index],
                          style: const TextStyle(color: Color(0xff0288D1)),
                          softWrap: true, // Allows text to wrap
                          maxLines:
                              null, // Text will wrap to any number of lines
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _updateSelectedOptions() {
    List<String> selectedOptions = [];
    for (int i = 0; i < _isSelectedList.length; i++) {
      if (_isSelectedList[i]) {
        selectedOptions.add(widget.options[i]);
      }
    }
    widget.onSubmit(selectedOptions);
  }
}
