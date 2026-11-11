import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacked_test/src/fonts.dart';

void main() {
  testWidgets('loadStackedFonts makes Roboto measure like a device',
      (tester) async {
    await tester.runAsync(loadStackedFonts);
    await tester.runAsync(loadStackedFonts); // memoized

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Show Bottom Sheet',
              key: Key('label'),
              style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
            ),
          ],
        ),
      ),
    );
    final width = tester.getSize(find.byKey(const Key('label'))).width;
    expect(width, lessThan(200));
  });
}
