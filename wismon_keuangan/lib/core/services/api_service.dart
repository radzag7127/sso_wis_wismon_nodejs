import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/payment/data/models/payment_model.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator (maps to host localhost)
  // Use localhost for web/desktop development
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Singleton HTTP client for connection pooling
  static final http.Client _httpClient = http.Client();

  // Cache for frequently accessed data
  static UserModel? _cachedUser;
  static List<PaymentHistoryItemModel>? _cachedPaymentHistory;
  static PaymentSummaryModel? _cachedPaymentSummary;
  static DateTime? _lastCacheUpdate;

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Store token with optimization
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get stored token with caching
  static String? _cachedToken;
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  // Clear token and cache
  Future<void> clearToken() async {
    _cachedToken = null;
    _cachedUser = null;
    _cachedPaymentHistory = null;
    _cachedPaymentSummary = null;
    _lastCacheUpdate = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Optimized headers with caching
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Check if cache is valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  // Login with error handling optimization
  Future<UserModel> login(String namamNim, String nrm) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final headers = await getHeaders();
    final body = jsonEncode({'namam_nim': namamNim, 'nrm': nrm});

    try {
      final response = await _httpClient
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Cache token and user
        _cachedToken = data['data']['token'];
        await saveToken(_cachedToken!);

        _cachedUser = UserModel.fromJson(data['data']['user']);
        return _cachedUser!;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      }
      rethrow;
    }
  }

  // Get profile with caching
  Future<UserModel> getProfile() async {
    // Return cached user if available and valid
    if (_cachedUser != null && _isCacheValid()) {
      return _cachedUser!;
    }

    final url = Uri.parse('$baseUrl/api/auth/profile');
    final headers = await getHeaders();

    try {
      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _cachedUser = UserModel.fromJson(data['data']);
        _lastCacheUpdate = DateTime.now();
        return _cachedUser!;
      } else {
        throw Exception(data['message'] ?? 'Failed to get profile');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please try again.');
      }
      rethrow;
    }
  }

  // Optimized payment history with caching and pagination
  Future<List<PaymentHistoryItemModel>> getPaymentHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? type,
    String sortBy = 'tanggal',
    String sortOrder = 'desc',
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and no filters applied
    if (!forceRefresh &&
        page == 1 &&
        startDate == null &&
        endDate == null &&
        type == null &&
        _cachedPaymentHistory != null &&
        _isCacheValid()) {
      return _cachedPaymentHistory!;
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (type != null) queryParams['type'] = type;

    final uri = Uri.parse(
      '$baseUrl/api/payments/history',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await getHeaders();
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      // Minimal logging - only errors in production
      if (response.statusCode != 200) {
        log('Payment History API Error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final List<dynamic> historyData = data['data']['data'];
        final historyItems = historyData
            .map((item) => PaymentHistoryItemModel.fromJson(item))
            .toList();

        // Cache only if it's the first page with no filters
        if (page == 1 && startDate == null && endDate == null && type == null) {
          _cachedPaymentHistory = historyItems;
          _lastCacheUpdate = DateTime.now();
        }

        return historyItems;
      } else {
        throw Exception(data['message'] ?? 'Failed to get payment history');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please try again.');
      }
      rethrow;
    }
  }

  // Get payment summary with caching
  Future<PaymentSummaryModel> getPaymentSummary({
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and valid
    if (!forceRefresh && _cachedPaymentSummary != null && _isCacheValid()) {
      return _cachedPaymentSummary!;
    }

    final url = Uri.parse('$baseUrl/api/payments/summary');

    try {
      final headers = await getHeaders();
      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _cachedPaymentSummary = PaymentSummaryModel.fromJson(data['data']);
        _lastCacheUpdate = DateTime.now();
        return _cachedPaymentSummary!;
      } else {
        throw Exception(data['message'] ?? 'Failed to get payment summary');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please try again.');
      }
      rethrow;
    }
  }

  // Get transaction detail (no caching as it's specific)
  Future<TransactionDetailModel> getTransactionDetail(
    String transactionId,
  ) async {
    final url = Uri.parse('$baseUrl/api/payments/detail/$transactionId');

    try {
      final headers = await getHeaders();
      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return TransactionDetailModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to get transaction detail');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please try again.');
      }
      rethrow;
    }
  }

  // Refresh payment data with cache invalidation
  Future<bool> refreshPaymentData() async {
    // Clear cache to force refresh
    _cachedPaymentHistory = null;
    _cachedPaymentSummary = null;
    _lastCacheUpdate = null;

    final url = Uri.parse('$baseUrl/api/payments/refresh');

    try {
      final headers = await getHeaders();
      final response = await _httpClient
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data']['refreshed'] ?? false;
      } else {
        throw Exception(data['message'] ?? 'Failed to refresh payment data');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please try again.');
      }
      rethrow;
    }
  }

  // Dispose method for cleanup
  static void dispose() {
    _httpClient.close();
  }
}
