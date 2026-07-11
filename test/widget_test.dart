import 'package:flutter_test/flutter_test.dart';

import 'package:mothx_gui/main.dart';

void main() {
  testWidgets('MothxApp can be instantiated', (WidgetTester tester) async {
    expect(() => const MothxApp(), returnsNormally);
  });
}
