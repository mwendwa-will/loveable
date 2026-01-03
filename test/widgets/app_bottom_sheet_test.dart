import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovely/widgets/app_bottom_sheet.dart';

void main() {
  group('AppBottomSheet', () {
    testWidgets('show displays bottom sheet with title and content',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      context,
                      title: 'Test Sheet',
                      content: const Text('Test Content'),
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Test Sheet'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('show with actions displays action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      context,
                      title: 'Sheet with Actions',
                      content: const Text('Content'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Submit'),
                        ),
                      ],
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('showList displays list of items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showList<String>(
                      context,
                      title: 'Select Item',
                      items: [
                        BottomSheetItem(
                          value: 'item1',
                          label: 'Item 1',
                        ),
                        BottomSheetItem(
                          value: 'item2',
                          label: 'Item 2',
                          subtitle: 'Subtitle 2',
                        ),
                        BottomSheetItem(
                          value: 'item3',
                          label: 'Item 3',
                          icon: Icons.star,
                        ),
                      ],
                    );
                  },
                  child: const Text('Show List'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show List'));
      await tester.pumpAndSettle();

      expect(find.text('Select Item'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.text('Subtitle 2'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('showList returns selected value when item tapped',
        (tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await AppBottomSheet.showList<String>(
                      context,
                      title: 'Select',
                      items: [
                        BottomSheetItem(value: 'a', label: 'Option A'),
                        BottomSheetItem(value: 'b', label: 'Option B'),
                      ],
                    );
                  },
                  child: const Text('Show List'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show List'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(result, 'b');
    });

    testWidgets('showList with selectedValue shows checkmark',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showList<int>(
                      context,
                      title: 'Select Number',
                      items: [
                        BottomSheetItem(value: 1, label: 'One'),
                        BottomSheetItem(value: 2, label: 'Two'),
                        BottomSheetItem(value: 3, label: 'Three'),
                      ],
                      selectedValue: 2,
                    );
                  },
                  child: const Text('Show List'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show List'));
      await tester.pumpAndSettle();

      // Should have checkmark on selected item
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('showList with showSearch displays search field',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showList<String>(
                      context,
                      title: 'Search Items',
                      showSearch: true,
                      items: [
                        BottomSheetItem(value: 'apple', label: 'Apple'),
                        BottomSheetItem(value: 'banana', label: 'Banana'),
                        BottomSheetItem(value: 'cherry', label: 'Cherry'),
                      ],
                    );
                  },
                  child: const Text('Show List'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show List'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('showList search filters items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showList<String>(
                      context,
                      title: 'Search',
                      showSearch: true,
                      items: [
                        BottomSheetItem(value: 'apple', label: 'Apple'),
                        BottomSheetItem(value: 'apricot', label: 'Apricot'),
                        BottomSheetItem(value: 'banana', label: 'Banana'),
                      ],
                    );
                  },
                  child: const Text('Show List'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show List'));
      await tester.pumpAndSettle();

      // All items visible initially
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Apricot'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      // Type in search field
      await tester.enterText(find.byType(TextField), 'ap');
      await tester.pumpAndSettle();

      // Only items matching 'ap' should be visible
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Apricot'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('showConfirmation displays confirmation sheet',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showConfirmation(
                      context,
                      title: 'Confirm Action',
                      message: 'Are you sure you want to proceed?',
                    );
                  },
                  child: const Text('Show Confirmation'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Confirmation'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);
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
                    result = await AppBottomSheet.showConfirmation(
                      context,
                      title: 'Confirm',
                      message: 'Proceed?',
                    );
                  },
                  child: const Text('Show Confirmation'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Confirmation'));
      await tester.pumpAndSettle();

      // Tap the FilledButton with 'Confirm' text (not the title)
      final confirmButton = find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Confirm'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('showConfirmation with icon displays icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showConfirmation(
                      context,
                      title: 'Delete',
                      message: 'Delete this item?',
                      icon: Icons.delete,
                    );
                  },
                  child: const Text('Show Confirmation'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Confirmation'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('showForm displays form with submit button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showForm(
                      context,
                      title: 'Add Note',
                      form: const TextField(
                        decoration: InputDecoration(labelText: 'Note'),
                      ),
                      onSubmit: () {},
                    );
                  },
                  child: const Text('Show Form'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Form'));
      await tester.pumpAndSettle();

      expect(find.text('Add Note'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('showForm with custom submit text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showForm(
                      context,
                      title: 'Save',
                      form: const TextField(),
                      onSubmit: () {},
                      submitText: 'Save Changes',
                    );
                  },
                  child: const Text('Show Form'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Form'));
      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('showForm shows loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.showForm(
                      context,
                      title: 'Processing',
                      form: const TextField(),
                      onSubmit: () {},
                      isLoading: true,
                    );
                  },
                  child: const Text('Show Form'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Form'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('BottomSheetItem stores value and label', (tester) async {
      const item = BottomSheetItem<String>(
        value: 'test',
        label: 'Test Label',
        subtitle: 'Test Subtitle',
        icon: Icons.star,
      );

      expect(item.value, 'test');
      expect(item.label, 'Test Label');
      expect(item.subtitle, 'Test Subtitle');
      expect(item.icon, Icons.star);
      expect(item.color, null);
    });

    testWidgets('bottom sheet has handle bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show(
                      context,
                      title: 'Sheet',
                      content: const Text('Content'),
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Look for the handle bar container
      final containers = tester.widgetList<Container>(find.byType(Container));
      final handleBar = containers.firstWhere(
        (container) =>
            container.constraints?.maxWidth == 32 &&
            container.constraints?.maxHeight == 4,
        orElse: () => Container(),
      );

      expect(handleBar.constraints, isNotNull);
    });
  });
}
