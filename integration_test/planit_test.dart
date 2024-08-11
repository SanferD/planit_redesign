import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:integration_test/integration_test.dart';
import "package:flutter_test/flutter_test.dart";
import "package:planit_redesign/main.dart";
import "package:planit_redesign/bloc/utils.dart";
import "package:planit_redesign/ui/widgets/calendar_widgets.dart";
import "package:planit_redesign/ui/widgets/headers_footers.dart";

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
    String currentDateStr = await _waitUntilAutoScrollToToday(tester);
    expect(find.text(currentDateStr), findsOneWidget);
  });

  testWidgets("should add a new calendar entry for today", (tester) async {
    // load the app and wait for the current date to show up
    await _loadApp(tester);

    // verify that the add new calendar button appears
    final addCalendarButton = find.byType(AddCalendarButton);
    expect(addCalendarButton, findsOneWidget);

    // tap the add new calendar button
    await tester.tap(addCalendarButton);
    await _pump(tester);

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
    await tester.tap(findTimeRangeLabel);
    await _pump(tester);

    // verify that the duration picker and save/cancel footer appears
    expect(find.byType(DurationPickerSpinner), findsOneWidget);
    expect(find.byType(Footer), findsOneWidget);

    // change the duration picker hours and minutes
    await _scrollPicker(tester, type: DurationPickerSpinner, desiredHour: 2, desiredMinute: 12);

    // cancel the duration picker
    await tester.tap(find.byKey(const Key("footer-btn-CANCEL")));
    await _pump(tester);

    // verify that the duration picker and the save/cancel footer are gone
    expect(find.byType(DurationPickerSpinner), findsNothing);
    expect(find.byType(Footer), findsNothing);

    // verify that the time range label has the original time
    final newFindTimeRangeLabel = find.byType(TimeRangeLabel);
    final newTrl = tester.widget(findTimeRangeLabel) as TimeRangeLabel;
    expect(newFindTimeRangeLabel, findsOneWidget);
    expect(newTrl.duration, equals(const Duration(hours: 1)));

    // tap the time range label again
    await tester.tap(newFindTimeRangeLabel);
    await _pump(tester);

    // change the duration picker hours and minutes
    await _scrollPicker(tester, type: DurationPickerSpinner, desiredHour: 2, desiredMinute: 12);

    // save the duration picker
    await tester.tap(find.byKey(const Key("footer-btn-SAVE")));
    await _pump(tester);

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
      await tester.drag(removableEvent, const Offset(200.0, 0.0), touchSlopX: 10.0);
      await tester.pumpAndSettle();
  
      // verify that there are 2 calendar events
      expect(find.byType(RemovableCalendarEvent), findsNWidgets(2));

      // swipe right to remove the calendar event
      final lastRemovableEvent = find.byType(RemovableCalendarEvent).last;
      await tester.drag(lastRemovableEvent, const Offset(-200.0, 0.0), touchSlopX: 10.0);
      await tester.pumpAndSettle();

      // verify that there is 1 calendar event
      expect(find.byType(RemovableCalendarEvent), findsOneWidget);
  });
}

Future<void> _scrollPicker(
  WidgetTester tester, {
  required Type type,
  required int desiredHour,
  required int desiredMinute,
}) async {
  final findDurationPickerSpinner = find.byType(type);
  final findListViews = find.descendant(
    of: findDurationPickerSpinner,
    matching: find.byType(ListView),
  );
  await __scrollOneColumn(tester,
      findListView: findListViews.first, desiredText: desiredHour.toString());
  await __scrollOneColumn(tester,
      findListView: findListViews.last, desiredText: desiredMinute.toString());
}

Future<void> __scrollOneColumn(
  WidgetTester tester, {
  required Finder findListView,
  required String desiredText,
}) async {
  var wText = find
      .descendant(of: findListView, matching: find.byType(Text))
      .evaluate()
      .toList()[1]
      .widget as Text;
  while (wText.data != desiredText) {
    await tester.drag(findListView, const Offset(0, -40), warnIfMissed: false);
    await _pump(tester);
    wText = find
        .descendant(of: findListView, matching: find.byType(Text))
        .evaluate()
        .toList()[1]
        .widget as Text;
  }
}

Future<void> _loadAppAndCreateCalendarEntry(WidgetTester tester) async {
  await _loadApp(tester);
  final addCalendarButton = find.byType(AddCalendarButton);
  await tester.tap(addCalendarButton);
  await _pump(tester);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _loadApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await _waitUntilAutoScrollToToday(tester);
}

Future<String> _waitUntilAutoScrollToToday(WidgetTester tester) async {
  final currentDateStr = DateFormat.MMMd().format(DateTime.now());
  await tester.pumpAndSettle(const Duration(seconds: 5));
  return currentDateStr;
}
