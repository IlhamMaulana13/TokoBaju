import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Dummy Data Produk
  final List<Map<String, dynamic>> _dummyProducts = [
    {
      'id': '1',
      'name': 'Kaos Polos Cotton Combed 30s',
      'price': 45000.0,
      'stock': 120,
      'image_url': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=200',
      'description': 'Kaos polos premium bahan 100% cotton combed nyaman dipakai sehari-hari.'
    },
    {
      'id': '2',
      'name': 'Kemeja Flannel Premium',
      'price': 135000.0,
      'stock': 45,
      'image_url': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=200',
      'description': 'Kemeja flannel motif kotak-kotak dengan bahan tebal dan jahitan rapi.'
    },
    {
      'id': '3',
      'name': 'Celana Chino Slim Fit',
      'price': 150000.0,
      'stock': 30,
      'image_url': 'https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=200',
      'description': 'Celana chino stretch slim fit, cocok untuk acara formal maupun kasual.'
    },
    {
      'id': '4',
      'name': 'Jaket Bomber Navy',
      'price': 210000.0,
      'stock': 15,
      'image_url': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=200',
      'description': 'Jaket bomber dengan lapisan dalam furing hangat, tahan angin dan modis.'
    },
  ];

  // Dummy Data Pesanan COD
  final List<Map<String, dynamic>> _dummyOrders = [
    {
      'id': 'COD-90234',
      'customer': 'Budi Santoso',
      'address': 'Jl. Merdeka No. 45, Gambir, Jakarta Pusat, 10110',
      'total': 270000.0,
      'status': 'Pending',
      'date': '13 Jul 2026, 14:30',
      'items': '2x Kaos Polos, 1x Kemeja Flannel'
    },
    {
      'id': 'COD-90235',
      'customer': 'Siti Rahma',
      'address': 'Perum Gading Indah Blok C3 No. 12, Sukolilo, Surabaya, 60111',
      'total': 135000.0,
      'status': 'Packing',
      'date': '13 Jul 2026, 12:15',
      'items': '1x Kemeja Flannel'
    },
    {
      'id': 'COD-90236',
      'customer': 'Andi Wijaya',
      'address': 'Jl. Slamet Riyadi No. 102, Laweyan, Surakarta, 57141',
      'total': 450000.0,
      'status': 'Shipped',
      'date': '12 Jul 2026, 18:00',
      'items': '3x Celana Chino Slim Fit'
    },
    {
      'id': 'COD-90237',
      'customer': 'Dewi Lestari',
      'address': 'Kost Asri Room 4, Gg. Sengon No. 5, Coblong, Bandung, 40135',
      'total': 210000.0,
      'status': 'Delivered',
      'date': '11 Jul 2026, 09:45',
      'items': '1x Jaket Bomber Navy'
    },
  ];

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
    final stockController = TextEditingController(text: product?['stock']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?['image_url'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: const Color(0xFF1E232A),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Stok',
                        controller: stockController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
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
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            product == null
                                ? 'Dummy: Berhasil menambah produk!'
                                : 'Dummy: Berhasil memperbarui produk!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E232A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
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
            fillColor: const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E232A)),
            ),
          ),
        ),
      ],
    );
  }

  // Tab Kelola Produk
  Widget _buildProductTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dummyProducts.length,
      itemBuilder: (context, index) {
        final product = _dummyProducts[index];
        return Card(
          color: Colors.white,
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
                    child: Image.network(
                      product['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E232A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(product['price']),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF6F61),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Stok: ${product['stock']}',
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Dummy: Menghapus ${product['name']}',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
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
    );
  }

  // Tab Pesanan COD
  Widget _buildOrdersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dummyOrders.length,
      itemBuilder: (context, index) {
        final order = _dummyOrders[index];
        final statusColor = _getStatusColor(order['status']);

        return Card(
          color: Colors.white,
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
                        color: const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order['id'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E232A),
                        ),
                      ),
                    ),
                    Text(
                      order['date'],
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
                  order['customer'],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E232A),
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
                  order['items'],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[800],
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
                        order['address'],
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
                          _formatRupiah(order['total']),
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
                          value: order['status'],
                          icon: Icon(Icons.arrow_drop_down, color: statusColor),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                          onChanged: (String? newStatus) {
                            if (newStatus != null) {
                              setState(() {
                                order['status'] = newStatus;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Status Pesanan ${order['id']} diubah ke $newStatus',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: _getStatusColor(newStatus),
                                ),
                              );
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _selectedIndex == 0 ? 'Kelola Katalog Produk' : 'Daftar Pesanan COD',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E232A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ADMIN',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildProductTab() : _buildOrdersTab(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showProductForm(),
              backgroundColor: const Color(0xFF1E232A),
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Tambah Produk',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
          backgroundColor: Colors.white,
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
          ],
        ),
      ),
    );
  }
}
