import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:odinclub/ui/components/app_card.dart';

void main() {
  testWidgets('AppCard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCard(
            child: Text('ODIN Club'),
          ),
        ),
      ),
    );

    expect(find.byType(AppCard), findsOneWidget);
    expect(find.text('ODIN Club'), findsOneWidget);
  });
}
