import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Configuration {
  static const double cutWidth = 28.0;
  static const double heightTimePicker = 200;
  static const double heightHeader = 140;
  static const double heightFooter = 74;
  static const double height1H = 100;
  static const double minItemHeight = 90;
  static const double fRegular = height1H / 60;
  static const double verticalLineThickness = 3;
  static final BorderRadius borderRadius = BorderRadius.circular(20);
}

class Utils {
  static EdgeInsets getContentPadding(BuildContext context) {
    final offset = getVerticalLineRightOffset(context);
    return EdgeInsets.only(left: offset - 8);
  }

  static EdgeInsets getVerticalLinePadding(BuildContext context) {
    final offset = getVerticalLineRightOffset(context);
    return EdgeInsets.only(right: offset);
  }

  static double getVerticalLineRightOffset(BuildContext context) {
    final offset = MediaQuery.of(context).size.width / 2 - 54;
    return offset;
  }

  static double getItemWidth(BuildContext context) {
    return MediaQuery.of(context).size.width - getVerticalLineRightOffset(context) - Configuration.verticalLineThickness;
  }
  static double getHeightContentsEmptyDay(BuildContext context) {
    return MediaQuery.of(context).size.height - Configuration.heightHeader;
  }
}

class LocalColors {
  static const primary = Color(0xFFFDFFFC);
  static const primary_80 = Color(0xCCFDFFFC);
  static const primary_60 = Color(0x99FDFFFC);
  static const primary_30 = Color(0x4DFDFFFC);
  static const background = Color(0xFF011627);
  static const background_80 = Color(0xCC011627);
  static const background_60 = Color(0x99011627);
  static const error = Color(0XFFE71D36);
  static const error_80 = Color(0xCCE71D36);
  static const error_60 = Color(0x99E71D36);
  static const t1 = Color(0xFF2EC4B6);
  static const t1_80 = Color(0xCC2EC4B6);
  static const t1_60 = Color(0x992EC4B6);
  static const t2 = Color(0xFFCE94EB);
  static const t2_80 = Color(0xCCCE94EB);
  static const t2_60 = Color(0x99CE94EB);
  static const t3 = Color(0xFFFF9F1C);
  static const t3_80 = Color(0xCCFF9F1C);
  static const t3_60 = Color(0x99FF9F1C);
}

class LocalFonts {
  static final h5 = GoogleFonts.permanentMarker(fontSize: 22, color: LocalColors.primary);
  static final h5_60 = GoogleFonts.permanentMarker(fontSize: 22, color: LocalColors.primary_60);
  static final h6 = GoogleFonts.permanentMarker(fontSize: 16, color: LocalColors.primary);
  static final h6_60 = GoogleFonts.permanentMarker(fontSize: 16, color: LocalColors.primary_60);
  static final h7 = GoogleFonts.permanentMarker(fontSize: 12, color: LocalColors.primary);
  static final h7_60 = GoogleFonts.permanentMarker(fontSize: 12, color: LocalColors.primary_60);
}

enum CalendarEventColorTypes { t1, t2, t3 }

enum TimelineItemShapes { atomic, first, middle, last }
