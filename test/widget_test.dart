import 'package:flutter_test/flutter_test.dart';
import 'package:odin/main.dart';

void main() {
  testWidgets('loads themed auth flow and switches to register', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OdinFinanceApp());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Remember me'), findsOneWidget);

    await tester.tap(find.text('Register').last);
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsWidgets);
    expect(find.text('Responsable Club'), findsOneWidget);
    expect(find.text('Autre role'), findsOneWidget);
  });
}
