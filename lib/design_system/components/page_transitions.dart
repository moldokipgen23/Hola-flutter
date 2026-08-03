import 'package:flutter/material.dart';

class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool slideFromBottom;

  AppPageRoute({
    required this.page,
    super.settings,
    this.slideFromBottom = false,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );

           if (slideFromBottom) {
             return SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0, 0.1),
                 end: Offset.zero,
               ).animate(curvedAnimation),
               child: FadeTransition(opacity: curvedAnimation, child: child),
             );
           }

           return SlideTransition(
             position: Tween<Offset>(
               begin: const Offset(0.05, 0),
               end: Offset.zero,
             ).animate(curvedAnimation),
             child: FadeTransition(opacity: curvedAnimation, child: child),
           );
         },
         transitionDuration: const Duration(milliseconds: 350),
         reverseTransitionDuration: const Duration(milliseconds: 300),
       );
}

class AppFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppFadePageRoute({required this.page, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      );
}

class AppModalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppModalPageRoute({required this.page, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        opaque: false,
        barrierDismissible: true,
      );
}
