import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braand_school_app/auth/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    // Disable GoogleFonts runtime fetching for tests to avoid network issues
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App smoke test - Login Screen renders', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    // Verify that the login screen shows the app name.
    expect(find.text('Braand School'), findsOneWidget);
    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
