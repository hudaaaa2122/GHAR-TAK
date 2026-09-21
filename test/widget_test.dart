import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghertak_mobile/main.dart';

void main() {
  testWidgets('GherTak app builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GherTakApp()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Gher'), findsWidgets);
  });
}
