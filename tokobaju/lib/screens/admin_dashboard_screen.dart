import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tokobaju/providers/theme_provider.dart';
import 'package:tokobaju/screens/add_product_screen.dart';
import 'package:tokobaju/screens/login_screen.dart';
import 'package:tokobaju/services/admin_service.dart';
import 'package:tokobaju/screens/admin_report_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final AdminService _adminService = AdminService();

  Future<List<dynamic>>? _productsFuture;
  Future<List<dynamic>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
    _refreshOrders();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _adminService.fetchProducts();
    });
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = _adminService.fetchOrders();
    });
  }

  // Format ke Rupiah
  String _formatRupiah(double val) {
    final parts = val.toInt().toString().split('');
    final List<String> res = [];
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      res.insert(0, parts[i]);
      count++;
      if (count == 3 && i != 0) {
        res.insert(0, '.');
        count = 0;
      }
    }
    return 'Rp ${res.join()}';
  }

  // Format Tanggal
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  // Warna status pesanan
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFFF9800); // Orange
      case 'Packing':
        return const Color(0xFF2196F3); // Blue
      case 'Shipped':
        return const Color(0xFF9C27B0); // Purple
      case 'Delivered':
        return const Color(0xFF4CAF50); // Green
      default:
        return Colors.grey;
    }
  }

  // Tampilkan Dialog Tambah/Edit Produk
  void _showProductForm({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?['image_url'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');

    // Initialize stock controllers
    final sizesList = product?['sizes'] as List<dynamic>? ?? [];
    int getStockForSize(String size) {
      final sizeObj = sizesList.firstWhere((item) => item['size'] == size, orElse: () => null);
      return sizeObj != null ? (sizeObj['stock'] as num?)?.toInt() ?? 0 : 0;
    }

    final stockSController = TextEditingController(text: product != null ? getStockForSize('S').toString() : '0');
    final stockMController = TextEditingController(text: product != null ? getStockForSize('M').toString() : '0');
    final stockLController = TextEditingController(text: product != null ? getStockForSize('L').toString() : '0');
    final stockXLController = TextEditingController(text: product != null ? getStockForSize('XL').toString() : '0');

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product == null ? 'Tambah Produk Baru' : 'Edit Produk',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(label: 'Nama Produk', controller: nameController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Harga (Rp)',
                            controller: priceController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Stok per Ukuran',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildMiniStockField('S', stockSController)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildMiniStockField('M', stockMController)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildMiniStockField('L', stockLController)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildMiniStockField('XL', stockXLController)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Image URL (Firebase)', controller: imageUrlController),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Deskripsi Produk',
                      controller: descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final priceText = priceController.text.trim();
                                final imageUrl = imageUrlController.text.trim();
                                final description = descriptionController.text.trim();

                                if (name.isEmpty || priceText.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Nama dan Harga wajib diisi', style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                final double? price = double.tryParse(priceText);

                                if (price == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Harga harus berupa angka valid', style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                final List<Map<String, dynamic>> sizesPayload = [
                                  {'size': 'S', 'stock': int.tryParse(stockSController.text) ?? 0},
                                  {'size': 'M', 'stock': int.tryParse(stockMController.text) ?? 0},
                                  {'size': 'L', 'stock': int.tryParse(stockLController.text) ?? 0},
                                  {'size': 'XL', 'stock': int.tryParse(stockXLController.text) ?? 0},
                                ];

                                setModalState(() {
                                  isSaving = true;
                                });

                                try {
                                  final data = {
                                    'name': name,
                                    'price': price,
                                    'image_url': imageUrl,
                                    'description': description,
                                    'sizes': sizesPayload,
                                  };

                                  if (product == null) {
                                    await _adminService.createProduct(data);
                                  } else {
                                    await _adminService.updateProduct(product['id'] as int, data);
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          product == null
                                              ? 'Berhasil menambah produk!'
                                              : 'Berhasil memperbarui produk!',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: const Color(0xFF4CAF50),
                                      ),
                                    );
                                    _refreshProducts();
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan produk: $e', style: GoogleFonts.poppins()),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                product == null ? 'Simpan Produk' : 'Perbarui Produk',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniStockField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  // Tab Kelola Produk
  Widget _buildProductTab() {
    return FutureBuilder<List<dynamic>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1E232A),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat produk',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E232A),
                  ),
                  child: Text('Coba Lagi', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final productsList = snapshot.data ?? [];
        if (productsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Belum ada produk',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E232A),
                  ),
                  child: Text('Refresh', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshProducts(),
          color: const Color(0xFF1E232A),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productsList.length,
            itemBuilder: (context, index) {
              final product = productsList[index] as Map<String, dynamic>;
              final double price = (product['price'] as num?)?.toDouble() ?? 0.0;
              final sizesList = product['sizes'] as List<dynamic>? ?? [];
              final int totalStock = sizesList.fold<int>(0, (sum, item) => sum + ((item['stock'] as num?)?.toInt() ?? 0));
              final int productId = product['id'] as int;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: const Color(0xFFF7F8FA),
                          child: (product['image_url'] != null && product['image_url'].toString().isNotEmpty)
                              ? Image.network(
                                  product['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _formatRupiah(price),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF6F61),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      ((product['rating'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Stok: $totalStock',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                            onPressed: () => _showProductForm(product: product),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () async {
                              final confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Hapus Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  content: Text('Apakah Anda yakin ingin menghapus produk "${product['name']}"?', style: GoogleFonts.poppins()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmDelete == true) {
                                try {
                                  await _adminService.deleteProduct(productId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Berhasil menghapus produk!', style: GoogleFonts.poppins()),
                                        backgroundColor: const Color(0xFF4CAF50),
                                      ),
                                    );
                                    _refreshProducts();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menghapus produk: $e', style: GoogleFonts.poppins()),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Tab Pesanan COD
  Widget _buildOrdersTab() {
    return FutureBuilder<List<dynamic>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1E232A),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat pesanan',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E232A),
                  ),
                  child: Text('Coba Lagi', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final ordersList = snapshot.data ?? [];
        if (ordersList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pesanan masuk',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E232A),
                  ),
                  child: Text('Refresh', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshOrders(),
          color: const Color(0xFF1E232A),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordersList.length,
            itemBuilder: (context, index) {
              final order = ordersList[index] as Map<String, dynamic>;
              final int orderId = order['id'] as int;
              final double totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;
              final String status = order['status'] ?? 'Pending';
              final String address = order['shipping_address'] ?? '';

              // Formatting order items description
              final List<dynamic> itemsList = order['items'] ?? [];
              final itemsText = itemsList.map((item) {
                final product = item['product'];
                final name = product != null ? product['name'] : 'Produk';
                final qty = item['quantity'] ?? 1;
                return '${qty}x $name';
              }).join(', ');

              // User/Customer info
              final user = order['user'];
              final customerName = user != null ? user['name'] : 'Pelanggan';

              final statusColor = _getStatusColor(status);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : const Color(0xFFF0F1F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'COD-$orderId',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(order['created_at']),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.8),
                      Text(
                        'Pelanggan:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                          customerName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Produk yang dibeli:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        itemsText.isNotEmpty ? itemsText : '-',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Alamat Pengiriman:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Pembayaran (COD):',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                _formatRupiah(totalPrice),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF6F61),
                                ),
                              ),
                            ],
                          ),
                          // Dropdown Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: status,
                                icon: Icon(Icons.arrow_drop_down, color: statusColor),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                                onChanged: (String? newStatus) async {
                                  if (newStatus != null && newStatus != status) {
                                    try {
                                      String? proofOfDeliveryUrl;
                                      
                                      // Jika status diubah ke Delivered, minta gambar bukti pengiriman
                                      if (newStatus == 'Delivered') {
                                        if (!context.mounted) return;
                                        final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
                                          context: context,
                                          backgroundColor: Theme.of(context).cardColor,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          ),
                                          builder: (BuildContext context) {
                                            return SafeArea(
                                              child: Wrap(
                                                children: [
                                                  ListTile(
                                                    leading: Icon(Icons.camera_alt, color: Theme.of(context).iconTheme.color),
                                                    title: Text('Ambil dari Kamera', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                                    onTap: () => Navigator.pop(context, ImageSource.camera),
                                                  ),
                                                  ListTile(
                                                    leading: Icon(Icons.photo_library, color: Theme.of(context).iconTheme.color),
                                                    title: Text('Pilih dari Galeri', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );

                                        if (selectedSource == null) {
                                          // Jika admin membatalkan pilihan sumber gambar, batalkan update status
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Status Delivered memerlukan bukti foto pengiriman.', style: GoogleFonts.poppins()),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        final picker = ImagePicker();
                                        final XFile? pickedFile = await picker.pickImage(
                                          source: selectedSource,
                                          maxWidth: 1000,
                                          maxHeight: 1000,
                                          imageQuality: 80,
                                        );
                                        
                                        if (pickedFile == null) {
                                          // Jika admin membatalkan pilih gambar, batalkan update status
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Status Delivered memerlukan bukti foto pengiriman.', style: GoogleFonts.poppins()),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        // Upload gambar ke ImgBB
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Mengunggah bukti pengiriman...', style: GoogleFonts.poppins()),
                                              backgroundColor: const Color(0xFF1E232A),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                        proofOfDeliveryUrl = await _adminService.uploadImageToImgBB(File(pickedFile.path));
                                      }

                                      await _adminService.updateOrderStatus(orderId, newStatus, proofOfDelivery: proofOfDeliveryUrl);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Status Pesanan COD-$orderId diubah ke $newStatus',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: _getStatusColor(newStatus),
                                          ),
                                        );
                                        _refreshOrders();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Gagal mengubah status: $e', style: GoogleFonts.poppins()),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                items: <String>['Pending', 'Packing', 'Shipped', 'Delivered']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(color: _getStatusColor(value)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Dashboard Admin',
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                tooltip: themeProvider.isDarkMode ? 'Mode Gelap' : 'Mode Terang',
                onPressed: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              );
            },
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.onPrimary, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ADMIN',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF6F61)),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Konfirmasi Logout',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Apakah Anda yakin ingin keluar dari akun Admin?',
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF6F61),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                _selectedIndex == 0
                    ? 'Kelola Katalog Produk'
                    : _selectedIndex == 1
                        ? 'Daftar Pesanan COD'
                        : 'Laporan Penjualan',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? _buildProductTab()
                : _selectedIndex == 1
                    ? _buildOrdersTab()
                    : const AdminReportScreen(),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
                if (result == true) {
                  _refreshProducts();
                }
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 4,
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
              label: Text(
                'Tambah Produk',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).cardColor,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: const Color(0xFFFF6F61),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Kelola Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Pesanan COD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}
