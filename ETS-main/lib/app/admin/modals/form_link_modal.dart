import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/form_helpers.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/shared/models/form_link.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';

Future<void> showFormLinkModal(
  BuildContext context, {
  required int eventId,
  FormLink? formLink,
  required Function(FormLink) onSubmit,
}) async {
  final labelController = TextEditingController(text: formLink?.label ?? '');
  final linkController = TextEditingController(text: formLink?.link ?? '');

  final isUpdating = formLink != null;

  final contingentController = ContingentController();
  await contingentController.loadContingents();

  List<Contingent> allContingents = contingentController.contingents;

  // Selected contingent IDs (visibleTo)
  Set<int> selectedContingents = {if (formLink != null) ...formLink.visibleTo};

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isUpdating ? 'Update Form Link' : 'Add Form Link'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTextField(labelController, 'Form Label'),
                  const SizedBox(height: 12),
                  buildTextField(linkController, 'Form URL'),
                  const SizedBox(height: 12),

                  /// Contingent Checkboxes
                  /// Contingent Checkboxes Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Visible To:',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Select All / Deselect All
                  CheckboxListTile(
                    dense: true,
                    title: Text(
                      selectedContingents.length == allContingents.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: selectedContingents.length == allContingents.length,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedContingents =
                              allContingents
                                  .map((c) => c.contingentId)
                                  .toSet(); // Select all
                        } else {
                          selectedContingents.clear(); // Deselect all
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Individual Contingent Checkboxes
                  ...allContingents.map((contingent) {
                    final isChecked = selectedContingents.contains(
                      contingent.contingentId,
                    );
                    return CheckboxListTile(
                      dense: true,
                      title: Text(
                        contingent.contingentCode,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: isChecked,
                      onChanged: (bool? val) {
                        setState(() {
                          if (val == true) {
                            selectedContingents.add(contingent.contingentId);
                          } else {
                            selectedContingents.remove(contingent.contingentId);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),

                  const SizedBox(height: 6),
                  ...allContingents.map((contingent) {
                    final isChecked = selectedContingents.contains(
                      contingent.contingentId,
                    );
                    return CheckboxListTile(
                      dense: true,
                      title: Text(
                        contingent.contingentCode,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: isChecked,
                      onChanged: (bool? val) {
                        setState(() {
                          if (val == true) {
                            selectedContingents.add(contingent.contingentId);
                          } else {
                            selectedContingents.remove(contingent.contingentId);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (labelController.text.trim().isEmpty ||
                      linkController.text.trim().isEmpty) {
                    AppFeedback.showError(
                      context,
                      'Label and URL are required',
                    );
                    return;
                  }

                  onSubmit(
                    FormLink(
                      id: formLink?.id ?? -1,
                      eventId: eventId,
                      label: labelController.text.trim(),
                      link: linkController.text.trim(),
                      visibleTo: selectedContingents.toList(),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text(isUpdating ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      );
    },
  );
}
