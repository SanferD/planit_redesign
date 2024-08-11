import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:intl/intl.dart';
import '../../bloc/ui_bloc.dart';
import '../../bloc/calendars_bloc.dart';
import '../utils/utils.dart';
import '../../infrastructure/stores/stores.dart';

class Header extends StatefulWidget {
  const Header({
    super.key,
    required this.dateTime,
    required this.jumpToToday,
    required this.calendar,
  });

  final DateTime dateTime;
  final Function() jumpToToday;
  final Calendar? calendar;

  DateTime get startTime => calendar?.startTime ?? dateTime;

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  Duration? _pickerDuration;
  DateTime? _pickerTime;

  DateTime get _date => DateTime(widget.dateTime.year, widget.dateTime.month, widget.dateTime.day);
  bool get _showPicker => _pickerDuration != null || _pickerTime != null;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // update showing the duration picker and setting the initial duration
        BlocListener<UIBloc, UIState>(
          listenWhen: (previous, current) {
            return previous.pickerDuration != current.pickerDuration || previous.pickerTime != current.pickerTime;
          },
          listener: (context, uiState) {
            final calendarsState = context.read<CalendarsBloc>().state;
            if (calendarsState.currentCalendarDate != _date && !_showPicker) {
              return;
            }
            setState(() {
              _pickerDuration = uiState.pickerDuration;
              _pickerTime = uiState.pickerTime;
            });
          },
        ),
      ],
      child: Container(
        height: Configuration.heightHeader + (_showPicker ? Configuration.heightTimePicker : 0),
        width: MediaQuery.of(context).size.width,
        color: LocalColors.background_80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Row(
              children: [
                const SizedBox(width: 16),
                CurrentDateHeaderButton(date: widget.dateTime),
                const SizedBox(width: 16),
                if (widget.calendar != null) CurrentTimeHeaderButton(calendar: widget.calendar!, time: widget.dateTime),
                if (widget.calendar == null) const SizedBox(width: 121),
                const SizedBox(width: 8),
                JumpToNowHeaderButton(jumpToToday: widget.jumpToToday),
                const MoreItemsHeaderButton(),
              ],
            ),
            const SizedBox(height: 8),
            if (_showPicker) const SizedBox(height: 24),
            if (_pickerDuration != null) DurationPickerSpinner(startDuration: _pickerDuration!),
            if (_pickerTime != null) StartTimePickerSpinner(startTime: _pickerTime!),
          ],
        ),
      ),
    );
  }
}

class DurationPickerSpinner extends StatelessWidget {
  const DurationPickerSpinner({
    super.key,
    required this.startDuration,
  });

  final Duration startDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // header for time picker
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 114),
            Text("Hour", style: LocalFonts.h7),
            const SizedBox(width: 68),
            Text("Minute", style: LocalFonts.h7),
          ],
        ),
        const SizedBox(height: 16),
        TimePickerSpinner(
          alignment: Alignment.center,
          is24HourMode: true,
          onTimeChange: (time) {
            context.read<UIBloc>().add(UIDurationPickerUpdated(duration: time.difference(DateTime(0))));
          },
          normalTextStyle: LocalFonts.h6_60,
          highlightedTextStyle: LocalFonts.h6,
          spacing: 60,
          itemHeight: 40,
          time: DateTime(0).add(startDuration),
        ),
      ],
    );
  }
}

class StartTimePickerSpinner extends StatelessWidget {
  const StartTimePickerSpinner({
    super.key,
    required this.startTime,
  });

  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // header for time picker
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 114),
            Text("Hour", style: LocalFonts.h7),
            const SizedBox(width: 68),
            Text("Minute", style: LocalFonts.h7),
          ],
        ),
        const SizedBox(height: 16),
        TimePickerSpinner(
          alignment: Alignment.center,
          is24HourMode: false,
          onTimeChange: (time) {
            context.read<UIBloc>().add(UITimePickerUpdated(time: time));
          },
          normalTextStyle: LocalFonts.h6_60,
          highlightedTextStyle: LocalFonts.h6,
          spacing: 60,
          itemHeight: 40,
          time: startTime,
        ),
      ],
    );
  }
}

class CurrentDateHeaderButton extends StatelessWidget {
  final DateTime date;

  const CurrentDateHeaderButton({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final day = DateFormat.E().format(this.date);
    final date = DateFormat.MMMd().format(this.date);
    return HeaderButton(
      color: LocalColors.primary_30,
      onTap: () => print("pressed CurrentDateHeaderButton"),
      child: Container(
        height: 72,
        width: 93,
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(day, style: LocalFonts.h5),
            Text(date, style: LocalFonts.h5),
          ],
        ),
      ),
    );
  }
}

class CurrentTimeHeaderButton extends StatelessWidget {
  final DateTime time;
  final Calendar calendar;

  const CurrentTimeHeaderButton({
    super.key,
    required this.time,
    required this.calendar,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.jm().format(time);
    return HeaderButton(
      color: LocalColors.primary_30,
      onTap: () {
        context.read<CalendarsBloc>().add(CalendarsRelativeEventEditBegan(calendar: calendar, relativeEventIndex: -1));
        context.read<UIBloc>().add(UITimePickerShown(time: time));
      },
      child: Container(
        width: 121,
        height: 72,
        alignment: Alignment.center,
        child: Text(timeStr, style: LocalFonts.h5),
      ),
    );
  }
}

class JumpToNowHeaderButton extends StatelessWidget {
  const JumpToNowHeaderButton({
    super.key,
    required this.jumpToToday,
  });

  final Function() jumpToToday;

  @override
  Widget build(BuildContext context) {
    return HeaderButton(
      color: Colors.transparent,
      onTap: jumpToToday,
      child: const SizedBox(
        width: 60,
        height: 72,
        child: Icon(
          Icons.calendar_today_outlined,
          size: 44,
          color: LocalColors.primary,
        ),
      ),
    );
  }
}

class MoreItemsHeaderButton extends StatelessWidget {
  const MoreItemsHeaderButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HeaderButton(
      color: Colors.transparent,
      onTap: () => print("pressed MoreItemsIconButton"),
      child: Container(
        width: 44,
        height: 72,
        alignment: Alignment.center,
        child: const Icon(
          Icons.more_vert_outlined,
          size: 44,
          color: LocalColors.primary,
        ),
      ),
    );
  }
}

class HeaderButton extends StatelessWidget {
  const HeaderButton({
    super.key,
    required this.child,
    required this.color,
    required this.onTap,
  });

  final Color? color;
  final Function()? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: Configuration.borderRadius,
      color: color,
      child: InkWell(
        borderRadius: Configuration.borderRadius,
        splashColor: LocalColors.primary_30,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({
    super.key,
    required this.kind,
  });

  final FooterKind kind;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: Configuration.heightFooter,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(color: LocalColors.background),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FooterButton(
              onPressed: () {
                context.read<CalendarsBloc>().add(CalendarsRelativeEventEditCancelled());
                switch (kind) {
                  case FooterKind.durationPicker:
                    context.read<UIBloc>().add(UIDurationPickerHidden());
                    break;
                  case FooterKind.timePicker:
                    context.read<UIBloc>().add(UITimePickerHidden());
                    break;
                }
              },
              text: "CANCEL",
            ),
            const SizedBox(width: 80),
            FooterButton(
              onPressed: () {
                switch (kind) {
                  case FooterKind.durationPicker:
                    context.read<UIBloc>().add(UIDurationPickerHidden());
                    context.read<CalendarsBloc>().add(CalendarsRelativeEventDurationUpdated(duration: context.read<UIBloc>().state.pickerDuration!));
                    break;
                  case FooterKind.timePicker:
                    context.read<UIBloc>().add(UITimePickerHidden());
                    context.read<CalendarsBloc>().add(CalendarsCalendarStartTimeUpdated(startTime: context.read<UIBloc>().state.pickerTime!));
                    break;
                }
              },
              text: "SAVE",
            ),
          ],
        ),
      ),
    );
  }
}

enum FooterKind { durationPicker, timePicker }

class FooterButton extends StatelessWidget {
  const FooterButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: Key("footer-btn-$text"),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(overlayColor: LocalColors.background_60, backgroundColor: LocalColors.t3),
      child: Text(text, style: LocalFonts.h5),
    );
  }
}
