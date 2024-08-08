import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../../bloc/calendars_bloc.dart';
import '../../bloc/ui_bloc.dart';
import '../../infrastructure/stores/stores.dart';
import '../../ui/utils/calendar_utils.dart';
import '../../ui/utils/utils.dart';
import '../../ui/widgets/calendar_widgets.dart';
import '../../ui/widgets/headers_footers.dart';
import '../../ui/widgets/timeline_widgets.dart';

class StickyCalendar extends StatefulWidget {
  const StickyCalendar({
    super.key,
    required date2calendar,
    required dates,
  })  : _date2calendar = date2calendar,
        _dates = dates;

  final Map<DateTime, Calendar?> _date2calendar;
  final List<DateTime> _dates;

  @override
  State<StickyCalendar> createState() => _StickyCalendarState();
}

class _StickyCalendarState extends State<StickyCalendar> {
  late ScrollController _followerController;
  late ScrollController _leaderController;
  bool _isUpdating = false;
  bool _isDragStart = false;
  bool _showDurationFooter = false;
  bool _showTimeFooter = false;
  bool get _showFooter => _showDurationFooter || _showTimeFooter;
  double _currentOffset = 0.0;
  final int _autoScrollOffset = 300;
  var _isFirstBuild = true;
  late DateTime _currentHeaderDate = _todayDate;
  late DateTime _lowerCutoffDate = _todayDate.subtract(const Duration(days: 7));
  late DateTime _upperCutoffDate = _todayDate.add(const Duration(days: 7));
  Map<DateTime, TimelineMultiSliver> date2timelineMultiSlivers = {};
  Map<DateTime, CalendarEventsMultiSliver> date2calendarMultiSlivers = {};
  Map<DateTime, Map<int, List<TimeOffset>>> date2timeOffsets = {};
  Map<DateTime, double> date2headerOffset = {};
  Map<DateTime, Calendar?> date2calendar = {};
  List<DateTime> dates = [];
  List<DateTime> dirtyDates = [];
  double offsetPadding = 2e5; // ~ 600years in the past

  @override
  void initState() {
    dates = widget._dates.toList();
    date2calendar = Map.from(widget._date2calendar);
    dirtyDates = dates.toList();
    _followerController = makeScrollController();
    _leaderController = makeScrollController();
    super.initState();
  }

  ScrollController makeScrollController() => ScrollController(
        keepScrollOffset: true,
        onAttach: (position) => position.addListener(_scrollListener),
        onDetach: (position) => position.removeListener(_scrollListener),
      );

  @override
  void didChangeDependencies() {
    _updateMe();
    super.didChangeDependencies();
  }

  void _updateMe() {
    if (dirtyDates.isEmpty) {
      return;
    }

    var dirtyDatesRange = dirtyDates.sublist(0);
    if (dirtyDates.length == 1) { // add the next calendar day incase calendar spans 2 days
      dirtyDatesRange.add(dirtyDates[0].add(const Duration(days: 1)));
    }
    for (var date in dirtyDatesRange) {
      final calendar = date2calendar[date];
      final yesterdayCalendar = date2calendar[date.subtract(const Duration(days: 1))];
      date2timeOffsets[date] = CalendarUtils.getTimelineOverride(
        todayStart: date,
        yesterdayCalendar: yesterdayCalendar,
        todayCalendar: calendar,
      );

      date2timelineMultiSlivers[date] = TimelineMultiSliver(
        key: UniqueKey(),
        calendar: calendar,
        currentTime: DateTime.now(), // todo: update
        date: date,
        heightContentsEmptyDay: Utils.getHeightContentsEmptyDay(context),
        timeOffsets: date2timeOffsets[date]!,
        width: MediaQuery.of(context).size.width,
      );

      date2calendarMultiSlivers[date] = CalendarEventsMultiSliver(
        key: UniqueKey(),
        heightContentsEmptyDay: Utils.getHeightContentsEmptyDay(context),
        yesterdayCalendar: yesterdayCalendar,
        date: date,
        calendar: date2calendar[date],
        dayHeight: _getOffsetForDay(date2timeOffsets[date]!),
        jumpToToday: () => jumpToNow(context: context),
        contentPadding: Utils.getContentPadding(context),
      );
    }

    // get first date of header offsets before population
    if (_isFirstBuild) {
      final firstDate = dirtyDates.removeAt(0);
      date2headerOffset[firstDate] = offsetPadding;
    }

    if (dirtyDates.length == 1) {
      // get the change in offset
      final dirtyDate = dirtyDates[0];
      final previousDate = dirtyDate.subtract(const Duration(days: 1));
      final oldOffset = date2headerOffset[dirtyDate]!;
      final newOffset = date2headerOffset[previousDate]! + _getOffsetForDay(date2timeOffsets[previousDate]!);
      final deltaOffset = newOffset - oldOffset;

      // update the offsets spanning from the dirty date
      var dt = dirtyDate;
      while (date2headerOffset.containsKey(dt)) {
        date2headerOffset[dt] = date2headerOffset[dt]! + deltaOffset;
        dt = dt.add(const Duration(days: 1));
      }
    } else if (dirtyDates.first.isAfter(dirtyDates.last)) {
      // growing toward the past
      for (var dirtyDate in dirtyDates) {
        final previousDate = dirtyDate.add(const Duration(days: 1));
        date2headerOffset[dirtyDate] = date2headerOffset[previousDate]! - _getOffsetForDay(date2timeOffsets[dirtyDate]!);
      }
      offsetPadding = date2headerOffset[dirtyDates.last]!;
    } else if (dirtyDates.first.isBefore(dirtyDates.last)) {
      // growing towards the future
      for (var dirtyDate in dirtyDates) {
        final previousDate = dirtyDate.subtract(const Duration(days: 1));
        date2headerOffset[dirtyDate] = date2headerOffset[previousDate]! + _getOffsetForDay(date2timeOffsets[previousDate]!);
      }
    } else {
      throw Exception("random dirty dates pattern, not implemented");
    }
  }

  double _getOffsetForDay(Map<int, List<TimeOffset>> hour2timeOffsets, {int hourUpperLimitInclusive = 24}) {
    double offset = Configuration.heightHeader;
    if (hour2timeOffsets.isNotEmpty) {
      for (var hour = 0; hour < 24; hour++) {
        if (hour >= hourUpperLimitInclusive) {
          break;
        }
        offset += hour2timeOffsets[hour]?.fold<double>(0.0, (pv, e) => pv + e.height) ?? Configuration.height1H;
      }
    } else {
      offset += Utils.getHeightContentsEmptyDay(context);
    }
    return offset;
  }

  @override
  void dispose() {
    _leaderController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    // freeze scrolling if footer is shown
    if (_showFooter) {
      _leaderController.jumpTo(_currentOffset);
    } else {
      _currentOffset = _leaderController.offset;
    }

    // update current header date

    // don't update current header date if it's the first build or updating (because datastructures are still populating)
    if (_isFirstBuild || _isUpdating) {
      return;
    }

    /// get date of current offset
    final offset = _leaderController.offset;
    final pvhd = _currentHeaderDate; // for logging
    var currentHeaderOffset = date2headerOffset[_currentHeaderDate]!;
    var nextHeaderOffset = date2headerOffset[_currentHeaderDate.add(const Duration(days: 1))]!;
    if (offset < currentHeaderOffset) {
      _currentHeaderDate = _currentHeaderDate.subtract(const Duration(days: 1));
      currentHeaderOffset = date2headerOffset[_currentHeaderDate]!;
    }
    if (nextHeaderOffset <= offset) {
      _currentHeaderDate = _currentHeaderDate.add(const Duration(days: 1));
    }
    if (pvhd != _currentHeaderDate) {
      print("pvhd: $pvhd, chd: $_currentHeaderDate, offset: ${_leaderController.offset}");
    }

    /// if the date of current offset is before lower cutoff, fetch previous week
    if (_currentHeaderDate.isBefore(_lowerCutoffDate)) {
      _lowerCutoffDate = _lowerCutoffDate.subtract(CalendarsConfiguration.autoscrollDeltaDuration);
      context.read<CalendarsBloc>().add(CalendarsFetchPreviousWeek());
    }

    /// if the date of current offset if after upper cutoff, fetch next week
    if (_currentHeaderDate.isAfter(_upperCutoffDate)) {
      _upperCutoffDate = _upperCutoffDate.add(CalendarsConfiguration.autoscrollDeltaDuration);
      context.read<CalendarsBloc>().add(CalendarsFetchNextWeek());
    }
  }

  DateTime get _todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstBuild) {}
    _isUpdating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isFirstBuild) {
        return;
      }
      await jumpToNow(context: context);
      setState(() {
        _isFirstBuild = false;
      });
    });
    final topOffsetWidget = TopOffsetMultiSliver(offsetPadding: offsetPadding);
    final timelineSlivers = <Widget>[topOffsetWidget] + dates.map((date) => date2timelineMultiSlivers[date]!).toList();
    final calendarSlivers = <Widget>[topOffsetWidget] + dates.map((date) => date2calendarMultiSlivers[date]!).toList();
    final w = MultiBlocListener(
      listeners: [
        // listen for UI state changes to show the footer
        BlocListener<UIBloc, UIState>(
          listenWhen: (previous, current) => previous.canScroll != current.canScroll,
          listener: (context, state) => setState(() {
            _showDurationFooter = state.pickerDuration != null;
            _showTimeFooter = state.pickerTime != null;
          }),
        ),
        // listen for calendar errors to be shown in an error dialog
        BlocListener<CalendarsBloc, CalendarsState>(
          listenWhen: (_, current) => current.status == CalendarsStatus.failure,
          listener: (context, state) async {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shadowColor: LocalColors.error,
                surfaceTintColor: LocalColors.error,
                backgroundColor: LocalColors.background,
                title: Text(state.error.title, style: LocalFonts.h5, textAlign: TextAlign.center),
                content: Text(state.error.message, style: LocalFonts.h7, textAlign: TextAlign.center),
              ),
            );
            context.read<CalendarsBloc>().add(CalendarsErrorCleared());
          },
        ),
        // listen for the drag start to show the drag autoscroll targets
        BlocListener<UIBloc, UIState>(
          listenWhen: (previous, current) => current.isDragging != _isDragStart,
          listener: (context, state) => setState(() {
            _isDragStart = state.isDragging;
          }),
        ),
        BlocListener<CalendarsBloc, CalendarsState>(
            listenWhen: (previous, current) => !previous.isFirstBuild,
            listener: (context, state) {
              setState(() {
                _isUpdating = true;
                dates = state.dates;
                date2calendar = state.date2calendar;
                dirtyDates = state.dirtyDates;
                _updateMe();
                _isUpdating = false;
              });
            }),
      ],
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _followerController.jumpTo(_leaderController.offset);
          }
          return true;
        },
        child: Stack(
          children: [
            const TimeColumnDivider(),
            CustomScrollView(controller: _followerController, slivers: timelineSlivers),
            CustomScrollView(controller: _leaderController, slivers: calendarSlivers),
            if (_showDurationFooter) const Footer(kind: FooterKind.durationPicker),
            if (_showTimeFooter) const Footer(kind: FooterKind.timePicker),
            if (_isDragStart) AutoScrollDragTarget(alignment: Alignment.topCenter, move: _moveUp),
            if (_isDragStart) AutoScrollDragTarget(alignment: Alignment.bottomCenter, move: _moveDown),
          ],
        ),
      ),
    );
    _isUpdating = false;
    return w;
  }

  _moveUp() {
    final double offset = max(_leaderController.offset - _autoScrollOffset, 0);
    _leaderController.animateTo(offset, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  _moveDown() {
    final double offset = max(_leaderController.offset + _autoScrollOffset, 0);
    _leaderController.animateTo(offset, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  Future<void> jumpToNow({required final BuildContext context}) => jumpToDateTime(dt: DateTime.now(), context: context);

  Future<void> jumpToDateTime({required final DateTime dt, required final BuildContext context}) => _leaderController
      .animateTo(getJumpToOffset(today: dt, currentHour: dt.hour, context: context), curve: Curves.easeInOut, duration: const Duration(milliseconds: 500));

  double getJumpToOffset({required final DateTime today, required final int currentHour, required final BuildContext context}) {
    double offset = offsetPadding; // initial padding offset
    final todayStart = DateTime(today.year, today.month, today.day);

    // add the offsets of the days before today
    for (var dt = dates[0]; dt.isBefore(todayStart); dt = dt.add(const Duration(days: 1))) {
      offset += _getOffsetForDay(date2timeOffsets[dt]!);
    }

    // if the current day doesn't have a calendar, then jumping to the header is good enough
    if (date2calendar[todayStart] == null) {
      return offset;
    }
    // otherwise jump to the current hour of the day, minus 1 item height if applicable
    var currentDayOffset = _getOffsetForDay(date2timeOffsets[todayStart]!, hourUpperLimitInclusive: currentHour);

    // remove the 1 hour height offset just to scroll to the correct offset
    if (currentDayOffset > Configuration.height1H) {
      currentDayOffset -= Configuration.height1H;
    }
    return offset + currentDayOffset;
  }
}

class TopOffsetMultiSliver extends StatelessWidget {
  const TopOffsetMultiSliver({
    super.key,
    required this.offsetPadding,
  });

  final double offsetPadding;

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      Container(
        color: LocalColors.background,
        width: MediaQuery.of(context).size.width,
        height: offsetPadding,
      )
    ]);
  }
}

class AutoScrollDragTarget extends StatelessWidget {
  const AutoScrollDragTarget({
    super.key,
    required this.alignment,
    required this.move,
  });

  final Alignment alignment;
  final Function() move;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: DragTarget(
        builder: (context, accepted, rejected) => Container(
          height: 40,
          width: double.infinity,
          color: Colors.transparent,
        ),
        onWillAcceptWithDetails: (_) {
          move();
          return false;
        },
      ),
    );
  }
}

class CalendarEventsMultiSliver extends MultiSliver {
  final Calendar? calendar;

  CalendarEventsMultiSliver({
    super.key,
    required double heightContentsEmptyDay,
    required DateTime date,
    required Calendar? yesterdayCalendar,
    required this.calendar,
    required Function() jumpToToday,
    required double dayHeight,
    required EdgeInsets contentPadding,
  }) : super(
          pushPinnedChildren: true,
          children: _buildDaySlivers(
            heightContentsEmptyDay: heightContentsEmptyDay,
            date: date,
            yesterdayCalendar: yesterdayCalendar,
            calendar: calendar,
            jumpToToday: jumpToToday,
            dayHeight: dayHeight,
            contentPadding: contentPadding,
          ),
        );

  static List<Widget> _buildDaySlivers({
    required double heightContentsEmptyDay,
    required DateTime date,
    required Calendar? yesterdayCalendar,
    required Calendar? calendar,
    required VoidCallback jumpToToday,
    required double dayHeight,
    required EdgeInsets contentPadding,
  }) {
    final dayWidgets = _getCalendarEventWidgets(
      heightContentsEmptyDay: heightContentsEmptyDay,
      todayStart: date,
      yesterdayCalendar: yesterdayCalendar,
      todayCalendar: calendar,
      dayHeight: dayHeight,
    );
    final dtSlivers = <Widget>[];

    // add the header
    final sph = SliverPinnedHeader(
      child: Header(
        dateTime: calendar?.startTime ?? date,
        jumpToToday: jumpToToday,
        calendar: calendar,
      ),
    );
    dtSlivers.add(sph);

    // package the day widgets in a sliver
    final widgets = dayWidgets.map((x) => Padding(padding: contentPadding, child: x)).toList();
    final sl = SliverList(delegate: SliverChildListDelegate.fixed(widgets));
    dtSlivers.add(sl);

    return dtSlivers;
  }

  static List<Widget> _getCalendarEventWidgets({
    required double heightContentsEmptyDay,
    required DateTime todayStart,
    required Calendar? yesterdayCalendar,
    required Calendar? todayCalendar,
    required double dayHeight,
  }) {
    List<Widget> result = [];
    var offsetCovered = Configuration.heightHeader;
    final DateTime previousEndTime; // this is the end time of the last event that was used
    final yesterdayStart = DateTime(todayStart.year, todayStart.month, todayStart.day - 1);
    final tomorrowStart = DateTime(todayStart.year, todayStart.month, todayStart.day + 1);
    final todayEnd = DateTime(todayStart.year, todayStart.month, todayStart.day, 23, 59);

    // populate calendar items from yesterday, if any
    if (yesterdayCalendar != null) {
      final type = _dateTimeToCalendarEventColorType(yesterdayStart);

      final startTime = yesterdayCalendar.startTime;
      var dt = startTime;
      var i = 0;

      /// find the first relative event that ends after todayStart, if any, and create a RemovableCalendarEvent for it
      for (; i < yesterdayCalendar.relativeEvents.length; i++) {
        final previousDT = dt;
        dt = dt.add(Duration(minutes: yesterdayCalendar.relativeEvents[i].durationMinutes));
        if (dt.isAfter(todayStart)) {
          final relativeEvent = yesterdayCalendar.relativeEvents[i];
          final durationMinutesForToday = dt.difference(todayStart).inMinutes;
          final removableCalendarEvent = _removableCalendarEvent(
            calendar: yesterdayCalendar,
            headerCalendarDT: todayStart,
            durationMinutes: durationMinutesForToday,
            relativeEvent: relativeEvent,
            relativeEventIndex: i,
            relativeEventStartTime: todayStart,
            title: relativeEvent.title,
            type: type,
            mode: previousDT.isAtSameMomentAs(todayStart) ? CalendarEventMode.none : CalendarEventMode.left,
          );
          result.add(removableCalendarEvent);
          offsetCovered += removableCalendarEvent.height;
          break;
        }
      }

      /// if there are any remaining relative events that start after todayStart, create RemovableCalendarEvent for them
      for (i += 1; i < yesterdayCalendar.relativeEvents.length; i++) {
        final relativeEvent = yesterdayCalendar.relativeEvents[i];
        final previousDT = dt;
        final durationMinutes = relativeEvent.durationMinutes;
        final removableCalendarEvent = _removableCalendarEvent(
          calendar: yesterdayCalendar,
          headerCalendarDT: todayStart,
          durationMinutes: durationMinutes,
          relativeEvent: relativeEvent,
          relativeEventIndex: i,
          relativeEventStartTime: previousDT,
          title: relativeEvent.title,
          type: type,
        );
        result.add(removableCalendarEvent);
        offsetCovered += removableCalendarEvent.height;
        dt = dt.add(Duration(minutes: durationMinutes));
      }

      // if there are relativeEvents that start after start of today, then previousEndTime is the end of the last relative event
      // otherwise no calendar events from yesterday roll over to today so previousEndTime is start of the day
      previousEndTime = dt.isAfter(todayStart) ? dt : todayStart;
    } else {
      previousEndTime = todayStart; // no calendar events from yesterday so previousEndTime is start of the day
    }

    // if there isn't a calendar for today yet, add a new calendar button
    if (todayCalendar == null) {
      final Widget widget;
      if (result.isEmpty) {
        widget = Stack(
          alignment: Alignment.centerLeft,
          children: [
            SizedBox(height: heightContentsEmptyDay),
            AddCalendarButton(
              startTime: todayStart,
            ),
          ],
        );
      }

      /// there are relative events from yesterday that rollover to today, so add a new calendar button at the right after the first
      /// it's presumed that there is at least 2 hours left today (enforced in BLoC)
      else {
        final hEnd = dayHeight - offsetCovered;
        widget = Stack(
          alignment: Alignment.topLeft,
          children: [
            SizedBox(height: hEnd),
            AddCalendarButton(
              startTime: previousEndTime,
            ),
          ],
        );
      }
      result.add(widget);
      return result;
    }

    // otherwise calendar for today, render the events at the correct offset

    /// add the offset
    final dOffset = todayCalendar.startTime.difference(previousEndTime).inMinutes.toDouble();
    final hOffset = dOffset * Configuration.fRegular;
    result.add(SizedBox(height: hOffset));
    offsetCovered += hOffset;

    /// render the events
    var dt = todayCalendar.startTime;
    final relativeEvents = todayCalendar.relativeEvents;
    final type = _dateTimeToCalendarEventColorType(todayStart);
    for (var i = 0; i < relativeEvents.length; i++) {
      final relativeEvent = relativeEvents[i];

      // update start time for next iteration to current item's end time
      final previousDT = dt;
      dt = dt.add(Duration(minutes: relativeEvent.durationMinutes.toInt()));

      // create widget
      if (previousDT.isAtSameMomentAs(tomorrowStart)) {
        // current event starts tomorrow, so done populating for today
        break;
      } else if (dt.isAfter(tomorrowStart)) {
        // current event spans to tomorrow; clip it to today and done
        final durationMinutesForToday = tomorrowStart.difference(previousDT).inMinutes;
        final w = _removableCalendarEvent(
          calendar: todayCalendar,
          durationMinutes: durationMinutesForToday,
          relativeEvent: relativeEvent,
          relativeEventIndex: i,
          relativeEventStartTime: previousDT,
          title: relativeEvent.title,
          type: type,
          mode: CalendarEventMode.right,
        );
        result.add(w);
        offsetCovered += w.height;
        break;
      } else {
        // current event is entirely within today, add it and test the next one
        final w = _removableCalendarEvent(
          calendar: todayCalendar,
          durationMinutes: relativeEvent.durationMinutes,
          relativeEvent: relativeEvent,
          relativeEventIndex: i,
          relativeEventStartTime: previousDT,
          title: relativeEvent.title,
          type: type,
        );
        result.add(w);
        offsetCovered += w.height;
      }
    }

    /// add end of page padding, if any
    final szHeight = dayHeight - offsetCovered;
    if (szHeight > 0) {
      result.add(SizedBox(height: szHeight));
    }
    return result;
  }

  static RemovableCalendarEvent _removableCalendarEvent({
    required Calendar calendar,
    DateTime? headerCalendarDT,
    required int durationMinutes,
    required RelativeEvent relativeEvent,
    required int relativeEventIndex,
    required DateTime relativeEventStartTime,
    required String title,
    required CalendarEventColorTypes type,
    CalendarEventMode? mode,
  }) {
    // compute scaling factor
    var f = CalendarUtils.computeScalingFactor(durationMinutes: durationMinutes.toDouble());

    // compute height
    final h = f * durationMinutes.toDouble();

    // compute end time
    final relativeEventEndTime = relativeEventStartTime.add(Duration(minutes: durationMinutes));

    // create widget
    return RemovableCalendarEvent(
      type: type,
      height: h,
      startTime: relativeEventStartTime,
      endTime: relativeEventEndTime,
      title: title,
      calendar: calendar,
      headerCalendarDT: headerCalendarDT ?? calendar.date,
      relativeEvent: relativeEvent,
      relativeEventIndex: relativeEventIndex,
      mode: mode ?? CalendarEventMode.none,
    );
  }

  static CalendarEventColorTypes _dateTimeToCalendarEventColorType(DateTime dt) {
    final days = dt.difference(DateTime(0)).inDays;
    switch (days % 3) {
      case 0:
        return CalendarEventColorTypes.t1;
      case 1:
        return CalendarEventColorTypes.t2;
      case 2:
        return CalendarEventColorTypes.t3;
      default:
        throw Exception("could not determine color type, days: $days, dt: $dt");
    }
  }
}

class TimelineMultiSliver extends MultiSliver {
  TimelineMultiSliver({
    super.key,
    required DateTime date,
    required Calendar? calendar,
    required Map<int, List<TimeOffset>> timeOffsets,
    required DateTime currentTime,
    required double width,
    required double heightContentsEmptyDay,
  }) : super(
          pushPinnedChildren: true,
          children: _buildSlivers(
            calendar: calendar,
            currentTime: currentTime,
            date: date,
            timeOffsets: timeOffsets,
            heightContentsEmptyDay: heightContentsEmptyDay,
            width: width,
          ),
        );

  static List<Widget> _buildSlivers({
    required Map<int, List<TimeOffset>> timeOffsets,
    required Calendar? calendar,
    required DateTime currentTime,
    required DateTime date,
    required double heightContentsEmptyDay,
    required double width,
  }) {
    final slivers = <Widget>[];

    // add the header
    final sph = SliverPinnedHeader(
      child: Container(
        height: Configuration.heightHeader,
        width: width,
        color: Colors.transparent,
      ),
    );
    slivers.add(sph);

    // if there's no calendar and no time offsets, add the empty space for the day
    if (calendar == null && timeOffsets.isEmpty) {
      final height = heightContentsEmptyDay;
      final w = BlocBuilder<UIBloc, UIState>(
          buildWhen: (previous, current) => previous.currentTime != current.currentTime,
          builder: (context, state) {
            final nowTimeOffset = _getNowTimeOffset(
              currentDT: currentTime.add(const Duration(minutes: 2*60)),
              height: height,
              myDT: date,
            );
            return Stack(
              children: [
                SizedBox(height: height),
                if (nowTimeOffset > -1) NowTimeMarker(offset: nowTimeOffset),
              ],
            );
          });
      slivers.add(SliverList(delegate: SliverChildListDelegate([w])));
      // if there's a calendar or if there are time offsets, add the hour markers with appropriate spacing
    } else {
      final hourChildren = <Widget>[];
      for (var hour = 0; hour < 24; hour++) {
        final hourTimeOffsets = timeOffsets[hour];
        final height = hourTimeOffsets?.fold<double>(
              0.0,
              (previousValue, element) => previousValue + element.height,
            ) ??
            Configuration.height1H;
        final w = BlocBuilder<UIBloc, UIState>(
          buildWhen: (previous, current) => previous.currentTime != current.currentTime,
          builder: (context, state) {
            final nowTimeOffset = _getNowTimeOffsetForTheHour(
              dt: state.currentTime,
              hour: hour,
              startOfDay: date,
              timeOffsetsForTheHour: timeOffsets[hour],
            );
            return Stack(
              children: [
                HourLabelMarker(hour: hour),
                SizedBox(height: height),
                if (nowTimeOffset > -1) NowTimeMarker(offset: nowTimeOffset),
              ],
            );
          },
        );
        hourChildren.add(w);
      }
      slivers.add(SliverList(delegate: SliverChildListDelegate(hourChildren)));
    }

    return slivers;
  }

  static double _getNowTimeOffset({required DateTime currentDT, required DateTime myDT, required double height}) {
    if (currentDT.year != myDT.year || currentDT.month != myDT.month || currentDT.day != myDT.day) {
      return -1;
    }
    const minutesInADay = 24 * 60;
    final minutes = currentDT.difference(myDT).inMinutes.toDouble();
    final offset = minutes / minutesInADay * height;
    return offset;
  }

  static double _getNowTimeOffsetForTheHour(
      {required DateTime startOfDay, required DateTime dt, required int hour, required List<TimeOffset>? timeOffsetsForTheHour}) {
    // if current time is not at the same hour as the hour being processed, return -1
    if (startOfDay.year != dt.year || startOfDay.month != dt.month || startOfDay.day != dt.day || dt.hour != hour) {
      return -1;
    }

    // there are no overrides for the hour, calculate the offset using the default height
    if (timeOffsetsForTheHour == null) {
      final startOfHour = DateTime(startOfDay.year, startOfDay.month, startOfDay.day, hour);
      final minutes = dt.difference(startOfHour).inMinutes.toDouble();
      const minutesInAnHour = 60.0;
      final offset = minutes / minutesInAnHour * Configuration.height1H;
      return offset;
    }

    // there are overrides for the hour, calculate the offset using the offsets of the overrides
    var offset = 0.0;
    for (var timeOffset in timeOffsetsForTheHour) {
      offset += timeOffset.getOffset(dt: dt);
    }
    return offset;
  }
}

class NowTimeMarker extends StatelessWidget {
  const NowTimeMarker({super.key, required this.offset});

  final double offset;

  @override
  Widget build(BuildContext context) {
    final left = Utils.getContentPadding(context).left;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: offset),
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(left: left - 1),
              child: Container(
                transform: Matrix4.rotationZ(pi / 4),
                width: 12,
                height: 12,
                color: LocalColors.background,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Divider(indent: left, thickness: 3, color: LocalColors.background),
            ),
          ],
        ),
      ],
    );
  }
}
