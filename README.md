# Shopy

<p align="center">
  <img src="assets/logo.svg" alt="Shopy logo" width="150"/>
</p>

Shopy adalah aplikasi mobile e-commerce (marketplace) yang memungkinkan pengguna untuk menjelajah, mencari, dan membeli berbagai produk langsung dari smartphone mereka.

## Fitur

- Browsing & pencarian produk berdasarkan kategori
- Detail produk (gambar, deskripsi, harga, rating)
- Keranjang belanja (cart)
- Checkout & manajemen pesanan
- Autentikasi pengguna (login/register)
- Riwayat transaksi
- Wishlist / produk favorit
- Notifikasi (promo, status pesanan)

## Tech Stack

- **Platform:** Mobile (Android/iOS)
- **Framework:** Flutter
- **Bahasa:** Dart
- **State Management:** Riverpod
- **Backend:** .NET Core (REST API)
- **Database:** PostgreSQL
- **Autentikasi:** JWT (JSON Web Token) dengan ASP.NET Core Identity + Refresh Token

## Instalasi

```bash
# Clone repository (monorepo, berisi mobile app & API)
git clone https://github.com/username/shopy.git
cd shopy

# Install dependencies mobile app
cd shopy-mobile
flutter pub get

# Install dependencies API
cd ../shopy-api
dotnet restore
```

## Cara Menjalankan

```bash
# Jalankan mobile app
cd shopy-mobile
flutter run

# Jalankan API
cd shopy-api
dotnet run
```

## Struktur Proyek

Repo ini menggunakan struktur **monorepo** — mobile app dan backend API berada dalam satu repository yang sama, masing-masing di subfolder terpisah.

```
shopy/
├── assets/             # Logo & aset bersama
├── shopy-mobile/       # Aplikasi Flutter
│   ├── lib/
│   │   ├── screens/    # Halaman-halaman aplikasi
│   │   ├── widgets/    # Komponen UI reusable
│   │   ├── services/   # API & logic bisnis
│   │   └── models/     # Data model
│   └── pubspec.yaml
├── shopy-api/          # Backend .NET Core
│   ├── Controllers/
│   ├── Models/
│   └── shopy-api.csproj
├── README.md
├── TASKS.md
└── ...
```

## Roadmap

- [ ] Setup project & UI dasar
- [ ] Implementasi autentikasi
- [ ] Halaman katalog produk
- [ ] Fitur keranjang & checkout
- [ ] Integrasi payment gateway
- [ ] Push notification
- [ ] Testing & rilis

## Kontribusi

Proyek ini dibuat untuk portofolio pribadi. Saran dan masukan terbuka melalui *issue* atau *pull request*.

## Lisensi

Belum ditentukan.
