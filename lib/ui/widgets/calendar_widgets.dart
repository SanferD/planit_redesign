import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:planit_redesign/bloc/ui_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../bloc/calendars_bloc.dart';
import '../../infrastructure/stores/stores.dart';
import '../utils/utils.dart';
import './background_image.dart';

class CalendarRelativeIndex {
  const CalendarRelativeIndex({required this.calendar, required this.relativeIndex});
  final Calendar calendar;
  final int relativeIndex;
}

class RemovableCalendarEvent extends StatelessWidget {
  const RemovableCalendarEvent({
    super.key,
    required this.calendar,
    required this.headerCalendarDT,
    required this.endTime,
    required this.height,
    required this.relativeEvent,
    required this.relativeEventIndex,
    required this.startTime,
    required this.title,
    required this.type,
    required this.mode,
  });

  final Calendar calendar;
  final DateTime headerCalendarDT;
  final DateTime endTime;
  final double height;
  final RelativeEvent relativeEvent;
  final int relativeEventIndex;
  final DateTime startTime;
  final String title;
  final CalendarEventColorTypes type;
  final CalendarEventMode mode;

  @override
  String toStringShort() {
    return "RemovableCalendarEvent(calendar: $calendar, endTime: $endTime, height: $height, relativeEvent: $relativeEvent, relativeEventIndex: $relativeEventIndex, startTime: $startTime, title: $title, type: $type)";
  }

  static Map<DismissDirection, double> dismissThresholds = {
    DismissDirection.startToEnd: 0.2,
    DismissDirection.endToStart: 0.7,
  };

  Color get colorSolid {
    switch (type) {
      case CalendarEventColorTypes.t1:
        return LocalColors.t1;
      case CalendarEventColorTypes.t2:
        return LocalColors.t2;
      case CalendarEventColorTypes.t3:
        return LocalColors.t3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable(
      data: CalendarRelativeIndex(calendar: calendar, relativeIndex: relativeEventIndex),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: CalendarEventOutline(
        height: height,
        color: colorSolid,
      ),
      onDragStarted: () {
        context.read<UIBloc>().add(UIDragStarted());
      },
      onDragCompleted: () {
        context.read<UIBloc>().add(UIDragStopped());
      },
      child: Dismissible(
        key: Key(const Uuid().v4()),
        direction: DismissDirection.horizontal,
        dragStartBehavior: DragStartBehavior.down,
        dismissThresholds: RemovableCalendarEvent.dismissThresholds,
        confirmDismiss: (final DismissDirection direction) async {
          if (direction == DismissDirection.startToEnd) {
            // add new item
            context
                .read<CalendarsBloc>()
                .add(CalendarsRelativeEventCreated(calendar: calendar, relativeEventIndex: relativeEventIndex));
          } else {
            // delete item
            context
                .read<CalendarsBloc>()
                .add(CalendarsRelativeEventDeleted(calendar: calendar, relativeEventIndex: relativeEventIndex));
          }
          return false;
        },
        background: const AddToLibraryBackground(icon: Icons.library_add),
        secondaryBackground: const DeleteBackground(icon: Icons.delete),
        child: DragTarget(
          builder: (context, candidateItems, rejectedItems) {
            return CalendarEvent(
              calendar: calendar,
              headerCalendarDT: headerCalendarDT,
              endTime: endTime,
              height: height,
              relativeEvent: relativeEvent,
              relativeEventIndex: relativeEventIndex,
              startTime: startTime,
              type: type,
              title: title,
              mode: mode,
            );
          },
          onAcceptWithDetails: (details) {
            final CalendarRelativeIndex d = details.data! as CalendarRelativeIndex;
            if (d.calendar.date != calendar.date) {
              // do not accept moves between different calendars
              return;
            }
            context.read<CalendarsBloc>().add(CalendarsRelativeEventMoved(
                  calendar: calendar,
                  newRelativeEventIndex: relativeEventIndex,
                  oldRelativeEventIndex: d.relativeIndex,
                ));
          },
        ),
      ),
    );
  }

}

class CalendarEventOutline extends StatelessWidget {
  const CalendarEventOutline({
    super.key,
    required this.height,
    required this.color,
  });

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topStart,
      width: 242,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: Configuration.borderRadius,
        border: Border.all(color: color, width: 3),
      ),
    );
  }
}

class DeleteBackground extends StatelessWidget {
  const DeleteBackground({
    super.key,
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [Icon(icon, size: 40, color: LocalColors.primary), const SizedBox(width: 4)],
    );
  }
}

class AddToLibraryBackground extends StatelessWidget {
  const AddToLibraryBackground({
    super.key,
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 10),
        Icon(icon, size: 40, color: LocalColors.primary),
      ],
    );
  }
}

enum CalendarEventMode {
  none,
  left,
  right,
}

class CalendarEvent extends StatefulWidget {
  final Calendar calendar;
  final DateTime headerCalendarDT;
  final DateTime endTime;
  final double height;
  final RelativeEvent relativeEvent;
  final int relativeEventIndex;
  final DateTime startTime;
  final String title;
  final CalendarEventColorTypes type;
  final CalendarEventMode mode;

  const CalendarEvent({
    super.key,
    required this.calendar,
    required this.headerCalendarDT,
    required this.endTime,
    required this.height,
    required this.relativeEvent,
    required this.relativeEventIndex,
    required this.startTime,
    required this.title,
    required this.type,
    required this.mode,
  });

  @override
  State<CalendarEvent> createState() => _CalendarEventState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return "CalendarEvent(calendar: $calendar, endTime: $endTime, height: $height, relativeEvent: $relativeEvent, relativeEventIndex: $relativeEventIndex, startTime: $startTime, title: $title, type: $type)";
  }

  Color get color60p {
    switch (type) {
      case CalendarEventColorTypes.t1:
        return LocalColors.t1_60;
      case CalendarEventColorTypes.t2:
        return LocalColors.t2_60;
      case CalendarEventColorTypes.t3:
        return LocalColors.t3_60;
    }
  }

  Color get colorSolid {
    switch (type) {
      case CalendarEventColorTypes.t1:
        return LocalColors.t1;
      case CalendarEventColorTypes.t2:
        return LocalColors.t2;
      case CalendarEventColorTypes.t3:
        return LocalColors.t3;
    }
  }
}

class _CalendarEventState extends State<CalendarEvent> {
  final TextEditingController titleController = TextEditingController();

  Color _innerColor = Colors.transparent; // ignore, see init state
  BlurMode _eventBlurMode = BlurMode.none;
  BlurMode _durationBlurMode = BlurMode.none;
  BlurMode _titleBlurMode = BlurMode.none;

  @override
  void initState() {
    titleController.text = widget.title;
    _innerColor = widget.color60p;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // current calendar is being editted. set blur appropriately
        BlocListener<CalendarsBloc, CalendarsState>(
          listenWhen: (previous, current) => current.currentCalendarDate == widget.calendar.date,
          listener: (context, calendarsState) {
            final uiState = context.read<UIBloc>().state;
            setState(() {
              var isMe = (calendarsState.currentRelativeEventIndex == widget.relativeEventIndex);
              if (isMe) {
                if (uiState.isEditingSomeDuration) {
                  _durationBlurMode = BlurMode.none;
                  _eventBlurMode = BlurMode.none;
                  _innerColor = widget.colorSolid;
                  _titleBlurMode = BlurMode.me;
                } else if (uiState.isEditingSomeTitle) {
                  _eventBlurMode = BlurMode.none;
                  _durationBlurMode = BlurMode.me;
                  _innerColor = widget.color60p;
                  _titleBlurMode = BlurMode.none;
                } else if (uiState.isEditingSomeStartTime) {
                  _eventBlurMode = BlurMode.me;
                }
              } else {
                _eventBlurMode = BlurMode.me;
              }
            });
          },
        ),
        // current calendar was being editted but is no longer. reset blur.
        BlocListener<CalendarsBloc, CalendarsState>(
          listenWhen: (previous, current) => current.currentCalendarDate == null && previous.currentCalendarDate == widget.calendar.date,
          listener: (context, calendarsState) {
            setState(() {
              _eventBlurMode = BlurMode.none;
              _durationBlurMode = BlurMode.none;
              _innerColor = widget.color60p;
            });
          },
        )
      ],
      child: Blur(
        blurMode: _eventBlurMode,
        child: ClipPath(
          clipBehavior: _doClip ? Clip.hardEdge : Clip.none,
          clipper: _clipper,
          child: Container(
            alignment: AlignmentDirectional.topStart,
            width: 242,
            height: widget.height,
            decoration: BoxDecoration(
              color: _innerColor,
              borderRadius: Configuration.borderRadius,
              border: Border.all(color: widget.colorSolid, width: 3),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: _leftPadding, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Blur(
                    blurMode: _durationBlurMode,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TimeRangeLabel(
                          color: widget.colorSolid,
                          startTime: widget.startTime,
                          endTime: widget.endTime,
                          calendar: widget.calendar,
                          headerCalendarDT: widget.headerCalendarDT,
                          relativeEventIndex: widget.relativeEventIndex,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Text(_myDurationStr, style: LocalFonts.h7_60),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: heightBetween),
                  Blur(
                    blurMode: _titleBlurMode,
                    child: FocusableTextWidget(
                      calendar: widget.calendar,
                      relativeEventIndex: widget.relativeEventIndex,
                      titleController: titleController,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _myDurationStr {
    final duration = widget.endTime.difference(widget.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    String durationStr = "";
    if (hours > 0) {
      durationStr += "${hours}h";
    }
    if (minutes > 0) {
      if (hours > 0) {
        durationStr += " ";
      }
      durationStr += "${minutes}m";
    }
    return durationStr;
  }

  double get _leftPadding {
    return (widget.mode == CalendarEventMode.left ? Configuration.cutWidth : 0.0) + 8.0;
  }

  bool get _doClip {
    return widget.mode != CalendarEventMode.none;
  }

  CustomClipper<Path> get _clipper {
    switch (widget.mode) {
      case CalendarEventMode.none:
      case CalendarEventMode.left:
        return _LeftModeClipper(width: 242, height: widget.height);
      case CalendarEventMode.right:
        return _RightModeClipper(width: 242, height: widget.height);
      default:
        throw Exception("Invalid mode: ${widget.mode}");
    }
  }

  double get heightBetween {
    return widget.height < Configuration.height1H ? 0.0 : 4.0;
  }

}

class _LeftModeClipper extends CustomClipper<Path> {
  const _LeftModeClipper({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Path getClip(Size size) {
    const cutWidth = Configuration.cutWidth;
    final cutHeight = (height / 3.0);
    final path = Path()
      ..moveTo(cutWidth, 0)
      ..lineTo(cutWidth, cutHeight)
      ..lineTo(0, cutHeight)
      ..lineTo(0, 2 * cutHeight)
      ..lineTo(cutWidth, 2 * cutHeight)
      ..lineTo(cutWidth, height)
      ..lineTo(width, height)
      ..lineTo(width, 0)
      ..lineTo(cutWidth, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _RightModeClipper extends CustomClipper<Path> {
  const _RightModeClipper({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Path getClip(Size size) {
    final widthOffset = width - Configuration.cutWidth;
    final heightOffset = height / 3;
    Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, heightOffset)
      ..lineTo(widthOffset, heightOffset)
      ..lineTo(widthOffset, 2 * heightOffset)
      ..lineTo(width, 2 * heightOffset)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..lineTo(0, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class FocusableTextWidget extends StatelessWidget {
  const FocusableTextWidget({
    super.key,
    required this.titleController,
    required this.calendar,
    required this.relativeEventIndex,
  });

  final TextEditingController titleController;
  final Calendar calendar;
  final int relativeEventIndex;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          context.read<CalendarsBloc>().add(CalendarsRelativeEventEditBegan(calendar: calendar, relativeEventIndex: relativeEventIndex));
          context.read<UIBloc>().add(UISomeTitleFocused());
        } else {
          context.read<CalendarsBloc>().add(CalendarsRelativeEventTitleUpdated(title: titleController.text));
          context.read<UIBloc>().add(UINoTitleFocused());
          if (titleController.text.length > CalendarsError.maxTitleLength) {
            titleController.text = "";
          }
        }
      },
      child: SizedBox(
        width: Utils.getItemWidth(context),
        child: TextField(
          scrollPadding: const EdgeInsets.all(0),
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          controller: titleController,
          style: LocalFonts.h6,
        ),
      ),
    );
  }
}

class TimeRangeLabel extends StatelessWidget {
  const TimeRangeLabel({
    super.key,
    required this.color,
    required this.startTime,
    required this.endTime,
    required this.calendar,
    required this.headerCalendarDT,
    required this.relativeEventIndex,
  });

  final Color color;
  final DateTime startTime;
  final DateTime endTime;
  final Calendar calendar;
  final DateTime headerCalendarDT;
  final int relativeEventIndex;

  Duration get duration => endTime.difference(startTime);

  @override
  Widget build(BuildContext context) {
    final startTimeStr = _formatTime(startTime);
    final endTimeStr = _formatTime(endTime);
    return BlocBuilder<UIBloc, UIState>(
        buildWhen: (previous, current) => previous.currentTime != current.currentTime,
        builder: (context, state) {
          final itemMinutes = endTime.difference(startTime).inMinutes;
          final int elapsedMinutes;
          if (startTime.isAfter(state.currentTime)) {
            elapsedMinutes = 0;
          } else if (endTime.isBefore(state.currentTime)) {
            elapsedMinutes = itemMinutes;
          } else {
            elapsedMinutes = state.currentTime.difference(startTime).inMinutes;
          }
          final completedPercentage = 100.0 * (elapsedMinutes.toDouble() / itemMinutes.toDouble());
          return InkWell(
            onTap: () {
              context.read<CalendarsBloc>().add(CalendarsRelativeEventEditBegan(
                    calendar: calendar,
                    relativeEventIndex: relativeEventIndex,
                  ));
              final durationMinutes = calendar.relativeEvents[relativeEventIndex].durationMinutes;
              context.read<UIBloc>().add(UIDurationPickerShown(duration: Duration(minutes: durationMinutes)));
            },
            child: UnconstrainedBox(
              child: Container(
                height: 28,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("$startTimeStr-$endTimeStr", style: LocalFonts.h6),
                      const SizedBox(width: 6),
                      if (completedPercentage > 0.0) DurationProgress(completedPercentage: completedPercentage),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  String _formatTime(DateTime time) {
    if (time.minute == 0) {
      // If minutes are 0, format without minutes
      return DateFormat('ha').format(time);
    } else {
      // Otherwise, format with minutes
      return DateFormat('h:mma').format(time);
    }
  }
}

class DurationProgress extends StatelessWidget {
  const DurationProgress({super.key, required this.completedPercentage});

  final double completedPercentage;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircleProgressBarPainter(completedPercentage: completedPercentage),
      size: const Size(16, 16),
    );
  }
}

class _CircleProgressBarPainter extends CustomPainter {
  final double completedPercentage;

  _CircleProgressBarPainter({required this.completedPercentage});

  @override
  void paint(Canvas canvas, Size size) {
    Paint completeArc = Paint()
      ..strokeWidth = 3
      ..color = LocalColors.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2.0, size.height / 2.0);
    double radius = min(size.width / 2.0, size.height / 2.0);
    double angle = 2.0 * pi * (completedPercentage / 100.0);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, angle, false, completeArc);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class AddCalendarButton extends StatelessWidget {
  const AddCalendarButton({
    super.key,
    required this.startTime,
  });

  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: _getIconLeftPadding(context)),
      child: IconButton(
        icon: const Icon(Icons.add_circle, size: 88),
        onPressed: () => context.read<CalendarsBloc>().add(CalendarsCalendarCreated(startTime: startTime)),
        color: LocalColors.primary,
        splashColor: LocalColors.background,
      ),
    );
  }

  double _getIconLeftPadding(BuildContext context) => (MediaQuery.of(context).size.width - Utils.getContentPadding(context).left - 3) / 2 - 44;
}

