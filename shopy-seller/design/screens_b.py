"""Mockup Shopy Seller — layar 9-16 (keuangan, promo, chat, ulasan, statistik, toko)."""

from PIL import Image, ImageDraw

from mockup_lib import *  # noqa: F403


# -------------------------------------------------------------------- 9. keuangan
def keuangan(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Keuangan", "Saldo & penghasilan toko")

    def deco(dc, w, h):
        dc.ellipse((w - 130, -80, w + 120, 170), fill=PRIMARY_DARK)
        dc.ellipse((w - 50, 130, w + 160, 340), fill=PRIMARY_DARK)

    dd = panel(img, (PAD, y, W - PAD, y + 300), r=32, fill=PRIMARY, decorate=deco)
    text(dd, (PAD + 40, y + 36), "Saldo Bisa Dicairkan", 26, "m", (255, 226, 210))
    text(dd, (PAD + 40, y + 74), rupiah(2480000), 54, "b", (255, 255, 255))
    icon(dd, (PAD + 40, y + 168), "clock", 22, (255, 226, 210), anchor="lm")
    text(dd, (PAD + 72, y + 168), "Saldo tertahan " + rupiah(640000) + " (pesanan berjalan)",
         22, "r", (255, 226, 210), anchor="lm")
    rr(dd, (PAD + 40, y + 206, W - PAD - 40, y + 274), 18, fill=(255, 255, 255))
    icon(dd, (W / 2 - 96, y + 240), "bank", 26, PRIMARY, anchor="lm")
    text(dd, (W / 2 - 60, y + 240), "Cairkan Dana", 27, "b", PRIMARY, anchor="lm")
    y += 336

    stats = [("Penghasilan bulan", rupiah(8640000), GREEN, "up"),
             ("Komisi dipotong", rupiah(172800), TEXT_SEC, "down"),
             ("Pesanan selesai", "58 pesanan", TEXT, None)]
    cw = (W - PAD * 2 - 24) / 3
    for i, (label, value, color, arrow) in enumerate(stats):
        bx = PAD + (cw + 12) * i
        dd = card(img, (bx, y, bx + cw, y + 168), r=24)
        text(dd, (bx + cw / 2, y + 34), ellipsize(label, cw - 30, 20, "r"), 20, "r", TEXT_SEC, anchor="ma")
        text(dd, (bx + cw / 2, y + 82), ellipsize(value, cw - 24, 26, "b"), 26, "b", color, anchor="ma")
        if arrow:
            icon(dd, (bx + cw / 2 - 40, y + 134), arrow, 20, GREEN if arrow == "up" else RED, anchor="lm")
            text(dd, (bx + cw / 2 - 12, y + 134), "12%", 20, "b",
                 GREEN if arrow == "up" else RED, anchor="lm")
    y += 208

    y = section_title(d, y, "Mutasi Saldo", "Unduh Laporan")
    x = PAD
    for label, on in [("Semua", True), ("Pemasukan", False), ("Pencairan", False)]:
        x += chip(d, (x, y - 6), label, on, size=23, padx=24, h=58) + 14
    y += 78

    rows = [("Pesanan #SHP-20260810-0122 selesai", "10 Agu 2026 - 14:20", 355060, True),
            ("Pesanan #SHP-20260809-0118 selesai", "09 Agu 2026 - 09:12", 189200, True),
            ("Pencairan ke BCA ****4821", "08 Agu 2026 - 16:40", 1500000, False),
            ("Pesanan #SHP-20260808-0101 selesai", "08 Agu 2026 - 11:05", 431500, True),
            ("Komisi Shopy Agustus", "07 Agu 2026 - 23:59", 62400, False)]
    for i, (title, when, amount, masuk) in enumerate(rows):
        by = y + i * 128
        dd = card(img, (PAD, by, W - PAD, by + 112), r=22)
        rr(dd, (PAD + 24, by + 28, PAD + 80, by + 84), 16, fill=GREEN_SOFT if masuk else RED_SOFT)
        icon(dd, (PAD + 52, by + 56), "down" if masuk else "up", 24, GREEN if masuk else RED, anchor="mm")
        text(dd, (PAD + 100, by + 28), ellipsize(title, 320, 23, "m"), 23, "m", TEXT)
        text(dd, (PAD + 100, by + 62), when, 20, "r", TEXT_SEC)
        text(dd, (W - PAD - 24, by + 46), ("+ " if masuk else "- ") + rupiah(amount), 24, "b",
             GREEN if masuk else TEXT, anchor="ra")
    save(img, path)


# ------------------------------------------------------------------- 10. pencairan
def pencairan(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Cairkan Dana", "Transfer saldo ke rekening bank")

    dd = card(img, (PAD, y, W - PAD, y + 130), r=24, fill=PRIMARY_SOFT, shadow=False)
    text(dd, (PAD + 30, y + 28), "Saldo bisa dicairkan", 23, "r", TEXT_SEC)
    text(dd, (PAD + 30, y + 66), rupiah(2480000), 36, "b", PRIMARY)
    y += 162

    text(d, (PAD, y), "Jumlah Pencairan", 24, "m", TEXT_SEC)
    rr(d, (PAD, y + 34, W - PAD, y + 146), 20, fill=SURFACE, outline=PRIMARY, width=3)
    text(d, (PAD + 30, y + 92), "Rp", 30, "m", TEXT_SEC, anchor="lm")
    text(d, (PAD + 86, y + 92), "2.000.000", 42, "b", TEXT, anchor="lm")
    text(d, (W - PAD - 30, y + 92), "Cairkan semua", 23, "b", PRIMARY, anchor="rm")
    text(d, (PAD + 4, y + 162), "Minimal " + rupiah(50000) + " - maksimal 3x pencairan per hari",
         21, "r", TEXT_SEC)
    y += 216

    y = section_title(d, y, "Rekening Tujuan", "Ubah")
    dd = card(img, (PAD, y, W - PAD, y + 150), r=24)
    rr(dd, (PAD + 26, y + 30, PAD + 130, y + 90), 12, fill=BLUE_SOFT)
    text(dd, (PAD + 78, y + 60), "BCA", 24, "b", BLUE, anchor="mm")
    text(dd, (PAD + 152, y + 34), "**** **** 4821", 27, "b", TEXT)
    text(dd, (PAD + 152, y + 74), "a.n Ramdan Nugraha", 22, "r", TEXT_SEC)
    icon(dd, (PAD + 26, y + 118), "check_circle", 21, GREEN, anchor="lm")
    text(dd, (PAD + 56, y + 118), "Rekening sudah terverifikasi", 21, "m", GREEN, anchor="lm")
    y += 182

    dd = card(img, (PAD, y, W - PAD, y + 268), r=24)
    text(dd, (PAD + 28, y + 26), "Rincian", 25, "b", TEXT)
    ry = y + 80
    for label, value, vc in [("Jumlah pencairan", rupiah(2000000), TEXT),
                             ("Biaya admin bank", "- " + rupiah(2500), RED)]:
        text(dd, (PAD + 28, ry), label, 23, "r", TEXT_SEC)
        text(dd, (W - PAD - 28, ry), value, 23, "b", vc, anchor="ra")
        ry += 46
    divider(dd, ry + 8, PAD + 28, W - PAD - 28)
    text(dd, (PAD + 28, ry + 34), "Diterima", 25, "b", TEXT)
    text(dd, (W - PAD - 28, ry + 32), rupiah(1997500), 29, "b", GREEN, anchor="ra")
    y += 300

    dd = card(img, (PAD, y, W - PAD, y + 116), r=22, fill=BLUE_SOFT, shadow=False)
    icon(dd, (PAD + 32, y + 58), "info", 28, BLUE, anchor="lm")
    text(dd, (PAD + 76, y + 26), "Dana masuk 1-2 hari kerja", 24, "b", (30, 80, 160))
    text(dd, (PAD + 76, y + 60), "Pencairan di atas jam 15.00 diproses besok", 21, "r", (60, 105, 175))
    y += 148

    primary_button(img, (PAD, y, W - PAD, y + 100), "Ajukan Pencairan")
    y += 140

    y = section_title(d, y, "Riwayat Pencairan")
    for i, (amount, when, status, color, soft) in enumerate(
            [(1500000, "08 Agu 2026", "Berhasil", GREEN, GREEN_SOFT),
             (900000, "01 Agu 2026", "Berhasil", GREEN, GREEN_SOFT),
             (500000, "25 Jul 2026", "Diproses", AMBER, AMBER_SOFT)]):
        by = y + i * 118
        dd = card(img, (PAD, by, W - PAD, by + 102), r=22)
        rr(dd, (PAD + 24, by + 24, PAD + 78, by + 78), 14, fill=soft)
        icon(dd, (PAD + 51, by + 51), "bank", 24, color, anchor="mm")
        text(dd, (PAD + 100, by + 26), rupiah(amount), 25, "b", TEXT)
        text(dd, (PAD + 100, by + 60), when + " - BCA ****4821", 20, "r", TEXT_SEC)
        badge(dd, (W - PAD - 24, by + 34), status, soft, color, size=19, padx=16, pady=8, anchor="rt")
    save(img, path)


# ---------------------------------------------------------------- 11. promo/voucher
def promo_voucher(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Promo & Voucher", "Naikkan penjualan tokomu", right_icons=("plus",))

    x = PAD
    for label, on in [("Voucher Toko", True), ("Diskon Produk", False), ("Flash Sale", False)]:
        x += chip(d, (x, y), label, on, size=24, padx=26, h=62) + 14
    y += 96

    promos = [("DISKON20", "Diskon 20%", "Maks. " + rupiah(50000) + " - min. belanja " + rupiah(150000),
               "1 - 31 Agu 2026", "Aktif", GREEN, GREEN_SOFT, 0.18, "18 / 100 dipakai"),
              ("GRATISONGKIR", "Gratis Ongkir " + rupiah(15000), "Min. belanja " + rupiah(100000),
               "15 - 30 Agu 2026", "Terjadwal", BLUE, BLUE_SOFT, 0.0, "Mulai 15 Agu 2026"),
              ("HEMAT10", "Diskon 10%", "Maks. " + rupiah(25000) + " - tanpa minimum",
               "1 - 31 Jul 2026", "Berakhir", TEXT_SEC, (238, 233, 229), 1.0, "100 / 100 dipakai")]

    for i, (kode, judul, syarat, periode, status, color, soft, progress, ket) in enumerate(promos):
        by = y + i * 340
        hgt = 300
        dd = card(img, (PAD, by, W - PAD, by + hgt), r=26)
        # sisi kiri bergaya tiket (dipotong rapi mengikuti sudut kartu)
        strip = Image.new("RGB", (134, hgt), soft)
        mask = Image.new("L", (134, hgt), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, 134 + 26, hgt - 1), radius=26, fill=255)
        img.paste(strip, (PAD, by), mask)
        dd = ImageDraw.Draw(img)
        icon(dd, (PAD + 67, by + hgt / 2 - 16), "ticket", 40, color, anchor="mm")
        text(dd, (PAD + 67, by + hgt / 2 + 14), "VOUCHER", 16, "b", color, anchor="ma")
        for ny in range(by + 24, by + hgt - 20, 28):
            dd.line((PAD + 134, ny, PAD + 134, ny + 14), fill=DIVIDER, width=3)

        tx = PAD + 168
        text(dd, (tx, by + 30), kode, 30, "b", TEXT)
        badge(dd, (W - PAD - 24, by + 28), status, soft, color, size=19, padx=16, pady=8, anchor="rt")
        text(dd, (tx, by + 78), judul, 25, "b", color if status != "Berakhir" else TEXT_SEC)
        text(dd, (tx, by + 116), ellipsize(syarat, W - PAD - 24 - tx, 21, "r"), 21, "r", TEXT_SEC)
        icon(dd, (tx, by + 168), "calendar", 20, TEXT_SEC, anchor="lm")
        text(dd, (tx + 30, by + 168), periode, 21, "r", TEXT_SEC, anchor="lm")
        bar = (tx, by + 200, W - PAD - 24, by + 216)
        rr(dd, bar, 8, fill=(240, 233, 228))
        if progress > 0:
            rr(dd, (bar[0], bar[1], bar[0] + (bar[2] - bar[0]) * progress, bar[3]), 8, fill=color)
        text(dd, (tx, by + 228), ket, 20, "r", TEXT_SEC)
        divider(dd, by + 264, tx, W - PAD - 24)
        icon(dd, (tx, by + 284), "pencil", 20, PRIMARY, anchor="lm")
        text(dd, (tx + 28, by + 284), "Ubah", 21, "b", PRIMARY, anchor="lm")
        icon(dd, (tx + 120, by + 284), "eye", 20, TEXT_SEC, anchor="lm")
        text(dd, (tx + 150, by + 284), "Statistik", 21, "r", TEXT_SEC, anchor="lm")
        toggle(dd, (W - PAD - 100, by + 266), on=(status == "Aktif"), w=64, h=36)

    fy = H - 168
    primary_button(img, (PAD, fy, W - PAD, fy + 100), "Buat Voucher Baru", icon_name="plus")
    save(img, path)


# ------------------------------------------------------------------------ 12. chat
def chat(path):
    img, d = new_screen()
    status_bar(d)

    # header chat
    y = 96
    icon(d, (PAD, y + 46), "arrow_left", 34, TEXT, anchor="lm")
    d.ellipse((PAD + 60, y + 12, PAD + 128, y + 80), fill=PRIMARY_SOFT)
    icon(d, (PAD + 94, y + 46), "user", 30, PRIMARY, anchor="mm")
    text(d, (PAD + 148, y + 16), "Andi Pratama", 30, "b", TEXT)
    d.ellipse((PAD + 148, y + 60, PAD + 166, y + 78), fill=GREEN)
    text(d, (PAD + 178, y + 52), "Online", 21, "r", GREEN)
    icon(d, (W - PAD, y + 46), "dots", 30, TEXT, anchor="rm")
    y += 106
    divider(d, y, 0, W)
    y += 24

    # konteks produk
    dd = card(img, (PAD, y, W - PAD, y + 132), r=22, fill=PRIMARY_SOFT, shadow=False)
    thumb(dd, (PAD + 22, y + 22, PAD + 110, y + 110), r=14)
    text(dd, (PAD + 130, y + 30), "Kaos Oversize Basic", 24, "b", TEXT)
    text(dd, (PAD + 130, y + 66), rupiah(129000) + " - stok 42", 22, "m", PRIMARY)
    icon(dd, (W - PAD - 26, y + 66), "chev_r", 22, TEXT_SEC, anchor="rm")
    y += 164

    text(d, (W / 2, y), "Hari Ini", 20, "m", TEXT_SEC, anchor="ma")
    y += 48

    bubbles = [
        ("in", "Halo kak, kaos oversize yang hitam ready ukuran XL?", "09:12"),
        ("out", "Halo kak Andi, ready ya. Stok XL masih 12 pcs.", "09:14"),
        ("in", "Kalau order sekarang bisa dikirim hari ini?", "09:15"),
        ("out", "Bisa kak, kalau bayar sebelum jam 3 sore kami kirim hari ini juga.", "09:16"),
        ("in", "Oke kak, saya checkout sekarang ya", "09:18"),
    ]
    for side, msg, when in bubbles:
        max_w = 440
        # bungkus teks manual
        words, lines, cur = msg.split(), [], ""
        for w in words:
            trial = (cur + " " + w).strip()
            if tw(trial, 24) > max_w and cur:
                lines.append(cur)
                cur = w
            else:
                cur = trial
        lines.append(cur)
        bw = max(tw(l, 24) for l in lines) + 56
        bh = len(lines) * 40 + 52
        if side == "in":
            box = (PAD, y, PAD + bw, y + bh)
            d.rounded_rectangle(box, radius=24, fill=SURFACE)
            for i, l in enumerate(lines):
                text(d, (PAD + 28, y + 22 + i * 40), l, 24, "r", TEXT)
            text(d, (PAD + 8, y + bh + 6), when, 19, "r", TEXT_SEC)
        else:
            box = (W - PAD - bw, y, W - PAD, y + bh)
            d.rounded_rectangle(box, radius=24, fill=PRIMARY)
            for i, l in enumerate(lines):
                text(d, (W - PAD - bw + 28, y + 22 + i * 40), l, 24, "r", (255, 255, 255))
            icon(d, (W - PAD - 8, y + bh + 16), "check", 18, TEXT_SEC, anchor="rm")
            text(d, (W - PAD - 34, y + bh + 6), when, 19, "r", TEXT_SEC, anchor="ra")
        y += bh + 46

    # sedang mengetik
    d.rounded_rectangle((PAD, y, PAD + 150, y + 66), radius=24, fill=SURFACE)
    for i in range(3):
        cx = PAD + 46 + i * 28
        d.ellipse((cx - 8, y + 25, cx + 8, y + 41), fill=(205, 195, 188))
    y += 100

    # balasan cepat
    x = PAD
    for label in ["Siap kak", "Ready ya kak", "Terima kasih"]:
        x += chip(d, (x, y), label, False, size=22, padx=22, h=56) + 12

    # input bar
    by = H - 150
    d.rectangle((0, by - 20, W, H), fill=SURFACE)
    d.line((0, by - 20, W, by - 20), fill=DIVIDER, width=2)
    icon(d, (PAD, by + 52), "picture", 32, TEXT_SEC, anchor="lm")
    icon(d, (PAD + 66, by + 52), "tag", 30, TEXT_SEC, anchor="lm")
    rr(d, (PAD + 120, by + 12, W - PAD - 100, by + 92), 999, fill=BG)
    text(d, (PAD + 152, by + 53), "Tulis pesan...", 25, "r", (185, 170, 162), anchor="lm")
    d.ellipse((W - PAD - 80, by + 12, W - PAD, by + 92), fill=PRIMARY)
    icon(d, (W - PAD - 40, by + 52), "send", 30, (255, 255, 255), anchor="mm")
    save(img, path)


# ---------------------------------------------------------------------- 13. ulasan
def ulasan(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Ulasan Produk", "Balas ulasan biar toko makin dipercaya")

    dd = card(img, (PAD, y, W - PAD, y + 250), r=26)
    text(dd, (PAD + 40, y + 44), "4.8", 72, "b", TEXT)
    for i in range(5):
        icon(dd, (PAD + 34 + i * 32, y + 156), "star", 24, AMBER, anchor="lm")
    text(dd, (PAD + 40, y + 186), "128 ulasan", 21, "r", TEXT_SEC)
    bx0, bx1 = PAD + 290, W - PAD - 80
    for i, (star, ratio) in enumerate([(5, 0.82), (4, 0.12), (3, 0.04), (2, 0.01), (1, 0.01)]):
        ly = y + 44 + i * 38
        text(dd, (bx0 - 30, ly - 4), str(star), 20, "m", TEXT_SEC, anchor="ra")
        icon(dd, (bx0 - 24, ly + 8), "star", 16, AMBER, anchor="lm")
        rr(dd, (bx0, ly, bx1, ly + 16), 8, fill=(240, 233, 228))
        if ratio > 0.02:
            rr(dd, (bx0, ly, bx0 + (bx1 - bx0) * ratio, ly + 16), 8, fill=AMBER)
        text(dd, (W - PAD - 24, ly - 4), f"{int(ratio * 100)}%", 19, "r", TEXT_SEC, anchor="ra")
    y += 286

    x = PAD
    for label, on in [("Semua", False), ("Belum Dibalas 4", True), ("5 Bintang", False)]:
        x += chip(d, (x, y - 6), label, on, size=23, padx=24, h=58) + 12
    y += 78

    reviews = [
        ("Andi Pratama", 5, "10 Agu 2026", "Kaos Oversize Basic",
         "Bahannya adem, jahitan rapi, pengiriman cepat. Recommended banget!", True, None),
        ("Siti Rahma", 4, "09 Agu 2026", "Sepatu Sneakers Urban",
         "Sepatunya bagus, cuma ukurannya agak kekecilan. Sisanya oke.", False,
         "Terima kasih kak Siti, next order boleh naik 1 size ya."),
    ]
    for nama, rating, when, produk, isi, perlu_balas, balasan in reviews:
        lines = _wrap(isi, W - PAD * 2 - 56, 23)
        body_h = 176 + len(lines) * 38 + 14
        hgt = body_h + (100 if perlu_balas else 178)
        dd = card(img, (PAD, y, W - PAD, y + hgt), r=26)
        d.ellipse((PAD + 26, y + 26, PAD + 94, y + 94), fill=PRIMARY_SOFT)
        icon(dd, (PAD + 60, y + 60), "user", 28, PRIMARY, anchor="mm")
        text(dd, (PAD + 116, y + 28), nama, 25, "b", TEXT)
        for i in range(5):
            icon(dd, (PAD + 116 + i * 30, y + 78), "star" if i < rating else "star_o", 22,
                 AMBER if i < rating else (210, 200, 194), anchor="lm")
        text(dd, (W - PAD - 26, y + 30), when, 20, "r", TEXT_SEC, anchor="ra")
        rr(dd, (PAD + 26, y + 112, PAD + 30 + tw(produk, 20, "m") + 30, y + 154), 10, fill=PRIMARY_SOFT)
        text(dd, (PAD + 42, y + 133), produk, 20, "m", PRIMARY, anchor="lm")

        ty = y + 176
        for i, l in enumerate(lines):
            text(dd, (PAD + 26, ty + i * 38), l, 23, "r", TEXT)
        ty += len(lines) * 38 + 14

        if perlu_balas:
            outline_button(dd, (PAD + 26, ty, PAD + 306, ty + 76), "Balas Ulasan",
                           icon_name="reply", size=23, r=16)
            badge(dd, (W - PAD - 26, ty + 22), "Belum dibalas", AMBER_SOFT, AMBER,
                  size=19, padx=16, pady=8, anchor="rt")
        else:
            rr(dd, (PAD + 26, ty, W - PAD - 26, ty + 154), 18, fill=PRIMARY_SOFT)
            icon(dd, (PAD + 52, ty + 36), "reply", 20, PRIMARY, anchor="lm")
            text(dd, (PAD + 82, ty + 36), "Balasan Penjual", 21, "b", PRIMARY, anchor="lm")
            text(dd, (PAD + 52, ty + 62), balasan, 22, "r", TEXT)
            text(dd, (PAD + 52, ty + 110), "Dibalas 09 Agu 2026", 19, "r", TEXT_SEC)
        y += hgt + 28
    save(img, path)


# ------------------------------------------------------------------- 14. statistik
def statistik(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Statistik Penjualan", "1 - 10 Agustus 2026", right_icons=("calendar",))

    x = PAD
    for label, on in [("7 Hari", True), ("30 Hari", False), ("90 Hari", False)]:
        x += chip(d, (x, y), label, on, size=24, padx=30, h=62) + 14
    y += 100

    stats = [("Omzet", "Rp12,4jt", "+18%", GREEN, "money"),
             ("Pesanan", "86", "+12%", GREEN, "list"),
             ("Produk Terjual", "142", "+9%", GREEN, "cube"),
             ("Rata-rata Order", "Rp144rb", "-3%", RED, "chart")]
    cw = (W - PAD * 2 - 24) / 2
    for i, (label, value, delta, dc, ic) in enumerate(stats):
        bx = PAD + (cw + 24) * (i % 2)
        by = y + (166 + 24) * (i // 2)
        dd = card(img, (bx, by, bx + cw, by + 166), r=26)
        icon(dd, (bx + 26, by + 44), ic, 24, PRIMARY, anchor="lm")
        text(dd, (bx + 58, by + 44), label, 21, "r", TEXT_SEC, anchor="lm")
        text(dd, (bx + 26, by + 72), value, 36, "b", TEXT)
        icon(dd, (bx + 26, by + 136), "up" if dc == GREEN else "down", 18, dc, anchor="lm")
        text(dd, (bx + 50, by + 136), delta + " vs minggu lalu", 20, "m", dc, anchor="lm")
    y += 166 * 2 + 24 + 40

    dd = card(img, (PAD, y, W - PAD, y + 400), r=26)
    text(dd, (PAD + 30, y + 30), "Omzet Harian", 27, "b", TEXT)
    text(dd, (W - PAD - 30, y + 36), "Puncak: Sabtu", 22, "m", PRIMARY, anchor="ra")
    bars = [0.42, 0.58, 0.35, 0.76, 0.52, 1.0, 0.68]
    vals = ["1,4jt", "1,9jt", "1,1jt", "2,4jt", "1,7jt", "3,1jt", "2,2jt"]
    labels = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]
    base, bh, bwid = y + 330, 200, 56
    gap = (W - PAD * 2 - 60 - bwid * 7) / 6
    for i, (v, lb, val) in enumerate(zip(bars, labels, vals)):
        bx = PAD + 30 + i * (bwid + gap)
        rr(dd, (bx, base - bh * v, bx + bwid, base), 12, fill=PRIMARY if v == 1.0 else (255, 160, 120))
        text(dd, (bx + bwid / 2, base - bh * v - 30), val, 18, "b",
             PRIMARY if v == 1.0 else TEXT_SEC, anchor="ma")
        text(dd, (bx + bwid / 2, base + 14), lb, 20, "r", TEXT_SEC, anchor="ma")
    y += 440

    y = section_title(d, y, "Produk Terlaris", "Lihat Semua")
    top = [("Kaos Oversize Basic", 48, 6192000), ("Sepatu Sneakers Urban", 22, 7678000),
           ("Tas Selempang Kanvas", 18, 3582000)]
    for i, (nama, terjual, omzet) in enumerate(top):
        by = y + i * 132
        dd = card(img, (PAD, by, W - PAD, by + 116), r=22)
        rank_color = [PRIMARY, (255, 160, 120), (255, 200, 170)][i]
        d.ellipse((PAD + 22, by + 38, PAD + 62, by + 78), fill=rank_color)
        text(dd, (PAD + 42, by + 58), str(i + 1), 22, "b", (255, 255, 255), anchor="mm")
        thumb(dd, (PAD + 78, by + 22, PAD + 150, by + 94), r=14)
        text(dd, (PAD + 170, by + 28), ellipsize(nama, 300, 24, "b"), 24, "b", TEXT)
        text(dd, (PAD + 170, by + 64), f"{terjual} terjual", 21, "r", TEXT_SEC)
        text(dd, (W - PAD - 24, by + 46), rupiah(omzet), 24, "b", PRIMARY, anchor="ra")
    save(img, path)


# ----------------------------------------------------------------- 15. profil toko
def profil_toko(path):
    img, d = new_screen()

    # header oranye melengkung
    head_h = 440
    d.rectangle((0, 0, W, head_h - 110), fill=PRIMARY)
    d.pieslice((-170, head_h - 300, W + 170, head_h), 0, 180, fill=PRIMARY)
    status_bar(d, dark=True)
    icon(d, (W - PAD, 116), "cog", 34, (255, 255, 255), anchor="rm")

    d.ellipse((W / 2 - 82, 150, W / 2 + 82, 314), fill=(255, 255, 255))
    d.ellipse((W / 2 - 72, 160, W / 2 + 72, 304), fill=PRIMARY_SOFT)
    icon(d, (W / 2, 232), "shop", 56, PRIMARY, anchor="mm")
    text(d, (W / 2, 330), "Ramdan Store", 38, "b", (255, 255, 255), anchor="ma")
    bw = tw("Toko Terverifikasi", 21, "m") + 66
    rr(d, (W / 2 - bw / 2, 386, W / 2 + bw / 2, 434), 999, fill=(255, 255, 255))
    icon(d, (W / 2 - bw / 2 + 20, 410), "check_circle", 20, GREEN, anchor="lm")
    text(d, (W / 2 - bw / 2 + 48, 399), "Toko Terverifikasi", 21, "m", GREEN)

    y = 480
    dd = card(img, (PAD, y, W - PAD, y + 150), r=26)
    cols = [("24", "Produk"), ("1.248", "Pengikut"), ("4.8", "Rating")]
    for i, (v, l) in enumerate(cols):
        cx = PAD + (W - PAD * 2) / 3 * i + (W - PAD * 2) / 6
        text(dd, (cx, y + 34), v, 32, "b", TEXT, anchor="ma")
        text(dd, (cx, y + 88), l, 21, "r", TEXT_SEC, anchor="ma")
        if i < 2:
            d.line((PAD + (W - PAD * 2) / 3 * (i + 1), y + 34, PAD + (W - PAD * 2) / 3 * (i + 1), y + 116),
                   fill=DIVIDER, width=2)
    y += 182

    dd = card(img, (PAD, y, W - PAD, y + 110), r=24)
    icon(dd, (PAD + 30, y + 55), "power", 26, GREEN, anchor="lm")
    text(dd, (PAD + 70, y + 28), "Toko Buka", 26, "b", TEXT)
    text(dd, (PAD + 70, y + 62), "Pesanan masuk otomatis diterima", 21, "r", TEXT_SEC)
    toggle(dd, (W - PAD - 106, y + 34), on=True)
    y += 142

    menus = [("Edit Profil Toko", "shop", "Nama, logo, deskripsi"),
             ("Alamat & Pengiriman", "map", "Alamat pickup, kurir aktif"),
             ("Rekening Bank", "bank", "BCA ****4821"),
             ("Keuangan & Pencairan", "wallet", "Saldo " + rupiah(2480000)),
             ("Statistik Penjualan", "line_chart", "Omzet, produk terlaris"),
             ("Promo & Voucher", "ticket", "2 promo aktif"),
             ("Ulasan Produk", "star", "4 belum dibalas"),
             ("Pengaturan Notifikasi", "bell", "Pesanan, chat, promo")]
    dd = card(img, (PAD, y, W - PAD, y + len(menus) * 104 + 20), r=26)
    for i, (label, ic, sub) in enumerate(menus):
        my = y + 20 + i * 104
        rr(dd, (PAD + 26, my + 18, PAD + 82, my + 74), 16, fill=PRIMARY_SOFT)
        icon(dd, (PAD + 54, my + 46), ic, 24, PRIMARY, anchor="mm")
        text(dd, (PAD + 102, my + 20), label, 25, "m", TEXT)
        text(dd, (PAD + 102, my + 52), sub, 20, "r", TEXT_SEC)
        icon(dd, (W - PAD - 28, my + 46), "chev_r", 22, TEXT_SEC, anchor="rm")
        if i < len(menus) - 1:
            divider(dd, my + 94, PAD + 102, W - PAD - 26)
    y += len(menus) * 104 + 52

    dd = card(img, (PAD, y, W - PAD, y + 100), r=24, fill=RED_SOFT, shadow=False)
    icon(dd, (W / 2 - 90, y + 50), "power", 26, RED, anchor="lm")
    text(dd, (W / 2 - 54, y + 50), "Keluar Akun", 26, "b", RED, anchor="lm")

    bottom_nav(img, "toko")
    save(img, path)


# ------------------------------------------------------------------ 16. notifikasi
def notifikasi(path):
    img, d = new_screen()
    status_bar(d)
    y = app_bar(img, d, "Notifikasi")
    text(d, (W - PAD, 118), "Tandai semua dibaca", 22, "b", PRIMARY, anchor="ra")

    x = PAD
    for label, on in [("Semua 12", True), ("Pesanan 5", False), ("Keuangan 3", False)]:
        x += chip(d, (x, y - 8), label, on, size=23, padx=24, h=58) + 12
    y += 76

    groups = [("Hari Ini", [
        ("Pesanan baru masuk", "#SHP-20260810-0142 dari Andi Pratama - segera konfirmasi",
         "2 menit lalu", "list", PRIMARY, PRIMARY_SOFT, True),
        ("Pembayaran diterima", "Pesanan #SHP-20260810-0139 sudah dibayar " + rupiah(364000),
         "18 menit lalu", "money", GREEN, GREEN_SOFT, True),
        ("Stok produk menipis", "Sepatu Sneakers Urban tersisa 8 pcs",
         "1 jam lalu", "warn", AMBER, AMBER_SOFT, True),
        ("Ulasan baru", "Andi Pratama memberi 5 bintang di Kaos Oversize Basic",
         "3 jam lalu", "star", AMBER, AMBER_SOFT, False),
    ]), ("Kemarin", [
        ("Pencairan berhasil", rupiah(1500000) + " sudah masuk ke BCA ****4821",
         "Kemarin, 16:40", "bank", BLUE, BLUE_SOFT, False),
        ("Pesan baru dari pembeli", "Siti Rahma: \"Kak, ukuran 42 ready?\"",
         "Kemarin, 13:05", "chat", PRIMARY, PRIMARY_SOFT, False),
        ("Voucher hampir habis", "DISKON20 sudah dipakai 18 dari 100 kuota",
         "Kemarin, 08:30", "ticket", GREEN, GREEN_SOFT, False),
    ])]

    for judul, items in groups:
        text(d, (PAD, y), judul, 26, "b", TEXT)
        y += 54
        for title, body, when, ic, color, soft, unread in items:
            lines = _wrap(body, W - PAD * 2 - 190, 21)
            hgt = 100 + len(lines) * 32 + 34
            dd = card(img, (PAD, y, W - PAD, y + hgt), r=24,
                      fill=(255, 247, 241) if unread else SURFACE)
            rr(dd, (PAD + 26, y + 30, PAD + 90, y + 94), 18, fill=soft)
            icon(dd, (PAD + 58, y + 62), ic, 26, color, anchor="mm")
            text(dd, (PAD + 112, y + 26), title, 25, "b", TEXT)
            for i, l in enumerate(lines):
                text(dd, (PAD + 112, y + 66 + i * 32), l, 21, "r", TEXT_SEC)
            text(dd, (PAD + 112, y + 74 + len(lines) * 32), when, 19, "r", (185, 170, 162))
            if unread:
                d.ellipse((W - PAD - 44, y + 34, W - PAD - 24, y + 54), fill=PRIMARY)
            y += hgt + 20
        y += 24
    save(img, path)


def _wrap(s, max_w, size, weight="r"):
    words, lines, cur = s.split(), [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if tw(trial, size, weight) > max_w and cur:
            lines.append(cur)
            cur = w
        else:
            cur = trial
    lines.append(cur)
    return lines
