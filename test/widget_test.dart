import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vender_app/main.dart';

void main() {
  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VendorApp());

    expect(find.text('Spinovo Partners'), findsOneWidget);
    expect(find.byIcon(Icons.local_laundry_service_rounded), findsOneWidget);
  });
}
