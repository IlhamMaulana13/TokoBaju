import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AdminService {
  static const String baseUrl = 'https://tokobaju-ibu-ida.vercel.app';

  // Helper untuk mengambil Firebase ID Token dari user yang sedang login
  Future<String?> getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Tidak ada user yang sedang login');
        return null;
      }
      final token = await user.getIdToken();
      return token;
    } catch (e) {
      debugPrint('❌ Gagal mengambil Firebase Token: $e');
      return null;
    }
  }

  // Helper untuk membuat headers dengan Authorization
  Future<Map<String, String>> _buildHeaders() async {
    final token = await getFirebaseToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // ============================================================
  // PRODUCT ENDPOINTS
  // ============================================================

  /// GET /api/admin/products — Mengambil semua produk
  Future<List<dynamic>> fetchProducts() async {
    final headers = await _buildHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint('✅ fetchProducts berhasil: ${body['products']?.length} produk');
        return body['products'] as List<dynamic>;
      } else {
        debugPrint('❌ fetchProducts gagal: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal mengambil produk: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ fetchProducts error: $e');
      rethrow;
    }
  }

  /// POST /api/admin/products — Membuat produk baru
  ///
  /// [data] harus mengandung:
  /// - `name` (String, wajib)
  /// - `price` (double, wajib)
  /// - `stock` (int, wajib)
  /// - `description` (String, opsional)
  /// - `image_url` (String, opsional - URL dari Firebase Storage)
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final headers = await _buildHeaders();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/products'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        debugPrint('✅ createProduct berhasil: ${body['product']}');
        return body['product'] as Map<String, dynamic>;
      } else {
        debugPrint('❌ createProduct gagal: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal membuat produk: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ createProduct error: $e');
      rethrow;
    }
  }

  /// PUT /api/admin/products/:id — Memperbarui produk berdasarkan ID
  ///
  /// [data] harus mengandung:
  /// - `name` (String, wajib)
  /// - `price` (double, wajib)
  /// - `stock` (int, wajib)
  /// - `description` (String, opsional)
  /// - `image_url` (String, opsional - URL dari Firebase Storage)
  Future<Map<String, dynamic>> updateProduct(int productId, Map<String, dynamic> data) async {
    final headers = await _buildHeaders();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/products/$productId'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint('✅ updateProduct berhasil: ${body['product']}');
        return body['product'] as Map<String, dynamic>;
      } else {
        debugPrint('❌ updateProduct gagal: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal memperbarui produk: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ updateProduct error: $e');
      rethrow;
    }
  }

  /// DELETE /api/admin/products/:id — Menghapus produk berdasarkan ID
  Future<void> deleteProduct(int productId) async {
    final headers = await _buildHeaders();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/products/$productId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ deleteProduct berhasil: produk ID $productId dihapus');
      } else {
        debugPrint('❌ deleteProduct gagal: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal menghapus produk: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ deleteProduct error: $e');
      rethrow;
    }
  }

  // ============================================================
  // ORDER ENDPOINTS
  // ============================================================

  /// GET /api/admin/orders — Mengambil semua pesanan (urut dari terbaru)
  /// Response sudah include relasi User dan OrderItems.Product
  Future<List<dynamic>> fetchOrders() async {
    final headers = await _buildHeaders();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint('✅ fetchOrders berhasil: ${body['orders']?.length} order');
        return body['orders'] as List<dynamic>;
      } else {
        debugPrint('❌ fetchOrders gagal: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal mengambil orders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ fetchOrders error: $e');
      rethrow;
    }
  }

  /// PUT /api/admin/orders/:id/status — Memperbarui status pesanan
  ///
  /// [newStatus] harus salah satu dari: 'Pending', 'Packing', 'Shipped', 'Delivered'
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String newStatus, {String? proofOfDelivery}) async {
    final headers = await _buildHeaders();
    try {
      final bodyData = {'status': newStatus};
      if (proofOfDelivery != null) {
        bodyData['proof_of_delivery'] = proofOfDelivery;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/orders/$orderId/status'),
        headers: headers,
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint('✅ updateOrderStatus berhasil: order $orderId -> $newStatus');
        return body['order'] as Map<String, dynamic>;
      } else {
        debugPrint('❌ updateOrderStatus gagal: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal memperbarui status order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ updateOrderStatus error: $e');
      rethrow;
    }
  }

  // ============================================================
  // IMGBB IMAGE UPLOAD
  // ============================================================

  /// Mengunggah berkas gambar ke ImgBB dan mengembalikan URL publik gambarnya.
  Future<String> uploadImageToImgBB(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=2a90f301933df8f150375997315228ed');
      final request = http.MultipartRequest('POST', uri);

      // Tambahkan berkas gambar ke multipart request
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      );
      request.files.add(multipartFile);

      debugPrint('📡 Mengirim gambar ke ImgBB...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final String imageUrl = body['data']['url'];
        debugPrint('✅ Unggah gambar berhasil: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Unggah gambar gagal: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal mengunggah gambar: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error saat mengunggah ke ImgBB: $e');
      rethrow;
    }
  }

  // ============================================================
  // SALES REPORT ENDPOINT
  // ============================================================

  /// GET /api/admin/reports — Mengambil laporan penjualan berdasarkan rentang tanggal
  Future<Map<String, dynamic>> getSalesReport(DateTime startDate, DateTime endDate) async {
    final headers = await _buildHeaders();
    final formatter = DateFormat('yyyy-MM-dd');
    final startStr = formatter.format(startDate);
    final endStr = formatter.format(endDate);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/reports?start_date=$startStr&end_date=$endStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint('✅ getSalesReport berhasil: ${body['total_orders']} order');
        return body as Map<String, dynamic>;
      } else {
        debugPrint('❌ getSalesReport gagal: ${response.statusCode} - ${response.body}');
        throw Exception('Gagal mengambil laporan penjualan: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getSalesReport error: $e');
      rethrow;
    }
  }

  /// GET /api/products — Mengambil semua produk dengan query pencarian (Public)
  Future<List<dynamic>> getPublicProducts(String query) async {
    try {
      final url = query.isEmpty
          ? '$baseUrl/api/products'
          : '$baseUrl/api/products?search=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['products'] as List<dynamic>;
      } else {
        throw Exception('Gagal mengambil produk publik: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getPublicProducts error: $e');
      rethrow;
    }
  }
}
