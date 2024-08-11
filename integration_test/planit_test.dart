import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:integration_test/integration_test.dart';
import "package:flutter_test/flutter_test.dart";
import "package:planit_redesign/main.dart";
import "package:planit_redesign/bloc/utils.dart";
import "package:planit_redesign/ui/widgets/calendar_widgets.dart";
import "package:planit_redesign/ui/widgets/headers_footers.dart";
import "package:planit_redesign/ui/utils/utils.dart";

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
    await tester.drag(removableEvent, const Offset(200.0, 0.0),
        touchSlopX: 10.0);
    await tester.pumpAndSettle();

    // verify that there are 2 calendar events
    expect(find.byType(RemovableCalendarEvent), findsNWidgets(2));

    // swipe right to remove the calendar event
    final lastRemovableEvent = find.byType(RemovableCalendarEvent).last;
    await tester.drag(lastRemovableEvent, const Offset(-200.0, 0.0),
        touchSlopX: 10.0);
    await tester.pumpAndSettle();

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
    await tester.drag(
      find.byType(CustomScrollView).last, // should be the leader custom scroll view
      const Offset(0.0, 16 * -Configuration.height1H),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    /// verify that the calendar event is still there with the correct time
    final findCalendarEntryAfterSave = find.byType(RemovableCalendarEvent);
    expect(findCalendarEntryAfterSave, findsOneWidget);
    final rceAfterSave =
        findCalendarEntry.evaluate().first.widget as RemovableCalendarEvent;
    expect(rceAfterSave.startTime, equals(timeAfterSave));
  });
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

String get nowDateTimeAsHeaderDateStr =>
    DateFormat.MMMd().format(DateTime.now());

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
        offsetY: -23.0,
        minIterations: 10); // finicky widget
  }
}

Future<void> __scrollOneColumn(
  WidgetTester tester, {
  required Finder findListView,
  required String desiredText,
  double offsetY = -40.0,
  maxIterations = 30,
  minIterations = 0,
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
      if (i >= minIterations) {
        break;
      }
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

Future<void> _loadAppAndCreateCalendarEntry(WidgetTester tester) async {
  await _loadApp(tester);
  final addCalendarButton = find.byType(AddCalendarButton);
  await _tap(tester, finder: addCalendarButton);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _loadApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle(const Duration(seconds: 5));
}
