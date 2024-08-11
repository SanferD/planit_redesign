import 'dart:core';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import '../bloc/calendars_bloc.dart';
import '../bloc/ui_bloc.dart';
import 'bloc/utils.dart';
import 'ui/utils/utils.dart';
import 'ui/screens/home_screen.dart';
import './infrastructure/stores/stores.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BlocUtils.initialize();
  runApp(const MyApp());
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
