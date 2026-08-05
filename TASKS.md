# Tahap Pengerjaan Shopy

Breakdown detail tahap pengerjaan aplikasi Shopy, dari setup awal sampai rilis. Untuk gambaran umum fitur & tech stack, lihat [README.md](./README.md).

## Fase 0 — Persiapan

- [ ] Setup monorepo: `git init` di root `D:\Flutter\Shopy`, dengan subfolder `shopy-mobile` (Flutter) dan `shopy-api` (.NET Core) — tanpa `.git` terpisah di masing-masing subfolder
- [ ] Setup PostgreSQL database (local & environment dev)
- [ ] Desain skema database awal (users, products, categories, cart, orders)
- [ ] Setup design system dasar: warna (oranye `#FF6B35` sebagai primary), tipografi, spacing
- [ ] Finalisasi logo & assets (sudah selesai — `assets/logo.svg`)

## Fase 1 — Autentikasi

- [ ] Backend: setup ASP.NET Core Identity
- [ ] Backend: endpoint register & login
- [ ] Backend: generate JWT (access token) + refresh token
- [ ] Backend: middleware validasi token
- [ ] Flutter: halaman Login & Register (UI)
- [ ] Flutter: provider (Riverpod) untuk auth state
- [ ] Flutter: simpan token dengan `flutter_secure_storage`
- [ ] Flutter: auto refresh token saat expired
- [ ] Flutter: halaman Splash/cek status login

## Fase 2 — Katalog Produk

- [ ] Backend: model & endpoint kategori produk
- [ ] Backend: model & endpoint produk (list, detail, search, filter)
- [ ] Flutter: halaman Home (listing produk, kategori)
- [ ] Flutter: halaman Detail Produk
- [ ] Flutter: fitur pencarian & filter produk
- [ ] Flutter: provider untuk state produk (Riverpod)

## Fase 3 — Keranjang & Wishlist

- [ ] Backend: endpoint cart (add, update qty, remove, get)
- [ ] Backend: endpoint wishlist
- [ ] Flutter: halaman Keranjang
- [ ] Flutter: cartProvider (Riverpod) — sinkron dengan navbar/icon cart
- [ ] Flutter: fitur wishlist/favorit di halaman produk

## Fase 4 — Checkout & Pesanan

- [ ] Backend: endpoint checkout (buat order dari cart)
- [ ] Backend: endpoint riwayat & detail pesanan
- [ ] Backend: manajemen status pesanan (pending, diproses, dikirim, selesai)
- [ ] Flutter: halaman Checkout (alamat, ringkasan, konfirmasi)
- [ ] Flutter: halaman Riwayat Transaksi
- [ ] Flutter: halaman Detail Pesanan + tracking status

## Fase 5 — Payment Gateway

- [ ] Riset & pilih payment gateway (Midtrans/Xendit, dll)
- [ ] Backend: integrasi API payment gateway
- [ ] Backend: webhook konfirmasi pembayaran
- [ ] Flutter: halaman pembayaran & konfirmasi

## Fase 6 — Notifikasi

- [ ] Setup push notification (Firebase Cloud Messaging)
- [ ] Backend: trigger notifikasi (promo, status pesanan)
- [ ] Flutter: handle notifikasi (foreground & background)

## Fase 7 — Polish & Testing

- [ ] Review & rapikan UI/UX di semua halaman
- [ ] Unit test (backend & Flutter)
- [ ] Widget/integration test (Flutter)
- [ ] Testing manual end-to-end (dari register sampai checkout)
- [ ] Perbaikan bug hasil testing

## Fase 8 — Rilis

- [ ] Setup app icon & splash screen final
- [ ] Build release (Android APK/AAB, iOS jika perlu)
- [ ] Deploy backend ke server/hosting
- [ ] Submit ke Play Store (dan App Store jika ada)
- [ ] Dokumentasi akhir & update README

---

**Cara pakai file ini:** centang `[ ]` jadi `[x]` setiap task selesai. Update fase secara berurutan, tapi boleh disesuaikan kalau ada prioritas yang berubah.
