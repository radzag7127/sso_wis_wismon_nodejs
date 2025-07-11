import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/payment/data/models/payment_model.dart';

class ApiService {
  // API Base URL
  // For Chrome/Web development: http://localhost:3000
  // For Android emulator: http://10.0.2.2:3000
  // For iOS simulator: http://localhost:3000
  static const String baseUrl = 'http://localhost:3000';
  static http.Client? _client;
  static final Map<String, dynamic> _cache = {};
  static const int _cacheTimeout = 5 * 60 * 1000; // 5 minutes

  // Regular constructor for DI, but still use singleton pattern for client
  ApiService() {
    _initializeClient();
  }

  void _initializeClient() {
    _client ??= http.Client();
  }

  // Cache management for better performance
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final cachedData = _cache[key];
    final timestamp = cachedData['timestamp'] as int;
    return DateTime.now().millisecondsSinceEpoch - timestamp < _cacheTimeout;
  }

  void _setCache(String key, dynamic data) {
    _cache[key] = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  dynamic _getCache(String key) {
    if (_isCacheValid(key)) {
      return _cache[key]['data'];
    }
    return null;
  }

  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  Future<void> setAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      // Handle storage error gracefully
    }
  }

  Future<void> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      // Handle error gracefully
    }
  }

  Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Generic GET method
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool useCache = false,
  }) async {
    final cacheKey = 'GET_$endpoint';

    // Check cache first if enabled
    if (useCache) {
      final cachedData = _getCache(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    try {
      final token = await getAuthToken();
      final response = await _client!
          .get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);

      // Cache successful responses
      if (useCache && response.statusCode == 200) {
        _setCache(cacheKey, data);
      }

      return data;
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on HttpException {
      throw Exception('Gagal terhubung ke server');
    } on FormatException {
      throw Exception('Respons server tidak valid');
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // Generic POST method
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await getAuthToken();
      final response = await _client!
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on HttpException {
      throw Exception('Gagal terhubung ke server');
    } on FormatException {
      throw Exception('Respons server tidak valid');
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // AUTH METHODS
  Future<UserModel> login(String namamNim, String nrm) async {
    final data = await post('/api/auth/login', {
      'namam_nim': namamNim,
      'nrm': nrm,
    });

    if (data['success']) {
      await setAuthToken(data['data']['token']);
      return UserModel.fromJson(data['data']['user']);
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  Future<UserModel> getProfile() async {
    final data = await get('/api/auth/profile', useCache: true);

    if (data['success']) {
      return UserModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to get profile');
    }
  }

  // PAYMENT METHODS
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
      final token = await getAuthToken();
      final response = await _client!
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);

      if (data['success']) {
        final List<dynamic> historyData = data['data']['data'];
        return historyData
            .map((item) => PaymentHistoryItemModel.fromJson(item))
            .toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to get payment history');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on HttpException {
      throw Exception('Gagal terhubung ke server');
    } on FormatException {
      throw Exception('Respons server tidak valid');
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<PaymentSummaryModel> getPaymentSummary({
    bool forceRefresh = false,
  }) async {
    final data = await get('/api/payments/summary', useCache: !forceRefresh);

    if (data['success']) {
      return PaymentSummaryModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to get payment summary');
    }
  }

  Future<TransactionDetailModel> getTransactionDetail(
    String transactionId,
  ) async {
    final data = await get('/api/payments/detail/$transactionId');

    if (data['success']) {
      return TransactionDetailModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to get transaction detail');
    }
  }

  Future<bool> refreshPaymentData() async {
    final data = await post('/api/payments/refresh', {});

    if (data['success']) {
      // Clear payment-related cache
      _cache.removeWhere((key, value) => key.contains('payment'));
      return data['data']['refreshed'] ?? false;
    } else {
      throw Exception(data['message'] ?? 'Failed to refresh payment data');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    switch (response.statusCode) {
      case 200:
      case 201:
        return responseData;
      case 400:
        throw Exception(responseData['message'] ?? 'Permintaan tidak valid');
      case 401:
        throw Exception('Sesi telah berakhir, silakan login kembali');
      case 403:
        throw Exception('Akses ditolak');
      case 404:
        throw Exception('Data tidak ditemukan');
      case 500:
        throw Exception('Terjadi kesalahan pada server');
      default:
        throw Exception('Terjadi kesalahan tidak terduga');
    }
  }

  // Clean up resources
  static void dispose() {
    _client?.close();
    _client = null;
    _cache.clear();
  }

  // Clear cache when needed
  static void clearCache() {
    _cache.clear();
  }

  // Clear expired cache entries
  static void cleanExpiredCache() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _cache.removeWhere((key, value) {
      final timestamp = value['timestamp'] as int;
      return now - timestamp >= _cacheTimeout;
    });
  }
}
