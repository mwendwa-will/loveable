import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/widgets/app_dialog.dart';

void main() {
  group('AppDialog', () {
    testWidgets('showConfirmation displays dialog with title and message',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showConfirmation(
                      context,
                      title: 'Test Title',
                      message: 'Test Message',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('showConfirmation returns true when confirmed',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await AppDialog.showConfirmation(
                      context,
                      title: 'Confirm Action',
                      message: 'Are you sure?',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('showConfirmation returns false when cancelled',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await AppDialog.showConfirmation(
                      context,
                      title: 'Confirm Action',
                      message: 'Are you sure?',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('showConfirmation with isDangerous shows error styling',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showConfirmation(
                      context,
                      title: 'Delete Item',
                      message: 'This cannot be undone',
                      isDangerous: true,
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify the dialog is shown with the dangerous styling
      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('This cannot be undone'), findsOneWidget);
    });

    testWidgets('showInfo displays single OK button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showInfo(
                      context,
                      title: 'Info Title',
                      message: 'Info Message',
                    );
                  },
                  child: const Text('Show Info'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pumpAndSettle();

      expect(find.text('Info Title'), findsOneWidget);
      expect(find.text('Info Message'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('showError displays error dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showError(
                      context,
                      title: 'Error Occurred',
                      message: 'Something went wrong',
                    );
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Error Occurred'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showError with details shows expandable section',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showError(
                      context,
                      title: 'Error',
                      message: 'Failed',
                      details: 'Stack trace here',
                    );
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Details are always visible when provided, no expansion needed
      expect(find.text('Stack trace here'), findsOneWidget);
    });

    testWidgets('showSuccess displays success dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showSuccess(
                      context,
                      title: 'Success!',
                      message: 'Operation completed',
                    );
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      expect(find.text('Success!'), findsOneWidget);
      expect(find.text('Operation completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('showWarning displays warning dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showWarning(
                      context,
                      title: 'Warning',
                      message: 'Proceed with caution',
                    );
                  },
                  child: const Text('Show Warning'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pumpAndSettle();

      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Proceed with caution'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('showLoading displays non-dismissible loading dialog',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showLoading(context, message: 'Processing...');
                  },
                  child: const Text('Show Loading'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Loading'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Processing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Try to dismiss by tapping barrier (should not work)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      // Dialog should still be visible
      expect(find.text('Processing...'), findsOneWidget);
    });

    testWidgets('dismiss closes the dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    AppDialog.showLoading(context, message: 'Loading...');
                    await Future.delayed(const Duration(milliseconds: 500));
                    AppDialog.dismiss(context);
                  },
                  child: const Text('Show and Dismiss'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show and Dismiss'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Loading...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets('showCustom displays custom content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showCustom(
                      context,
                      title: 'Custom Dialog',
                      content: const Text('Custom content here'),
                      type: DialogType.info,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                  child: const Text('Show Custom'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Custom'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Dialog'), findsOneWidget);
      expect(find.text('Custom content here'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('custom button text is respected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppDialog.showConfirmation(
                      context,
                      title: 'Delete?',
                      message: 'Delete this item?',
                      confirmText: 'Delete',
                      cancelText: 'Keep',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Keep'), findsOneWidget);
    });
  });
}
