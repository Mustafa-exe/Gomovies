import 'package:flutter_test/flutter_test.dart';

import 'package:gomovies_private/app.dart';
import 'package:gomovies_private/ui/screens/home_screen.dart';

void main() {
  testWidgets('App renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Global Search'), findsOneWidget);
  });
}
