# Tahap Pengerjaan Shopy Seller

Breakdown detail tahap pengerjaan **sisi penjual (seller)** aplikasi Shopy. Dokumen ini melanjutkan [TASKS.md](./TASKS.md) (sisi pembeli, Fase 0-6 sudah selesai) dan memakai gaya penulisan yang sama: centang `[ ]` jadi `[x]` setiap task selesai.

**Keputusan arsitektur yang sudah diambil:**

- **App terpisah** — folder baru `shopy-seller/` di monorepo yang sama (bukan mode di dalam app pembeli).
- **Order dipecah per toko** — 1 checkout bisa menghasilkan beberapa **SubOrder**, tiap toko hanya mengelola sub-order miliknya.
- **Cakupan penuh** — toko & produk & pesanan, keuangan & pencairan, promo & voucher, chat & ulasan.

---

## Kondisi Saat Ini (hasil audit kode)

Yang **sudah ada** dan bisa dipakai ulang: ASP.NET Core Identity + JWT + refresh token, `Categories`, `Products`, `Carts`, `Orders`/`OrderItems`/`OrderStatusHistories`, `Payments` (Midtrans Core API), `Notifications` + `DeviceTokens` (FCM), `Reviews` (tabel saja), design system Flutter (`AppColors`/`AppTypography`/`AppSpacing`/`AppTheme`), pola `ApiClient` + Riverpod + `flutter_secure_storage`.

Yang **belum ada sama sekali** dan jadi pekerjaan utama dokumen ini:

| # | Gap | Dampak |
|---|-----|--------|
| 1 | Tidak ada entitas **toko/seller**. `Product` tidak punya `StoreId`, `Order` tidak tahu produk itu milik siapa | Fondasi seluruh fitur seller |
| 2 | **Role belum dipakai**. `AddRoles<IdentityRole<Guid>>()` sudah didaftarkan di `Program.cs`, tapi tidak ada role yang di-seed dan `TokenService` **tidak menyisipkan claim role sama sekali** | Semua endpoint seller butuh ini |
| 3 | Tidak ada endpoint **CRUD produk** (hanya `GET`), dan `Product.ImageUrl` cuma 1 gambar berupa string | Manajemen produk |
| 4 | Tidak ada infrastruktur **upload file** | Logo toko, foto produk, bukti kirim, dokumen verifikasi |
| 5 | `PATCH /api/orders/{id}/status` masih dibatasi ke pesanan milik user sendiri (lihat catatan TASKS.md Fase 4) | Harus dipindah ke sisi seller |
| 6 | **Stok tidak pernah dikurangi** saat checkout — `OrdersController.Checkout` hanya memvalidasi `Quantity > Stock` 🐛 | Wajib diperbaiki di Fase 4 |
| 7 | Tidak ada **Reviews controller** (tabelnya ada, endpoint-nya tidak) | Ulasan & balasan penjual |
| 8 | Tidak ada **chat** dan tidak ada infrastruktur realtime | Chat pembeli-penjual |
| 9 | Tidak ada **saldo/komisi/pencairan** | Keuangan seller |
| 10 | Voucher/diskon masih **hardcoded di Flutter** (`kMockPromoCode = 'HEMAT20'` di `providers/cart_provider.dart`), `Product` tidak punya field diskon | Promo & voucher |
| 11 | `POST /api/notifications/promo` **terbuka untuk user manapun yang login** | Harus dikunci ke role Admin |
| 12 | Ongkir masih flat `Rp15.000` (`FlatShippingCost` di `OrdersController` & `kMockShippingCost` di Flutter) | Ongkir per kurir/berat |

> ⚠️ **Breaking change:** menambah `Product.StoreId` (wajib) dan memecah `Orders` jadi `SubOrders` akan mengubah tabel & DTO yang sudah dipakai app pembeli. Rencanakan migrasi data seeder (`Data/CatalogSeeder.cs`, 12 produk) ke satu "toko demo" sebelum menjalankan migration.

---

## Fase 0 — Persiapan & Skema Data

- [x] Buat app Flutter baru `shopy-seller` di root monorepo (`flutter create`), **tanpa `.git` terpisah** — konsisten dengan `shopy-mobile`/`shopy-api`
  - `flutter create --org com.shopy --project-name shopy_seller .` dijalankan di folder `shopy-seller/` yang sudah ada (isi `design/` mockup tetap aman). Bundle ID `com.shopy.shopySeller` (beda dari `com.shopy.shopyMobile`) supaya bisa ter-install berdampingan di HP yang sama.
- [x] Salin/ekstrak design system dari `shopy-mobile/lib/theme/` (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`) — opsi: jadikan package lokal `packages/shopy_ui` supaya tidak dobel maintain
  - Dipilih **copy-paste langsung** (bukan package lokal) — konsisten dengan pola project ini (belum pernah ada shared package di monorepo). 4 file disalin apa adanya ke `shopy-seller/lib/theme/`.
- [x] Salin pola infrastruktur dari `shopy-mobile`: `services/api_client.dart` (interceptor auto-refresh token), `services/token_storage_service.dart`, struktur `providers/` + `models/` + `screens/` + `widgets/`
  - `api_client.dart`, `token_storage_service.dart`, dan `models/auth/auth_response.dart` disalin apa adanya (login pakai endpoint sama persis, lihat Fase 1). Folder `providers/`, `models/`, `screens/`, `widgets/` dibuat kosong, diisi mulai Fase 1.
- [x] Tambah dependency: `flutter_riverpod`, `dio`, `flutter_secure_storage`, `google_fonts`, `flutter_svg`, `image_picker`, `firebase_core`, `firebase_messaging`, `fl_chart` (grafik statistik)
  - Versi disamakan dengan `shopy-mobile` untuk yang sudah ada; `image_picker`/`fl_chart` baru (belum pernah dipakai di `shopy-mobile`). `flutter analyze` & `flutter test` (smoke test) lulus.
- [x] Desain skema database seller — ketentuan umum tetap sama: **semua tabel pakai soft delete** (`IsDeleted bool`, default `false`)
  - [x] Table `Stores`: `Id`, `OwnerUserId` (FK `AspNetUsers`, unique — 1 user = 1 toko), `Name`, `Slug` (unique), `Description`, `LogoUrl`, `BannerUrl`, `PhoneNumber`, `Status` (enum: `Pending`/`Active`/`Suspended`/`Closed`), `IsOpen` (buka/tutup toko), `RatingAverage`, `RatingCount`, `ProductCount`, `FollowerCount`, `CreatedAt`, `UpdatedAt`, `IsDeleted`
  - [x] Table `StoreAddresses` (alamat pickup / asal pengiriman): `Id`, `StoreId` (FK), `Label`, `PicName`, `PhoneNumber`, `FullAddress`, `City`, `Province`, `PostalCode`, `IsDefault`, `IsDeleted`
  - [x] Table `StoreDocuments` (verifikasi toko): `Id`, `StoreId` (FK), `Type` (enum: `Ktp`/`Npwp`/`Nib`), `FileUrl`, `Status` (`Pending`/`Approved`/`Rejected`), `RejectReason`, `ReviewedAt`, `IsDeleted`
  - [x] Ubah `Products`: tambah `StoreId` (FK **wajib**), `Weight` (gram), `Condition` (enum `New`/`Used`), `SoldCount`, `ViewCount`, `DiscountPrice` (nullable), `DiscountStartAt`/`DiscountEndAt`
  - [x] Table `ProductImages`: `Id`, `ProductId` (FK), `Url`, `SortOrder`, `IsPrimary`, `IsDeleted` — menggantikan `Product.ImageUrl` tunggal (kolom lama dipertahankan dulu sebagai cache gambar utama supaya app pembeli tidak langsung rusak)
  - [x] Table `SubOrders`: `Id`, `OrderId` (FK), `StoreId` (FK), `SubOrderNumber` (unique, mis. `SHP-20260810-0142-1`), `Status` (enum: `WaitingPayment`/`NewOrder`/`Processing`/`Shipped`/`Completed`/`Cancelled`/`Rejected`), `Subtotal`, `ShippingCost`, `VoucherDiscount`, `CommissionAmount`, `SellerEarning`, `CourierCode`, `CourierService`, `TrackingNumber`, `ShippedAt`, `CompletedAt`, `AutoCancelAt`, `CancelReason`, `CreatedAt`, `UpdatedAt`, `IsDeleted`
  - [x] Ubah `OrderItems`: tambah `SubOrderId` (FK) — item tetap tergantung ke `Order` untuk kompatibilitas, tapi dikelompokkan per sub-order
    - ⚠️ Dibuat **nullable**, bukan wajib — logic checkout yang benar-benar mengelompokkan per toko baru dikerjakan di Fase 4 (refactor checkout).
  - [x] Table `SubOrderStatusHistories` (pengganti/pendamping `OrderStatusHistories`): `Id`, `SubOrderId`, `Status`, `Note`, `ChangedByUserId`, `ChangedAt`
  - [x] `Orders.Status` jadi **status agregat** hasil turunan sub-order (mis. semua sub-order `Completed` → order `Completed`)
    - Tidak ada perubahan skema untuk ini — murni catatan perilaku buat logic Fase 4.
  - [x] Table `StoreBalances`: `StoreId` (PK/FK), `AvailableBalance`, `PendingBalance`, `TotalEarning`, `UpdatedAt`
  - [x] Table `BalanceTransactions` (mutasi saldo): `Id`, `StoreId` (FK), `Type` (enum: `SaleIncome`/`Commission`/`Withdrawal`/`WithdrawalFee`/`Refund`/`Adjustment`), `Amount` (signed), `BalanceAfter`, `SubOrderId` (nullable), `WithdrawalId` (nullable), `Description`, `CreatedAt`
  - [x] Table `BankAccounts`: `Id`, `StoreId` (FK), `BankCode`, `BankName`, `AccountNumber`, `AccountHolderName`, `IsVerified`, `IsDefault`, `IsDeleted`
  - [x] Table `Withdrawals`: `Id`, `StoreId` (FK), `BankAccountId` (FK), `Amount`, `AdminFee`, `NetAmount`, `Status` (`Pending`/`Processing`/`Completed`/`Rejected`), `RejectReason`, `RequestedAt`, `ProcessedAt`, `IsDeleted`
  - [x] Table `Vouchers` (voucher toko): `Id`, `StoreId` (FK), `Code`, `Type` (enum: `Percentage`/`FixedAmount`/`FreeShipping`), `Value`, `MaxDiscount`, `MinPurchase`, `Quota`, `UsedCount`, `StartAt`, `EndAt`, `IsActive`, `IsDeleted` — unique `(StoreId, Code)`
  - [x] Table `VoucherUsages`: `Id`, `VoucherId` (FK), `UserId` (FK), `SubOrderId` (FK), `DiscountAmount`, `UsedAt`
  - [x] Table `FlashSales` + `FlashSaleItems` (opsional, untuk tab Flash Sale): periode, produk, harga khusus, kuota — **disertakan sekarang** (bukan ditunda)
  - [x] Table `ChatRooms`: `Id`, `StoreId` (FK), `BuyerUserId` (FK), `LastMessageAt`, `LastMessagePreview`, `UnreadCountSeller`, `UnreadCountBuyer`, `CreatedAt`, `IsDeleted` — unique `(StoreId, BuyerUserId)`
  - [x] Table `ChatMessages`: `Id`, `ChatRoomId` (FK), `SenderType` (enum `Buyer`/`Seller`), `SenderUserId`, `Body`, `AttachmentUrl`, `ProductId` (nullable), `SubOrderId` (nullable), `ReadAt`, `CreatedAt`, `IsDeleted`
  - [x] Ubah `Reviews`: tambah `StoreId`, `SubOrderId`, `SellerReply`, `SellerRepliedAt`, `ImageUrls` (atau tabel `ReviewImages`)
    - Dipilih 1 kolom `ImageUrls` (JSON array string), bukan tabel `ReviewImages` terpisah — belum dipakai sampai `ReviewsController` dibuat di Fase 7.
  - [x] Table `StoreFollowers` (opsional, untuk angka "Pengikut" di profil toko): `Id`, `StoreId`, `UserId`, `CreatedAt` — **disertakan sekarang** (bukan ditunda)
- [x] Migrasi data lama: buat 1 "toko demo" lalu assign semua produk seeder (`Data/CatalogSeeder.cs`) ke toko itu, dan generate `SubOrders` untuk `Orders` yang sudah ada — **jalankan sebelum** `StoreId` dijadikan non-nullable
  - `CatalogSeeder.cs` diperluas: bikin akun `seller-demo@shopy.com` (password `SellerDemo1234!`, dev-only) + toko "Toko Demo Shopy", semua 12 produk seeder di-assign ke situ — tapi karena seeder ini cuma jalan sekali (guard `Categories` kosong) dan sudah pernah jalan di sesi sebelumnya, jalur ini belum benar-benar tereksekusi di DB dev sekarang.
  - Yang benar-benar jalan: migration `AddSellerFoundation` sendiri punya backfill raw-SQL 2 lapis (idempotent) — (1) 12 produk lama yang sudah ada di-assign ke toko fallback "Toko Migrasi" (dibuatkan akun + toko dummy otomatis), (2) 1 `Order` lama (`SHP-20260807-8349`) dikelompokkan jadi `SubOrder` per toko dari produknya. Sudah diverifikasi lewat psql: 0 produk tersisa dengan `StoreId` kosong, 0 `OrderItems` tanpa `SubOrderId`.
- [x] Setup EF Core migration & apply ke database dev (`shopy`/`shopy_dev`)
  - Migration `AddSellerFoundation` — perlu diketahui: DB dev asli project ini ternyata **Postgres native Windows** (`localhost:5432`), BUKAN container `shopy-postgres` di `docker-compose.yml` (yang ada & jalan tapi kosong/tidak dipakai — cek dengan `psql` native, bukan `docker exec`, kalau mau verifikasi data).
- [x] Konfigurasi baru di `appsettings.json`: `Platform:CommissionPercent` (mis. 2%), `Platform:WithdrawalAdminFee` (mis. Rp2.500), `Platform:MinWithdrawal`, `Platform:AutoCancelHours` (mis. 24 jam), `Platform:AutoCompleteDays` (mis. 3 hari setelah `Shipped`)
  - Ditambahkan ke `appsettings.json` & `appsettings.Development.json`: `CommissionPercent=2`, `WithdrawalAdminFee=2500`, `MinWithdrawal=50000`, `AutoCancelHours=24`, `AutoCompleteDays=3`. Belum dibaca oleh kode manapun (baru dipakai mulai Fase 4/5).
- ⚠️ **Regresi app pembeli sudah dicek** — `dotnet build` 0 error, `/api/products`, `/api/categories`, login `test@shopy.com`, dan `/api/orders` semua masih 200 dengan bentuk response sama seperti sebelumnya.

## Fase 1 — Auth & Role Seller

- [x] Backend: seed role `Buyer` / `Seller` / `Admin` lewat `RoleManager` saat startup (pola sama seperti `CatalogSeeder`)
  - `Data/RoleSeeder.cs` — beda dari `CatalogSeeder`, ini dipanggil **unconditional** di `Program.cs` (semua environment, bukan cuma Development), karena role wajib ada di production juga. Diverifikasi lewat psql: 3 role (`Buyer`/`Seller`/`Admin`) ter-seed di `AspNetRoles`.
- [x] Backend: `TokenService.GenerateAccessToken` menyisipkan claim `role` (dari `UserManager.GetRolesAsync`) + claim `store_id` kalau user punya toko aktif — **saat ini claim yang dikirim cuma `sub`, `email`, `jti`, `full_name`**
  - Method jadi `GenerateAccessTokenAsync` (inject `UserManager<ApplicationUser>` + `ShopyDbContext`). Claim `store_id` disisipkan kalau user punya toko **apapun statusnya** (bukan cuma `Active`) — status gating jadi tanggung jawab guard terpisah, bukan syarat claim ada/tidaknya.
  - ⚠️ Detail teknis penting: claim role ditulis pakai tipe string pendek `"role"` (bukan `ClaimTypes.Role`) — inbound claim type mapping bawaan JWT bearer ASP.NET otomatis convert ini ke `ClaimTypes.Role` saat validasi token, supaya `[Authorize(Roles=...)]`/`User.IsInRole()` beneran jalan. Sudah diverifikasi manual: decode token hasil `POST /api/seller/store` menunjukkan `"role":"Seller"` dan `"store_id":"<guid>"`.
- [x] Backend: helper `ClaimsPrincipalExtensions.GetStoreId()` + attribute `[Authorize(Roles = "Seller")]` di semua controller seller, dan guard "toko harus `Active`"
  - `GetStoreId()` sudah ada (pola sama seperti `GetUserId()`). ⚠️ Guard "toko harus Active" **belum dibuat jadi reusable attribute/filter** — 3 endpoint Fase 1 semuanya `[Authorize]` biasa (bukan `Roles=Seller`), karena dipanggil pas toko belum/baru dibuat. Guard aktif baru ditambah pas Fase 2/3 punya endpoint yang beneran butuh (mis. manajemen produk).
- [x] Backend: `POST /api/seller/store` (buka toko — user yang sudah login mengajukan toko, status awal `Pending`), `GET /api/seller/store/status` (status verifikasi)
  - `Controllers/SellerController.cs`. `POST /api/seller/store` sekalian bikin 1 `StoreAddress` default (alamat pickup) + 1 `StoreBalance` kosong dalam transaksi yang sama — CRUD alamat toko terpisah baru Fase 2, jadi digabung ke sini dulu. Response-nya `AuthResponse` baru (token ter-refresh dengan claim `role`/`store_id` terbaru) supaya Flutter tidak perlu logout/login ulang setelah buka toko. Diverifikasi lewat `curl`: buka toko sukses (200), buka toko kedua kalinya ditolak (409 Conflict).
- [x] Backend: `GET /api/seller/me` — profil user + ringkasan toko (untuk bootstrap app seller)
  - Balas `store: null` kalau belum ada toko — dipakai Splash/routing Flutter buat memutuskan halaman berikutnya.
- [x] Backend: login pakai endpoint yang sama (`POST /api/auth/login`), tapi app seller menolak user tanpa role `Seller` dengan pesan jelas ("Akun ini belum punya toko")
  - ⚠️ **Diinterpretasi ulang** — dibaca literal ini kontradiktif dengan alur onboarding (user baru justru belum punya role Seller saat pertama kali buka app). Bukan hard-reject di login: setelah auth sukses, app selalu panggil `GET /api/seller/me` lalu routing — belum punya toko → wizard Buka Toko; `Pending` → Menunggu Verifikasi; `Active` → dashboard; `Suspended`/`Closed` → baru di situ tampil pesan blokir jelas.
- [x] Flutter: Splash + cek sesi (reuse pola `splash_screen.dart` dari app pembeli, desain **Pulse Rings**)
  - `screens/splash/splash_screen.dart` — sama persis pola Pulse Rings, bedanya routing setelah bootstrap manggil `navigateAfterAuth()` (lihat catatan `storeProvider` di bawah), bukan langsung ke Home.
- [x] Flutter: halaman Login & Register seller — reuse desain **Wave Header** dari app pembeli
  - `screens/auth/{login_screen,register_screen}.dart` — field & validasi sama persis app pembeli, tagline diganti "Kelola tokomu, kapan saja". Tombol Google/Facebook tetap placeholder "belum dikonfigurasi" (bukan scope Fase 1).
- [x] Flutter: halaman **Buka Toko** (3 langkah: Data Toko → Alamat → Verifikasi) + halaman status "Menunggu Verifikasi"

  ![Mockup Buka Toko - Bold & Colorful](./shopy-seller/design/assets/daftar-toko-seller-bold-colorful.png)

  - `screens/store/open_store_screen.dart` — wizard 3 langkah dalam 1 `PageView` + step indicator custom (lingkaran nomor + garis, meniru mockup). Langkah 1 "Data Toko" sesuai mockup **kecuali field "Kategori Toko"** ⚠️ (dilewati — tidak ada field kategori di skema `Store` Fase 0, konsisten dengan pola project ini yang banyak melewati elemen mockup yang backend-nya belum ada). Tombol "Unggah Logo Toko" & catatan di langkah 3 "Verifikasi" sengaja belum fungsional ⚠️ (infrastruktur upload file baru Fase 2) — cuma snackbar/catatan info, sama pola seperti tombol social login di app pembeli. Langkah 2 "Alamat" & 3 "Verifikasi" didesain sendiri (tidak ada mockup terpisah), pakai token desain yang sama.
  - `screens/store/awaiting_verification_screen.dart` — dipakai untuk status `Pending` maupun varian blokir `Suspended`/`Closed` (pesan beda per status, bukan file terpisah).
  - `screens/dashboard/dashboard_placeholder_screen.dart` — placeholder untuk toko `Active`, pola sama persis seperti Home placeholder `shopy-mobile` Fase 1 (dashboard asli baru Fase 8). **Sudah digantikan** `StoreProfileScreen` di Fase 2 (file placeholder ini dihapus) — dashboard sungguhan tetap menyusul Fase 8.
- [x] Flutter: `authProvider` + `storeProvider` (Riverpod), token disimpan di `flutter_secure_storage`
  - `providers/auth_provider.dart` disalin dari app pembeli + method baru `refreshSessionFrom()` (dipakai setelah buka toko sukses). Bukan `storeProvider` melainkan `providers/seller_provider.dart` → `sellerMeProvider` (`FutureProvider`, sumber kebenaran status toko selalu dari `GET /api/seller/me`, bukan dari claim JWT lokal yang bisa basi). Routing terpusat di `routing/post_auth_router.dart` (`navigateAfterAuth`), dipanggil dari Splash, Login, Register, dan setelah submit Buka Toko — supaya logic-nya tidak terduplikasi 4 tempat.
  - Wizard form Buka Toko sengaja **tidak** pakai `NotifierProvider` terpisah — state field disimpan di `TextEditingController` lokal widget, konsisten dengan pola form lain di app pembeli (`login_screen.dart`, dst).
- ⚠️ Catatan yang diwariskan dari TASKS.md Fase 1: login Google/Facebook masih butuh kredensial OAuth asli, dan pengiriman email OTP masih pakai placeholder Gmail SMTP. Sisi seller ikut kena batasan yang sama.
- ⚠️ **Belum dites visual di browser/device asli** — `flutter analyze` bersih & `flutter test` lulus (termasuk test routing Splash→Login, pakai fake `AuthNotifier` supaya tidak menyentuh `flutter_secure_storage` asli di lingkungan test — pola sama seperti `shopy-mobile/test/home_screen_test.dart`), dan alur backend penuh (register → buka toko → cek klaim token → store/status → tolak toko kedua) sudah diverifikasi lewat `curl`. Tapi percobaan screenshot otomatis di lingkungan ini sebelumnya gagal (WebGL, lihat TASKS.md Fase 2), jadi verifikasi visual wizard Buka Toko di Chrome/device asli belum dilakukan — coba jalankan manual (`flutter run -d chrome`, folder `shopy-seller`) sebelum dianggap benar-benar kelar.

## Fase 2 — Profil & Pengaturan Toko

- [x] Backend: **infrastruktur upload file** `POST /api/uploads` (validasi tipe & ukuran, simpan ke `wwwroot/uploads` untuk dev + abstraksi `IFileStorage` supaya gampang pindah ke S3/Cloudinary saat deploy) — ini prasyarat logo toko, foto produk, bukti kirim, dan dokumen verifikasi
  - `Services/IFileStorage.cs` + `LocalFileStorage.cs`, `Controllers/UploadsController.cs` (`POST /api/uploads?category=logo|banner|document`, maks 5MB, validasi content-type per kategori). `app.UseStaticFiles()` ditambah di `Program.cs`, folder `wwwroot/uploads/` (isi digitignore, struktur dipertahankan lewat `.gitkeep`).
  - ⚠️ **URL disimpan relatif** (mis. `/uploads/logo/xxx.png`), bukan absolut — client (kedua app Flutter) yang menggabungkan `resolveApiBaseUrl() + url` saat render `Image.network`, supaya tidak bergantung host/port tertentu (device fisik vs emulator vs web beda-beda, lihat catatan `adb reverse` sebelumnya).
  - Diuji lewat `curl -F`: upload logo sukses, file ke-serve balik lewat `UseStaticFiles()` (200).
- [x] Backend: `GET /api/seller/store`, `PUT /api/seller/store` (nama, deskripsi, logo, banner, kontak), `PATCH /api/seller/store/open` (buka/tutup toko)
  - Ditambahkan ke `Controllers/SellerController.cs`, semua pakai `[Authorize(Roles = "Seller")]` (beda dari 3 endpoint Fase 1 yang masih `[Authorize]` polos — role sudah pasti ada sejak toko dibuka).
- [x] Backend: CRUD `StoreAddresses` (alamat pickup) `GET/POST/PUT/DELETE /api/seller/store/addresses` + set default
  - `Controllers/SellerStoreAddressesController.cs` — pola identik `AddressesController.cs` (app pembeli), scoped ke `StoreId` bukan `UserId`.
- [x] Backend: CRUD `BankAccounts` `GET/POST/DELETE /api/seller/bank-accounts` + set default
  - `Controllers/SellerBankAccountsController.cs`, pola sama.
- [x] Backend: upload `StoreDocuments` untuk verifikasi + endpoint admin approve/reject (lihat Fase 9)
  - `POST`/`GET /api/seller/store/documents` di `SellerController.cs`. Bagian admin approve/reject memang belum dikerjakan (menunggu Fase 9, sesuai catatan dokumen).
  - ⚠️ **Belum ada halaman Flutter untuk upload dokumen** — checklist Flutter Fase 2 di bawah memang tidak menyebutnya, jadi disusul kapan Fase 9 (verifikasi admin) benar-benar butuh dipakai. Endpoint generik `POST /api/uploads?category=document` sudah siap dipakai nanti.
- [x] Backend (publik): `GET /api/stores/{slug}` (profil toko untuk app pembeli) + `GET /api/stores/{slug}/products`
  - `Controllers/StoresController.cs` (tanpa `[Authorize]`). ⚠️ **Toko yang belum `Active` sengaja 404** di endpoint ini (tidak ditulis eksplisit di dokumen, tapi masuk akal — pembeli tidak perlu lihat toko yang belum diverifikasi). Sekalian menambahkan `StoreId`/`StoreName`/`StoreSlug` ke `ProductListItemDto`/`ProductDetailDto` (`Models/Catalog/CatalogDtos.cs`) — **ini mengerjakan lebih dulu item Fase 3 baris "tambahkan storeId/storeName ke DTO produk publik"**, sudah dicentang di sana juga.
  - Diuji lengkap lewat `curl`: toko `Pending` → 404, diubah `Active` via psql → 200, `GET .../products` mengembalikan produk toko itu saja, `GET /api/products` (endpoint lama) masih 200 dengan field baru tanpa breaking field lama.
- [x] Flutter: halaman **Profil & Pengaturan Toko** (statistik ringkas, toggle buka/tutup toko, menu ke semua submenu, keluar akun)

  ![Mockup Profil Toko - Bold & Colorful](./shopy-seller/design/assets/profil-toko-seller-bold-colorful.png)

  - `screens/store/store_profile_screen.dart` — menggantikan `DashboardPlaceholderScreen` Fase 1 sebagai landing toko `Active`. Statistik (Produk/Pengikut/Rating) dibaca dari field denormalized `Store` (`ProductCount`/`FollowerCount`/`RatingAverage`) — masih 0 buat toko baru karena belum ada mekanisme yang menambahnya (baru terisi mulai Fase 3+). Badge "Toko Terverifikasi" cuma muncul kalau `Status == Active`. Menu 3 item fungsional (Edit Profil, Alamat, Rekening) + 5 placeholder (Keuangan/Statistik/Promo/Ulasan/Notifikasi — semua Fase 5-8, tap-nya snackbar "belum tersedia").
- [x] Flutter: halaman Edit Profil Toko, Alamat & Pengiriman, Rekening Bank
  - `screens/store/edit_store_profile_screen.dart` — form + 2 `image_picker` (logo/banner), upload ke `POST /api/uploads` lalu simpan URL-nya, submit `PUT /api/seller/store`. `screens/store/store_addresses_screen.dart` & `bank_accounts_screen.dart` — list + bottom sheet tambah (pola sama `address_form_sheet.dart` app pembeli) + hapus + jadikan utama.
- ⚠️ Perubahan di app pembeli (`shopy-mobile`): halaman Detail Produk perlu menampilkan kartu info toko + tombol "Kunjungi Toko", dan perlu halaman Profil Toko publik.
  - **Disertakan di Fase 2 ini** (bukan ditunda) — `product_detail_screen.dart` dapat kartu toko (nama + "Kunjungi Toko") sebelum bagian deskripsi, navigasi ke `screens/stores/store_profile_screen.dart` (baru — banner, logo, rating, stats, grid produk toko pakai `ProductCard` yang sudah ada). Model `ProductSummary`/`ProductDetail` di-extend dengan `storeId`/`storeName`/`storeSlug` (ikut update `test/home_screen_test.dart` yang bikin `ProductSummary` manual).
- ⚠️ **Regresi & verifikasi**: `dotnet build` 0 error. `flutter analyze` + `flutter test` bersih di **kedua** app (`shopy-seller` & `shopy-mobile`). Belum sempat dites visual manual di browser/device asli (sama seperti catatan Fase 1) — coba `flutter run -d chrome` di kedua folder kalau mau verifikasi visual.

## Fase 3 — Manajemen Produk

- [x] Backend: `GET /api/seller/products` (paged, filter `status`=aktif/nonaktif/habis, search, sort) — hanya produk milik toko yang login
  - `Controllers/SellerProductsController.cs` — `status=all|active|inactive|outofstock` (`active`=`IsActive && Stock>0`, `outofstock`=`IsActive && Stock==0`), `q` search nama, `sort=newest|priceAsc|priceDesc|stockAsc`. Tambah juga `GET /{id}` (tidak eksplisit di checklist tapi jelas prasyarat buat prefill halaman Edit Produk).
- [x] Backend: `POST /api/seller/products` (nama, kategori, harga, stok, berat, kondisi, deskripsi, gambar[], status tayang) + slug auto-generate & dijamin unik
  - Slug generator baru (belum ada helper serupa di backend manapun) — slugify nama + cek tabrakan, tambah suffix `-2`/`-3` dst. ⚠️ **Slug immutable setelah dibuat** (tidak ikut berubah walau nama diedit lewat `PUT`), supaya link yang sudah beredar di app pembeli tidak rusak.
  - Sekalian mulai menjaga `Store.ProductCount` (field denormalized dari Fase 0 yang dari Fase 2 selalu nampil 0 di Profil Toko) — `++` saat create, `--` saat delete. Bukan item eksplisit di checklist, tapi memperbaiki stat yang sebelumnya statis.
- [x] Backend: `PUT /api/seller/products/{id}`, `DELETE /api/seller/products/{id}` (soft delete), `PATCH /api/seller/products/{id}/active` (toggle tayang)
  - Ganti foto di `PUT` = **replace-all** (hapus semua `ProductImage` lama, insert ulang dari `imageUrls` yang dikirim client, index 0 = `IsPrimary`) — lebih simpel dari sinkronisasi per-foto, cukup untuk skala "maks 5 foto".
- [x] Backend: `PATCH /api/seller/products/bulk` — update stok & harga banyak produk sekaligus
- [x] Backend: `GET /api/seller/products/low-stock` (ambang batas bisa diatur, dipakai dashboard & notifikasi)
  - `?threshold=` (default 10). ⚠️ Endpoint ini dibuat sesuai checklist (buat Fase 8 nanti), tapi halaman Atur Stok & Harga di bawah **tidak memanggilnya** — banner stok menipis di situ dihitung client-side dari list yang sudah di-fetch untuk halaman itu sendiri, supaya tidak dobel request data yang sama.
  - Kategori upload baru `"product"` ditambahkan ke `UploadsController` (Fase 2) — reuse endpoint generik yang sama.
- [x] Backend: tambahkan `storeId`/`storeName` ke DTO produk publik (`Models/Catalog/CatalogDtos.cs`) supaya app pembeli bisa menampilkan asal toko — **sudah dikerjakan di Fase 2** (jadi prasyarat endpoint publik `GET /api/stores/{slug}/products` & kartu toko di Detail Produk), ikut ditambah `storeSlug` juga (tidak diminta eksplisit di baris ini, tapi diperlukan buat link "Kunjungi Toko")
- [x] Flutter: halaman **Daftar Produk** (tab Semua/Aktif/Nonaktif/Habis, toggle tayang, badge stok menipis, aksi ubah/hapus, FAB tambah produk)

  ![Mockup Daftar Produk - Bold & Colorful](./shopy-seller/design/assets/produk-list-seller-bold-colorful.png)

  - `screens/product/product_list_screen.dart` — filter pakai `ChoiceChip` (bukan `TabBar`, biar cocok gaya pill mockup), dihitung client-side dari 1 list `status=all` (bukan 4 request terpisah per tab). ⚠️ **Belum ada bottom nav 5-tab** (Beranda/Produk/Pesanan/Chat/Toko) yang tampil di mockup halaman ini maupun mockup Profil Toko (Fase 2) — itu eksplisit scope Fase 8 ("bottom nav 5 tab"). Untuk sekarang, akses ke halaman ini lewat kartu baru **"Produk Saya"** di `StoreProfileScreen` (di atas menu list, isi `${store.productCount} produk terdaftar`) — nav shell asli menyusul Fase 8.
- [x] Flutter: halaman **Tambah/Edit Produk** (multi-foto + foto utama, kategori, harga, stok stepper, berat, deskripsi, kondisi, toggle tayang, simpan draf)

  ![Mockup Form Produk - Bold & Colorful](./shopy-seller/design/assets/produk-form-seller-bold-colorful.png)

  - `screens/product/product_form_screen.dart` — 1 screen dipakai create & edit (`productId` nullable). Foto diupload langsung saat dipilih (bukan ditunda sampai submit) lewat `image_picker` `pickMultiImage`. "Simpan Draf" = `isActive:false`, "Simpan & Tayangkan" = `isActive:true` — reuse field `IsActive` yang sudah ada, tidak perlu status "draft" baru di skema. ⚠️ **Kategori dipilih dari daftar flat** ("Root" kalau tanpa anak, "Root > Anak" kalau ada) hasil gabungan `GET /api/categories` + `GET /api/categories/{slug}` per root — bukan picker 2-langkah drill-down seperti tersirat mockup ("Fashion Pria > Atasan"), karena data kategori seeder cuma 2 level (tidak ada level "Atasan").
- [x] Flutter: halaman **Atur Stok & Harga** (edit cepat massal + banner peringatan stok menipis)

  ![Mockup Atur Stok & Harga - Bold & Colorful](./shopy-seller/design/assets/stok-harga-seller-bold-colorful.png)

  - `screens/product/stock_price_screen.dart` — `TextEditingController` per baris, track produk yang "dirty" buat badge counter di tombol "Simpan Perubahan (N)", submit sekali lewat `PATCH /bulk`.
- ⚠️ **Regresi & verifikasi**: `dotnet build` 0 error. Alur penuh diuji lewat `curl` — buat toko → upload foto produk → buat produk (cek `Store.ProductCount` naik) → filter list per status → toggle aktif/nonaktif → bulk update harga+stok → low-stock → hapus (cek `Store.ProductCount` turun lagi & hilang dari endpoint publik). `GET /api/products` (endpoint lama) tetap 200 dengan produk toko lain tidak terganggu. `flutter analyze` + `flutter test` bersih di `shopy-seller`. Verifikasi visual manual belum dilakukan (sama seperti Fase 1-2).

- [x] Flutter: `productProvider` + `productFormProvider` (Riverpod) + `services/seller_product_api_service.dart`

  - Dikerjakan dengan nama beda dari yang dicatat di checklist ini, tapi fungsinya identik: `providers/seller_product_provider.dart` (`sellerProductsProvider`/`sellerProductDetailProvider`, bukan `productProvider`/`productFormProvider`) + `services/seller_product_api_service.dart` (sudah sesuai). Item ini kelewat dicentang saat Fase 3 selesai — dikerjakan bersamaan dengan item Daftar/Form Produk di atas.

## Fase 4 — Pesanan (SubOrder)

- [x] Backend: **refactor checkout** — `POST /api/orders` mengelompokkan cart item per `StoreId`, membuat 1 `Order` + N `SubOrder`, menghitung ongkir & komisi per toko

  - `Controllers/OrdersController.cs` `Checkout` — `cartItems.GroupBy(ci => ci.Product.StoreId)`, per grup bikin 1 `SubOrder` (`SubOrderNumber = "{OrderNumber}-{seq}"`, `Status=WaitingPayment`, `ShippingCost` = quote kurir default (`Models/Orders/CourierOption.cs`, tabel statis 3 kurir), `CommissionAmount = Subtotal * Platform:CommissionPercent/100`, `SellerEarning = Subtotal+ShippingCost-CommissionAmount`), assign `OrderItem.SubOrderId`. `Order.Status`/`TotalAmount`/`ShippingCost` jadi agregat dari semua `SubOrder` (helper `Services/OrderStatusHelper.cs`). `Models/Order.cs` ditambah nav `ICollection<SubOrder> SubOrders` (perbaikan relasi 1 arah dari Fase 0) + `ShopyDbContext` di-update `.WithMany(o => o.SubOrders)`.
  - Endpoint lama `PATCH /api/orders/{id}/status` (bebas ke status apa pun) **dihapus total**, bukan dibatasi — diganti endpoint baru khusus pembeli di `Controllers/SubOrdersController.cs` (`GET /api/orders/sub-orders`, `GET /api/orders/sub-orders/{id}`, `PATCH /api/orders/sub-orders/{id}/status`, cuma terima `Cancelled` sebelum `Processing` atau `Completed` setelah `Shipped`).
  - `OrderDetailDto` diubah jadi **envelope ringan** (`Status`, `TotalAmount`, `Address`, list `SubOrders`) — rincian per item/ongkir/komisi pindah ke `SubOrderDetailDto` (`Models/Orders/SubOrderDtos.cs`). `GET /api/orders` & `GET /api/orders/{id}` (ringkasan order induk) tetap dipertahankan untuk halaman sukses checkout multi-toko.
- [x] Backend: **kurangi stok** saat sub-order diterima penjual 🐛 (sekarang stok tidak pernah berkurang sama sekali)

  - `Controllers/SellerOrdersController.cs` `Accept` — `Product.Stock -= item.Quantity` saat `NewOrder`→`Processing`. ⚠️ **Restorasi stok saat ditolak/dibatalkan TIDAK diimplementasikan** — dengan alur accept/reject/auto-cancel yang ada sekarang, `reject`/auto-cancel cuma valid dari status `NewOrder` (sebelum stok dikurangi), jadi belum ada skenario nyata yang butuh restorasi. Baru relevan kalau nanti ada alur "batalkan setelah diproses".
- [x] Backend: `GET /api/seller/orders?status=&page=` (tab Baru/Diproses/Dikirim/Selesai) & `GET /api/seller/orders/{id}` (detail + pembeli + alamat + rincian komisi)

  - `Controllers/SellerOrdersController.cs` + `Models/Sellers/SellerOrderDtos.cs`. ⚠️ **Cuma 4 tab** (`new`/`processing`/`shipped`/`completed`) sesuai mockup — tidak ada tab "Batal" terpisah (pesanan `Rejected`/`Cancelled` tidak muncul di tab manapun untuk sekarang, bisa ditambah nanti). Info pembeli ("Bergabung {tahun} - N pesanan") — N dihitung dari jumlah `SubOrder` pembeli itu **di toko ini saja**.
- [x] Backend: `POST /api/seller/orders/{id}/accept` (Baru → Diproses), `POST /api/seller/orders/{id}/reject` (+ alasan, stok dikembalikan), `POST /api/seller/orders/{id}/ship` (kurir + nomor resi + foto bukti opsional → Dikirim)

  - Ketiganya di `SellerOrdersController.cs`, masing-masing mencatat `SubOrderStatusHistory` + panggil `NotifySubOrderStatusChangedAsync` + `RecalculateOrderStatus` (agregat `Order.Status`). ⚠️ "stok dikembalikan" saat reject tidak relevan (lihat poin stok di atas — reject terjadi sebelum stok dikurangi).
  - Kurir **dipilih seller saat kirim** (bukan buyer saat checkout, sesuai mockup Kirim Pesanan) — field `CourierCode`/`CourierService`/`TrackingNumber` murni info pengiriman, tidak mengubah `ShippingCost` yang sudah dibayar buyer.
- [x] Backend: job/pengecekan **auto-cancel** kalau penjual tidak konfirmasi sampai `AutoCancelAt`, dan **auto-complete** X hari setelah `Shipped`

  - `Services/SubOrderAutoTransitionService.cs` (`BackgroundService` baru, `PeriodicTimer` 5 menit, jalan langsung saat start) — auto-reject `NewOrder` yang `AutoCancelAt` lewat, auto-complete `Shipped` yang `ShippedAt + Platform:AutoCompleteDays` lewat. Didaftarkan via `builder.Services.AddHostedService<SubOrderAutoTransitionService>()` di `Program.cs`.
- [x] Backend: setiap transisi status memanggil `INotificationService` ke pembeli (reuse `NotifyOrderStatusChangedAsync`, sesuaikan supaya berbasis sub-order)

  - `INotificationService.NotifyOrderStatusChangedAsync(Order)` diganti `NotifySubOrderStatusChangedAsync(SubOrder, Store)` — body pesan sebut nama toko (mis. `"Pesanan #SHP-...-1 dari Toko A sedang dikirim."`). `Notification.OrderId` tetap dipakai buat deep-link (bukan `SubOrderId` — kolom itu belum ada, tidak nambah migration buat ini).
- [x] Backend: batasi `PATCH /api/orders/{id}/status` versi pembeli — hanya boleh `Cancelled` (sebelum diproses) dan `Completed` (terima barang); perubahan status lain jadi wewenang seller ⚠️ ini mengubah perilaku yang dicatat di TASKS.md Fase 4

  - Endpoint lama dihapus total (lihat poin checkout di atas), diganti `PATCH /api/orders/sub-orders/{id}/status` dengan pembatasan transisi persis seperti ini.
- [x] Backend: ongkir per kurir & berat (menggantikan `FlatShippingCost = 15000`) — minimal tabel tarif statis dulu, integrasi API kurir (RajaOngkir/Biteship) menyusul

  - `Models/Orders/CourierOption.cs` — tabel statis 3 kurir (JNE Reguler Rp15.000/2-3hr, J&T Express Rp14.000/2-4hr, SiCepat REG Rp16.000/1-3hr, sesuai mockup). ⚠️ **Bukan per-berat** — mockup tidak menunjukkan tiering berat, jadi tarif flat per kurir per toko. Checkout auto-quote kurir pertama (JNE Reguler) sebagai default; tabel yang sama juga di-hardcode independen di `shopy-seller` (`models/order/courier.dart`) buat pilihan kurir saat kirim, konsisten dengan pola `kMockShippingCost` sebelumnya.
- [x] Flutter: halaman **Daftar Pesanan** (tab status, countdown batas konfirmasi, tombol Tolak/Proses, tombol Input Resi)

  ![Mockup Daftar Pesanan - Bold & Colorful](./shopy-seller/design/assets/pesanan-list-seller-bold-colorful.png)

  - `shopy-seller/lib/screens/order/order_list_screen.dart` — 4 tab (`ChoiceChip`, pola sama Fase 3), countdown per detik (`Timer.periodic`) buat tab Baru dari `AutoCancelAt`, tombol Tolak (dialog alasan)/Proses Pesanan di tab Baru, tombol "Input Nomor Resi" (buka `ShipOrderScreen`) di tab Diproses.
- [x] Flutter: halaman **Detail Pesanan** (banner status + countdown, kartu pembeli + tombol chat, alamat & kurir, daftar produk, rincian pembayaran + potongan komisi + estimasi masuk saldo, catatan pembeli)

  ![Mockup Detail Pesanan - Bold & Colorful](./shopy-seller/design/assets/pesanan-detail-seller-bold-colorful.png)

  - `shopy-seller/lib/screens/order/order_detail_screen.dart` — banner dinamis per status, tombol Chat (disambungkan di Fase 7), tombol aksi bawah dinamis (Tolak/Proses untuk Baru, Input Resi untuk Diproses).
- [x] Flutter: halaman **Kirim Pesanan** (pilih kurir, input/scan nomor resi, foto bukti serah terima, konfirmasi)

  ![Mockup Kirim Pesanan - Bold & Colorful](./shopy-seller/design/assets/kirim-pesanan-seller-bold-colorful.png)

  - `shopy-seller/lib/screens/order/ship_order_screen.dart` — `RadioGroup<Courier>` pilih kurir dari 3 opsi statis, input resi (tombol Scan placeholder), upload foto opsional lewat `image_picker` + `POST /api/uploads?category=proof` (kategori baru di `UploadsController`), checkbox konfirmasi wajib sebelum submit. Kartu "Pesanan Masuk" baru ditambahkan di `store_profile_screen.dart` (pola sama kartu "Produk Saya" Fase 3) sebagai entry point — bottom nav 5-tab tetap scope Fase 8.
- [x] Perubahan di app pembeli: Keranjang dikelompokkan per toko, Checkout menampilkan ongkir per toko, Riwayat & Detail Pesanan dipecah per toko, dan timeline "Lacak Pesanan" dibaca dari `SubOrderStatusHistories`. Tombol "Lacak Paket" bisa diisi nomor resi asli dari seller.

  - `shopy-mobile`: `CartItem` + `CartItemDto` (backend) ditambah `storeId`/`storeName`. `CartState.storeGroups`/`selectedStoreGroups` (grouping computed di state layer) dipakai `cart_screen.dart` (section per toko) & `checkout_screen.dart` (kartu produk+ongkir per toko, submit tetap 1 `cartItemIds` gabungan — backend yang kelompokkan). `checkout_success_screen.dart` menampilkan "N toko diproses"; tombol "Lihat Pesanan" (di sini, payment-success, & notifikasi berjenis pesanan) diarahkan ke `OrderHistoryScreen` (bukan detail 1 toko spesifik) karena 1 pembayaran/notifikasi order-level bisa mencakup beberapa toko.
  - Model/provider/service baru: `models/order/sub_order_*.dart`, `providers/order_provider.dart` (`subOrderDetailProvider`, `orderHistoryProvider` di-refactor pakai `SubOrderSummary`/`SubOrderStatus`), `services/order_api_service.dart` (`getSubOrders`/`getSubOrderDetail`/`updateSubOrderStatus`). Model lama `OrderSummary`/`OrderStatusHistoryEntry` (order-level, dipakai riwayat lama) dihapus karena sudah tergantikan penuh, bukan didiamkan sebagai dead code.
  - `order_history_screen.dart` — 1 card per `SubOrder` (nama toko ditampilkan), 4 tab sama seperti sebelumnya (`Semua`/`Diproses`/`Dikirim`/`Selesai`) tapi filter sekarang berbasis `SubOrderStatus`. `order_detail_screen.dart` — timeline 5 langkah (`WaitingPayment→NewOrder→Processing→Shipped→Completed`) dari `SubOrderStatusHistories`, tombol "Lacak Paket" menampilkan dialog kurir+resi asli kalau sudah `Shipped`, tombol "Batalkan Pesanan" (`WaitingPayment`/`NewOrder`) atau "Pesanan Diterima" (`Shipped`) sesuai status.
- ⚠️ **Regresi & verifikasi**: `dotnet build` 0 error/warning. Alur penuh diuji lewat `curl` (2 akun seller beda toko + 1 akun buyer baru): checkout keranjang lintas 2 toko → `Order` punya 2 `SubOrder` `WaitingPayment` dgn subtotal/ongkir/komisi benar → simulasi payment settled langsung lewat DB (Midtrans belum dikonfigurasi di dev, sesuai keterbatasan yang sama dari Fase-fase sebelumnya) → `NewOrder`+`AutoCancelAt` terisi → seller A `accept` (stok produk A berkurang sesuai qty) → seller B `reject` (+alasan, stok produk B tidak berubah) → seller A `ship` (+resi) → buyer `PATCH sub-orders/{id}/status` `Completed` → `Order.Status` teragregat benar di tiap langkah (`Pending→Processing→Shipped→Completed`, sesuai `OrderStatusHelper`, campuran `Completed`+`Rejected` tetap dihitung `Completed`). Notifikasi tercatat benar di tiap transisi (isi pesan sebut nama toko). Regresi: `GET /api/products`, `GET /api/stores/{slug}` normal; akun lama tetap bisa lihat riwayat via endpoint baru. 🐛 **1 bug ditemukan & diperbaiki selama verifikasi**: `SubOrdersController.UpdateStatus` pakai `subOrder.StatusHistories.Add(...)` (lewat navigation collection yang sebagian sudah di-`Include` dari 2 jalur berbeda) menyebabkan `DbUpdateConcurrencyException` konsisten saat buyer klik "Pesanan Diterima" — diperbaiki dengan `dbContext.SubOrderStatusHistories.Add(...)` langsung ke `DbSet`, konsisten dengan pola yang sudah dipakai di controller lain. `flutter analyze` + `flutter test` bersih di **kedua** app (`shopy-seller` & `shopy-mobile`). Verifikasi visual manual belum dilakukan (sama seperti fase-fase sebelumnya).

## Fase 5 — Keuangan & Pencairan

- [x] Backend: pembentukan saldo otomatis — saat sub-order `Completed`: catat `BalanceTransactions` `SaleIncome` (+) dan `Commission` (−), pindahkan dari `PendingBalance` ke `AvailableBalance`

  - `Services/StoreBalanceService.cs` (baru, `IStoreBalanceService`) — `SettleAsync(SubOrder)` dipanggil dari 2 titik: buyer `PATCH sub-orders/{id}/status` (`Completed`) di `SubOrdersController`, dan auto-complete `Shipped→Completed` di `SubOrderAutoTransitionService`. Mencatat 2 baris `BalanceTransaction` berurutan dengan `BalanceAfter` snapshot masing-masing: `SaleIncome` (+`Subtotal+ShippingCost`, gross) lalu `Commission` (−`CommissionAmount`) — totalnya pas `SellerEarning`. `StoreBalance.TotalEarning` juga ikut bertambah (penghasilan lifetime).
- [x] Backend: escrow — dana masuk `PendingBalance` saat pembayaran `Settled` (hook di `PaymentsController`/webhook Midtrans yang sudah ada), baru cair setelah pesanan selesai

  - `PaymentsController.ApplyStatusAsync` — `StoreBalanceService.AddPendingAsync(SubOrder)` dipanggil tepat setelah `SubOrder.Status` maju `WaitingPayment→NewOrder`. `PendingBalance` **bukan bagian ledger** (tidak ada baris `BalanceTransaction` untuk ini) — cuma penanda "dana ditahan dari pesanan berjalan", sesuai mockup Keuangan yang cuma menampilkan 1 angka tanpa rincian mutasi.
  - 🐛 **Celah yang diperbaiki**: kalau sub-order yang sudah `Settled` (jadi sudah nambah `PendingBalance`) ternyata dibatalkan (`buyer cancel` dari `NewOrder`) atau ditolak seller (`Reject`, cuma valid dari `NewOrder`) atau auto-reject (`SubOrderAutoTransitionService`), dana yang tertahan itu harus dilepas balik — kalau tidak, `PendingBalance` nyangkut selamanya. Ditangani `StoreBalanceService.ReleasePendingAsync(SubOrder)`, dipanggil dari ketiga titik itu.
- [x] Backend: `GET /api/seller/balance` (saldo tersedia, tertahan, total penghasilan), `GET /api/seller/balance/transactions?type=&page=` (mutasi)

  - `Controllers/SellerFinanceController.cs` (baru, `api/seller/finance`) + `Models/Sellers/SellerFinanceDtos.cs`. `GetBalance` juga menghitung `MonthlyEarning`/`MonthlyCommission`/`CompletedOrderCountThisMonth` on-the-fly dari `BalanceTransaction`/`SubOrder` bulan berjalan (bukan kolom tersimpan). `type` di endpoint transaksi: `income` (`SaleIncome`, tab "Pemasukan") / `withdrawal` (`Withdrawal`+`WithdrawalFee`, tab "Pencairan") / kosong (semua, termasuk baris `Commission` yang cuma muncul di tab ini). ⚠️ **Indikator tren "↑12%"/"↓12%" di mockup tidak diimplementasikan** — murni dekoratif, butuh hitung ulang periode sebelumnya, tidak ada di deskripsi fungsional checklist.
- [x] Backend: `POST /api/seller/withdrawals` (validasi minimal, saldo cukup, rekening terverifikasi, batas per hari), `GET /api/seller/withdrawals`

  - Validasi: rekening milik toko sendiri & `IsVerified`, `Amount >= Platform:MinWithdrawal` (Rp50.000), `Amount <= AvailableBalance`, jumlah pencairan toko ini **hari ini** `< Platform:MaxWithdrawalsPerDay` (baru, default 3, sesuai "maksimal 3x pencairan per hari" di mockup). Berhasil → `AvailableBalance -= Amount`, `Withdrawal` baru `Status=Pending`, 2 baris ledger `Withdrawal` (−`NetAmount`) + `WithdrawalFee` (−`AdminFee`, dari `Platform:WithdrawalAdminFee` Rp2.500) — memanfaatkan enum `WithdrawalFee` yang sejak Fase 0 belum pernah dipakai.
  - ⚠️ **`BankAccount.IsVerified` di-auto-`true` saat dibuat** (`SellerBankAccountsController.CreateBankAccount`, sebelumnya selalu `false`) — deviasi sadar, tidak ada alur verifikasi admin sampai Fase 9, kalau tetap `false` fitur pencairan tidak akan pernah bisa dites/dipakai. Validasi `IsVerified` di endpoint withdrawal tetap dipertahankan (bukan dihapus).
  - **Tidak ada disbursement beneran** — `Withdrawal` tetap `Status=Pending` selamanya di fase ini, diproses manual admin di Fase 9 (lihat catatan asli di bawah, tetap berlaku).
- [x] Backend: `GET /api/seller/reports/earnings?from=&to=` + ekspor CSV ("Unduh Laporan")

  - `SellerFinanceController.GetEarningsReport` — return file CSV langsung (`Tanggal,Tipe,Deskripsi,Jumlah,Saldo Setelah`), filter tanggal opsional. 🐛 **Bug ditemukan & diperbaiki saat verifikasi**: angka desimal awalnya di-render pakai koma sebagai pemisah desimal (locale server, bukan `en-US`) — misal `215000,00` — yang bentrok dengan koma pemisah kolom CSV dan merusak strukturnya. Diperbaiki dengan `.ToString(CultureInfo.InvariantCulture)` eksplisit untuk kolom `Jumlah`/`Saldo Setelah`.
  - Di sisi `shopy-seller`, tombol **"Unduh Laporan" tetap snackbar placeholder** ("belum tersedia") — tidak ada `url_launcher`/file-download package terpasang, konsisten dengan tombol placeholder lain (Scan/Chat) dan menghindari nambah dependency baru di luar scope fase ini.
- [x] Flutter: halaman **Keuangan** (kartu saldo, ringkasan penghasilan/komisi/pesanan selesai, filter mutasi, daftar mutasi saldo)

  ![Mockup Keuangan - Bold & Colorful](./shopy-seller/design/assets/keuangan-seller-bold-colorful.png)

  - `shopy-seller/lib/screens/finance/finance_screen.dart` — kartu saldo oranye + tombol "Cairkan Dana", 3 kartu stat (tanpa indikator tren, lihat catatan di atas), filter chip Semua/Pemasukan/Pencairan, list mutasi (panah hijau turun = pemasukan, panah merah naik = pengeluaran, warna diambil dari tanda `amount`).
- [x] Flutter: halaman **Pencairan Dana** (jumlah + cairkan semua, rekening tujuan, rincian biaya admin, info estimasi, riwayat pencairan)

  ![Mockup Pencairan Dana - Bold & Colorful](./shopy-seller/design/assets/pencairan-seller-bold-colorful.png)

  - `shopy-seller/lib/screens/finance/withdrawal_screen.dart` — reuse `bankAccountsProvider` (Fase 2) buat pilih rekening tujuan (bottom sheet "Ubah" kalau rekening >1), rincian biaya admin dihitung real-time client-side dari konstanta `kWithdrawalAdminFee` (cerminan `Platform:WithdrawalAdminFee`, sama pola dengan `kMockShippingCost`/tabel kurir Fase 4 — backend tetap sumber kebenaran akhir saat submit), riwayat pencairan dengan badge status (`Pending`/`Processing`→kuning, `Completed`→hijau "Berhasil", `Rejected`→merah). Menu "Keuangan & Pencairan" di `store_profile_screen.dart` (`_MenuCard`) sekarang diarahkan ke `FinanceScreen` (sebelumnya `onNotAvailable`).
- ⚠️ Pencairan **beneran** ke rekening butuh layanan disbursement (Midtrans Iris / Xendit Disbursement) yang berbeda dari Core API pembayaran yang sudah dipakai. Untuk sekarang cukup sampai status `Pending`/`Processing` yang diproses manual oleh admin (Fase 9), sama polanya seperti `Midtrans:ServerKey` yang masih kosong di TASKS.md Fase 5.
- ⚠️ **Regresi & verifikasi**: `dotnet build` 0 error/warning. Alur penuh diuji lewat `curl` (seller+buyer baru): checkout → simulasi settle → `GET balance` (`pendingBalance` sesuai `SellerEarning`) → accept→ship→buyer `Completed` → `GET balance` (`availableBalance` naik, `pendingBalance` balik 0, `totalEarning`/`monthlyEarning`/`monthlyCommission`/`completedOrderCountThisMonth` benar) → `GET transactions` 2 baris `SaleIncome`+`Commission` dengan `BalanceAfter` benar → withdrawal di bawah minimal (400) → withdrawal wajar (sukses, `availableBalance` berkurang persis, 2 baris ledger `Withdrawal`+`WithdrawalFee`) → withdrawal melebihi saldo (400) → skenario kedua: settle sub-order lain lalu seller `reject` sebelum `Completed` → `pendingBalance` balik ke 0 tanpa mengganggu `availableBalance` (verifikasi `ReleasePendingAsync`) → `GET reports/earnings` CSV valid (setelah fix locale). Regresi: `GET /api/products` normal. `flutter analyze` + `flutter test` bersih di `shopy-seller`. Verifikasi visual manual belum dilakukan (sama seperti fase-fase sebelumnya).

## Fase 6 — Promo & Voucher Toko

- [x] Backend: CRUD voucher toko `GET/POST/PUT/DELETE /api/seller/vouchers` + `PATCH .../active`

  - `Controllers/SellerVouchersController.cs` (baru) + `Models/Sellers/VoucherDtos.cs`. `VoucherDto` juga membawa `Status` terhitung (`Active`/`Scheduled`/`Ended`/`Inactive` — dari tanggal+kuota, independen dari toggle `IsActive`) dan `TotalDiscountGiven`/`TotalOrderValue` (agregat `VoucherUsage`, buat tombol "Statistik" di mockup).
- [x] Backend: validasi & penerapan voucher di checkout (`POST /api/vouchers/validate` untuk app pembeli) — cek kuota, periode, minimal belanja, 1 voucher per toko per transaksi, catat ke `VoucherUsages`

  - `Services/VoucherValidationHelper.cs` (logika validasi+hitung diskon, dipakai identik oleh `Controllers/VouchersController.cs` (`POST /api/vouchers/validate`, buyer-facing) dan `OrdersController.Checkout` — checkout **tidak pernah percaya angka diskon dari client**, selalu re-validasi server-side per grup toko sebelum menerapkan). `CheckoutRequest` (`Models/Orders/OrderDtos.cs`) ditambah `Vouchers` (opsional, `{StoreId, Code}` per toko — kalau ada duplikat untuk toko yang sama, yang pertama dipakai). **Voucher = diskon yang ditanggung seller, bukan Shopy** — `SubOrder.VoucherDiscount` mengurangi `SellerEarning`, tapi `CommissionAmount` tetap dihitung dari `Subtotal` asli (Shopy tetap dapat komisi penuh). Untuk `VoucherType.FreeShipping`, `VoucherDiscount = min(Value, ShippingCost)`.
- [x] Backend: diskon produk (harga coret) — `PATCH /api/seller/products/{id}/discount` mengisi `DiscountPrice` + periode; DTO produk publik mengembalikan harga asli & harga diskon

  - `Services/PricingHelper.cs` (`EffectivePrice`/`IsDiscounted`, dipakai identik oleh `ProductsController` publik, `CartController`, dan `OrdersController.Checkout` supaya diskon otomatis berlaku konsisten di katalog, keranjang, dan checkout). `ProductListItemDto`/`ProductDetailDto`/`CartItemDto` ditambah `OriginalPrice` (nullable, cuma keisi kalau sedang diskon) — `Price` yang dikembalikan selalu harga efektif, jadi kode lama yang baca `Price` tidak perlu berubah.
- [ ] Backend: flash sale terjadwal (opsional) — `FlashSales`/`FlashSaleItems` + endpoint publik "sedang berlangsung"

  - ⚠️ **Dilewati sepenuhnya di fase ini** — eksplisit ditandai "(opsional)" di checklist sendiri, dan cakupan fase ini sudah besar (voucher penuh + diskon produk + integrasi checkout 2 app). Skema (`FlashSale`/`FlashSaleItem`) tetap ada dari Fase 0, tinggal diisi kalau nanti dibutuhkan. Tab "Flash Sale" di halaman Promo & Voucher ditampilkan sebagai placeholder ("belum tersedia").
- [x] Backend: statistik pemakaian voucher (dipakai berapa kali, omzet yang dihasilkan)

  - Disisipkan langsung ke `VoucherDto` (`TotalDiscountGiven`/`TotalOrderValue`, dihitung on-the-fly dari `VoucherUsage` tiap kali diambil) — bukan endpoint/halaman statistik terpisah, cukup buat tombol "Statistik" di mockup yang cuma butuh angka ringkas.
- [x] Flutter: halaman **Promo & Voucher** (tab Voucher Toko / Diskon Produk / Flash Sale, kartu voucher + progress kuota, aktif/nonaktifkan, buat voucher baru)

  ![Mockup Promo & Voucher - Bold & Colorful](./shopy-seller/design/assets/promo-voucher-seller-bold-colorful.png)

  - `shopy-seller/lib/screens/promo/promo_voucher_screen.dart` — 3 tab. **Voucher Toko**: kartu voucher (status badge, progress bar kuota, toggle `IsActive`, tombol Ubah/Statistik), tombol "Buat Voucher Baru". **Diskon Produk**: reuse `sellerProductsProvider` (Fase 3), tiap produk tampilkan harga coret kalau sedang diskon + tombol Atur/Ubah Diskon → `product_discount_sheet.dart` (bottom sheet set/ubah/hapus). **Flash Sale**: placeholder.
- [x] Flutter: form Buat/Ubah Voucher (kode, tipe, nilai, maksimal diskon, minimal belanja, kuota, periode)

  - `shopy-seller/lib/screens/promo/voucher_form_screen.dart` — 1 screen dipakai create & edit (pola sama `ProductFormScreen` Fase 3), field maksimal diskon disembunyikan untuk tipe `FreeShipping`. Menu "Promo & Voucher" di `store_profile_screen.dart` diarahkan ke halaman ini (sebelumnya `onNotAvailable`).
- [x] Perubahan di app pembeli: kode promo masih di-hardcode di Flutter (`kMockPromoCode = 'HEMAT20'` di `providers/cart_provider.dart`, dipakai `widgets/cart/promo_code_section.dart`) — ganti dengan panggilan ke endpoint validasi voucher. Kartu produk & Detail Produk perlu menampilkan harga coret (TASKS.md Fase 2 sudah mencatat ini sebagai bagian mockup yang dilewati karena field diskon belum ada).

  - `kMockPromoCode`/`kMockPromoDiscount`/`applyPromoCode`/`clearPromo`/`hasPromo`/`promoCode`/`promoDiscount` **dihapus** dari `cart_state.dart`/`cart_provider.dart` (bukan didiamkan) — begitu juga file `widgets/cart/promo_code_section.dart` dan pemakaiannya di `cart_screen.dart`/`checkout_summary_sheet.dart`. ⚠️ **Voucher pindah dari Keranjang (1 kode global) ke Checkout (per toko)** — karena `Voucher` scope-nya per `StoreId` sejak awal, dan sejak Fase 4 checkout sudah dikelompokkan per toko. Tiap `_StoreOrderGroup` di `checkout_screen.dart` sekarang punya bagian "Punya kode voucher toko ini?" sendiri (dialog input → `POST /api/vouchers/validate` dengan `StoreId` grup itu), state lokal `Map<storeId, (code, discountAmount)>` dikirim sebagai `vouchers` saat submit.
  - `models/catalog/product_summary.dart`/`product_detail.dart`/`models/cart/cart_item.dart` ditambah `originalPrice` nullable + getter `isDiscounted` — kartu produk (Home/Search), Detail Produk, dan `CartItemCard` menampilkan harga asli dicoret di atas harga efektif kalau sedang diskon.
- ⚠️ **Regresi & verifikasi**: `dotnet build` 0 error/warning. Alur penuh diuji lewat `curl`: seller set diskon produk (100rb→80rb) → `GET /api/products` publik & keranjang tampilkan harga diskon+`originalPrice` benar → seller buat voucher `FixedAmount` (min. belanja, kuota 2) → `POST /api/vouchers/validate` (subtotal kurang dari minimal → invalid; cukup → valid+jumlah benar) → checkout dengan voucher → `SubOrder.VoucherDiscount`/`SellerEarning`/`Order.TotalAmount` benar (komisi tetap dihitung dari subtotal asli), `Voucher.UsedCount` naik, `VoucherUsage` tercatat → settle→accept→ship→buyer `Completed` → `GET /api/seller/finance/balance` & mutasi saldo (Fase 5) mencerminkan `SellerEarning` net-diskon dengan benar → checkout ke-2 pakai kode sama (kuota jadi 2/2) → checkout ke-3 dengan kode sama ditolak `400` ("Kuota voucher sudah habis") → `GET /api/seller/vouchers/{id}` tampilkan statistik terhitung benar. Regresi: `GET /api/products` normal untuk produk tanpa diskon. `flutter analyze` + `flutter test` bersih di **kedua** app. Verifikasi visual manual belum dilakukan (sama seperti fase-fase sebelumnya).

## Fase 7 — Chat & Ulasan ✅

- [x] Backend: `GET /api/seller/chats` (daftar room + unread), `GET /api/seller/chats/{roomId}/messages?before=`, `POST /api/seller/chats/{roomId}/messages`, `POST /api/seller/chats/{roomId}/read` — `SellerChatsController`, semua scoped by `GetMyStoreIdAsync()`.
- [x] Backend: sisi pembeli `POST /api/chats` (buka/ambil room dengan toko tertentu, find-or-create via unique index `(StoreId,BuyerUserId)`) + `GET/POST {roomId}/messages`, `POST {roomId}/read` — `ChatsController`.
- [x] Backend: lampiran pesan berupa produk atau pesanan (`ProductId`/`SubOrderId` di `ChatMessages`), gambar lewat `UploadsController` kategori `"chat"` baru (image-only).
- [x] Backend: realtime — **dipilih fallback polling 5 detik + push FCM** (bukan SignalR), sesuai catatan checklist sendiri; tidak ada infrastruktur realtime di project ini dan menambahkannya di luar scope fase yang sudah menggabungkan 2 fitur besar. Indikator "online"/typing di mockup **tidak diimplementasikan** (butuh koneksi persisten). Read-receipt (centang 1/2) tetap jalan karena murni `ChatMessage.ReadAt != null`. Logika kirim pesan (bikin `ChatMessage`, update `UnreadCount`/`LastMessagePreview`, kirim push) dipusatkan di `Services/ChatService.cs` dipakai identik oleh `ChatsController` & `SellerChatsController`. Push chat dikirim langsung lewat `IPushNotificationService` tanpa baris `Notification` DB — perluasan `NotificationType` (`NewChat`, dst) sengaja disisakan untuk Fase 8.
- [x] Backend: **ReviewsController** — `GET /api/products/{id}/reviews` (publik), `POST /api/orders/{subOrderId}/reviews` (pembeli, hanya pesanan `Completed` miliknya, produk harus ada di sub-order itu), hitung ulang `Product.RatingAverage`/`RatingCount` & `Store.RatingAverage`/`RatingCount` lewat `Services/ReviewAggregationHelper.cs`. Deviasi: dedup ulasan dipakai **per `(ProductId, UserId)`** (1 ulasan per pembeli per produk selamanya), bukan per sub-order — mengikuti unique index asli di `Review` yang ditemukan saat implementasi (409 kalau sudah pernah menilai produk itu, dari order manapun).
- [x] Backend: `GET /api/seller/reviews/summary` (rata-rata, total, belum dibalas, distribusi bintang %) + `GET /api/seller/reviews?filter=belum-dibalas|1..5` + `POST /api/seller/reviews/{id}/reply` — `SellerReviewsController`.
- [x] Flutter (shopy-seller): halaman **Daftar Chat** (`screens/chat/chat_list_screen.dart`) + **Ruang Chat** (`chat_room_screen.dart`: bubble, status terkirim/dibaca, balasan cepat statis client-side, lampiran gambar via `image_picker` & produk via bottom sheet `sellerProductsProvider`, polling 5 detik).
- [x] Flutter (shopy-seller): halaman **Ulasan Produk** (`screens/review/review_list_screen.dart`: kartu ringkasan + distribusi bintang, filter chip Semua/Belum Dibalas/1-5★, form balas inline). Kedua halaman disambungkan lewat kartu "Chat" & menu "Ulasan Produk" di `store_profile_screen.dart`.
- [x] Flutter (shopy-mobile): tombol **"Hubungi Penjual"** (`order_detail_screen.dart`) & tombol **"Chat"** baru (`screens/stores/store_profile_screen.dart`) buka/ambil room lalu push ke `ChatRoomScreen` versi ringan (teks+gambar saja, tanpa lampiran produk/quick-reply).
- [x] Flutter (shopy-mobile): section **"Beri Ulasan"** per item di `order_detail_screen.dart` saat `SubOrder.Status == Completed` — pakai `SubOrderDetailDto.ReviewedProductIds` (field baru) untuk toggle tombol "Beri Ulasan" (bottom sheet: star picker + komentar + 1 foto opsional) vs label "✓ Sudah Dinilai".
- [x] Flutter (shopy-mobile): Halaman Detail Produk sekarang menampilkan daftar ulasan asli (`GET /api/products/{id}/reviews`, paginated "Muat Lebih Banyak"), menggantikan placeholder teks lama.
- [x] Tambahan (di luar plan awal, ditemukan saat menyambungkan Flutter): tombol Chat di `shopy-seller/screens/order/order_detail_screen.dart` (kartu pembeli, sejak Fase 4 masih placeholder "belum tersedia") ikut disambungkan — seller tidak bisa membuat room baru (hanya pembeli yang memulai lewat `POST /api/chats`), jadi ditambah `GET /api/seller/chats/by-buyer/{buyerUserId}` (cari room yang sudah ada dengan pembeli itu, 404 kalau pembeli itu belum pernah chat) dan `BuyerInfoDto` (`Models/Sellers/SellerOrderDtos.cs`) ditambah `UserId`.

## Fase 8 — Dashboard, Statistik & Notifikasi ✅

- [x] Backend: `GET /api/seller/dashboard` (`SellerDashboardController`) — saldo (`StoreBalance`), ringkasan hari ini (pesanan baru = live count `Status==NewOrder`; produk terjual & penghasilan = scoped `SubOrder.CreatedAt` hari ini, exclude Cancelled/Rejected; pengunjung toko = lihat deviasi `ViewCount` di bawah), "perlu ditindaklanjuti" (pesanan baru/siap dikirim/stok menipis/ulasan belum dibalas), `sales7Days` per-hari.
- [x] Backend: `GET /api/seller/statistics?period=7d|30d|90d` (`SellerStatisticsController`) — omzet/pesanan/produk terjual/rata-rata order + delta% vs periode sebelumnya yang sama panjang, `dailySeries` harian, `topProducts` top 5 (quantitySold+revenue).
- [x] Backend: `Product.ViewCount` (kolom sudah ada sejak awal, belum pernah di-increment) — sekarang di-increment di `ProductsController.GetBySlug`. Deviasi: "Pengunjung Toko" di dashboard = `SUM(ViewCount)` **kumulatif**, bukan harian — tidak ada tabel log kunjungan per-hari di skema dan menambahnya di luar scope fase ini.
- [x] Backend: `NotificationType` diperluas — `NewOrder`, `PaymentReceived`, `LowStock`, `NewReview`, `NewChat`, `Withdrawal`, `VoucherQuota` (migration `AddSellerNotifications`, disimpan sebagai string jadi append-only aman) — dan `Notification.StoreId` (nullable FK, null untuk notifikasi buyer lama). `NotificationsController` (`api/notifications`) di-reuse apa adanya untuk seller (filter `UserId` sudah otomatis benar).
- [x] Backend: push ke device seller — `DeviceToken.AppType` (`Buyer`/`Seller`, default `Buyer` biar data lama valid) ditambah, `POST /api/device-tokens` terima field `appType` opsional. `NotificationService` dapat 6 method baru (`NotifyNewOrderAsync`, `NotifyPaymentReceivedAsync`, `NotifyLowStockAsync`, `NotifyNewReviewAsync`, `NotifyNewChatAsync`, `NotifyVoucherQuotaAsync`) lewat helper bersama `SendToStoreOwnerAsync` yang insert baris `Notification` + push ke token ber-`AppType=Seller` milik pemilik toko. Dihubungkan ke titik yang sudah ada: `PaymentsController.ApplyStatusAsync` (NewOrder+PaymentReceived, saat sub-order settle), `SellerOrdersController.Accept` (LowStock, setelah stock dikurangi ≤10), `ReviewsController.CreateReview` (NewReview), `ChatService.SendMessageAsync` cabang buyer→seller (NewChat — cabang seller→buyer sengaja **tidak diubah**, tetap direct-push tanpa baris `Notification` seperti keputusan Fase 7, karena buyer belum punya notification-center), `OrdersController.Checkout` (VoucherQuota, dikumpulkan lalu dikirim **setelah** `SaveChangesAsync` final supaya tidak ada partial-commit kalau toko lain di checkout multi-toko gagal validasi).
  - `NotifyWithdrawalCompletedAsync` **dibuat tapi belum ada pemanggil** — pemrosesan withdrawal (`PATCH /api/admin/withdrawals/{id}`) itu eksplisit item Fase 9, jadi tidak bisa diverifikasi end-to-end sekarang.
  - Semua 6 trigger aktif diverifikasi end-to-end via curl (checkout→voucher quota, webhook settle→NewOrder+PaymentReceived, accept→LowStock, review→NewReview, chat→NewChat, plus regresi cabang seller→buyer chat tetap tidak bikin baris `Notification`).
- [x] Flutter: halaman **Dashboard/Beranda** (`screens/dashboard/dashboard_screen.dart`) — kartu saldo + tombol Cairkan Dana, ringkasan hari ini 4 kartu, perlu ditindaklanjuti 4 baris (navigasi ke `OrderListScreen`/`ProductListScreen`/`ReviewListScreen` dengan filter awal — lihat catatan `initialStatus`/`initialFilter` di bawah), grafik 7 hari (`fl_chart`, sudah ada di pubspec sejak awal tapi belum pernah dipakai).

  ![Mockup Dashboard - Bold & Colorful](./shopy-seller/design/assets/dashboard-seller-bold-colorful.png)

- [x] Flutter: halaman **Statistik Penjualan** (`screens/statistics/statistics_screen.dart`) — filter periode chip, 4 kartu metrik + delta (panah naik/turun hijau/merah), grafik omzet harian (`fl_chart`), produk terlaris top 5.

  ![Mockup Statistik - Bold & Colorful](./shopy-seller/design/assets/statistik-seller-bold-colorful.png)

- [x] Flutter: halaman **Notifikasi Seller** (`screens/notifications/notification_history_screen.dart`, port dari punya buyer) — group Hari Ini/Kemarin, penanda belum dibaca, tandai semua dibaca. Deviasi: filter kategori disederhanakan jadi 3 chip (Semua/Pesanan/Keuangan) sesuai mockup — `Pesanan` = `NewOrder`, `Keuangan` = `PaymentReceived`+`Withdrawal`; 4 tipe lain (`LowStock`/`NewReview`/`NewChat`/`VoucherQuota`) cuma muncul di "Semua", tidak match chip manapun.
  ![Mockup Notifikasi - Bold & Colorful](./shopy-seller/design/assets/notifikasi-seller-bold-colorful.png)

- [x] Flutter: banner notifikasi foreground — `widgets/notification/in_app_notification_banner.dart` + `notification_banner_host.dart`, port 1:1 dari app pembeli (dibungkus lewat `builder:` di `main.dart`), ditambah `notification_type_style.dart` (ikon+warna per `NotificationType`, dipakai identik oleh banner & kartu riwayat).
- [x] Tambahan (di luar checklist asli, dibutuhkan supaya dashboard & notifikasi punya rumah): bottom nav **5 tab** baru (`screens/shell/seller_home_shell.dart` — Beranda/Produk/Pesanan/Chat/Toko, badge merah di tab Pesanan & Chat) menggantikan navigasi push-only dari `StoreProfileScreen` yang jadi satu-satunya halaman utama sejak Fase 0. `post_auth_router.dart` diarahkan ke shell ini untuk toko `Active`; `StoreProfileScreen` ditrim (kartu Pesanan Masuk/Chat/Produk Saya dihapus karena sudah jadi tab sendiri) dan 2 menu placeholder terakhirnya ("Statistik Penjualan", "Pengaturan Notifikasi" → "Notifikasi") disambungkan.
- [x] Tambahan kecil: `OrderListScreen`/`ReviewListScreen` (shopy-seller) ditambah parameter opsional `initialStatus`/`initialFilter` supaya baris "Perlu Ditindaklanjuti" di dashboard bisa deep-link ke tab yang relevan. "Stok produk menipis" mengarah ke `ProductListScreen` polos (tidak ada tab low-stock di layar itu — di luar scope menambah tab baru ke layar Fase 3).
- ⚠️ Firebase: `shopy-seller` **belum didaftarkan** sebagai aplikasi kedua di project Firebase yang sama dengan `shopy-mobile` — perlu `flutterfire configure` (menghasilkan `shopy-seller/lib/firebase_options.dart`, `google-services.json`, dll.) dijalankan manual oleh user (butuh akses akun/CLI Firebase, di luar kemampuan sesi ini). Sudah dibuat `shopy-seller/lib/firebase_options.dart` **placeholder** (`REPLACE_ME`) supaya kode compile — `PushNotificationService.initialize()` gagal dengan aman & no-op sampai file itu diganti asli, sisa app tetap berfungsi normal. Semua kode push lainnya (`NotificationService`, `AppType`, dst.) sudah app-agnostic dan siap jalan begitu file itu diganti, tanpa perubahan kode lagi.

## Fase 9 — Admin & Moderasi (minimal) ✅

- [x] Backend: `[Authorize(Roles = "Admin")]` — `AdminStoresController` (`api/admin/stores`): `GET ?status=`, `POST {id}/approve` (Pending→Active), `POST {id}/reject` (body `{reason}`, Pending→Rejected), `POST {id}/suspend` (body `{reason?}`, Active→Suspended), `POST {id}/activate` (Suspended→Active). Migration nambah `StoreStatus.Rejected` (disimpan string, append aman) + `Store.ModerationReason` (dipakai bareng reject & suspend, dikosongkan lagi saat activate).
- [x] Backend: proses pencairan — `AdminWithdrawalsController` `PATCH /api/admin/withdrawals/{id}` body `{status, reason?}` → `Processing`/`Completed`/`Rejected`. Ditemukan saat implementasi: dana withdrawal sudah dipotong dari `StoreBalance.AvailableBalance` sejak seller **request** (bukan saat admin approve, lihat `SellerFinanceController.RequestWithdrawal`) — jadi `Processing`/`Completed` cuma ubah status, sedangkan `Rejected` **refund** penuh (`Amount`) balik ke saldo toko + baris `BalanceTransaction` `Type=Refund` (enum sudah ada). `Completed` memanggil `NotifyWithdrawalCompletedAsync` — **menutup gap dari Fase 8** (method itu dibuat di sana tapi belum ada pemanggil).
- [x] Backend: moderasi produk & ulasan — `AdminModerationController`: `POST /api/admin/products/{id}/takedown`, `POST /api/admin/reviews/{id}/takedown`. Reuse 100% mekanisme soft-delete (`ISoftDeletable` + global query filter) yang sudah ada — sama persis dengan `DELETE /api/seller/products/{id}` milik seller sendiri, cuma di-trigger admin. Takedown ulasan juga memanggil `ReviewAggregationHelper.RecalculateProductRatingAsync`/`RecalculateStoreRatingAsync` (helper Fase 7). Tidak ada kolom baru sama sekali untuk item ini.
- [x] Backend: **`POST /api/notifications/promo` dikunci ke role Admin** — sebelumnya terbuka buat user manapun yang login.
- [x] Backend: pengaturan platform — tabel baru `PlatformSettings` (1 baris singleton) + `IPlatformSettingsService` (`GetAsync`/`UpdateAsync`), `AdminSettingsController` (`GET`/`PUT /api/admin/settings`). Menggantikan 6 titik baca `IConfiguration:Platform:*` yang sebelumnya statis (`OrdersController`, `PaymentsController`, `SellerFinanceController` ×3, `SubOrderAutoTransitionService`) + 2 titik hardcode `LowStockThreshold=10` dari Fase 8 (`SellerDashboardController`, `SellerOrdersController.Accept`) — baris pertama dibuat otomatis dari default `appsettings.json` yang sudah ada, jadi tidak ada perubahan perilaku sampai admin benar-benar ubah sesuatu. `SellerProductsController.GetLowStock`'s `threshold` query-param **sengaja tidak diubah** (itu filter ad-hoc seller sendiri, bukan aturan platform).
- [x] Diuji lewat Swagger/curl + akun admin yang di-seed — **tidak ada dashboard admin (web)**, sesuai cakupan dokumen ini.
  - `Data/AdminSeeder.cs` (baru, dev-only, pola sama `CatalogSeeder.EnsureDemoStoreAsync`): akun `admin-demo@shopy.com` / `AdminDemo1234!` (role Admin), dipanggil di `Program.cs` bareng seeding dev lainnya.
  - Diverifikasi end-to-end via curl: toko Pending→approve (langsung kebuka publik)/reject+alasan/suspend+alasan (langsung tertutup dari publik)→activate; withdrawal request→Processing→Completed (baris `Notification` `Type=Withdrawal` muncul, gap Fase 8 tertutup) dan request kedua→Rejected (saldo balik persis ke jumlah sebelum request + baris `BalanceTransaction` `Refund`); takedown ulasan (rating produk recalculate ke 0) lalu takedown produk (hilang dari endpoint publik, 404); kunci promo (403 non-admin, 200 admin); ubah `CommissionPercent` lewat `PUT /api/admin/settings` lalu checkout baru → `SubOrder.CommissionAmount` langsung pakai persentase baru tanpa redeploy.

## Fase 10 — Polish & Testing

- [ ] Review & rapikan UI/UX semua halaman seller (bandingkan dengan mockup)
- [ ] Unit test backend: pemecahan sub-order, perhitungan komisi & saldo, validasi voucher, transisi status pesanan
- [ ] Widget/integration test Flutter seller
- [ ] Testing manual end-to-end: buka toko → verifikasi → tambah produk → pembeli checkout → seller terima → kirim resi → pembeli selesaikan → saldo masuk → ajukan pencairan
- [ ] Uji lintas-app: pastikan app pembeli (`shopy-mobile`) tetap jalan setelah refactor `StoreId` & `SubOrders`
- [ ] Seed data demo seller untuk pengembangan (mirip `CatalogSeeder`)
- [ ] Perbaikan bug hasil testing

## Fase 11 — Rilis

- [ ] App icon & splash screen final app seller (bedakan dari app pembeli, mis. logo dengan aksen "Seller")
- [ ] Build release (Android APK/AAB, iOS jika perlu)
- [ ] Deploy backend versi baru + jalankan migration di server
- [ ] Submit ke Play Store sebagai aplikasi terpisah
- [ ] Dokumentasi akhir & update README (tambahkan `shopy-seller/` ke struktur proyek)

---

## Catatan Teknis

**Akun test (dari TASKS.md):**

```
test@shopy.com
Test1234!
```

**Akun demo dev-only lain (dibuat seeder, cuma jalan di `Environment.IsDevelopment()`):**

```
seller-demo@shopy.com / SellerDemo1234!   (role Seller, CatalogSeeder)
admin-demo@shopy.com  / AdminDemo1234!    (role Admin, AdminSeeder — Fase 9)
```

**Struktur monorepo setelah Fase 0:**

```
shopy/
├── assets/                 # Logo & aset bersama
├── shopy-mobile/           # App Flutter pembeli (sudah ada)
├── shopy-seller/           # App Flutter penjual (baru)
│   ├── lib/
│   └── design/assets/      # Mockup UI seller
├── shopy-api/              # Backend .NET Core (dipakai bersama)
├── TASKS.md                # Tahap pengerjaan sisi pembeli
├── TASKSELLER.md           # Dokumen ini
└── README.md
```

**Urutan pengerjaan yang disarankan:** Fase 0 → 1 → 3 → 4 adalah jalur kritis (toko → role → produk → pesanan). Fase 5-8 bisa dikerjakan paralel setelah Fase 4 selesai. Fase 9 boleh menyusul belakangan karena bisa disiasati lewat Swagger.

**Mockup:** semua gambar di `shopy-seller/design/assets/` memakai gaya **Bold & Colorful** yang sama dengan app pembeli (primary `#FF6B35`, Poppins, kanvas 750×2160). Script generatornya ada di `shopy-seller/design/` (`mockup_lib.py`, `screens_a.py`, `screens_b.py`) kalau nanti perlu diubah.

---

**Cara pakai file ini:** centang `[ ]` jadi `[x]` setiap task selesai. Tulis catatan implementasi & peringatan (⚠️) di bawah task terkait, sama seperti gaya TASKS.md, supaya konteksnya tidak hilang.
