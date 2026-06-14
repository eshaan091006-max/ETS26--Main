import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/form_helpers.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/shared/models/department.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/form_link.dart';
import 'package:malhar_ets/utils/app_feedback.dart';

Future<void> showEventModal(
  BuildContext context, {
  Event? event,
  required Function(Event, List<FormLink>) onSubmit,
}) async {
  DepartmentController deptCont = DepartmentController();
  await deptCont.loadDepartments();

  if (deptCont.departments.isEmpty) {
    AppFeedback.showError(context, 'No departments found. Please add a department first.');
    return;
  }

  final nameController = TextEditingController(text: event?.eventName ?? '');
  final marksController = TextEditingController(
    text:
        event?.highestMarks != null && event!.highestMarks != -1
            ? event.highestMarks.toString()
            : '',
  );

  List<Map<String, TextEditingController>> linkControllers = [];

  if (event != null) {
    List<FormLink> existingLinks = FormLinkController().getFormLinksByEventId(event.eventId);
    for (var link in existingLinks) {
      linkControllers.add({
        'label': TextEditingController(text: link.label ?? ''),
        'url': TextEditingController(text: link.link),
      });
    }
    if (existingLinks.isEmpty && event.formLink.isNotEmpty) {
      linkControllers.add({
        'label': TextEditingController(text: 'Main Link'),
        'url': TextEditingController(text: event.formLink),
      });
    }
  } else {
    linkControllers.add({
        'label': TextEditingController(text: 'Main Link'),
        'url': TextEditingController(text: ''),
    });
  }

  Department selectedDepartment =
      deptCont.getDepartmentById(
        event?.departmentId ?? deptCont.departments.first.id,
      ) ??
      deptCont.departments.first;
  DateTime selectedDate = event?.dateTime ?? DateTime.now();
  int eventType = event?.eventType ?? 0;

  final isUpdating = event != null;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isUpdating ? 'Update Event' : 'Add Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTextField(nameController, 'Event Name'),
                  const SizedBox(height: 12),
                  buildTextField(
                    marksController,
                    'Highest Marks (Optional)',
                    inputType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  buildDropdown<Department>(
                    label: 'Department',
                    value: selectedDepartment,
                    items: deptCont.departments,
                    getLabel: (dept) => dept.name,
                    onChanged: (val) {
                      setState(() {
                        selectedDepartment = val ?? deptCont.departments.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date: ${DateFormat('dd MMM yyyy – hh:mm a').format(selectedDate)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            if (time != null) {
                              setState(() {
                                selectedDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Links Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Links', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      ...linkControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        var controllers = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: buildTextField(controllers['label']!, 'Label'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: buildTextField(controllers['url']!, 'URL'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    linkControllers.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        icon: const Icon(Icons.add, color: AppColors.accent),
                        label: const Text('Add Link', style: TextStyle(color: AppColors.accent)),
                        onPressed: () {
                          setState(() {
                            linkControllers.add({
                              'label': TextEditingController(text: ''),
                              'url': TextEditingController(text: ''),
                            });
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  buildDropdown<int>(
                    label: 'Event Type',
                    value: eventType,
                    items: const [0, 1],
                    getLabel: (val) => val == 0 ? 'Classic' : 'Flagship',
                    onChanged: (val) {
                      setState(() {
                        eventType = val!;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    AppFeedback.showError(context, 'Event name is required');
                    return;
                  }

                  final highestMarks =
                      int.tryParse(marksController.text.trim()) ?? -1;

                  List<FormLink> finalLinks = [];
                  for (var c in linkControllers) {
                    if (c['url']!.text.trim().isNotEmpty) {
                      finalLinks.add(FormLink(
                        eventId: event?.eventId ?? 0,
                        label: c['label']!.text.trim(),
                        link: c['url']!.text.trim(),
                        visibleTo: [],
                      ));
                    }
                  }

                  AppFeedback.showLoading(context, message: isUpdating ? 'Updating...' : 'Adding...');
                  final modalContext = context;
                  
                  await onSubmit(
                    Event(
                      eventId: event?.eventId ?? 0,
                      eventName: nameController.text.trim(),
                      highestMarks: highestMarks,
                      dateTime: DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedDate.hour,
                        selectedDate.minute,
                        selectedDate.second,
                      ),
                      formLink: finalLinks.isNotEmpty ? finalLinks.first.link : '',
                      departmentId: selectedDepartment.id,
                      eventType: eventType,
                    ),
                    finalLinks,
                  );

                  if (modalContext.mounted) {
                    AppFeedback.hideLoading(modalContext);
                    Navigator.pop(modalContext);
                  }
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
