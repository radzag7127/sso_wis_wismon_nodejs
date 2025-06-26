import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/payment.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  // Store token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Clear token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with token
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    final headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Login
  Future<User> login(String namamNim, String nrm) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final headers = await getHeaders();
    final body = jsonEncode({'namam_nim': namamNim, 'nrm': nrm});

    final response = await http.post(url, headers: headers, body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      // Save token
      await saveToken(data['data']['token']);
      return User.fromJson(data['data']['user']);
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  // Get profile
  Future<User> getProfile() async {
    final url = Uri.parse('$baseUrl/api/auth/profile');
    final headers = await getHeaders();

    final response = await http.get(url, headers: headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return User.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to get profile');
    }
  }

  // Get payment history
  Future<List<PaymentHistoryItem>> getPaymentHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? type,
    String sortBy = 'tanggal',
    String sortOrder = 'desc',
  }) async {
    final queryParams = {
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

    final headers = await getHeaders();
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      final List<dynamic> historyData = data['data']['data'];
      return historyData
          .map((item) => PaymentHistoryItem.fromJson(item))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to get payment history');
    }
  }

  // Get payment summary
  Future<PaymentSummary> getPaymentSummary() async {
    final url = Uri.parse('$baseUrl/api/payments/summary');
    final headers = await getHeaders();

    final response = await http.get(url, headers: headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return PaymentSummary.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to get payment summary');
    }
  }

  // Get transaction detail
  Future<TransactionDetail> getTransactionDetail(String transactionId) async {
    final url = Uri.parse('$baseUrl/api/payments/detail/$transactionId');
    final headers = await getHeaders();

    final response = await http.get(url, headers: headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return TransactionDetail.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to get transaction detail');
    }
  }

  // Refresh payment data
  Future<bool> refreshPaymentData() async {
    final url = Uri.parse('$baseUrl/api/payments/refresh');
    final headers = await getHeaders();

    final response = await http.post(url, headers: headers);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return data['data']['refreshed'] ?? false;
    } else {
      throw Exception(data['message'] ?? 'Failed to refresh payment data');
    }
  }
}
