import 'package:flutter_test/flutter_test.dart';
import 'package:elite_wave_cabs/app.dart';

void main() {
  testWidgets('App loads test', (WidgetTester tester) async {
    await tester.pumpWidget(const EliteWaveCabsApp());

    expect(find.text('Elite Wave Cabs'), findsNothing);
  });
}