import '../../infrastructure/stores/stores.dart';
import './utils.dart';

class CalendarUtils {
  static Map<int, List<TimeOffset>> getTimelineOverride({
    required final DateTime todayStart,
    required final Calendar? yesterdayCalendar,
    required final Calendar? todayCalendar,
  }) {
    Map<int, List<TimeOffset>> overrideForToday = {};
    Map<int, int> totalMinutesPerHour = {};

    _updateOverrideAndTotalMinutesPerHour(
      todayStart: todayStart,
      calendar: yesterdayCalendar,
      override: overrideForToday,
      totalMinutesPerHour: totalMinutesPerHour,
    );
    _updateOverrideAndTotalMinutesPerHour(
      todayStart: todayStart,
      calendar: todayCalendar,
      override: overrideForToday,
      totalMinutesPerHour: totalMinutesPerHour,
    );

    // account for missing pixels of time blocks that aren't fully covered (time window of first and last item)
    totalMinutesPerHour.forEach((hour, minutes) {
      if (minutes < 60) {
        final deltaMinutes = 60 - minutes;
        final hourStartDT = DateTime(todayStart.year, todayStart.month, todayStart.day, hour, minutes);
        final hourEnd = DateTime(todayStart.year, todayStart.month, todayStart.day, hour+1);
        if (overrideForToday[hour] == null) {
          overrideForToday[hour] = [];
        }
        overrideForToday[hour]!.add(TimeOffset(startTime: hourStartDT, endTime: hourEnd, height: Configuration.fRegular * deltaMinutes));
      }
    });
    return overrideForToday;
  }

  static void _updateOverrideAndTotalMinutesPerHour({
    required DateTime todayStart,
    required Calendar? calendar,
    required Map<int, List<TimeOffset>> override,
    required Map<int, int> totalMinutesPerHour,
  }) {
    if (calendar == null) {
      return;
    }

    assert(todayStart.hour == 0);
    assert(todayStart.minute == 0);
    assert(todayStart.second == 0);

    final todayEnd = DateTime(todayStart.year, todayStart.month, todayStart.day, 23, 59);

    var dt = calendar.startTime;
    final relativeEvents = calendar.relativeEvents;
    for (var i = 0; i < relativeEvents.length; i++) {
      final re = relativeEvents[i];

      // compute start and end times of relative event
      final reStartTime = dt;
      final reEndTime = dt.add(Duration(minutes: re.durationMinutes));

      // update dt for next iteration
      dt = reEndTime;

      // if the relative event starts tomorrow, don't consider it because it isn't rendered for today
      if (reStartTime.isAfter(todayEnd)) {
        continue;
      }

      // if the relative event ends yesterday (or at 00:00 today) don't consider it because it isn't rendered for today
      if (reEndTime.isBefore(todayStart) || reEndTime.isAtSameMomentAs(todayStart)) {
        continue;
      }

      // compute the start time and end time of the relative event that falls on today
      final startTime = reStartTime.isBefore(todayStart) ? todayStart : reStartTime;
      final endTime = reEndTime.isAfter(todayEnd) ? todayEnd : reEndTime;

      // compute scaling factor
      final durationMinutes = endTime.difference(startTime).inMinutes;
      final f = computeScalingFactor(durationMinutes: durationMinutes.toDouble());

      // for each hour in the day, calculate the minutes this relative item spans across that hour
      final timeOffsetsPerHour = computeTimeOffsetsPerHour(startTime: startTime, endTime: endTime, f: f, durationMinutes: durationMinutes);

      // use the number of minutes per hour and scaling factor to calculate the timeline height required by this item
      timeOffsetsPerHour.forEach((hour, timeOffset) {
        if (override[hour] == null) {
          override[hour] = [];
        }
        override[hour]!.add(timeOffset);
        totalMinutesPerHour[hour] = (totalMinutesPerHour[hour] ?? 0) + timeOffset.durationMinutes;
      });
    }
  }

  static double computeScalingFactor({required double durationMinutes}) {
    final double f; // compute f (pixels/minute) so that f*durationMinutes >= minItemHeight
    if (Configuration.height1H / 60 * durationMinutes < Configuration.minItemHeight) {
      f = Configuration.minItemHeight / durationMinutes;
    } else {
      f = Configuration.height1H / 60;
    }
    return f;
  }

  static Map<int, TimeOffset> computeTimeOffsetsPerHour(
      {required DateTime startTime, required DateTime endTime, required double f, required int durationMinutes}) {
    // Initialize a map to hold the minutes for each hour
    Map<int, TimeOffset> hour2timeOffset = {};

    DateTime current = startTime;

    // Iterate over the interval
    while (current.isBefore(endTime)) {
      // Determine the end of the current hour
      DateTime hourEnd = DateTime(current.year, current.month, current.day, current.hour + 1);

      // If the hourEnd is after the endTime, set it to endTime
      if (hourEnd.isAfter(endTime)) {
        hourEnd = endTime;
      }

      // Calculate the minutes in the current hour
      final int minutes = hourEnd.difference(current).inMinutes;

      // Add the minutes to the appropriate hour in the map
      hour2timeOffset[current.hour] = TimeOffset(startTime: current, endTime: hourEnd, height: f * minutes);

      // Move to the next hour
      current = hourEnd;
    }

    return hour2timeOffset;
  }

}

class TimeOffset {
  TimeOffset({
    required this.startTime,
    required this.endTime,
    required this.height,
  }) : durationMinutes = endTime.difference(startTime).inMinutes.toInt();

  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double height;

  double getOffset({required final DateTime dt}) {
    if (dt.isBefore(startTime)) {
      return 0;
    }
    if (dt.isAfter(endTime)) {
      return height;
    }

    final int minutes = dt.difference(startTime).inMinutes.toInt();
    return (minutes / durationMinutes) * height;
  }

  @override
  String toString() {
    return 'TimeOffset(startTime: $startTime, endTime: $endTime, durationMinutes: $durationMinutes, height: $height)';
  }
}
