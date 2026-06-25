import 'package:flutter_test/flutter_test.dart';

import 'package:vibecoding_gui/main.dart';

void main() {
  testWidgets('VibeWorkApp can be instantiated', (WidgetTester tester) async {
    // Smoke test: just verify VibeWorkApp can be created without errors.
    expect(() => const VibeWorkApp(), returnsNormally);
  });
}
