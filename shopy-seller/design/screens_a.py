"""Mockup Shopy Seller — layar 1-8 (onboarding toko, dashboard, produk, pesanan)."""

from PIL import ImageDraw

from mockup_lib import *  # noqa: F403


# ------------------------------------------------------------------ 1. daftar toko
def daftar_toko(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Buka Toko Gratis", "Lengkapi data tokomu, 3 langkah selesai")

    # stepper
    steps = ["Data Toko", "Alamat", "Verifikasi"]
    y += 16
    slot = (W - PAD * 2) / 3
    for i, s in enumerate(steps):
        cx = PAD + slot * i + slot / 2
        on = i == 0
        if i < 2:
            d.line((cx + 34, y + 34, cx + slot - 34, y + 34), fill=DIVIDER, width=4)
        d.ellipse((cx - 30, y + 4, cx + 30, y + 64), fill=PRIMARY if on else PRIMARY_SOFT)
        text(d, (cx, y + 35), str(i + 1), 28, "b", (255, 255, 255) if on else TEXT_SEC, anchor="mm")
        text(d, (cx, y + 78), s, 22, "b" if on else "r", TEXT if on else TEXT_SEC, anchor="ma")
    y += 140

    # unggah logo
    cx = W / 2
    d.ellipse((cx - 78, y, cx + 78, y + 156), fill=PRIMARY_SOFT)
    icon(d, (cx, y + 70), "camera", 52, PRIMARY, anchor="mm")
    rr(d, (cx + 34, y + 108, cx + 86, y + 160), 999, fill=PRIMARY)
    icon(d, (cx + 60, y + 134), "plus", 24, (255, 255, 255), anchor="mm")
    text(d, (cx, y + 174), "Unggah Logo Toko", 24, "m", TEXT_SEC, anchor="ma")
    y += 236

    y = field(d, y, "Nama Toko", "Ramdan Store", icon_name="shop")
    y = field(d, y, "URL Toko", "shopy.id/ramdan-store", placeholder=True, icon_name="external")
    y = field(d, y, "Kategori Toko", "Fashion & Aksesoris", icon_name="tag", chevron=True)
    y = field(d, y, "Nomor HP Toko", "0812-3456-7890", icon_name="phone")

    text(d, (PAD, y), "Deskripsi Toko", 24, "m", TEXT_SEC)
    rr(d, (PAD, y + 34, W - PAD, y + 214), 18, fill=SURFACE, outline=DIVIDER, width=2)
    for i, w in enumerate([540, 500, 360]):
        d.rounded_rectangle((PAD + 26, y + 70 + i * 42, PAD + 26 + w, y + 90 + i * 42), radius=8,
                            fill=(238, 231, 226))
    y += 244

    # checkbox syarat
    rr(d, (PAD, y, PAD + 38, y + 38), 8, fill=PRIMARY)
    icon(d, (PAD + 19, y + 20), "check", 22, (255, 255, 255), anchor="mm")
    text(d, (PAD + 58, y + 2), "Saya setuju dengan ", 24, "r", TEXT_SEC)
    text(d, (PAD + 58 + tw("Saya setuju dengan ", 24), y + 2), "Syarat & Ketentuan Penjual", 24, "b", PRIMARY)
    y += 90

    primary_button(img, (PAD, y, W - PAD, y + 100), "Lanjut ke Alamat Toko", icon_name="chev_r")
    save(img, path)


# --------------------------------------------------------------------- 2. dashboard
def dashboard(path):
    img, d = new_screen()
    status_bar(d)

    # header toko
    y = 96
    rr(d, (PAD, y, PAD + 92, y + 92), 24, fill=PRIMARY_SOFT)
    icon(d, (PAD + 46, y + 46), "shop", 42, PRIMARY, anchor="mm")
    text(d, (PAD + 116, y + 6), "Ramdan Store", 36, "b", TEXT)
    icon(d, (PAD + 116, y + 62), "check_circle", 22, GREEN, anchor="lm")
    text(d, (PAD + 148, y + 50), "Toko Terverifikasi", 22, "m", GREEN)
    icon(d, (W - PAD - 10, y + 46), "bell", 36, TEXT, anchor="rm")
    rr(d, (W - PAD - 30, y + 18, W - PAD, y + 48), 999, fill=RED)
    text(d, (W - PAD - 15, y + 34), "3", 19, "b", (255, 255, 255), anchor="mm")
    y += 128

    # kartu saldo
    box = (PAD, y, W - PAD, y + 260)

    def deco(dc, w, h):
        dc.ellipse((w - 120, -70, w + 110, 160), fill=PRIMARY_DARK)
        dc.ellipse((w - 40, 120, w + 150, 310), fill=PRIMARY_DARK)

    d2 = panel(img, box, r=32, fill=PRIMARY, decorate=deco)
    text(d2, (PAD + 40, y + 40), "Saldo Penjualan", 26, "m", (255, 226, 210))
    text(d2, (PAD + 40, y + 78), rupiah(2480000), 52, "b", (255, 255, 255))
    text(d2, (PAD + 40, y + 152), "Saldo tertahan " + rupiah(640000), 23, "r", (255, 226, 210))
    bw = 250
    rr(d2, (PAD + 40, y + 190, PAD + 40 + bw, y + 250), 16, fill=(255, 255, 255))
    icon(d2, (PAD + 70, y + 221), "wallet", 26, PRIMARY, anchor="lm")
    text(d2, (PAD + 106, y + 221), "Cairkan Dana", 25, "b", PRIMARY, anchor="lm")
    y += 300

    # statistik hari ini
    y = section_title(d, y, "Ringkasan Hari Ini", "Lihat Statistik")
    stats = [("Pesanan Baru", "5", "chart", PRIMARY, "+2 dari kemarin"),
             ("Produk Terjual", "12", "cube", BLUE, "+4 dari kemarin"),
             ("Pengunjung Toko", "348", "eye", GREEN, "+12% minggu ini"),
             ("Penghasilan", "Rp1,2jt", "money", AMBER, "+8% minggu ini")]
    cw = (W - PAD * 2 - 24) / 2
    for i, (label, value, ic, color, delta) in enumerate(stats):
        bx = PAD + (cw + 24) * (i % 2)
        by = y + (170 + 24) * (i // 2)
        dd = card(img, (bx, by, bx + cw, by + 170), r=26)
        rr(dd, (bx + 26, by + 26, bx + 80, by + 80), 16, fill=tuple(min(255, c + (255 - c) * 87 // 100) for c in color))
        icon(dd, (bx + 53, by + 53), ic, 26, color, anchor="mm")
        text(dd, (bx + 26, by + 92), value, 38, "b", TEXT)
        text(dd, (bx + 26, by + 136), label, 21, "r", TEXT_SEC)
    y += 170 * 2 + 24 + 40

    # perlu diproses
    y = section_title(d, y, "Perlu Ditindaklanjuti")
    rows = [("Pesanan baru menunggu konfirmasi", "5 pesanan", "list", PRIMARY),
            ("Siap dikirim, input resi", "2 pesanan", "truck", BLUE),
            ("Stok produk menipis", "3 produk", "warn", AMBER),
            ("Ulasan belum dibalas", "4 ulasan", "star", GREEN)]
    for i, (title, sub, ic, color) in enumerate(rows):
        by = y + i * 116
        dd = card(img, (PAD, by, W - PAD, by + 100), r=24)
        soft = tuple(min(255, c + (255 - c) * 87 // 100) for c in color)
        rr(dd, (PAD + 22, by + 22, PAD + 78, by + 78), 16, fill=soft)
        icon(dd, (PAD + 50, by + 50), ic, 26, color, anchor="mm")
        text(dd, (PAD + 98, by + 22), title, 25, "b", TEXT)
        text(dd, (PAD + 98, by + 56), sub, 22, "r", TEXT_SEC)
        icon(dd, (W - PAD - 26, by + 50), "chev_r", 24, TEXT_SEC, anchor="rm")
    y += 116 * 4 + 24

    # grafik mini
    dd = card(img, (PAD, y, W - PAD, y + 300), r=26)
    text(dd, (PAD + 30, y + 28), "Penjualan 7 Hari Terakhir", 27, "b", TEXT)
    text(dd, (W - PAD - 30, y + 34), "Rp12,4jt", 25, "b", PRIMARY, anchor="ra")
    bars = [0.45, 0.62, 0.38, 0.80, 0.55, 0.95, 0.70]
    labels = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]
    base, bh = y + 240, 130
    bwid = 52
    gap = (W - PAD * 2 - 60 - bwid * 7) / 6
    for i, (v, lb) in enumerate(zip(bars, labels)):
        bx = PAD + 30 + i * (bwid + gap)
        rr(dd, (bx, base - bh, bx + bwid, base), 12, fill=PRIMARY_SOFT)
        rr(dd, (bx, base - bh * v, bx + bwid, base), 12, fill=PRIMARY if v > 0.9 else (255, 150, 110))
        text(dd, (bx + bwid / 2, base + 12), lb, 20, "r", TEXT_SEC, anchor="ma")

    bottom_nav(img, "beranda")
    save(img, path)


# ------------------------------------------------------------------- 3. daftar produk
def produk_list(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Produk Saya", "24 produk terdaftar", back=False, right_icons=("search", "sort"))

    tabs = [("Semua 24", True), ("Aktif 20", False), ("Nonaktif 2", False), ("Habis 2", False)]
    x = PAD
    for label, on in tabs:
        x += chip(d, (x, y + 8), label, on, size=24, padx=24, h=60) + 16
    y += 100

    items = [("Kaos Oversize Basic", 129000, 42, 128, True, None),
             ("Sepatu Sneakers Urban", 349000, 8, 76, True, "Stok Menipis"),
             ("Tas Selempang Kanvas", 199000, 15, 54, True, None),
             ("Jam Tangan Minimalis", 450000, 0, 31, False, "Stok Habis")]
    for i, (name, price, stock, sold, active, warn) in enumerate(items):
        by = y + i * 224
        dd = card(img, (PAD, by, W - PAD, by + 204), r=26)
        thumb(dd, (PAD + 24, by + 26, PAD + 172, by + 174), r=20)
        if warn:
            badge(dd, (PAD + 24, by + 26), warn, RED if stock == 0 else AMBER,
                  (255, 255, 255), size=17, padx=12, pady=7)
        tx = PAD + 196
        text(dd, (tx, by + 28), ellipsize(name, W - PAD - 130 - tx, 27, "b"), 27, "b", TEXT)
        text(dd, (tx, by + 70), rupiah(price), 29, "b", PRIMARY)
        icon(dd, (tx, by + 130), "archive", 22, TEXT_SEC, anchor="lm")
        text(dd, (tx + 32, by + 130), f"Stok {stock}", 22, "m", TEXT if stock else RED, anchor="lm")
        icon(dd, (tx + 156, by + 130), "chart", 22, TEXT_SEC, anchor="lm")
        text(dd, (tx + 188, by + 130), f"Terjual {sold}", 22, "r", TEXT_SEC, anchor="lm")
        toggle(dd, (W - PAD - 100, by + 40), on=active)
        text(dd, (W - PAD - 62, by + 96), "Aktif" if active else "Nonaktif", 19, "m", TEXT_SEC, anchor="ma")
        icon(dd, (tx, by + 172), "pencil", 22, PRIMARY, anchor="lm")
        text(dd, (tx + 32, by + 172), "Ubah", 22, "b", PRIMARY, anchor="lm")
        icon(dd, (tx + 130, by + 172), "trash", 22, TEXT_SEC, anchor="lm")
        text(dd, (tx + 162, by + 172), "Hapus", 22, "r", TEXT_SEC, anchor="lm")

    # FAB tambah produk
    fy = H - 130 - 128
    fw = 320
    primary_button(img, (W - PAD - fw, fy, W - PAD, fy + 92), "Tambah Produk", icon_name="plus", r=999)

    bottom_nav(img, "produk")
    save(img, path)


# ----------------------------------------------------------------- 4. form produk
def produk_form(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Tambah Produk", "Isi detail produk yang mau dijual")

    text(d, (PAD, y), "Foto Produk (maks. 5)", 24, "m", TEXT_SEC)
    y += 40
    slot = 150
    for i in range(3):
        bx = PAD + i * (slot + 18)
        if i < 2:
            thumb(d, (bx, y, bx + slot, y + slot), r=18)
            rr(d, (bx + slot - 34, y - 6, bx + slot + 6, y + 34), 999, fill=(70, 55, 50))
            icon(d, (bx + slot - 14, y + 14), "times", 20, (255, 255, 255), anchor="mm")
            if i == 0:
                badge(d, (bx + 8, y + slot - 40), "Utama", PRIMARY, size=17, padx=10, pady=6)
        else:
            rr(d, (bx, y, bx + slot, y + slot), 18, fill=PRIMARY_SOFT, outline=PRIMARY, width=3)
            icon(d, (bx + slot / 2, y + slot / 2 - 12), "camera", 34, PRIMARY, anchor="mm")
            text(d, (bx + slot / 2, y + slot / 2 + 16), "Tambah", 19, "m", PRIMARY, anchor="ma")
    y += slot + 40

    y = field(d, y, "Nama Produk", "Kaos Oversize Basic Cotton Combed 30s")
    y = field(d, y, "Kategori", "Fashion Pria > Atasan", icon_name="tag", chevron=True)
    y = field(d, y, "Harga Satuan", "129.000", icon_name="money", suffix="/ pcs")

    # stok + berat berdampingan
    half = (W - PAD * 2 - 24) / 2
    text(d, (PAD, y), "Stok", 24, "m", TEXT_SEC)
    rr(d, (PAD, y + 34, PAD + half, y + 122), 18, fill=SURFACE, outline=DIVIDER, width=2)
    rr(d, (PAD + 14, y + 48, PAD + 74, y + 108), 12, fill=PRIMARY_SOFT)
    text(d, (PAD + 44, y + 78), "-", 32, "b", PRIMARY, anchor="mm")
    text(d, (PAD + half / 2 + 10, y + 78), "42", 28, "b", TEXT, anchor="mm")
    rr(d, (PAD + half - 74, y + 48, PAD + half - 14, y + 108), 12, fill=PRIMARY_SOFT)
    text(d, (PAD + half - 44, y + 78), "+", 32, "b", PRIMARY, anchor="mm")
    text(d, (PAD + half + 24, y), "Berat", 24, "m", TEXT_SEC)
    rr(d, (PAD + half + 24, y + 34, W - PAD, y + 122), 18, fill=SURFACE, outline=DIVIDER, width=2)
    text(d, (PAD + half + 50, y + 79), "250", 26, "r", TEXT, anchor="lm")
    text(d, (W - PAD - 26, y + 79), "gram", 24, "m", TEXT_SEC, anchor="rm")
    y += 156

    text(d, (PAD, y), "Deskripsi Produk", 24, "m", TEXT_SEC)
    rr(d, (PAD, y + 34, W - PAD, y + 244), 18, fill=SURFACE, outline=DIVIDER, width=2)
    for i, w in enumerate([580, 546, 600, 380]):
        d.rounded_rectangle((PAD + 26, y + 68 + i * 42, PAD + 26 + w, y + 88 + i * 42), radius=8,
                            fill=(238, 231, 226))
    y += 276

    text(d, (PAD, y), "Kondisi", 24, "m", TEXT_SEC)
    x = PAD
    x += chip(d, (x, y + 34), "Baru", True, size=24, padx=30, h=62) + 16
    chip(d, (x, y + 34), "Bekas", False, size=24, padx=30, h=62)
    y += 128

    dd = card(img, (PAD, y, W - PAD, y + 104), r=20)
    text(dd, (PAD + 28, y + 26), "Tayangkan Produk", 26, "b", TEXT)
    text(dd, (PAD + 28, y + 60), "Produk langsung tampil di katalog", 21, "r", TEXT_SEC)
    toggle(dd, (W - PAD - 104, y + 32), on=True)

    # aksi bawah
    by = H - 168
    d.rectangle((0, by - 24, W, H), fill=SURFACE)
    d.line((0, by - 24, W, by - 24), fill=DIVIDER, width=2)
    half = (W - PAD * 2 - 24) / 2
    outline_button(d, (PAD, by, PAD + half, by + 100), "Simpan Draf")
    primary_button(img, (PAD + half + 24, by, W - PAD, by + 100), "Simpan & Tayangkan")
    save(img, path)


# ----------------------------------------------------------------- 5. stok & harga
def stok_harga(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Atur Stok & Harga", "Ubah cepat tanpa buka detail produk")

    dd = card(img, (PAD, y, W - PAD, y + 108), r=22, fill=AMBER_SOFT, shadow=False)
    icon(dd, (PAD + 34, y + 54), "warn", 30, AMBER, anchor="lm")
    text(dd, (PAD + 80, y + 26), "3 produk stoknya menipis", 25, "b", (150, 100, 10))
    text(dd, (PAD + 80, y + 60), "Segera tambah stok biar tetap bisa dibeli", 21, "r", (170, 130, 60))
    y += 140

    rr(d, (PAD, y, W - PAD, y + 84), 18, fill=PRIMARY_SOFT)
    icon(d, (PAD + 28, y + 42), "search", 26, TEXT_SEC, anchor="lm")
    text(d, (PAD + 70, y + 43), "Cari produk...", 25, "r", (185, 170, 162), anchor="lm")
    y += 116

    items = [("Kaos Oversize Basic", "129.000", "42", False),
             ("Sepatu Sneakers Urban", "349.000", "8", True),
             ("Tas Selempang Kanvas", "199.000", "15", False),
             ("Jam Tangan Minimalis", "450.000", "0", True),
             ("Topi Baseball Katun", "89.000", "27", False)]
    for i, (name, price, stock, low) in enumerate(items):
        by = y + i * 196
        dd = card(img, (PAD, by, W - PAD, by + 176), r=24)
        thumb(dd, (PAD + 22, by + 22, PAD + 122, by + 122), r=16)
        text(dd, (PAD + 144, by + 24), name, 25, "b", TEXT)
        if low:
            badge(dd, (W - PAD - 22, by + 22), "Stok rendah", AMBER_SOFT, AMBER, size=17, padx=12, pady=7, anchor="rt")
        # input harga
        text(dd, (PAD + 144, by + 66), "Harga", 20, "m", TEXT_SEC)
        rr(dd, (PAD + 144, by + 92, PAD + 384, by + 152), 14, fill=BG, outline=DIVIDER, width=2)
        text(dd, (PAD + 162, by + 123), "Rp", 22, "m", TEXT_SEC, anchor="lm")
        text(dd, (PAD + 204, by + 123), price, 24, "b", TEXT, anchor="lm")
        # input stok
        text(dd, (PAD + 408, by + 66), "Stok", 20, "m", TEXT_SEC)
        rr(dd, (PAD + 408, by + 92, W - PAD - 22, by + 152), 14, fill=BG, outline=DIVIDER, width=2)
        rr(dd, (PAD + 418, by + 100, PAD + 468, by + 144), 10, fill=PRIMARY_SOFT)
        text(dd, (PAD + 443, by + 122), "-", 26, "b", PRIMARY, anchor="mm")
        text(dd, (PAD + 512, by + 123), stock, 24, "b", RED if stock == "0" else TEXT, anchor="mm")
        rr(dd, (W - PAD - 82, by + 100, W - PAD - 32, by + 144), 10, fill=PRIMARY_SOFT)
        text(dd, (W - PAD - 57, by + 122), "+", 26, "b", PRIMARY, anchor="mm")

    by = H - 168
    d.rectangle((0, by - 24, W, H), fill=SURFACE)
    d.line((0, by - 24, W, by - 24), fill=DIVIDER, width=2)
    primary_button(img, (PAD, by, W - PAD, by + 100), "Simpan Perubahan (3)")
    save(img, path)


# --------------------------------------------------------------------- 6. pesanan
def pesanan_list(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Pesanan", back=False, right_icons=("search", "filter"))

    tabs = [("Baru 5", True), ("Diproses 3", False), ("Dikirim 2", False), ("Selesai", False)]
    x = PAD
    for label, on in tabs:
        x += chip(d, (x, y + 4), label, on, size=24, padx=24, h=60) + 14
    y += 96

    orders = [("#SHP-20260810-0142", "Andi Pratama", "Baru", PRIMARY, "2 menit lalu",
               [("Kaos Oversize Basic", 2, 129000), ("Topi Baseball Katun", 1, 89000)], 362000, "baru"),
              ("#SHP-20260810-0139", "Siti Rahma", "Baru", PRIMARY, "18 menit lalu",
               [("Sepatu Sneakers Urban", 1, 349000)], 364000, "baru"),
              ("#SHP-20260810-0131", "Budi Santoso", "Diproses", BLUE, "1 jam lalu",
               [("Tas Selempang Kanvas", 1, 199000), ("Jam Tangan Minimalis", 1, 450000)], 664000, "proses")]

    for no, buyer, status, color, when, produk, total, mode in orders:
        head, item_h, foot = 128, 100, 96
        timer = 46 if mode == "baru" else 0
        hgt = head + item_h * len(produk) + 78 + timer + foot + 20
        by = y
        dd = card(img, (PAD, by, W - PAD, by + hgt), r=28)
        text(dd, (PAD + 28, by + 26), no, 23, "m", TEXT_SEC)
        badge(dd, (W - PAD - 28, by + 22), status, color, size=20, padx=18, pady=9, anchor="rt")
        icon(dd, (PAD + 28, by + 80), "user", 22, TEXT_SEC, anchor="lm")
        text(dd, (PAD + 60, by + 81), buyer, 25, "b", TEXT, anchor="lm")
        text(dd, (W - PAD - 28, by + 70), when, 21, "r", TEXT_SEC, anchor="ra")
        divider(dd, by + 112, PAD + 28, W - PAD - 28)

        py = by + head + 4
        for nama, qty, harga in produk:
            thumb(dd, (PAD + 28, py, PAD + 112, py + 84), r=14)
            text(dd, (PAD + 132, py + 10), ellipsize(nama, 360, 24, "m"), 24, "m", TEXT)
            text(dd, (PAD + 132, py + 46), f"{qty} x " + rupiah(harga), 21, "r", TEXT_SEC)
            text(dd, (W - PAD - 28, py + 28), rupiah(qty * harga), 23, "b", TEXT, anchor="ra")
            py += item_h

        ty = py + 8
        text(dd, (PAD + 28, ty), f"{sum(q for _, q, _ in produk)} produk", 22, "r", TEXT_SEC)
        text(dd, (W - PAD - 28, ty - 6), "Total " + rupiah(total), 27, "b", TEXT, anchor="ra")

        ay = by + hgt - 96
        if mode == "baru":
            icon(dd, (PAD + 28, ay - 30), "clock", 20, RED, anchor="lm")
            text(dd, (PAD + 56, ay - 30), "Proses dalam 23:45:12", 21, "b", RED, anchor="lm")
            half = (W - PAD * 2 - 56 - 20) / 2
            outline_button(dd, (PAD + 28, ay, PAD + 28 + half, ay + 76), "Tolak", size=25, color=TEXT_SEC, r=16)
            primary_button(img, (PAD + 48 + half, ay, W - PAD - 28, ay + 76), "Proses Pesanan", size=25, r=16)
        else:
            primary_button(img, (PAD + 28, ay, W - PAD - 28, ay + 76), "Input Nomor Resi",
                           icon_name="truck", size=25, r=16)
        y += hgt + 28

    bottom_nav(img, "pesanan")
    save(img, path)


# -------------------------------------------------------------- 7. detail pesanan
def pesanan_detail(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Detail Pesanan", "#SHP-20260810-0142")

    def deco(dc, w, h):
        dc.ellipse((w - 90, -60, w + 120, 150), fill=PRIMARY_DARK)

    dd = panel(img, (PAD, y, W - PAD, y + 150), r=26, fill=PRIMARY, decorate=deco)
    icon(dd, (PAD + 40, y + 62), "bell", 34, (255, 255, 255), anchor="lm")
    text(dd, (PAD + 90, y + 38), "Pesanan Baru", 30, "b", (255, 255, 255))
    text(dd, (PAD + 90, y + 78), "Konfirmasi sebelum 23:45:12 atau otomatis batal", 21, "r", (255, 226, 210))
    y += 182

    # pembeli
    dd = card(img, (PAD, y, W - PAD, y + 130), r=24)
    d.ellipse((PAD + 26, y + 26, PAD + 104, y + 104), fill=PRIMARY_SOFT)
    icon(dd, (PAD + 65, y + 65), "user", 32, PRIMARY, anchor="mm")
    text(dd, (PAD + 124, y + 32), "Andi Pratama", 27, "b", TEXT)
    text(dd, (PAD + 124, y + 68), "Bergabung 2025 - 12 pesanan", 21, "r", TEXT_SEC)
    rr(dd, (W - PAD - 130, y + 40, W - PAD - 26, y + 100), 14, fill=PRIMARY_SOFT)
    icon(dd, (W - PAD - 106, y + 70), "chat", 24, PRIMARY, anchor="lm")
    text(dd, (W - PAD - 74, y + 70), "Chat", 22, "b", PRIMARY, anchor="lm")
    y += 158

    # alamat
    dd = card(img, (PAD, y, W - PAD, y + 268), r=24)
    icon(dd, (PAD + 28, y + 42), "map", 24, PRIMARY, anchor="lm")
    text(dd, (PAD + 62, y + 42), "Alamat Pengiriman", 25, "b", TEXT, anchor="lm")
    text(dd, (PAD + 28, y + 78), "Andi Pratama - 0812-3456-7890", 23, "m", TEXT)
    text(dd, (PAD + 28, y + 118), "Jl. Melati No. 21, RT 03/RW 05, Kebayoran", 22, "r", TEXT_SEC)
    text(dd, (PAD + 28, y + 154), "Baru, Jakarta Selatan, DKI Jakarta 12160", 22, "r", TEXT_SEC)
    divider(dd, y + 200, PAD + 28, W - PAD - 28)
    icon(dd, (PAD + 28, y + 232), "truck", 21, TEXT_SEC, anchor="lm")
    text(dd, (PAD + 58, y + 232), "JNE REG (2-3 hari) - Rp15.000", 22, "m", TEXT, anchor="lm")
    y += 296

    # produk
    dd = card(img, (PAD, y, W - PAD, y + 268), r=24)
    text(dd, (PAD + 28, y + 24), "Produk Dipesan", 25, "b", TEXT)
    py = y + 70
    for nama, qty, harga in [("Kaos Oversize Basic", 2, 129000), ("Topi Baseball Katun", 1, 89000)]:
        thumb(dd, (PAD + 28, py, PAD + 118, py + 90), r=16)
        text(dd, (PAD + 138, py + 6), nama, 24, "m", TEXT)
        text(dd, (PAD + 138, py + 42), f"{qty} x " + rupiah(harga), 22, "r", TEXT_SEC)
        text(dd, (W - PAD - 28, py + 24), rupiah(qty * harga), 25, "b", TEXT, anchor="ra")
        py += 110
    y += 296

    # rincian
    dd = card(img, (PAD, y, W - PAD, y + 356), r=24)
    text(dd, (PAD + 28, y + 24), "Rincian Pembayaran", 25, "b", TEXT)
    rows = [("Subtotal produk", rupiah(347000), TEXT_SEC, TEXT),
            ("Ongkos kirim", rupiah(15000), TEXT_SEC, TEXT),
            ("Total dibayar pembeli", rupiah(362000), TEXT, TEXT),
            ("Komisi Shopy (2%)", "- " + rupiah(6940), TEXT_SEC, RED)]
    ry = y + 80
    for label, value, lc, vc in rows:
        text(dd, (PAD + 28, ry), label, 23, "b" if lc == TEXT else "r", lc)
        text(dd, (W - PAD - 28, ry), value, 23, "b", vc, anchor="ra")
        ry += 48
    divider(dd, ry + 12, PAD + 28, W - PAD - 28)
    text(dd, (PAD + 28, ry + 42), "Estimasi masuk saldo", 25, "b", TEXT)
    text(dd, (W - PAD - 28, ry + 40), rupiah(355060), 29, "b", GREEN, anchor="ra")
    y += 384

    dd = card(img, (PAD, y, W - PAD, y + 120), r=24, fill=PRIMARY_SOFT, shadow=False)
    text(dd, (PAD + 28, y + 24), "Catatan pembeli", 22, "m", TEXT_SEC)
    text(dd, (PAD + 28, y + 60), "Tolong dibungkus rapi ya kak, buat kado.", 24, "r", TEXT)

    by = H - 168
    d.rectangle((0, by - 24, W, H), fill=SURFACE)
    d.line((0, by - 24, W, by - 24), fill=DIVIDER, width=2)
    half = (W - PAD * 2 - 24) / 2
    outline_button(d, (PAD, by, PAD + half, by + 100), "Tolak Pesanan", color=TEXT_SEC)
    primary_button(img, (PAD + half + 24, by, W - PAD, by + 100), "Proses Pesanan")
    save(img, path)


# --------------------------------------------------------------- 8. kirim pesanan
def kirim_pesanan(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Kirim Pesanan", "#SHP-20260810-0139 - Siti Rahma")

    dd = card(img, (PAD, y, W - PAD, y + 140), r=24)
    thumb(dd, (PAD + 24, y + 24, PAD + 116, y + 116), r=16)
    text(dd, (PAD + 138, y + 30), "Sepatu Sneakers Urban", 25, "b", TEXT)
    text(dd, (PAD + 138, y + 68), "1 barang - berat total 850 gram", 22, "r", TEXT_SEC)
    y += 172

    y = section_title(d, y, "Pilih Kurir")
    kurir = [("JNE Reguler", "Estimasi 2-3 hari", 15000, True),
             ("J&T Express", "Estimasi 2-4 hari", 14000, False),
             ("SiCepat REG", "Estimasi 1-3 hari", 16000, False)]
    for i, (nama, est, ongkir, on) in enumerate(kurir):
        by = y + i * 128
        dd = card(img, (PAD, by, W - PAD, by + 112), r=22,
                  outline=PRIMARY if on else None, width=3 if on else 0)
        rr(dd, (PAD + 24, by + 26, PAD + 104, by + 86), 12, fill=PRIMARY_SOFT)
        icon(dd, (PAD + 64, by + 56), "truck", 26, PRIMARY, anchor="mm")
        text(dd, (PAD + 126, by + 26), nama, 25, "b", TEXT)
        text(dd, (PAD + 126, by + 62), est, 21, "r", TEXT_SEC)
        text(dd, (W - PAD - 90, by + 44), rupiah(ongkir), 24, "b", TEXT, anchor="ra")
        cx, cy = W - PAD - 46, by + 56
        d.ellipse((cx - 20, cy - 20, cx + 20, cy + 20), outline=PRIMARY if on else DIVIDER, width=4)
        if on:
            d.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=PRIMARY)
    y += 128 * 3 + 20

    text(d, (PAD, y), "Nomor Resi", 24, "m", TEXT_SEC)
    rr(d, (PAD, y + 34, W - PAD, y + 122), 18, fill=SURFACE, outline=DIVIDER, width=2)
    text(d, (PAD + 26, y + 79), "JNE0012938471", 27, "b", TEXT, anchor="lm")
    rr(d, (W - PAD - 130, y + 48, W - PAD - 14, y + 108), 14, fill=PRIMARY_SOFT)
    icon(d, (W - PAD - 110, y + 78), "qr", 24, PRIMARY, anchor="lm")
    text(d, (W - PAD - 78, y + 78), "Scan", 22, "b", PRIMARY, anchor="lm")
    y += 154

    text(d, (PAD, y), "Foto Bukti Serah Terima (opsional)", 24, "m", TEXT_SEC)
    rr(d, (PAD, y + 34, W - PAD, y + 244), 18, fill=PRIMARY_SOFT, outline=PRIMARY, width=3)
    icon(d, (W / 2, y + 118), "camera", 46, PRIMARY, anchor="mm")
    text(d, (W / 2, y + 152), "Ambil / unggah foto paket", 24, "m", PRIMARY, anchor="ma")
    y += 280

    rr(d, (PAD, y, PAD + 38, y + 38), 8, fill=PRIMARY)
    icon(d, (PAD + 19, y + 20), "check", 22, (255, 255, 255), anchor="mm")
    text(d, (PAD + 58, y + 2), "Paket sudah saya serahkan ke kurir", 24, "r", TEXT)
    y += 84

    dd = card(img, (PAD, y, W - PAD, y + 116), r=22, fill=BLUE_SOFT, shadow=False)
    icon(dd, (PAD + 32, y + 58), "info", 28, BLUE, anchor="lm")
    text(dd, (PAD + 76, y + 26), "Status berubah jadi \"Dikirim\"", 24, "b", (30, 80, 160))
    text(dd, (PAD + 76, y + 60), "Pembeli otomatis dapat notifikasi + nomor resi", 21, "r", (60, 105, 175))

    by = H - 168
    d.rectangle((0, by - 24, W, H), fill=SURFACE)
    d.line((0, by - 24, W, by - 24), fill=DIVIDER, width=2)
    primary_button(img, (PAD, by, W - PAD, by + 100), "Kirim & Simpan Resi", icon_name="truck")
    save(img, path)
