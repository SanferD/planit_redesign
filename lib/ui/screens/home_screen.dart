import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/calendars_bloc.dart';
import '../widgets/background_image.dart';
import '../widgets/sticky_calendar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundImage(
        imageFileName: "james-webb-telescope.jpg",
        stackChildren: [
          BlocBuilder<CalendarsBloc, CalendarsState>(
            buildWhen: (previous, current) {
              return previous.isFirstBuild;
            },
            builder: (context, calendarsState) {
              print("BUILDING...");
              switch (calendarsState.status) {
                case CalendarsStatus.initial:
                  return const Text("initial");
                case CalendarsStatus.inprogress:
                  return const Text("inprogress");
                case CalendarsStatus.failure:
                case CalendarsStatus.success:
                  return StickyCalendar(
                    key: const Key("sticky-calendar"),
                    date2calendar: calendarsState.date2calendar,
                    dates: calendarsState.dates,
                  );
                default:
                  throw Exception("unsupported status: ${calendarsState.status}");
              }
            },
          ),
        ],
      ),
    );
  }
}
