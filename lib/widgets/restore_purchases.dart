import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/providers/entitlements.dart';

class RestorePurchases extends ConsumerWidget {
  const RestorePurchases({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final notifier = ref.read(entitlementsProvider.notifier);
        final messenger = ScaffoldMessenger.of(context);
        await notifier.refresh();
        final isPremium = ref.read(entitlementsProvider.notifier).isPremium;
        messenger.showSnackBar(
          SnackBar(content: Text(isPremium ? 'Restored: premium active' : 'No active subscription found')),
        );
      },
      child: const Text('Restore purchases / Already subscribed? Sign in'),
    );
  }
}
