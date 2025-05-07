import 'package:flutter/material.dart';

class MyCalendar extends StatefulWidget {
  final String? restorationId;
  final String value;
  final String label;
  final String hint = 'Tap To Select Year';
  final Function(String) onSubmit;
  final int lines;
  dynamic type;

  MyCalendar({
    super.key,
    this.restorationId,
    required this.value,
    required this.label,
    required this.lines,
    required this.onSubmit,
  });

  @override
  _MyCalendarState createState() => _MyCalendarState();
}

class _MyCalendarState extends State<MyCalendar> with RestorationMixin {
  @override
  String? get restorationId => widget.restorationId;

  final TextEditingController _controller = TextEditingController();
  final RestorableDateTime _selectedDate = RestorableDateTime(
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  late final RestorableRouteFuture<DateTime?> _restorableYearPickerRouteFuture =
      RestorableRouteFuture<DateTime?>(
    onComplete: _selectDate,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _yearPickerRoute,
        arguments: _selectedDate.value.millisecondsSinceEpoch,
      );
    },
  );

  @pragma('vm:entry-point')
  static Route<DateTime?> _yearPickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            height: 250,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(DateTime.now().year),
              initialDate:
                  DateTime.fromMillisecondsSinceEpoch(arguments! as int),
              selectedDate:
                  DateTime.fromMillisecondsSinceEpoch(arguments as int),
              onChanged: (DateTime selectedDate) {
                Navigator.pop(context, selectedDate);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
        _restorableYearPickerRouteFuture, 'year_picker_route_future');
  }

  void _selectDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = DateTime(newSelectedDate.year);
        _controller.value = TextEditingValue(
          text: "${_selectedDate.value.year}",
          selection: TextSelection.fromPosition(
            TextPosition(offset: "${_selectedDate.value.year}".length),
          ),
        );
      });
      widget.onSubmit("${_selectedDate.value.year}");
    }
  }

  @override
  void didUpdateWidget(covariant MyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _controller.text = widget.value.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hintColor: Colors.blue,
        inputDecorationTheme: const InputDecorationTheme(
          border:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          focusedBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        child: TextField(
          onChanged: (value) {
            _controller.value = TextEditingValue(
              text: value,
              selection: TextSelection.fromPosition(
                TextPosition(offset: value.length),
              ),
            );
            widget.onSubmit(value);
          },
          onTap: () {
            _restorableYearPickerRouteFuture.present();
          },
          keyboardType: widget.type,
          controller: _controller,
          readOnly: true,
          enableInteractiveSelection: false,
          maxLines: widget.lines,
          obscureText:
              widget.type == TextInputType.visiblePassword ? true : false,
          enableSuggestions: false,
          autocorrect: false,
          style: const TextStyle(color: Color(0xff0288D1)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8),
            hintStyle: const TextStyle(color: Color(0xff0288D1)),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 0.0),
            ),
            focusColor: Colors.blue,
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2.0),
            ),
            filled: false,
            label: Text(
              widget.label,
              style: const TextStyle(color: Color(0xff0288D1)),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
        ),
      ),
    );
  }
}
