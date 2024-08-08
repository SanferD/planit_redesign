import 'dart:async';

import 'package:bloc/bloc.dart';
import '../infrastructure/stores/stores.dart';

class CalendarsConfiguration {
  static const autoscrollDays = 8;
  static const initialDays = 7*12;

  static get autoscrollDeltaDuration => const Duration(days: autoscrollDays - 1);
}

sealed class CalendarsEvent {}

class CalendarsStarted extends CalendarsEvent {}

class CalendarsFetchNextWeek extends CalendarsEvent {}

class CalendarsFetchPreviousWeek extends CalendarsEvent {}

class CalendarsRelativeEventCreated extends CalendarsEvent {
  CalendarsRelativeEventCreated({required this.calendar, required this.relativeEventIndex});
  final Calendar calendar;
  final int relativeEventIndex;
}

class CalendarsRelativeEventEditBegan extends CalendarsEvent {
  CalendarsRelativeEventEditBegan({required this.calendar, required this.relativeEventIndex});
  final Calendar calendar;
  final int relativeEventIndex;
}

class CalendarsRelativeEventEditCancelled extends CalendarsEvent {}

class CalendarsRelativeEventTitleUpdated extends CalendarsEvent {
  CalendarsRelativeEventTitleUpdated({required this.title});
  final String title;
}

class CalendarsRelativeEventDurationUpdated extends CalendarsEvent {
  CalendarsRelativeEventDurationUpdated({required this.duration});
  final Duration duration;
}

class CalendarsRelativeEventDeleted extends CalendarsEvent {
  CalendarsRelativeEventDeleted({required this.calendar, required this.relativeEventIndex});
  final Calendar calendar;
  final int relativeEventIndex;
}

class CalendarsRelativeEventMoved extends CalendarsEvent {
  CalendarsRelativeEventMoved({required this.calendar, required this.oldRelativeEventIndex, required this.newRelativeEventIndex});
  final Calendar calendar;
  final int oldRelativeEventIndex;
  final int newRelativeEventIndex;
}

class CalendarsCalendarCreated extends CalendarsEvent {
  CalendarsCalendarCreated({required this.startTime});
  final DateTime startTime;
}

class CalendarsCalendarStartTimeUpdated extends CalendarsEvent {
  CalendarsCalendarStartTimeUpdated({required this.startTime});
  final DateTime startTime;
}

class CalendarsErrorCleared extends CalendarsEvent {}

enum CalendarsStatus { initial, success, failure, inprogress }

class CalendarsError {
  static const maxTitleLength = 20;
  static const none = CalendarsError._(title: "", message: "");
  static const internal = CalendarsError._(title: "Internal Error", message: "An unexpected internal error occurred :(");
  static const durationTooShort = CalendarsError._(title: "Duration Too Short", message: "Duration cannot be 0.");
  static const overlap = CalendarsError._(title: "Two Calendars Overlap", message: "Current calendar should not overlap with the next.");
  static const tooLong = CalendarsError._(title: "Calendar Too Long", message: "Current calendar should not span more than 20 hours into tomorrow.");

  const CalendarsError._({required this.title, required this.message});
  const CalendarsError.titleTooLong({required String longTitle})
      : this._(title: "Title Too Long", message: "The title '$longTitle' is ${longTitle.length} characters. Please keep it under $maxTitleLength characters.");

  final String title;
  final String message;
}

final DateTime now = DateTime.now();
final DateTime today = DateTime(now.year, now.month, now.day);
final DateTime initialLowerDate = today.subtract(const Duration(days: CalendarsConfiguration.initialDays));
final DateTime initialUpperDate = today.add(const Duration(days: CalendarsConfiguration.initialDays));

final class CalendarsState {
  CalendarsStatus get status => _status;
  CalendarsError get error => _error;
  Map<DateTime, Calendar> get date2calendar => _date2calendar;
  DateTime get calendarsLowerDate => _calendarsLowerDate;
  DateTime get calendarsUpperDate => _calendarsUpperDate;
  List<DateTime> get dates => _dates.sublist(1);
  List<DateTime> get allDates => _dates;
  DateTime? get currentCalendarDate => _currentCalendarDate;
  int? get currentRelativeEventIndex => _currentRelativeEventIndex;
  bool get isFirstBuild => _dates.isEmpty;
  List<DateTime> get dirtyDates => _dirtyDates;

  CalendarsState copyWith({
    CalendarsStatus? status,
    CalendarsError? error,
    Map<DateTime, Calendar>? date2calendar,
    List<DateTime>? dates,
    DateTime? calendarsLowerDate,
    DateTime? calendarsUpperDate,
    DateTime? currentCalendarDate,
    int? currentRelativeEventIndex,
    List<DateTime>? dirtyDates,
  }) {
    return CalendarsState(
      status: status ?? _status,
      error: error ?? _error,
      date2calendar: date2calendar ?? _date2calendar,
      dates: dates ?? _dates,
      calendarsLowerDate: calendarsLowerDate ?? _calendarsLowerDate,
      calendarsUpperDate: calendarsUpperDate ?? _calendarsUpperDate,
      currentCalendarDate: currentCalendarDate ?? _currentCalendarDate,
      currentRelativeEventIndex: currentRelativeEventIndex ?? _currentRelativeEventIndex,
      dirtyDates: dirtyDates ?? [],
    );
  }

  CalendarsState({
    status = CalendarsStatus.initial,
    error = CalendarsError.none,
    DateTime? calendarsLowerDate,
    DateTime? calendarsUpperDate,
    Map<DateTime, Calendar> date2calendar = const {},
    List<DateTime> dates = const [],
    DateTime? currentCalendarDate,
    int? currentRelativeEventIndex,
    List<DateTime> dirtyDates = const [],
  })  : _status = status,
        _error = error,
        _calendarsLowerDate = calendarsLowerDate ?? initialLowerDate,
        _calendarsUpperDate = calendarsUpperDate ?? initialUpperDate,
        _date2calendar = date2calendar,
        _dates = dates,
        _currentCalendarDate = currentCalendarDate,
        _currentRelativeEventIndex = currentRelativeEventIndex,
        _dirtyDates = dirtyDates;

  /* errors */
  final CalendarsStatus _status;
  final CalendarsError _error;

  /* calendars state */
  final DateTime _calendarsLowerDate;
  final DateTime _calendarsUpperDate;
  final Map<DateTime, Calendar> _date2calendar; // (y,m,d) -> calendar, the range is closed over [(y1, m1, d1), (y2, m2, d2)]
  final List<DateTime> _dates;
  final List<DateTime> _dirtyDates;

  /* calendar state */
  final DateTime? _currentCalendarDate;
  final int? _currentRelativeEventIndex;

  Calendar? getCalendar({required final DateTime date}) {
    return _date2calendar[date]?.copy();
  }

  CalendarsState resetRelativeEvent() {
    return CalendarsState(
      status: _status,
      error: _error,
      date2calendar: _date2calendar,
      calendarsLowerDate: _calendarsLowerDate,
      calendarsUpperDate: _calendarsUpperDate,
      dates: _dates,
      currentCalendarDate: null,
      currentRelativeEventIndex: null,
    );
  }

  CalendarsState copyCalendarsWith({
    CalendarsStatus? status,
    CalendarsError? error,
    Map<DateTime, Calendar>? date2calendar,
    List<DateTime>? dates,
    List<DateTime>? dirtyDates,
    DateTime? calendarsLowerDate,
    DateTime? calendarsUpperDate,
  }) {
    return resetRelativeEvent().copyWith(
      status: status ?? _status,
      error: error ?? _error,
      calendarsLowerDate: calendarsLowerDate ?? _calendarsLowerDate,
      calendarsUpperDate: calendarsUpperDate ?? _calendarsUpperDate,
      date2calendar: date2calendar ?? _date2calendar,
      dates: dates ?? _dates,
      dirtyDates: dirtyDates ?? [],
    );
  }

  CalendarsState copyCalendarWith({
    CalendarsStatus? status,
    CalendarsError? error,
    DateTime? date,
    Calendar? calendar,
  }) {
    if (date != null) {
      if (calendar == null) {
        _date2calendar.remove(date);
      } else {
        _date2calendar[date] = calendar;
      }
    }
    return resetRelativeEvent().copyWith(
      status: status ?? _status,
      error: error ?? _error,
      date2calendar: _date2calendar,
      dirtyDates: date == null ? [] : [date],
    );
  }

  CalendarsState copyRelativeEventWith({
    CalendarsStatus? status,
    CalendarsError? error,
    DateTime? currentCalendarDate,
    int? currentRelativeEventIndex,
  }) {
    return copyWith(
      status: status ?? _status,
      error: error ?? _error,
      currentCalendarDate: currentCalendarDate ?? _currentCalendarDate,
      currentRelativeEventIndex: currentRelativeEventIndex ?? _currentRelativeEventIndex,
    );
  }
}

final class CalendarsBloc extends Bloc<CalendarsEvent, CalendarsState> {
  final CalendarsStore _calendarsStore;

  CalendarsBloc({required CalendarsStore calendarsStore})
      : _calendarsStore = calendarsStore,
        super(CalendarsState()) {
    on<CalendarsStarted>(_loadCalendars);
    on<CalendarsFetchNextWeek>(_fetchNextWeek);
    on<CalendarsFetchPreviousWeek>(_fetchPreviousWeek);
    on<CalendarsRelativeEventCreated>(_createNextRelativeEvent);
    on<CalendarsRelativeEventEditBegan>(_beginRelativeEventEdit);
    on<CalendarsRelativeEventEditCancelled>(_cancelRelativeEventEdit);
    on<CalendarsRelativeEventTitleUpdated>(_updateRelativeEventTitle);
    on<CalendarsRelativeEventDurationUpdated>(_updateRelativeEventDuration);
    on<CalendarsRelativeEventDeleted>(_deleteRelativeEvent);
    on<CalendarsRelativeEventMoved>(_moveRelativeEvent);
    on<CalendarsCalendarCreated>(_createNewCalendar);
    on<CalendarsCalendarStartTimeUpdated>(_updateCalendarStartTime);
    on<CalendarsErrorCleared>(_clearErrors);
  }

  FutureOr<void> _loadCalendars(CalendarsStarted event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ load calendars");
    emit(state.copyCalendarsWith(status: CalendarsStatus.inprogress));
    final lower = state.calendarsLowerDate;
    final upper = state.calendarsUpperDate;
    final List<Calendar> calendars;
    try {
      calendars = await _calendarsStore.listCalendars(lower: lower, upper: upper);
    } catch (e) {
      emit(state.copyCalendarsWith(error: CalendarsError.internal, status: CalendarsStatus.failure));
      return;
    }
    final Map<DateTime, Calendar> date2calendar = {};
    for (var calendar in calendars) {
      date2calendar[calendar.date] = calendar;
    }
    final List<DateTime> dates = [];
    for (var dt = lower; dt.isBefore(upper) || dt.isAtSameMomentAs(upper); dt = dt.add(const Duration(days: 1))) {
      dates.add(dt);
    }

    emit(state.copyCalendarsWith(date2calendar: date2calendar, dates: dates, status: CalendarsStatus.success));
  }

  FutureOr<void> _fetchNextWeek(CalendarsFetchNextWeek event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ fetch next week");
    final newUpper = state.calendarsUpperDate.add(const Duration(days: CalendarsConfiguration.autoscrollDays));
    final List<Calendar> calendars;
    try {
      calendars = await _calendarsStore.listCalendars(lower: state.calendarsUpperDate, upper: newUpper);
    } catch (e) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
    final Map<DateTime, Calendar> nextDate2calendar = {};
    for (var calendar in calendars) {
      nextDate2calendar[calendar.date] = calendar;
    }
    final newDate2calendar = {...state.date2calendar, ...nextDate2calendar};
    final List<DateTime> dirtyDates = [];
    for (var dt = state.calendarsUpperDate.add(const Duration(days: 1));
        dt.isBefore(newUpper) || dt.isAtSameMomentAs(newUpper);
        dt = dt.add(const Duration(days: 1))) {
      dirtyDates.add(dt);
    }
    final newDates = state.allDates.toList()..addAll(dirtyDates);
    emit(state.copyCalendarsWith(
      calendarsUpperDate: newUpper,
      date2calendar: newDate2calendar,
      dates: newDates,
      dirtyDates: dirtyDates, // increasing values
      status: CalendarsStatus.success,
    ));
  }

  FutureOr<void> _fetchPreviousWeek(CalendarsFetchPreviousWeek event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ fetch previous week");
    final newLower = state.calendarsLowerDate.subtract(const Duration(days: CalendarsConfiguration.autoscrollDays));
    final List<Calendar> calendars;
    try {
      calendars = await _calendarsStore.listCalendars(lower: newLower, upper: state.calendarsLowerDate);
    } catch (e) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
    final Map<DateTime, Calendar> nextDate2calendar = {};
    for (var calendar in calendars) {
      nextDate2calendar[calendar.date] = calendar;
    }
    final newDate2calendar = {...nextDate2calendar, ...state.date2calendar};
    final List<DateTime> nextDates = [];
    for (var dt = newLower; dt.isBefore(state.calendarsLowerDate); dt = dt.add(const Duration(days: 1))) {
      nextDates.add(dt);
    }
    final newDates = nextDates.toList()..addAll(state.allDates);
    nextDates.add(state.allDates.first); // add old first date to next dates (i.e. dirty dates) because they're now "included" in state.dates
    final dirtyDates = nextDates.reversed.toList();
    print("dirtyDates: $dirtyDates, date-min: ${state.allDates.first}, date-max: ${state.allDates.last}");
    emit(state.copyCalendarsWith(
      calendarsLowerDate: newLower,
      date2calendar: newDate2calendar,
      dates: newDates,
      dirtyDates: dirtyDates, // decreasing values
      status: CalendarsStatus.success,
    ));
  }

  FutureOr<void> _createNextRelativeEvent(CalendarsRelativeEventCreated event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ create next relative event");
    final calendar = state.getCalendar(date: event.calendar.date)!;
    final newRelativeEvents = calendar.relativeEvents.toList()..insert(event.relativeEventIndex + 1, RelativeEvent());
    calendar.relativeEvents = newRelativeEvents;
    if (!_isValidCalendarOrEmitError(emit: emit, calendar: calendar)) {
      return;
    }
    try {
      await _calendarsStore.putCalendar(calendar);
    } catch (e) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
    emit(state.copyCalendarWith(date: calendar.date, calendar: calendar, status: CalendarsStatus.success));
  }

  FutureOr<void> _beginRelativeEventEdit(CalendarsRelativeEventEditBegan event, Emitter<CalendarsState> emit) {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ begin relative event edit");
    emit(state.copyRelativeEventWith(currentCalendarDate: event.calendar.date, currentRelativeEventIndex: event.relativeEventIndex));
  }

  FutureOr<void> _cancelRelativeEventEdit(CalendarsRelativeEventEditCancelled event, Emitter<CalendarsState> emit) {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ cancel relatie event edit");
    emit(state.resetRelativeEvent());
  }

  FutureOr<void> _updateRelativeEventTitle(CalendarsRelativeEventTitleUpdated event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ update relative event title");
    if (event.title.length > CalendarsError.maxTitleLength) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.titleTooLong(longTitle: event.title)));
      return;
    }
    final calendar = state.getCalendar(date: state.currentCalendarDate!)!;
    calendar.relativeEvents[state.currentRelativeEventIndex!].title = event.title;
    try {
      await _calendarsStore.putCalendar(calendar);
    } catch (e) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
    emit(state.copyCalendarWith(date: calendar.date, calendar: calendar, status: CalendarsStatus.success));
  }

  FutureOr<void> _updateRelativeEventDuration(CalendarsRelativeEventDurationUpdated event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ update relative event duration");
    if (event.duration.inMinutes <= 0) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.durationTooShort));
      return;
    }
    final calendar = state.getCalendar(date: state.currentCalendarDate!)!;
    calendar.relativeEvents[state.currentRelativeEventIndex!].durationMinutes = event.duration.inMinutes;
    if (!_isValidCalendarOrEmitError(emit: emit, calendar: calendar)) {
      return;
    }
    try {
      await _calendarsStore.putCalendar(calendar);
    } catch (e) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
    emit(state.copyCalendarWith(date: calendar.date, calendar: calendar, status: CalendarsStatus.success));
  }

  FutureOr<void> _deleteRelativeEvent(CalendarsRelativeEventDeleted event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ delete relative event");
    final calendar = state.getCalendar(date: event.calendar.date)!;
    final newRelativeEvents = calendar.relativeEvents.toList()..removeAt(event.relativeEventIndex);
    calendar.relativeEvents = newRelativeEvents;
    if (!_isValidCalendarOrEmitError(emit: emit, calendar: calendar)) {
      return;
    }
    try {
      final Calendar? newCalendar;
      if (newRelativeEvents.isEmpty) {
        await _calendarsStore.deleteCalendar(calendar);
        newCalendar = null;
      } else {
        await _calendarsStore.putCalendar(calendar);
        newCalendar = calendar;
      }
      emit(state.copyCalendarWith(status: CalendarsStatus.success, date: calendar.date, calendar: newCalendar));
    } catch (e) {
      emit(state.copyCalendarWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
  }

  FutureOr<void> _moveRelativeEvent(CalendarsRelativeEventMoved event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ move relative event");
    final calendar = state.getCalendar(date: event.calendar.date)!;
    final relativeEvent = calendar.relativeEvents[event.oldRelativeEventIndex];
    final newRelativeEvents = calendar.relativeEvents.toList()
      ..removeAt(event.oldRelativeEventIndex)
      ..insert(event.newRelativeEventIndex, relativeEvent);
    calendar.relativeEvents = newRelativeEvents;
    if (!_isValidCalendarOrEmitError(emit: emit, calendar: calendar)) {
      return;
    }
    try {
      await _calendarsStore.putCalendar(calendar);
    } catch (e) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
    emit(state.copyCalendarWith(date: calendar.date, calendar: calendar, status: CalendarsStatus.success));
  }

  FutureOr<void> _createNewCalendar(CalendarsCalendarCreated event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ create new calendar");
    final calendar = Calendar();
    calendar.startTime = event.startTime;
    calendar.relativeEvents = [RelativeEvent()];
    if (!_isValidCalendarOrEmitError(emit: emit, calendar: calendar)) {
      return;
    }
    try {
      await _calendarsStore.putCalendar(calendar);
    } catch (e) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
    emit(state.copyCalendarWith(date: calendar.date, calendar: calendar, status: CalendarsStatus.success));
  }

  FutureOr<void> _updateCalendarStartTime(CalendarsCalendarStartTimeUpdated event, Emitter<CalendarsState> emit) async {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ update calendar start time");
    final calendar = state.getCalendar(date: state.currentCalendarDate!)!;
    calendar.startTime = event.startTime;
    if (!_isValidCalendarOrEmitError(emit: emit, calendar: calendar)) {
      return;
    }
    try {
      await _calendarsStore.putCalendar(calendar);
    } catch (e) {
      emit(state.copyCalendarsWith(status: CalendarsStatus.failure, error: CalendarsError.internal));
      return;
    }
    emit(state.copyCalendarWith(date: calendar.date, calendar: calendar, status: CalendarsStatus.success));
  }

  FutureOr<void> _clearErrors(CalendarsErrorCleared event, Emitter<CalendarsState> emit) {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~ clear erros");
    emit(state.copyCalendarsWith(error: CalendarsError.none, status: CalendarsStatus.success));
  }

  bool _isValidCalendarOrEmitError({required Emitter<CalendarsState> emit, required Calendar calendar}) {
    final todayDate = calendar.date;
    final tomorrowDate = todayDate.add(const Duration(days: 1));
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    final tomorrowCalendar = state.getCalendar(date: tomorrowDate);
    final yesterdayCalendar = state.getCalendar(date: yesterdayDate);

    if (tomorrowCalendar != null && calendar.endTime.isAfter(tomorrowCalendar.startTime)) {
      emit(state.copyCalendarsWith(error: CalendarsError.overlap, status: CalendarsStatus.failure));
      return false;
    }

    if (yesterdayCalendar != null && yesterdayCalendar.endTime.isAfter(calendar.startTime)) {
      emit(state.copyCalendarsWith(error: CalendarsError.overlap, status: CalendarsStatus.failure));
      return false;
    }

    final tomorrow4HoursBeforeEnd = DateTime(tomorrowDate.year, tomorrowDate.month, tomorrowDate.day, 20);
    if (calendar.endTime.isAfter(tomorrow4HoursBeforeEnd)) {
      emit(state.copyCalendarsWith(error: CalendarsError.tooLong, status: CalendarsStatus.failure));
      return false;
    }
    return true;
  }
}
