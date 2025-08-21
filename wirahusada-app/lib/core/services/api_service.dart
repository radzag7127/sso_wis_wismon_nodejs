import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/payment/data/models/payment_model.dart';

// Import Transkrip, KRS, KHS
import '../../features/transkrip/data/models/transkrip_model.dart';
import '../../features/krs/data/models/krs_model.dart';
import '../../features/khs/data/models/khs_model.dart';
import 'package:flutter/foundation.dart';

// --- PERUBAHAN: Import entitas Course agar bisa digunakan di fungsi baru ---
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';

// Import performance utilities for async JSON decoding
import '../utils/performance_utils.dart';

// Custom exception for token expiration
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);

  @override
  String toString() => 'TokenExpiredException: $message';
}

class ApiService {
  // Platform-specific API Base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Chrome/Web development
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Android emulator
    } else {
      return 'http://localhost:3000'; // iOS simulator
    }
  }
  static http.Client? _client;
  static final Map<String, dynamic> _cache = {};
  static const int _cacheTimeout = 5 * 60 * 1000; // 5 min

  // Token refresh management
  static bool _isRefreshing = false;
  static final List<Function()> _refreshQueue = [];

  // Smart logging configuration
  static const bool _enableVerboseLogging =
      false; // Feature flag for verbose logs
  static const int _maxLogBodyLength = 500; // Truncate large responses

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

  // Smart response logging method
  void _logResponse(http.Response response) {
    if (!kDebugMode) return;

    if (_enableVerboseLogging) {
      // Verbose logging for debugging
      final body = response.body;
      print('--- 📬 [API Response] ${response.statusCode} ---');
      if (body.length > _maxLogBodyLength) {
        print(
          'Body: ${body.substring(0, _maxLogBodyLength)}... (${body.length} chars total)',
        );
      } else {
        print('Body: $body');
      }
      print('---');
    } else {
      // Minimal logging by default - only log errors and important status
      if (response.statusCode >= 400) {
        print('❌ API ${response.statusCode}: ${response.request?.url.path}');
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ API ${response.statusCode}: ${response.request?.url.path}');
      }
    }
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
      await prefs.remove('refresh_token');
      await prefs.remove('token_expiry');
    } catch (e) {
      // Handle error gracefully
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    } catch (e) {
      return null;
    }
  }

  Future<void> setRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', token);
    } catch (e) {
      // Handle storage error gracefully
    }
  }

  Future<void> setTokenExpiry(int expiryTimeStamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('token_expiry', expiryTimeStamp);
    } catch (e) {
      // Handle storage error gracefully
    }
  }

  Future<int?> getTokenExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('token_expiry');
    } catch (e) {
      return null;
    }
  }

  Future<bool> isTokenExpiringSoon() async {
    try {
      final expiry = await getTokenExpiry();
      if (expiry == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Consider token expiring soon if less than 2 minutes remaining
      const buffer = 120; // 2 minutes in seconds

      return (expiry - now) <= buffer;
    } catch (e) {
      return true; // Assume expired on error
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
      final data = await _makeRequestWithRetry(() async {
        final token = await getAuthToken();
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = _getHeaders(token);

        // Smart logging - minimal by default, verbose only when needed
        if (kDebugMode && _enableVerboseLogging) {
          print('--- 🚀 [API Request] ${url.path} ---');
          print('Headers: $headers');
        }

        return await _client!
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 30));
      });

      // Cache successful responses
      if (useCache) {
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
      // Minimal error logging
      if (kDebugMode) {
        print('❌ API Error: $endpoint - ${e.toString()}');
      }
      throw Exception(
        'Terjadi kesalahan: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
  }

  // Generic POST method
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _makeRequestWithRetry(() async {
        final token = await getAuthToken();
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = _getHeaders(token);
        final body = jsonEncode(data);

        if (kDebugMode) {
          print('--- 📤 [API POST Request] 📤 ---');
          print('URL: $url');
          print('Headers: $headers');
          print('Body: $body');
        }

        return await _client!
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
      });
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on HttpException {
      throw Exception('Gagal terhubung ke server');
    } on FormatException {
      throw Exception('Respons server tidak valid');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [API POST Error]: $e');
      }
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // AUTH METHODS
  Future<UserModel> login(String namamNim, String nrm) async {
    try {
      final data = await post('/api/auth/login', {
        'namam_nim': namamNim,
        'nrm': nrm,
      });

      if (kDebugMode) {
        print('--- 🔐 [LOGIN RESPONSE] 🔐 ---');
        print('Success: ${data['success']}');
        print('Data keys: ${data['data']?.keys.toList()}');
        print('AccessToken present: ${data['data']?['accessToken'] != null}');
        print('User data: ${data['data']?['user']}');
        print('-------------------------');
      }

      if (data['success']) {
        final accessToken = data['data']['accessToken'];
        if (accessToken != null) {
          await setAuthToken(accessToken);

          // Also store refresh token if available
          final refreshToken = data['data']['refreshToken'];
          if (refreshToken != null) {
            await setRefreshToken(refreshToken);
          }

          // Store token expiry if available (backend should provide expiresIn in seconds)
          // Handle both String and int types from backend
          final expiresInRaw = data['data']['expiresIn'];
          int? expiresIn;

          if (expiresInRaw != null) {
            if (expiresInRaw is int) {
              expiresIn = expiresInRaw;
            } else if (expiresInRaw is String) {
              expiresIn = int.tryParse(expiresInRaw);
            }
          }

          if (expiresIn != null) {
            final expiryTime =
                (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresIn;
            await setTokenExpiry(expiryTime);
            if (kDebugMode) {
              print(
                '✅ Token expiry set for: ${DateTime.fromMillisecondsSinceEpoch(expiryTime * 1000)} (expiresIn: $expiresIn seconds)',
              );
            }
          } else {
            // Default to 15 minutes if not provided (backend default)
            final expiryTime =
                (DateTime.now().millisecondsSinceEpoch ~/ 1000) + (15 * 60);
            await setTokenExpiry(expiryTime);
            if (kDebugMode) {
              print(
                '⚠️ Using default 15min expiry: ${DateTime.fromMillisecondsSinceEpoch(expiryTime * 1000)} (expiresIn was: $expiresInRaw)',
              );
            }
          }

          if (kDebugMode) {
            print('✅ Tokens and expiry saved successfully');
          }
        } else {
          if (kDebugMode) {
            print('❌ No accessToken found in response');
          }
          throw Exception('No access token received from server');
        }

        return UserModel.fromJson(data['data']['user']);
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
      rethrow;
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

      final data = await _handleResponse(response);

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

  Future<List<PaymentTypeModel>> getPaymentTypes({
    bool forceRefresh = false,
  }) async {
    final data = await get('/api/payments/types', useCache: !forceRefresh);

    if (data['success']) {
      final List<dynamic> typesData = data['data'];
      return typesData.map((item) => PaymentTypeModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to get payment types');
    }
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    // Use performance-optimized JSON decoding for large responses
    final responseData = await PerformanceUtils.decodeJsonAsync(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return responseData;
      case 400:
        throw Exception(responseData['message'] ?? 'Permintaan tidak valid');
      case 401:
        // Check error type for more specific handling
        final errorType = responseData['errorType'] ?? 'token_expired';
        final message = responseData['message'] ?? 'Authentication failed';
        
        if (kDebugMode) {
          print('🔒 Auth error type: $errorType, message: $message');
        }
        
        // Don't immediately throw - let the caller handle token refresh
        throw TokenExpiredException(message);
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

  // Refresh token method
  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh to complete
      await _waitForRefresh();
      return true;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        if (kDebugMode) {
          print('❌ No refresh token available');
        }
        return false;
      }

      final url = Uri.parse('$baseUrl/api/auth/refresh');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Send refresh token in request body for mobile apps
      final body = jsonEncode({
        'refreshToken': refreshToken,
      });

      if (kDebugMode) {
        print('🔄 Attempting token refresh...');
      }

      final response = await _client!
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = await PerformanceUtils.decodeJsonAsync(response.body);
        if (data['success'] == true) {
          final newAccessToken = data['data']['accessToken'];
          final newRefreshToken = data['data']['refreshToken'];

          if (newAccessToken != null) {
            await setAuthToken(newAccessToken);
            
            // Always update refresh token if provided by backend
            if (newRefreshToken != null) {
              await setRefreshToken(newRefreshToken);
              if (kDebugMode) {
                print('✅ New refresh token stored');
              }
            } else if (kDebugMode) {
              print('⚠️ No new refresh token provided by backend');
            }

            // Update token expiry
            // Handle both String and int types from backend
            final expiresInRaw = data['data']['expiresIn'];
            int? expiresIn;

            if (expiresInRaw != null) {
              if (expiresInRaw is int) {
                expiresIn = expiresInRaw;
              } else if (expiresInRaw is String) {
                expiresIn = int.tryParse(expiresInRaw);
              }
            }

            if (expiresIn != null) {
              final expiryTime =
                  (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresIn;
              await setTokenExpiry(expiryTime);
            } else {
              // Default to 15 minutes if not provided
              final expiryTime =
                  (DateTime.now().millisecondsSinceEpoch ~/ 1000) + (15 * 60);
              await setTokenExpiry(expiryTime);
            }

            if (kDebugMode) {
              print('✅ Token refresh successful');
            }

            // Process queued requests
            _processRefreshQueue();
            return true;
          }
        }
      }

      if (kDebugMode) {
        print('❌ Token refresh failed: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token refresh error: $e');
      }
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _waitForRefresh() async {
    while (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _processRefreshQueue() {
    for (final callback in _refreshQueue) {
      callback();
    }
    _refreshQueue.clear();
  }

  // Enhanced request methods with automatic token refresh
  Future<Map<String, dynamic>> _makeRequestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      return await _handleResponse(response);
    } on TokenExpiredException {
      if (kDebugMode) {
        print('🔄 Token expired, attempting refresh...');
      }

      final refreshSuccess = await refreshToken();
      if (refreshSuccess) {
        // Retry the original request with new token
        final response = await request();
        return await _handleResponse(response);
      } else {
        // Refresh failed, user needs to login again
        throw Exception('Sesi telah berakhir, silakan login kembali');
      }
    }
  }

  // --- AKADEMIK METHODS ---
  Future<KrsModel> getKrs(int semesterKe, int jenisSemester) async {
    // PERBAIKAN: Tambahkan parameter jenisSemester ke endpoint
    final data = await get(
      '/api/akademik/mahasiswa/krs?semesterKe=$semesterKe&jenisSemester=$jenisSemester',
    );
    if (data['success'] == true) {
      return KrsModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data KRS');
    }
  }

  Future<KhsModel> getKhs(int semesterKe, int jenisSemester) async {
    // PERBAIKAN: Tambahkan parameter jenisSemester ke endpoint
    final data = await get(
      '/api/akademik/mahasiswa/khs?semesterKe=$semesterKe&jenisSemester=$jenisSemester',
    );
    if (data['success'] == true) {
      return KhsModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data KHS');
    }
  }

  Future<TranskripModel> getTranskrip() async {
    final data = await get('/api/akademik/mahasiswa/transkrip');
    if (data['success'] == true) {
      return TranskripModel.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Gagal mengambil data transkrip');
    }
  }

  // --- FUNGSI BARU: Untuk mengirim permintaan usulan penghapusan ke backend ---
  // Fungsi ini akan dipanggil oleh Repository.
  Future<bool> proposeCourseDeletion(Course courseToUpdate) async {
    // Logika untuk membalik status boolean. Jika saat ini true, akan menjadi false, dan sebaliknya.
    final newStatus = !courseToUpdate.usulanHapus;

    final response = await post(
      '/api/akademik/mahasiswa/transkrip/usul-hapus',
      {
        // Data ini dikirim sebagai body request ke backend
        'kodeMataKuliah': courseToUpdate.kodeMataKuliah,
        'kurikulum': courseToUpdate.kurikulum,
        'semesterKe': courseToUpdate.semesterKe,
        'newStatus': newStatus,
      },
    );

    if (response['success'] == true) {
      return true; // Mengembalikan true jika API merespon sukses
    } else {
      // Melempar error jika API gagal
      throw Exception(response['message'] ?? 'Gagal memperbarui status usulan');
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
