# Tahap Pengerjaan Shopy Admin

Breakdown detail tahap pengerjaan **app admin** Shopy. Dokumen ini melanjutkan [TASKS.md](./TASKS.md) (sisi pembeli) dan [TASKSELLER.md](./TASKSELLER.md) (sisi penjual, termasuk Fase 9 — Admin & Moderasi backend) dan memakai gaya penulisan yang sama: centang `[ ]` jadi `[x]` setiap task selesai, catat keputusan/penyimpangan dengan ⚠️ di bawah task terkait.

**Keputusan arsitektur yang sudah diambil:**

- **App terpisah** — folder baru `shopy-admin/` di monorepo yang sama (bukan mode di dalam app seller/pembeli), pola identik `shopy-seller/`.
- **Backend admin sebagian besar sudah ada** (TASKSELLER.md Fase 9) — dokumen ini fokus **membangun UI Flutter-nya** + **menutup beberapa gap backend** yang baru kelihatan begitu UI-nya benar-benar mau dipakai (lihat audit di bawah).
- **Tidak ada mockup PNG siap pakai** untuk app ini (beda dari `shopy-mobile`/`shopy-seller` yang punya folder `design/assets/` bergaya "Bold & Colorful") — layout tiap halaman didesain bebas pakai token desain yang sama (`AppColors`/`AppTypography`/`AppSpacing`/`AppTheme`, disalin dari `shopy-seller`).
- **Cakupan:** verifikasi toko, pencairan dana, moderasi produk & ulasan, pengaturan platform, broadcast promo. **Di luar cakupan** (dicatat eksplisit di Fase 9 TASKSELLER.md, tetap berlaku di sini): disbursement bank sungguhan (Midtrans Iris/Xendit), manajemen akun user individual (ban/suspend user yang bukan konteks toko), dashboard statistik lintas-platform (GMV total, dst).

---

## Kondisi Saat Ini (hasil audit kode)

Yang **sudah ada** dan bisa dipakai ulang: role `Admin` ter-seed (`Data/RoleSeeder.cs`), akun demo `admin-demo@shopy.com` (`Data/AdminSeeder.cs`), JWT sudah menyisipkan claim `role` sejak TASKSELLER.md Fase 1, dan 4 controller backend `[Authorize(Roles = "Admin")]` lengkap dari **TASKSELLER.md Fase 9**:

- `AdminStoresController` (`api/admin/stores`) — `GET ?status=`, `POST {id}/approve`, `POST {id}/reject` (+alasan), `POST {id}/suspend` (+alasan), `POST {id}/activate`.
- `AdminWithdrawalsController` (`api/admin/withdrawals`) — `GET ?status=`, `PATCH {id}` (`Processing`/`Completed`/`Rejected` +alasan, otomatis refund saldo kalau ditolak, otomatis kirim notifikasi ke seller kalau selesai).
- `AdminModerationController` (`api/admin`) — `POST products/{id}/takedown`, `POST reviews/{id}/takedown`.
- `AdminSettingsController` (`api/admin/settings`) — `GET`/`PUT` (komisi, biaya admin pencairan, minimal pencairan, maks pencairan/hari, batas auto-cancel/auto-complete, ambang stok menipis).
- `NotificationsController.BroadcastPromo` (`POST /api/notifications/promo`) — sekarang dikunci ke role Admin.

Plus infrastruktur umum yang tinggal disalin dari `shopy-seller/`: design system (`lib/theme/`), `services/api_client.dart` (interceptor auto-refresh token), `services/token_storage_service.dart`, pola provider Riverpod + `flutter_secure_storage`.

Yang **belum ada sama sekali** dan jadi pekerjaan utama dokumen ini:

| # | Gap | Dampak |
|---|-----|--------|
| 1 | Tidak ada **app Flutter admin** sama sekali — 4 controller di atas cuma pernah dites lewat curl/Swagger | Seluruh dokumen ini |
| 2 | Tidak ada endpoint admin buat **lihat detail 1 toko** (termasuk dokumen verifikasi `StoreDocuments`) — `AdminStoresController` cuma punya list & 4 aksi status, tidak ada `GET {id}` | Admin approve toko "buta", tidak bisa lihat data lengkap sebelum approve/reject |
| 3 | **Seller belum punya halaman Flutter buat upload `StoreDocuments`** (dicatat sejak TASKSELLER.md Fase 2: "Belum ada halaman Flutter untuk upload dokumen") — skema & endpoint `POST /api/seller/store/documents` sudah ada, tapi tidak ada jalur nyata dokumen itu terisi | Walau gap #2 ditutup, tidak akan ada dokumen buat direview |
| 4 | Tidak ada endpoint admin buat **cari/browse produk & ulasan** — `AdminModerationController` cuma punya `POST {id}/takedown`, butuh ID yang sudah diketahui duluan, tidak ada `GET` buat menemukan ID itu | Fitur moderasi produk/ulasan tidak bisa dipakai nyata tanpa tahu ID dari psql |
| 5 | Tidak ada endpoint **statistik lintas-platform** (total toko/pesanan/omzet semua toko) | Opsional — dicatat sebagai future improvement, bukan blocker |

---

## Fase 0 — Persiapan & Skema App ✅

- [x] Buat app Flutter baru `shopy-admin` di root monorepo (`flutter create`), **tanpa `.git` terpisah** — konsisten dengan app lain di monorepo ini
  - `flutter create --org com.shopy --project-name shopy_admin .` — bundle ID otomatis jadi `com.shopy.shopy_admin` (bukan camelCase `shopyAdmin` seperti draf awal dokumen ini — `flutter create` ikut nama project apa adanya, konsisten dgn `shopy-seller` yang juga `com.shopy.shopy_seller`, bukan `shopySeller`). Tidak ada `.git` terpisah ter-buat, sama seperti 2 app lain.
- [x] Salin design system dari `shopy-seller/lib/theme/` (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`) apa adanya — konsisten dengan pola copy-paste (bukan package lokal) yang sudah dipakai di 2 app lain
- [x] Salin infrastruktur dari `shopy-seller`: `services/api_client.dart`, `services/token_storage_service.dart`, `models/auth/auth_response.dart`, struktur folder `providers/`/`models/`/`screens/`/`widgets/`
  - ⚠️ **Perhatikan `resolveApiBaseUrl()`** — kalau mau dites di HP fisik lewat USB, butuh `adb reverse tcp:5083 tcp:5083` (sama seperti `shopy-seller`, tidak permanen, harus diulang tiap sesi debug baru).
- [x] Tambah dependency: `flutter_riverpod`, `dio`, `flutter_secure_storage`, `google_fonts` — **tidak perlu** `image_picker`/`fl_chart`/`firebase_core`/`firebase_messaging` untuk cakupan dasar dokumen ini (tidak ada upload gambar atau grafik statistik di app admin; push notification admin dicatat sebagai opsional, lihat Fase 7)
  - `main.dart` ditulis ulang jadi `ProviderScope` + `MaterialApp` minimal pakai `AppTheme.light`, `home:` placeholder teks "Shopy Admin" (diganti `SplashScreen` asli begitu Fase 1 dikerjakan). `test/widget_test.dart` template counter diganti smoke test sesuai shell baru. `flutter analyze` 0 isu, `flutter test` lulus.
  - ⚠️ **Proaktif ditambahkan** (belum kejadian di app ini, tapi sudah kejadian & diperbaiki di `shopy-seller`): `android/gradle.properties` langsung diberi `kotlin.incremental=false` sejak awal — Kotlin incremental compiler crash (`IllegalArgumentException: this and base files have different roots`) di lingkungan dev ini karena pub cache ada di drive `C:` sementara semua project ada di drive `D:`. Berlaku buat app manapun di monorepo ini yang dibuild Android di mesin ini.
- [x] App icon — logo baru (`assets/logo.svg`, hexagon navy `#2B2D42` + "S" oranye `#FF6B35`, sengaja beda bentuk & warna dominan dari `shopy-seller` yang rounded-square oranye) diberikan langsung, bukan reuse icon seller
  - Pola identik `shopy-seller`: SVG dirender ke PNG 1024×1024 lewat headless Chrome (1 versi flat buat iOS/Windows/macOS/Web, 1 versi cuma glyph transparan buat Android adaptive icon foreground), `flutter_launcher_icons` di-generate ke semua platform (`adaptive_icon_background: "#2B2D42"`), `remove_alpha_ios: true` langsung disertakan dari awal (bukan nyusul kena warning dulu seperti `shopy-seller`). File `ic_launcher.png` default dihapus (sudah tidak direferensikan manifest). `flutter analyze` tetap 0 isu.

## Fase 1 — Auth & Shell ✅

- [x] Backend: pastikan Flutter bisa tahu role user setelah login — **tidak perlu endpoint baru**, JWT sudah menyisipkan claim `role` sejak TASKSELLER.md Fase 1, tinggal di-decode client-side
  - `services/jwt_decoder.dart` (baru) — decode payload JWT manual (base64url + json), tanpa verifikasi signature (itu tetap tanggung jawab backend). 🐛 **Bug ditemukan & diperbaiki saat verifikasi lewat curl ke backend asli**: user bisa punya lebih dari 1 role (persis kejadian nyata — akun `admin-demo@shopy.com` sekarang juga ke-assign role Seller karena sempat dipakai buka toko lewat `shopy-seller` pas testing sebelumnya), dan begitu lebih dari 1 role, claim `role` di JWT payload jadi **array**, bukan string tunggal. Fungsi awal `decodeRole()` (asumsi string tunggal) diganti `hasRole(token, role)` yang menangani kedua bentuk (`List` maupun `String`). Diverifikasi lewat curl langsung ke backend: token `admin-demo` (claim `role: ['Seller','Admin']`) → `hasRole(...,'Admin')` true; token akun baru tanpa role apapun → false.
- [x] Flutter: Splash + cek sesi (reuse pola Pulse Rings dari `shopy-seller`)
  - `screens/splash/splash_screen.dart` — sama persis pola Pulse Rings, warna aksen `AppColors.secondary` (navy) bukan `primary` (oranye) buat sedikit membedakan dari splash `shopy-seller`, konsisten dengan warna app icon Fase 0.
- [x] Flutter: halaman **Login** — **wajib tolak kalau role token bukan `Admin`**, tampilkan pesan jelas ("Akun ini bukan akun admin") lalu logout paksa, **jangan** diarahkan ke wizard/halaman lain manapun
  - `providers/auth_provider.dart` — pengecekan role ditaruh di `AuthNotifier.login()` **sebelum** sesi disimpan (`throw AuthException` kalau bukan Admin, `_persistSession` tidak pernah dipanggil) — bukan cuma redirect setelah login sukses, tapi akun non-admin memang tidak pernah punya sesi tersimpan di app ini sama sekali. `screens/auth/login_screen.dart` — versi ringkas dari punya `shopy-seller` (tanpa halaman Register & tombol login sosial, tidak relevan buat tool internal ini; subjudul eksplisit bilang "Khusus akun admin — akun lain akan ditolak").
- [x] Flutter: shell navigasi — bottom nav **4 tab**: Toko / Pencairan / Moderasi / Lainnya (tab "Lainnya" isi menu Pengaturan Platform + Broadcast Promo + Keluar Akun)
  - `screens/shell/admin_home_shell.dart` — didesain bottom-nav dari awal (bukan ditunda lalu di-retrofit seperti `shopy-seller` di TASKSELLER.md Fase 8). Tab Toko/Pencairan/Moderasi masih placeholder ("Halaman ini belum tersedia") — diganti halaman asli begitu Fase 2-4 dikerjakan. Tab Lainnya sudah fungsional penuh: 2 menu placeholder (Pengaturan Platform, Broadcast Promo — Fase 5-6) + tombol **Keluar Akun** yang beneran jalan (`AuthNotifier.logout()` + kembali ke `LoginScreen`).
  - `routing/post_auth_router.dart` — jauh lebih sederhana dari versi `shopy-seller` (tidak ada status toko/verifikasi buat dicek di sisi admin), langsung ke shell begitu `login()` sukses (yang berarti role Admin sudah pasti valid).
- ⚠️ **Verifikasi**: `flutter analyze` 0 isu, `flutter test` lulus (pola `_FakeAuthNotifier` sama seperti `shopy-seller`, supaya tidak menyentuh `flutter_secure_storage` asli). Logic `hasRole` diverifikasi langsung lewat curl ke backend asli (bukan cuma unit test) memakai akun `admin-demo@shopy.com` sungguhan — lihat catatan bug di atas. Verifikasi visual manual (`flutter run -d windows`/`chrome`) belum dilakukan.

## Fase 2 — Verifikasi Toko

## Fase 2 — Verifikasi Toko ✅

- [x] Backend: `GET /api/admin/stores/{id}` (detail 1 toko: data lengkap + list `StoreDocuments` terkait) — menutup gap #2
  - `AdminStoreDetailDto` (baru, `Models/Admin/AdminStoreDtos.cs`) reuse `StoreDocumentDto` yang sudah ada dari `Models/Sellers/SellerDtos.cs` (bentuknya identik, tidak perlu DTO baru buat dokumen). Sekalian nambah `q` (search nama toko, `EF.Functions.ILike`, pola sama `SellerProductsController`) ke `GET /api/admin/stores` — ternyata belum ada di endpoint list dari Fase 9, padahal dibutuhkan buat halaman List Toko di bawah.
- [x] Backend: **halaman Flutter seller buat upload dokumen verifikasi** (`shopy-seller`, bukan `shopy-admin`) — form pilih jenis dokumen (`Ktp`/`Npwp`/`Nib`) + `image_picker` + `POST /api/uploads?category=document` + `POST /api/seller/store/documents` — menutup gap #3
  - `shopy-seller`: `models/store/store_document.dart`, `services/seller_document_api_service.dart`, `providers/seller_document_provider.dart`, `screens/store/store_documents_screen.dart` (list 3 jenis dokumen tetap, upload/ganti per jenis, badge status). Diakses dari tombol baru di `AwaitingVerificationScreen` ("Lengkapi Dokumen Verifikasi", muncul untuk status `Pending`/`Rejected`).
  - 🐛 **2 gap tambahan ditemukan & ditutup sekalian saat mengerjakan ini** (di luar rencana awal, tapi langsung bikin fitur ini gak ada gunanya kalau tidak ditutup): (1) Dart enum `StoreStatus` di `shopy-seller` **belum punya `rejected`** sama sekali (`parseStoreStatus` diam-diam nganggep `Rejected` sebagai `pending`) — toko yang ditolak admin akan salah tampil "Menunggu Verifikasi" padahal sudah final ditolak. (2) `StoreSummaryDto` (backend, dipakai `GET /api/seller/me`) **tidak pernah mengirim `ModerationReason`** — seller tidak punya cara sama sekali melihat alasan penolakan/suspend dari admin, walau field itu sudah ada di DB sejak Fase 9. Keduanya diperbaiki: `StoreStatus.rejected` ditambah di Dart, `ModerationReason` ditambah ke `StoreSummaryDto` + `StoreSummary` (Dart) + ditampilkan di `AwaitingVerificationScreen` (kartu "Alasan dari admin").
- [x] Flutter (`shopy-admin`): halaman **List Toko** — filter chip status (Semua/Menunggu/Aktif/Ditangguhkan/Ditolak), search nama toko
  - `screens/store/store_list_screen.dart` + `providers/admin_store_provider.dart` (`AdminStoreListNotifier`, pola sama `OrderHistoryNotifier`/`NotificationHistoryNotifier` — paginated, filter status + search, "Muat Lebih Banyak"). ⚠️ **"badge jumlah per status" di rencana awal tidak dikerjakan** — butuh endpoint ringkasan count-per-status terpisah yang tidak ada di checklist manapun, dianggap dekorasi, bukan fungsi inti.
- [x] Flutter (`shopy-admin`): halaman **Detail Toko** — info toko & pemilik, list dokumen verifikasi (tampil gambar + status per dokumen, tap buat lihat ukuran penuh), tombol aksi sesuai status (`Pending` → Approve/Reject+alasan wajib; `Active` → Suspend+alasan opsional; `Suspended` → Activate)
  - `screens/store/store_detail_screen.dart`. ⚠️ Toko `Rejected` **tidak punya tombol aksi apapun** di halaman ini — backend `Approve` cuma jalan dari status `Pending` (lihat `AdminStoresController`, tidak diubah di fase ini), jadi toko yang ditolak memang final, sesuai pesan yang sudah ditampilkan `AwaitingVerificationScreen` ("hubungi admin Shopy untuk diajukan ulang" — perlu intervensi manual, bukan self-service lewat app).
- ⚠️ **Verifikasi**: `dotnet build` 0 error, `flutter analyze`+`flutter test` bersih di **kedua** app (`shopy-seller` & `shopy-admin`). Alur penuh diuji lewat curl: seller upload 2 dokumen (KTP+NPWP) → admin cari toko lewat `?q=` (cocok & tidak cocok) → admin lihat detail toko + dokumennya → admin reject dengan alasan → **seller melihat balik alasan itu lewat `GET /api/seller/me`** (mengonfirmasi 2 gap di atas benar-benar tertutup) → toko tetap 404 di endpoint publik.

## Fase 3 — Pencairan Dana

- [ ] Backend: sudah lengkap (`AdminWithdrawalsController`, TASKSELLER.md Fase 9) — tidak ada task backend baru di fase ini
- [ ] Flutter: halaman **List Pencairan** — filter chip status (Semua/Menunggu/Diproses/Selesai/Ditolak), tiap baris tampilkan nama toko, jumlah, bank tujuan (masked), tanggal request
- [ ] Flutter: aksi ubah status — dari list atau halaman detail, tombol Proses (`Pending→Processing`), Selesaikan (`→Completed`, trigger notifikasi ke seller), Tolak (`→Rejected` + alasan wajib, saldo otomatis balik ke seller)

## Fase 4 — Moderasi Produk & Ulasan

- [ ] Backend: `GET /api/admin/products?search=&page=` (cari produk lintas semua toko — nama produk, nama toko, status aktif) — menutup gap #4
- [ ] Backend: `GET /api/admin/reviews?search=&page=` (cari ulasan lintas semua toko — bisa cari by nama produk/nama pembeli, atau list ulasan rating rendah dulu sebagai default sort) — menutup gap #4
- [ ] Flutter: halaman **Cari Produk** — search bar + list hasil (thumbnail, nama, toko, status) + tombol Takedown per item + dialog konfirmasi
- [ ] Flutter: halaman **Cari Ulasan** — search bar + list hasil (rating, komentar, nama produk/toko/pembeli) + tombol Takedown per item + dialog konfirmasi

## Fase 5 — Pengaturan Platform

- [ ] Backend: sudah lengkap (`AdminSettingsController`, TASKSELLER.md Fase 9) — tidak ada task backend baru
- [ ] Flutter: halaman **Pengaturan Platform** — form 1 layar isi semua field (`CommissionPercent`, `WithdrawalAdminFee`, `MinWithdrawal`, `MaxWithdrawalsPerDay`, `AutoCancelHours`, `AutoCompleteDays`, `LowStockThreshold`), validasi ringan (angka positif), tombol Simpan + snackbar konfirmasi, tampilkan `UpdatedAt` terakhir

## Fase 6 — Broadcast Promo

- [ ] Backend: sudah lengkap (`POST /api/notifications/promo`, dikunci Admin di TASKSELLER.md Fase 9) — tidak ada task backend baru
- [ ] Flutter: halaman **Broadcast Promo** — form judul + isi pesan, tombol Kirim + dialog konfirmasi ("akan terkirim ke N user terdaftar"), tampilkan hasil (`recipientCount` dari response)

## Fase 7 — Polish & Testing (opsional)

- [ ] Review & rapikan UI/UX semua halaman (konsistensi dengan token desain `shopy-seller`, karena tidak ada mockup acuan)
- [ ] Widget test Flutter admin per halaman (pola sama `shopy-seller/test/`)
- [ ] Testing manual end-to-end: toko baru `Pending` → approve → cek publik kebuka; withdrawal request → Processing → Completed → cek notifikasi; takedown produk → cek hilang dari publik; ubah `CommissionPercent` → cek checkout baru pakai angka baru
- [ ] Push notification buat admin (opsional) — kalau mau admin dapat notif real-time pas ada toko baru `Pending`/withdrawal baru, butuh `DeviceToken.AppType` tambah value `Admin` + `NotificationService` method baru + Firebase app ketiga terdaftar. **Tidak wajib** untuk MVP — admin bisa cek manual lewat list yang di-refresh.
- [ ] Seed data demo tambahan kalau perlu (toko `Pending` contoh, withdrawal contoh) — bisa reuse akun demo yang sudah ada dari fase-fase sebelumnya

## Fase 8 — Rilis (opsional)

- [ ] App icon & splash screen final (bedakan dari `shopy-seller`/`shopy-mobile`, mis. aksen warna berbeda untuk role admin)
- [ ] Build release (internal — app ini **tidak untuk dipublikasi ke Play Store**, cukup APK/build internal dibagi ke admin platform)
- [ ] Dokumentasi akhir & update README (tambahkan `shopy-admin/` ke struktur proyek)

---

## Catatan Teknis

**Akun admin demo (dari `Data/AdminSeeder.cs`, TASKSELLER.md Fase 9, dev-only):**

```
admin-demo@shopy.com
AdminDemo1234!
```

**Struktur monorepo setelah dokumen ini:**

```
shopy/
├── assets/                 # Logo & aset bersama
├── shopy-mobile/           # App Flutter pembeli
├── shopy-seller/           # App Flutter penjual
├── shopy-admin/            # App Flutter admin (baru)
│   └── lib/
├── shopy-api/              # Backend .NET Core (dipakai bersama)
├── TASKS.md                # Tahap pengerjaan sisi pembeli
├── TASKSELLER.md           # Tahap pengerjaan sisi penjual (termasuk Fase 9 — backend admin)
├── TASKADMIN.md            # Dokumen ini
└── README.md
```

**Urutan pengerjaan yang disarankan:** Fase 0 → 1 adalah jalur kritis (app + login + shell). Fase 2 (Verifikasi Toko) paling bernilai dikerjakan duluan karena itu yang lagi dibutuhkan sekarang, tapi butuh keputusan dulu: kerjain gap #2+#3 penuh (dokumen bisa direview) atau approve "buta" dulu (lebih cepat, dokumen menyusul). Fase 3, 4, 5, 6 independen satu sama lain, bisa dikerjakan urutan apa saja setelah Fase 1 selesai. Fase 7-8 opsional/belakangan, sama seperti Fase 10-11 TASKSELLER.md.

**Cara pakai file ini:** centang `[ ]` jadi `[x]` setiap task selesai. Tulis catatan implementasi & peringatan (⚠️) di bawah task terkait begitu benar-benar dikerjakan, sama seperti gaya TASKS.md/TASKSELLER.md, supaya konteksnya tidak hilang.
