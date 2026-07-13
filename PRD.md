# PRD: Aplikasi E-Commerce Toko Baju (COD)

## 1. Problem Statement
Dalam pengembangan aplikasi e-commerce, integrasi payment gateway seringkali memakan waktu. Di sisi lain, banyak pembeli yang lebih nyaman dan percaya bertransaksi menggunakan metode bayar di tempat (Cash on Delivery). Dibutuhkan sebuah aplikasi penjualan toko baju yang responsif, modern, dan fokus pada alur pemesanan COD.

## 2. Goals
Membangun MVP (Minimum Viable Product) aplikasi mobile e-commerce untuk toko baju menggunakan Flutter dan Golang. Aplikasi ini memfasilitasi transaksi murni melalui COD dan memanfaatkan Firebase untuk efisiensi autentikasi serta penyimpanan media.

## 3. Target Users
1. **Customer (Pelanggan):** Pengguna akhir yang mencari baju, memasukkan ke keranjang, dan melakukan pemesanan (COD).
2. **Admin (Pengelola Toko):** Pihak internal yang bertugas menambahkan katalog baju, melihat pesanan masuk, dan mengupdate status pengiriman COD.

## 4. User Stories
- Sebagai **Customer**, saya ingin login dengan cepat menggunakan nomor HP/Email agar bisa langsung berbelanja.
- Sebagai **Customer**, saya ingin melihat katalog baju dengan tampilan yang responsif di HP.
- Sebagai **Customer**, saya ingin melakukan *checkout* pesanan dan memilih COD sebagai metode pembayaran.
- Sebagai **Admin**, saya ingin melihat daftar pesanan COD yang masuk untuk menyiapkan pengiriman.
- Sebagai **Admin**, saya ingin bisa mengubah status pesanan (Pending -> Dikirim -> Selesai).

## 5. Functional Requirement
- **Autentikasi & Storage (Firebase):** - Login dan Register menggunakan Firebase Auth.
  - Upload dan penyimpanan gambar produk menggunakan Firebase Cloud Storage.
- **Relational Data (MySQL):** Menyimpan data relasional seperti profil user, produk, keranjang, dan riwayat pesanan.
- **Katalog Produk:** Menampilkan daftar baju beserta gambar, harga, dan deskripsi.
- **Keranjang Belanja (Cart):** Menyimpan sementara baju yang ingin dibeli.
- **Checkout:** Form pemesanan yang khusus menggunakan COD dan mencatat alamat pengiriman.
- **Manajemen Order:** Fitur bagi admin untuk memperbarui status pesanan COD secara manual.

## 6. Non-Functional Requirement
- **UI/UX:** Tampilan *mobile-friendly*, responsif, dan intuitif (Flutter).
- **Kecepatan & Performa:** Backend (Golang Gin) harus merespons API dengan cepat.
- **Keamanan:** Autentikasi di-handle sepenuhnya oleh sistem keamanan Firebase.

## 7. Scope
- **In-Scope (Dikerjakan):** - Aplikasi Mobile (Flutter).
  - RESTful API (Golang Gin-Gonic).
  - Database Management (MySQL & Gorm).
  - Firebase Admin SDK (Auth & Storage).
  - Sistem pembayaran manual (COD).
- **Out-of-Scope (Tidak Dikerjakan / Ditunda):** - Integrasi Payment Gateway (Midtrans, Xendit, dll).
  - Perhitungan ongkos kirim otomatis via API ekspedisi pihak ketiga.