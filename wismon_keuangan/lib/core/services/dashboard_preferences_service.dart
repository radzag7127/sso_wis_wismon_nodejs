import 'package:shared_preferences/shared_preferences.dart';

class DashboardPreferencesService {
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
      return true;
    } catch (e) {
      return false;
    }
  }
}
