import 'dart:async';
import 'package:flutter/material.dart';

class MySearchableSelectInput extends StatefulWidget {
  final String label;
  final String value;
  final List<String> list;
  final Function(String) onSubmit;
  final double? labelFontSize;
  final bool enabled;

  const MySearchableSelectInput({
    super.key,
    required this.list,
    required this.label,
    required this.onSubmit,
    required this.value,
    this.labelFontSize,
    this.enabled = true,
  });

  @override
  State<StatefulWidget> createState() => _MySearchableSelectInputState();
}

class _MySearchableSelectInputState extends State<MySearchableSelectInput> {
  late String _selectedOption;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredList = [];
  bool _isExpanded = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.value != "" &&
            widget.value != "null" &&
            widget.value != "0" &&
            widget.list.contains(widget.value)
        ? widget.value
        : widget.list.isNotEmpty
            ? widget.list.first
            : "";
    _filteredList = List.from(widget.list);
    if (_selectedOption.isNotEmpty) {
      _searchController.text = _selectedOption;
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant MySearchableSelectInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _selectedOption = widget.value != "" &&
                widget.value != "null" &&
                widget.value != "0" &&
                widget.list.contains(widget.value)
            ? widget.value
            : widget.list.isNotEmpty
                ? widget.list.first
                : "";
        if (_selectedOption.isNotEmpty) {
          _searchController.text = _selectedOption;
        }
      });
    }
    if (oldWidget.list != widget.list) {
      setState(() {
        _filteredList = List.from(widget.list);
      });
    }
  }

  void _filterList(String query) {
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredList = List.from(widget.list);
      } else {
        _filteredList = widget.list
            .where((item) =>
                item.toLowerCase().contains(query.toLowerCase()) &&
                item != "--Select--")
            .toList();
      }
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 120), () {
      _filterList(value);
    });
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  void _selectItem(String item) {
    setState(() {
      _selectedOption = item;
      _searchController.text = item;
      _isExpanded = false;
    });
    widget.onSubmit(item);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
        hintColor: const Color(0xff0288D1),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.yellow),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  onTap: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Color(0xff0288D1)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xff0288D1),
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0288D1), width: 0.0),
                    ),
                    focusColor: Colors.blue,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    filled: false,
                    label: Text(
                      widget.label,
                      style: TextStyle(
                        color: const Color(0xff0288D1),
                        fontSize: widget.labelFontSize ?? 16,
                      ),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ],
            ),
            if (_isExpanded && _filteredList.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xff0288D1), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    final item = _filteredList[index];
                    final isSelected = item == _selectedOption;
                    return InkWell(
                      onTap: () => _selectItem(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: isSelected
                            ? const Color(0xff0288D1).withOpacity(0.1)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: const Color(0xff0288D1),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Color(0xff0288D1),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
