import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tokobaju/services/admin_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockMController = TextEditingController(text: '0');
  final _stockLController = TextEditingController(text: '0');
  final _stockXLController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final AdminService _adminService = AdminService();
  bool _isSubmitting = false;
  String? _selectedCategory;
  final List<String> _categories = ['Kaos', 'Kemeja', 'Hoodie', 'Jaket', 'Celana'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockMController.dispose();
    _stockLController.dispose();
    _stockXLController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar dari galeri: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih gambar produk terlebih dahulu', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Menampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E232A)),
              const SizedBox(width: 20),
              Text(
                'Mengunggah data...',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 1. Unggah gambar ke ImgBB
      final String imageUrl = await _adminService.uploadImageToImgBB(_imageFile!);

      // 2. Buat produk di Golang backend
      final double price = double.parse(_priceController.text);
      
      final List<Map<String, dynamic>> sizesList = [
        {'size': 'M', 'stock': int.tryParse(_stockMController.text) ?? 0},
        {'size': 'L', 'stock': int.tryParse(_stockLController.text) ?? 0},
        {'size': 'XL', 'stock': int.tryParse(_stockXLController.text) ?? 0},
      ];

      final data = {
        'name': _nameController.text.trim(),
        'price': price,
        'image_url': imageUrl,
        'category': _selectedCategory ?? 'Semua',
        'description': _descriptionController.text.trim(),
        'sizes': sizesList,
      };

      await _adminService.createProduct(data);

      if (!mounted) return;
      // Close the loading dialog
      Navigator.pop(context);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk berhasil ditambahkan!', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );

      // Go back to admin dashboard
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      // Close the loading dialog
      Navigator.pop(context);

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan produk: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tambah Produk',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E232A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E232A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Area Preview Gambar
              GestureDetector(
                onTap: _isSubmitting ? null : _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Pilih Gambar dari Galeri',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Input Fields
              _buildFormLabel('Nama Produk'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                enabled: !_isSubmitting,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _buildInputDecoration('Masukkan nama produk'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama produk tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dropdown Kategori
              _buildFormLabel('Kategori'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E232A)),
                decoration: _buildInputDecoration('Pilih kategori produk'),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kategori wajib dipilih';
                  }
                  return null;
                },
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
              ),
              const SizedBox(height: 16),

              // Input Harga
              _buildFormLabel('Harga (Rp)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _buildInputDecoration('Contoh: 150000'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga wajib diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harus angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stok per Ukuran Section
              _buildFormLabel('Stok per Ukuran (M, L, XL)'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildStockInput('M', _stockMController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStockInput('L', _stockLController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStockInput('XL', _stockXLController),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildFormLabel('Deskripsi Produk (Opsional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isSubmitting,
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _buildInputDecoration('Masukkan deskripsi detail produk'),
              ),
              const SizedBox(height: 32),

              // Button Simpan Produk
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E232A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Simpan Produk',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildStockInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ukuran $label',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
          decoration: _buildInputDecoration('0').copyWith(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Wajib';
            }
            if (int.tryParse(value) == null) {
              return 'Angka';
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E232A)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}
