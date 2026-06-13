import 'package:flutter/material.dart';

Future<void> confirmDeletionModal(
  BuildContext context,
  String label, {
  required VoidCallback onSubmit,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder:
            (context, setState) => AlertDialog(
              title: Text("Confirm Delete"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('1. Make Sure You have Chosen the right $label.'),
                  const SizedBox(height: 12),
                  Text(
                    '2. Make Sure You have deleted all the Participations connected with this $label.',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onSubmit();
                  },
                  child: Text('Delete'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
      );
    },
  );
}
