import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:planit_redesign/bloc/calendars_bloc.dart";
import "package:planit_redesign/bloc/utils.dart";
import "package:planit_redesign/main.dart";
import "package:planit_redesign/ui/utils/utils.dart";
import "package:planit_redesign/ui/widgets/calendar_widgets.dart";
import "package:planit_redesign/ui/widgets/headers_footers.dart";
import "package:planit_redesign/ui/widgets/sticky_calendar.dart";
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await BlocUtils.initialize();
  });

  tearDown(() async {
    await BlocUtils.dispose();
  });

  testWidgets("should autoscroll to the current date", (tester) async {
    // load the app
    await tester.pumpWidget(const MyApp());
    await _pumpAndSettle(tester);

    // wait for the current date to show up
    expect(find.text(nowDateTimeAsHeaderDateStr), findsOneWidget);
  });

  testWidgets("should add a new calendar entry for today", (tester) async {
    // load the app and wait for the current date to show up
    await _loadApp(tester);

    // verify that the add new calendar button appears
    final addCalendarButton = find.byType(AddCalendarButton);
    expect(addCalendarButton, findsOneWidget);

    // tap the add new calendar button
    await _tap(tester, finder: addCalendarButton);

    // verify that there's a new calendar entry
    expect(find.byType(RemovableCalendarEvent), findsOneWidget);
  });

  testWidgets("should update title of a calendar entry", (tester) async {
    // load the app and create a calendar entry
    await _loadAppAndCreateCalendarEntry(tester);

    // verify that the title field appears
    final titleField = find.byType(FocusableTextWidget);
    expect(titleField, findsOneWidget);

    // enter a new title
    const titleText = "title text";
    await tester.enterText(titleField, titleText);
    await _pump(tester);

    // verify that the new title appears
    expect(find.text(titleText), findsOneWidget);
  });

  testWidgets(
      "should correctly interact with the time range label of a calendar entry",
      (tester) async {
    // load the app and create a calendar entry
    await _loadAppAndCreateCalendarEntry(tester);

    // verify that the time range label appears with the correct time
    final findTimeRangeLabel = find.byType(TimeRangeLabel);
    final trl = tester.widget(findTimeRangeLabel) as TimeRangeLabel;
    expect(findTimeRangeLabel, findsOneWidget);
    expect(trl.duration, equals(const Duration(hours: 1)));

    // tap the time range label
    await _tap(tester, finder: findTimeRangeLabel);

    // verify that the duration picker and save/cancel footer appears
    expect(find.byType(DurationPickerSpinner), findsOneWidget);
    expect(find.byType(Footer), findsOneWidget);

    // change the duration picker hours and minutes
    await _scrollPicker(tester,
        type: DurationPickerSpinner, desiredHour: 2, desiredMinute: 12);

    // cancel the duration picker
    await _tapCancelFooterButton(tester);

    // verify that the duration picker and the save/cancel footer are gone
    expect(find.byType(DurationPickerSpinner), findsNothing);
    expect(find.byType(Footer), findsNothing);

    // verify that the time range label has the original time
    final newFindTimeRangeLabel = find.byType(TimeRangeLabel);
    final newTrl = tester.widget(findTimeRangeLabel) as TimeRangeLabel;
    expect(newFindTimeRangeLabel, findsOneWidget);
    expect(newTrl.duration, equals(const Duration(hours: 1)));

    // tap the time range label again
    await _tap(tester, finder: newFindTimeRangeLabel);

    // change the duration picker hours and minutes
    await _scrollPicker(tester,
        type: DurationPickerSpinner, desiredHour: 2, desiredMinute: 12);

    // save the duration picker
    await _tapSaveFooterButton(tester);

    // verify that the duration picker and the save/cancel footer are gone
    expect(find.byType(DurationPickerSpinner), findsNothing);
    expect(find.byType(Footer), findsNothing);

    // verify that the time range label appears with the new time
    final anotherFindTimeRangeLabel = find.byType(TimeRangeLabel);
    final anotherTrl = tester.widget(findTimeRangeLabel) as TimeRangeLabel;
    expect(anotherFindTimeRangeLabel, findsOneWidget);
    expect(anotherTrl.duration, equals(const Duration(hours: 2, minutes: 12)));
  });

  testWidgets("should add and remove next relative event", (tester) async {
    // load the app and create a calendar entry
    await _loadAppAndCreateCalendarEntry(tester);

    // swipe left to create next calendar event
    final removableEvent = find.byType(RemovableCalendarEvent);
    await _addNextEvent(tester, removableEvent: removableEvent);

    // verify that there are 2 calendar events
    expect(find.byType(RemovableCalendarEvent), findsNWidgets(2));

    // swipe right to remove the calendar event
    final lastRemovableEvent = find.byType(RemovableCalendarEvent).last;
    await _removeEvent(tester, removableEvent: lastRemovableEvent);

    // verify that there is 1 calendar event
    expect(find.byType(RemovableCalendarEvent), findsOneWidget);
  });

  testWidgets("should change start time of calendar", (tester) async {
    // load the app and create a calendar entry
    await _loadAppAndCreateCalendarEntry(tester);

    // verify that the start time in the header is 12:00 AM
    /// get the header for today
    final findHeader = find
        .ancestor(
          of: find.text(nowDateTimeAsHeaderDateStr),
          matching: find.byType(Header),
        )
        .first;

    /// get the CurrentTimeHeaderButton descendant
    final findCurrentTimeHeaderButton = find
        .descendant(
          of: findHeader,
          matching: find.byType(CurrentTimeHeaderButton),
        )
        .first;

    /// verify that the time on the button is 12:00 AM
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    expect(
        find.descendant(
            of: findCurrentTimeHeaderButton,
            matching: find.text(DateFormat.jm().format(todayStart))),
        findsOneWidget);

    // verify that there's only one calendar event with the start time 12:00 AM
    final findCalendarEntry = find.byType(RemovableCalendarEvent);
    expect(findCalendarEntry, findsOneWidget);
    final rce =
        findCalendarEntry.evaluate().first.widget as RemovableCalendarEvent;
    expect(rce.startTime, equals(todayStart));

    // tap the start time in the header
    await _tap(tester, finder: findCurrentTimeHeaderButton);

    // verify that the time picker appears
    final starTimePickerSpinner = find.byType(StartTimePickerSpinner);
    expect(starTimePickerSpinner, findsOneWidget);

    // change the time picker hours and minutes and AM/PM
    await _scrollPicker(
      tester,
      type: StartTimePickerSpinner,
      desiredHour: 2,
      desiredMinute: 1,
      desiredMeridiem: Meridiem.pm,
    );

    // cancel the time picker
    await _tapCancelFooterButton(tester);

    // verify that the time picker is gone
    expect(find.byType(StartTimePickerSpinner), findsNothing);

    // verify that the start time in the header is still 12:00 AM
    final findCurrentTimeAfterCancel = find
        .descendant(
            of: findHeader, matching: find.byType(CurrentTimeHeaderButton))
        .first;
    expect(
        find.descendant(
            of: findCurrentTimeAfterCancel,
            matching: find.text(DateFormat.jm().format(todayStart))),
        findsOneWidget);

    // verify that there's still only one calendar event with the start time 12:00 AM
    final findCalendarEntryAfterCancel = find.byType(RemovableCalendarEvent);
    expect(findCalendarEntry, findsOneWidget);
    final rceAfterCancel = findCalendarEntryAfterCancel.evaluate().first.widget
        as RemovableCalendarEvent;
    expect(rceAfterCancel.startTime, equals(todayStart));

    // tap the start time in the header again and change the time picker hours and minutes
    await _tap(tester, finder: findCurrentTimeAfterCancel);

    // change the time picker hours, minutes, and AM/PM
    await _scrollPicker(
      tester,
      type: StartTimePickerSpinner,
      desiredHour: 2,
      desiredMinute: 1,
      desiredMeridiem: Meridiem.pm,
    );

    // save the time picker
    await _tapSaveFooterButton(tester);

    // verify that the time picker is gone, and the start time in the header is the new time
    expect(find.byType(StartTimePickerSpinner), findsNothing);

    // verify that the start time in the header is 2:01 PM
    final timeAfterSave = todayStart.add(const Duration(hours: 14, minutes: 1));
    final findCurrentTimeAfterSave = find
        .descendant(
            of: findHeader, matching: find.byType(CurrentTimeHeaderButton))
        .first;
    expect(
        find.descendant(
            of: findCurrentTimeAfterSave,
            matching: find.text(DateFormat.jm().format(timeAfterSave))),
        findsOneWidget);

    // verify that there's still only one calendar event with the new start time

    /// scroll the screen by 16 hours to find the calendar event
    await _scroll(tester, delta: -16 * Configuration.height1H);

    /// verify that the calendar event is still there with the correct time
    final findCalendarEntryAfterSave = find.byType(RemovableCalendarEvent);
    expect(findCalendarEntryAfterSave, findsOneWidget);
    final rceAfterSave =
        findCalendarEntry.evaluate().first.widget as RemovableCalendarEvent;
    expect(rceAfterSave.startTime, equals(timeAfterSave));
  });

  testWidgets("should facilitate calendars that span multiple days",
      (tester) async {
    // load app and create the first calendar event
    await _loadAppAndCreateCalendarEntry(tester);

    // change the duration of the first event to 4 hours
    await _tap(tester, finder: find.byType(TimeRangeLabel));
    await _scrollPicker(tester,
        type: DurationPickerSpinner, desiredHour: 4, desiredMinute: 0);
    await _tapSaveFooterButton(tester);

    // add second calendar event
    await _addNextEvent(tester,
        removableEvent: find.byType(RemovableCalendarEvent));

    // change the duration of the second calendar event to 3 hours
    await _tap(tester, finder: find.byType(TimeRangeLabel).last);
    await _scrollPicker(tester,
        type: DurationPickerSpinner, desiredHour: 3, desiredMinute: 0);
    await _tapSaveFooterButton(tester);

    // add third calendar event
    await _addNextEvent(tester,
        removableEvent: find.byType(RemovableCalendarEvent).last);

    // change start time to 7:00 PM
    final findCurrentTimeHeaderButton = find
        .descendant(
          of: find.byType(Header).first,
          matching: find.byType(CurrentTimeHeaderButton),
        )
        .first;
    await _tap(tester, finder: findCurrentTimeHeaderButton);
    await _scrollPicker(tester,
        type: StartTimePickerSpinner,
        desiredHour: 7,
        desiredMinute: 0,
        desiredMeridiem: Meridiem.pm);
    await _tapSaveFooterButton(tester);

    // scroll until the header of the next day is almost visible
    await _scroll(tester, delta: -19 * Configuration.height1H);

    // verify that there are 2 calendar events for today
    expect(
        find.descendant(
            of: find.byType(CalendarEventsMultiSliver).first,
            matching: find.byType(RemovableCalendarEvent)),
        findsNWidgets(2));

    // scroll until the header of the next day is at the top
    await _scroll(tester, delta: -5.2 * Configuration.height1H);

    // verify that there are 2 calendar events for tomorrow
    expect(
        find.descendant(
            of: find.byType(CalendarEventsMultiSliver).last,
            matching: find.byType(RemovableCalendarEvent)),
        findsNWidgets(2));

    // verify that there's a Add CalendarButton for tomorrow
    expect(find.byType(AddCalendarButton), findsOneWidget);

    // tap the Add CalendarButton for tomorrow
    await _tap(tester, finder: find.byType(AddCalendarButton));

    // verify that there's a new calendar event for tomorrow
    expect(
        find.descendant(
            of: find.byType(CalendarEventsMultiSliver).last,
            matching: find.byType(RemovableCalendarEvent)),
        findsNWidgets(3));

    // verify that the color of the calendar event for tomorrow is different
    final events = find
        .descendant(
            of: find.byType(CalendarEventsMultiSliver).last,
            matching: find.byType(RemovableCalendarEvent))
        .evaluate()
        .map((e) => e.widget as RemovableCalendarEvent)
        .toList();
    expect(events.last.colorSolid, isNot(events.first.colorSolid));

    // verify that the start time of the calendar event is at the end time of the last event for the previous calendar
    final now = DateTime.now();
    final tomorrow3am = DateTime(now.year, now.month, now.day + 1, 3);
    find.descendant(
        of: find.byType(CurrentTimeHeaderButton),
        matching: find.text(DateFormat.jm().format(tomorrow3am)));
  });

  testWidgets("should error on invalid title length", (tester) async {
    // load the app and create a calendar entry
    await _loadAppAndCreateCalendarEntry(tester);

    // tap the title field
    await _tap(tester, finder: find.byType(FocusableTextWidget));

    // enter a long title
    const titleText =
        "very long title text it should show error dialog shortly";
    await tester.enterText(find.byType(FocusableTextWidget), titleText);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _pumpAndSettle(tester);

    // verify that the error dialog appears with the correct message
    _verifyErrorDialog(const CalendarsError.titleTooLong(longTitle: titleText));

    // tap outside the dialog
    await _closeErrorDialog(tester);

    // verify that the error dialog disappears
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("should error on invalid duration", (tester) async {
    // laod the app and create a calendar entry
    await _loadAppAndCreateCalendarEntry(tester);

    // tap the time range label
    await _tap(tester, finder: find.byType(TimeRangeLabel));

    // set the duration to 0
    await _scrollPicker(tester,
        type: DurationPickerSpinner, desiredHour: 0, desiredMinute: 0);
    await _tapSaveFooterButton(tester);

    // verify that the error dialog appears with the correct message
    _verifyErrorDialog(CalendarsError.durationTooShort);

    // tap outside the dialog
    await _closeErrorDialog(tester);

    // verify that the error dialog disappears
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("should error on overlapping calendars", (tester) async {
    // laod the app and create a calendar entry
    await _loadAppAndCreateCalendarEntry(tester);

    // add a couple of entries today so that the calendar spans 10 hours
    for (var i = 0; i < 10; i++) {
      await _addNextEvent(
        tester,
        removableEvent: find.byType(RemovableCalendarEvent).first,
      );
    }

    // scroll to tomorrow
    await _scroll(tester, delta: -24 * Configuration.height1H);

    // tap the add calendar button
    await _tap(tester, finder: find.byType(AddCalendarButton));

    // add a couple of entries tomorrow so that the calendar spans 10 hours
    for (var i = 0; i < 10; i++) {
      await _addNextEvent(
        tester,
        removableEvent: find.byType(RemovableCalendarEvent).first,
      );
    }

    // change the start time for tomorrow to 3:00 AM
    final tomorrowCurrentTimeHeaderButton = find
        .descendant(
          of: find.byType(Header).last,
          matching: find.byType(CurrentTimeHeaderButton),
        )
        .first;
    await _tap(tester, finder: tomorrowCurrentTimeHeaderButton);
    await _scrollPicker(tester,
        type: StartTimePickerSpinner, desiredHour: 3, desiredMinute: 0);
    await _tapSaveFooterButton(tester);

    //~ error when the calendars overlap after changing the start time of the current calendar

    // scroll back to today
    await _scroll(tester, delta: 23 * Configuration.height1H);

    // change the start time to 10:00 PM
    final todayCurrentTimeHeaderButton = find
        .descendant(
          of: find.byType(Header).first,
          matching: find.byType(CurrentTimeHeaderButton),
        )
        .first;
    await _tap(tester, finder: todayCurrentTimeHeaderButton);
    await _scrollPicker(tester,
        type: StartTimePickerSpinner,
        desiredHour: 10,
        desiredMinute: 0,
        desiredMeridiem: Meridiem.pm);
    await _tapSaveFooterButton(tester);

    // verity that the error dialog appears with the correct message
    _verifyErrorDialog(CalendarsError.overlap);

    // close the error dialog
    await _closeErrorDialog(tester);

    // change the start time to 3:00 PM
    await _tap(tester, finder: todayCurrentTimeHeaderButton);
    await _scrollPicker(tester,
        type: StartTimePickerSpinner,
        desiredHour: 3,
        desiredMinute: 0,
        desiredMeridiem: Meridiem.pm);
    await _tapSaveFooterButton(tester);

    //~ error when the calendars overlap after changing the start time of the next calendar

    // scroll to tomorrow
    await _scroll(tester, delta: -24 * Configuration.height1H);

    // change the start time to 2:00 AM
    await _tap(tester, finder: tomorrowCurrentTimeHeaderButton);
    await _scrollPicker(tester,
        type: StartTimePickerSpinner,
        desiredHour: 1,
        desiredMinute: 0,
        desiredMeridiem: Meridiem.am);
    await _tapSaveFooterButton(tester);

    // verify that the error dialog appears with the correct message
    _verifyErrorDialog(CalendarsError.overlap);

    // close the error dialog
    await _closeErrorDialog(tester);

    //~ error when the calendars overlap after changing the duration of the current calendar

    // scroll back to today
    await _scroll(tester, delta: 14 * Configuration.height1H);

    // change the duration of the current calendar to 15 hours
    await _tap(tester, finder: find.byType(TimeRangeLabel).first);
    await _scrollPicker(tester,
        type: DurationPickerSpinner, desiredHour: 15, desiredMinute: 0);
    await _tapSaveFooterButton(tester);

    // verify that the error dialog appears with the correct message
    _verifyErrorDialog(CalendarsError.overlap);

    // close the error dialog
    await _closeErrorDialog(tester);

    // verify that the error dialog disappears
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
      "should error when the current calendar spans too long a time span",
      (tester) async {
    // load the app and create a calendar entry
    await _loadAppAndCreateCalendarEntry(tester);

    // add multiple calendar entries until it spans 20 hours
    for (var i = 0; i < 24; i++) {
      await _addNextEvent(
        tester,
        removableEvent: find.byType(RemovableCalendarEvent).first,
      );
    }

    // change the duration of the last calendar entry to 22 hours
    await _tap(tester, finder: find.byType(TimeRangeLabel).last);
    await _scrollPicker(tester,
        type: DurationPickerSpinner, desiredHour: 22, desiredMinute: 0);
    await _tapSaveFooterButton(tester);

    // verify that the error dialog appears with the correct message
    _verifyErrorDialog(CalendarsError.calendarsTooLong);

    // close the error dialog
    await _closeErrorDialog(tester);

    // verify that the error dialog disappears
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("should seamlessly scroll forward by 3 months", (tester) async {
    // load the app
    await _loadApp(tester);

    // get screen height
    final BuildContext context = tester.element(find.byType(Header).first);
    final screenHeight = MediaQuery.of(context).size.height;

    // scroll forward by 3 months at a rate of 5 days per scroll
    const numDays = 3 * 30;
    const scrollRate = 5; // days per scroll
    const numScrolls = numDays / scrollRate;
    final delta = scrollRate * screenHeight;
    for (var i = 0; i < numScrolls; i++) {
      await _scroll(tester, delta: -delta);
    }

    // verify that the current header is 3 months from now
    final desiredDateTime =
        DateTime.now().add(const Duration(days: numDays - 1));
    final desiredDateStr = DateFormat.MMMd().format(desiredDateTime);
    final findHeader = find.ancestor(
      of: find.text(desiredDateStr),
      matching: find.byType(Header),
    );
    expect(findHeader, findsOneWidget);
  });

  testWidgets("should seamlessly scroll backward by 3 months", (tester) async {
    // load the app
    await _loadApp(tester);

    // get screen height
    final BuildContext context = tester.element(find.byType(Header).first);
    final screenHeight = MediaQuery.of(context).size.height;

    // scroll backward by 3 months at a rate of 5 days per scroll
    const numDays = 3 * 30;
    const scrollRate = 5; // days per scroll
    const numScrolls = numDays / scrollRate;
    final delta = scrollRate * screenHeight;
    for (var i = 0; i < numScrolls; i++) {
      await _scroll(tester, delta: delta);
    }

    // verify that the current header is 3 months before now
    final desiredDateTime =
        DateTime.now().subtract(const Duration(days: numDays - 1));
    final desiredDateStr = DateFormat.MMMd().format(desiredDateTime);
    final findHeader = find.ancestor(
      of: find.text(desiredDateStr),
      matching: find.byType(Header),
    );
    expect(findHeader, findsOneWidget);
  });
}

String get nowDateTimeAsHeaderDateStr =>
    DateFormat.MMMd().format(DateTime.now());

Future<void> _closeErrorDialog(WidgetTester tester) async {
  await tester.tapAt(const Offset(100.0, 200.0));
  await _pumpAndSettle(tester);
}

void _verifyErrorDialog(CalendarsError error) {
  expect(find.byType(AlertDialog), findsOneWidget);
  final ad = find.byType(AlertDialog).evaluate().first.widget as AlertDialog;
  expect((ad.title as Text).data, equals(error.title));
  expect((ad.content as Text).data, equals(error.message));
}

Future<void> _scroll(WidgetTester tester, {required double delta}) async {
  await tester.drag(
    find
        .byType(CustomScrollView)
        .last, // should be the leader custom scroll view
    Offset(0.0, delta),
  );
  await _pumpAndSettle(tester);
}

Future<void> _removeEvent(WidgetTester tester,
    {required Finder removableEvent}) async {
  await tester.drag(removableEvent, const Offset(-200.0, 0.0),
      touchSlopX: 10.0);
  await _pumpAndSettle(tester);
}

Future<void> _addNextEvent(WidgetTester tester,
    {required Finder removableEvent}) async {
  await tester.drag(removableEvent, const Offset(200.0, 0.0), touchSlopX: 10.0);
  await _pump(tester);
  await _pump(tester);
  await _pump(tester);
}

Future<void> _tapCancelFooterButton(WidgetTester tester) async {
  await _tap(tester, finder: find.byKey(const Key("footer-btn-CANCEL")));
}

Future<void> _tapSaveFooterButton(WidgetTester tester) async {
  await _tap(tester, finder: find.byKey(const Key("footer-btn-SAVE")));
}

Future<void> _tap(WidgetTester tester, {required Finder finder}) async {
  await tester.tap(finder);
  await _pump(tester);
}

enum Meridiem { am, pm }

Future<void> _scrollPicker(
  WidgetTester tester, {
  required Type type,
  required int desiredHour,
  required int desiredMinute,
  Meridiem? desiredMeridiem,
}) async {
  final findDurationPickerSpinner = find.byType(type);
  final findListViews = find.descendant(
    of: findDurationPickerSpinner,
    matching: find.byType(ListView),
  );
  await __scrollOneColumn(tester,
      findListView: findListViews.at(0), desiredText: desiredHour.toString());
  await __scrollOneColumn(tester,
      findListView: findListViews.at(1), desiredText: desiredMinute.toString());
  if (desiredMeridiem != null) {
    await __scrollOneColumn(tester,
        findListView: findListViews.at(2),
        desiredText: desiredMeridiem == Meridiem.am ? "AM" : "PM",
        offsetY: -23.0);
  }
}

Future<void> __scrollOneColumn(
  WidgetTester tester, {
  required Finder findListView,
  required String desiredText,
  double offsetY = -45.0,
  maxIterations = 300,
}) async {
  Text? activeText = find
      .descendant(of: findListView, matching: find.byType(Text))
      .evaluate()
      .map((e) => e.widget as Text)
      .where(
          (t) => t.style != null && t.style!.color == const Color(0xfffdfffc))
      .firstOrNull;
  for (var i = 0; i < maxIterations; i++) {
    if (activeText != null && activeText.data == desiredText) {
      await _pumpAndSettle(tester);
      break;
    }
    await tester.drag(findListView, Offset(0, offsetY), warnIfMissed: false);
    await _pump(tester);
    activeText = find
        .descendant(of: findListView, matching: find.byType(Text))
        .evaluate()
        .map((e) => e.widget as Text)
        .where(
            (t) => t.style != null && t.style!.color == const Color(0xfffdfffc))
        .firstOrNull;
  }
}

Future<int> _pumpAndSettle(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(seconds: 5));

Future<void> _pump(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _loadAppAndCreateCalendarEntry(WidgetTester tester) async {
  await _loadApp(tester);
  final addCalendarButton = find.byType(AddCalendarButton);
  await _tap(tester, finder: addCalendarButton);
}

Future<void> _loadApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await _pumpAndSettle(tester);
}
