import 'package:flutter/material.dart';
import '../utils/utils.dart';

class HourLabelMarker extends StatelessWidget {
  const HourLabelMarker({
    super.key,
    required this.hour, /* between [0, 23] */
  });

  final int hour;

  @override
  Widget build(BuildContext context) {
    const indent = 56.0;
    return Stack(
      children: [
        const Divider(
          indent: indent,
          thickness: 1,
          color: LocalColors.primary_60,
          height: 1,
        ),
        Padding(
          padding: const EdgeInsets.only(left: indent),
          child: Text(_hourLabel, style: LocalFonts.h7_60),
        ),
      ],
    );
  }

  String get _hourLabel {
    final hour = (this.hour % 12) == 0 ? 12 : this.hour % 12;
    final eeee = this.hour < 12 ? "AM" : "PM";
    return "$hour $eeee";
  }
}

class TimeColumnDivider extends StatelessWidget {
  const TimeColumnDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Utils.getVerticalLinePadding(context),
      child: VerticalDivider(
        width: MediaQuery.of(context).size.height,
        thickness: Configuration.verticalLineThickness,
        color: LocalColors.primary_60,
      ),
    );
  }
}
