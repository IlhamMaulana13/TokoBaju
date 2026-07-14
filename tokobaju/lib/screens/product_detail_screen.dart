import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tokobaju/providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  final List<String> _sizes = ['M', 'L', 'XL'];

  // Helper to format currency
  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _addToCart() {
    if (_selectedSize == null || _selectedSize!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih ukuran terlebih dahulu!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final price = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    final String imgUrl = widget.product['image_url'] ?? widget.product['imageUrl'] ?? '';

    context.read<CartProvider>().addItem(
          widget.product['id'].toString(),
          widget.product['name'] ?? 'Produk',
          price,
          imgUrl,
          _selectedSize!,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Berhasil menambahkan ${widget.product['name']} (Ukuran $_selectedSize) ke keranjang!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imgUrl = widget.product['image_url'] ?? widget.product['imageUrl'] ?? '';
    final double rating = (widget.product['rating'] as num?)?.toDouble() ?? 0.0;
    final double price = (widget.product['price'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          // Custom Slivers AppBar for Premium Image Display
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E232A)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF1E232A),
            flexibleSpace: FlexibleSpaceBar(
              background: imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    widget.product['category']?.toUpperCase() ?? 'UMUM',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6F61),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Name & Price
                  Text(
                    widget.product['name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E232A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(price),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFF6F61),
                        ),
                      ),
                      // Rating display
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E232A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 36, thickness: 0.8),

                  // Size Section
                  Text(
                    'Pilih Ukuran',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E232A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: (widget.product['sizes'] as List<dynamic>? ?? _sizes.map((s) => {'size': s, 'stock': 1}).toList()).map((sizeData) {
                      final String sizeName = sizeData['size'] ?? '';
                      final int stock = sizeData['stock'] ?? 0;
                      final isSelected = _selectedSize == sizeName;
                      final isOutOfStock = stock <= 0;

                      return ChoiceChip(
                        label: Text(
                          isOutOfStock ? '$sizeName (Habis)' : sizeName,
                          style: GoogleFonts.poppins(
                            color: isOutOfStock
                                ? Colors.grey[400]
                                : (isSelected ? Colors.white : const Color(0xFF1E232A)),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1E232A),
                        backgroundColor: const Color(0xFFF0F1F5),
                        disabledColor: const Color(0xFFE0E0E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[200]!),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onSelected: isOutOfStock
                            ? null
                            : (selected) {
                                setState(() {
                                  _selectedSize = selected ? sizeName : null;
                                });
                              },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 36, thickness: 0.8),

                  // Description
                  Text(
                    'Deskripsi Produk',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E232A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (widget.product['description'] != null && widget.product['description'].toString().trim().isNotEmpty)
                        ? widget.product['description']
                        : 'Tidak ada deskripsi untuk produk ini.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ElevatedButton(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E232A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tambah ke Keranjang',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
