import 'package:flutter_test/flutter_test.dart';
import 'package:elite_wave_cabs/app.dart';

void main() {
  testWidgets('App loads test', (WidgetTester tester) async {
    await tester.pumpWidget(const EliteWaveCabsApp());

    // The app title is present in the widget tree; verify it appears.
    expect(find.text('Elite Wave Cabs'), findsOneWidget);
  });
}