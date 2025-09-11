import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPreferencesService {
  // Stream controller for broadcasting dashboard preference changes
  static final StreamController<DashboardChangeEvent> _changeController = 
      StreamController<DashboardChangeEvent>.broadcast();
  
  /// Stream that emits events when dashboard preferences change
  static Stream<DashboardChangeEvent> get changeStream => _changeController.stream;
  static const String _dashboardTypesKey = 'dashboard_payment_types';
  static const String _hasCustomizedKey = 'dashboard_has_customized';

  // Default payment types - easily configurable
  static const List<String> defaultPaymentTypes = [
    'SPP',
    'SWP',
    'Pendaftaran Mahasiswa Baru',
    'Praktek Rumah Sakit',
    'Seragam',
    'Wisuda',
    'KTI dan Wisuda',
  ];

  /// Get user's selected payment types for dashboard
  /// Returns default types if not customized yet
  Future<List<String>> getSelectedPaymentTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCustomized = prefs.getBool(_hasCustomizedKey) ?? false;

      if (!hasCustomized) {
        // Return default types for new users
        return List<String>.from(defaultPaymentTypes);
      }

      final selectedTypes = prefs.getStringList(_dashboardTypesKey);
      return selectedTypes ?? List<String>.from(defaultPaymentTypes);
    } catch (e) {
      // Fallback to defaults on error
      return List<String>.from(defaultPaymentTypes);
    }
  }

  /// Save user's selected payment types for dashboard
  Future<bool> saveSelectedPaymentTypes(List<String> paymentTypes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_dashboardTypesKey, paymentTypes);
      await prefs.setBool(_hasCustomizedKey, true);
      
      // Notify all listeners about the dashboard change
      _changeController.add(DashboardChangeEvent(
        changeType: DashboardChangeType.paymentTypesUpdated,
        newPaymentTypes: paymentTypes,
        timestamp: DateTime.now(),
      ));
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has customized their dashboard
  Future<bool> hasUserCustomized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasCustomizedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Reset to default settings
  Future<bool> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dashboardTypesKey);
      await prefs.setBool(_hasCustomizedKey, false);
      
      // Notify about reset to defaults
      _changeController.add(DashboardChangeEvent(
        changeType: DashboardChangeType.resetToDefault,
        newPaymentTypes: defaultPaymentTypes,
        timestamp: DateTime.now(),
      ));
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Clean up resources when app terminates
  static void dispose() {
    _changeController.close();
  }
}

/// Event types for dashboard changes
enum DashboardChangeType {
  paymentTypesUpdated,
  resetToDefault,
}

/// Event fired when dashboard preferences change
class DashboardChangeEvent {
  final DashboardChangeType changeType;
  final List<String> newPaymentTypes;
  final DateTime timestamp;
  
  const DashboardChangeEvent({
    required this.changeType,
    required this.newPaymentTypes,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'DashboardChangeEvent{type: $changeType, paymentTypes: $newPaymentTypes, time: $timestamp}';
  }
}
