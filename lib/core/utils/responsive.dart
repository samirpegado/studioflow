import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint && 
           width < AppConstants.tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;
  }
  
  static double getPadding(BuildContext context) {
    if (isMobile(context)) {
      return AppConstants.paddingMD;
    } else if (isTablet(context)) {
      return AppConstants.paddingLG;
    } else {
      return AppConstants.paddingXL;
    }
  }
  
  static int getCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }
  
  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200;
    } else if (isTablet(context)) {
      return 900;
    } else {
      return double.infinity;
    }
  }
}

