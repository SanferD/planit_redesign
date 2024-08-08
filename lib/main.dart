import 'dart:core';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../bloc/calendars_bloc.dart';
import '../bloc/ui_bloc.dart';
import 'ui/utils/utils.dart';
import 'ui/screens/home_screen.dart';
import './infrastructure/stores/stores.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await registerCalendarStore();
  runApp(const MyApp());
}

Future<void> registerCalendarStore() async {
  final dir = await getApplicationSupportDirectory();
  final isar = await Isar.open([CalendarSchema], directory: dir.path, inspector: true);
  GetIt.instance.registerSingleton(CalendarsStore(isar: isar));
}

final themeData = ThemeData(
  useMaterial3: true,
  textTheme: TextTheme(
    bodyLarge: LocalFonts.h5,
    bodyMedium: LocalFonts.h6,
    bodySmall: LocalFonts.h7,
    displayLarge: LocalFonts.h5,
    displayMedium: LocalFonts.h6,
    displaySmall: LocalFonts.h7,
    headlineLarge: LocalFonts.h5,
    headlineMedium: LocalFonts.h6,
    headlineSmall: LocalFonts.h7,
    labelLarge: LocalFonts.h5,
    labelMedium: LocalFonts.h6,
    labelSmall: LocalFonts.h7,
    titleLarge: LocalFonts.h5,
    titleMedium: LocalFonts.h6,
    titleSmall: LocalFonts.h7,
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /*{
      final Calendar calendar = Calendar();
      calendar.startTime = DateTime(2024, 7, 17, 8);
      RelativeEvent re1 = RelativeEvent(); re1.title="title-1"; re1.durationMinutes=45;
      RelativeEvent re2 = RelativeEvent(); re2.title="title-2"; re2.durationMinutes=30;
      RelativeEvent re3 = RelativeEvent(); re3.title="title-3"; re3.durationMinutes=60;
      calendar.relativeEvents.add(re1);
      calendar.relativeEvents.add(re2);
      calendar.relativeEvents.add(re3);

      GetIt.I.get<CalendarStore>().putCalendar(calendar);
    }*/

    return MaterialApp(
      title: 'Flutter Demo',
      theme: themeData,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CalendarsBloc(calendarsStore: GetIt.I.get<CalendarsStore>())..add(CalendarsStarted())),
          BlocProvider(create: (_) => UIBloc()),
        ],
        child: const HomeScreen(),
      ),
    );
  }
}
