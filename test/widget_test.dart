import 'package:flutter_test/flutter_test.dart';

import 'package:imposter/main.dart';

void main() {
  testWidgets('App startet und zeigt MenuScreen', (WidgetTester tester) async {
    // Unsere App bauen
    await tester.pumpWidget(const ImposterApp());

    // Prüfen, ob "Imposter" im AppBar-Titel oder Text vorkommt
    expect(find.text('Imposter'), findsOneWidget);
  });
}

