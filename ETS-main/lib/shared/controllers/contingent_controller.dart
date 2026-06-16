// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContingentController {
  static final SupabaseClient _client = Supabase.instance.client;

  // Singleton instance
  static final ContingentController _instance =
      ContingentController._internal();

  RealtimeChannel? _contingentChannel;
  factory ContingentController() {
    return _instance;
  }

  ContingentController._internal();

  final List<Contingent> _contingents = [];

  List<Contingent> get contingents => _contingents;

  Future<void> loadContingents() async {
    try {
      final List<dynamic> response = await _client.rpc('get_contingent_list_rpc');
      _contingents.clear();
      _contingents.addAll(
        response.map((json) => Contingent.fromJson(Map<String, dynamic>.from(json))).toList(),
      );
    } catch (e) {
      print("Error loading contingents: $e");
    } finally {
      PageRefreshController.triggerRefresh();
    }
  }

  void subscribeToContingents(GlobalKey<NavigatorState> key) {
    Timer? debounceTimer;
    _contingentChannel = _client.channel('public:contingents');

    _contingentChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'contingents',
          callback: (payload) {
            debounceTimer?.cancel();

            // Start new debounce timer
            debounceTimer = Timer(const Duration(seconds: 2), () async {
              print('Contingent Table Updated!');
              await loadContingents();
            });
          },
        )
        .subscribe();
  }

  void printAll() {
    for (Contingent contingent in _contingents) {
      print(
        "${contingent.contingentId} ${contingent.contingentCode} ${contingent.password}",
      );
    }
  }

  Future<ContingentController> initializeContingents() async {
    await loadContingents();
    return this;
  }

  Contingent? getContingentById(int id) {
    try {
      return _contingents.firstWhere((c) => c.contingentId == id);
    } catch (e) {
      return null;
    }
  }

  // 🔹 CREATE
  Future<bool> createContingent(
    BuildContext context,
    Contingent contingent,
  ) async {
    try {
      await loadContingents();
      int nextId = 1;
      if (_contingents.isNotEmpty) {
        nextId = _contingents.map((c) => c.contingentId).reduce((a, b) => a > b ? a : b) + 1;
      }
      contingent.contingentId = nextId;

      final response =
          await _client
              .from('contingents')
              .insert(contingent.toInsertJson())
              .select();

      print(response);

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(context, "Contingent created successfully.");
        await loadContingents();
        return true;
      } else {
        AppFeedback.showError(context, "Failed to create contingent.");
        return false;
      }
    } catch (e) {
      AppFeedback.showError(context, "Error creating contingent: $e");
      return false;
    }
  }

  // 🔹 UPDATE
  Future<bool> updateContingent(
    BuildContext context,
    Contingent contingent,
  ) async {
    try {
      final response =
          await _client
              .from('contingents')
              .update(contingent.toJson())
              .eq('contingent_id', contingent.contingentId)
              .select();

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(context, "Contingent updated successfully.");
        await loadContingents();
        return true;
      } else {
        AppFeedback.showError(context, "Failed to update contingent.");
        return false;
      }
    } catch (e) {
      AppFeedback.showError(context, "Error updating contingent: $e");
      return false;
    }
  }

  // 🔹 DELETE
  Future<bool> deleteContingent(BuildContext context, int contingentId) async {
    try {
      final response =
          await _client
              .from('contingents')
              .delete()
              .eq('contingent_id', contingentId)
              .select();

      if (response.isNotEmpty) {
        AppFeedback.showSuccess(context, "Contingent deleted successfully.");
        await loadContingents();
        return true;
      } else {
        AppFeedback.showError(context, "Failed to delete contingent.");
        return false;
      }
    } catch (e) {
      AppFeedback.showError(context, "Error deleting contingent: $e");
      return false;
    }
  }
}
