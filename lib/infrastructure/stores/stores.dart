import 'package:isar/isar.dart';

part 'stores.g.dart';

@collection
class Calendar {
  Calendar();

  Id? id;
  DateTime startTime = DateTime.now();
  List<RelativeEvent> relativeEvents = [];

  DateTime get date {
    return DateTime(startTime.year, startTime.month, startTime.day);
  }

  DateTime get endTime {
    var dt = startTime;
    for (var re in relativeEvents) {
      dt = dt.add(Duration(minutes: re.durationMinutes));
    }
    return dt;
  }

  @override
  String toString() {
    return "Calendar{id: $id, startTime: $startTime, relativeEvents: $relativeEvents}";
  }

  Calendar copy() {
    final Calendar copy = Calendar();
    copy.id = id;
    copy.startTime = startTime;
    copy.relativeEvents = relativeEvents.map((re) => re.copy()).toList();
    return copy;

  }
}

@embedded
class RelativeEvent {
  RelativeEvent();

  Id? id;
  String title = "";
  int durationMinutes = 60;

  @override
  String toString() {
    return "RelativeEvent{title: $title, durationMinutes: $durationMinutes}";
  }

  RelativeEvent copy() {
    final RelativeEvent copy = RelativeEvent();
    copy.id = id;
    copy.title = title;
    copy.durationMinutes = durationMinutes;
    return copy;
  }
}

class CalendarsStore {
  const CalendarsStore({required this.isar});

  final Isar isar;

  Future<Calendar?> getCalendar(final DateTime now) async {
    final DateTime oneDayLater = now.add(const Duration(hours: 23, minutes: 59));
    List<Calendar> calendars = await isar.calendars.filter().startTimeBetween(now, oneDayLater).findAll();
    assert(calendars.length <= 1);
    return calendars.length == 1 ? calendars[0] : null;
  }

  Future<void> putCalendar(final Calendar calendar) async {
    await isar.writeTxn(() async {
      print("writing calendar with id ${calendar.id}");
      await isar.calendars.put(calendar);
    });
  }

  Future<List<Calendar>> listCalendars({required final DateTime lower, required final DateTime upper}) async {
    List<Calendar> calendars = await isar.calendars.filter().startTimeBetween(lower, upper).findAll();
    return calendars;
  }

  Future<void> deleteCalendar(final Calendar calendar) async {
    await isar.writeTxn(() async {
      await isar.calendars.delete(calendar.id!);
    });
  }
}
