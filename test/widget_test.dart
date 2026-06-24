import 'package:flutter_test/flutter_test.dart';

import 'package:vibecoding_gui/main.dart';

void main() {
  testWidgets('VibeCodingApp can be instantiated', (WidgetTester tester) async {
    // Smoke test: just verify VibeCodingApp can be created without errors.
    expect(() => const VibeCodingApp(), returnsNormally);
  });
}
