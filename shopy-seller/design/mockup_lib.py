"""Helper render mockup Shopy Seller — gaya "Bold & Colorful" (sama seperti mockup
pembeli di shopy-mobile/design/assets).

Kanvas 750x2160 (setara layar 375x1080 @2x), font Poppins, ikon FontAwesome 4.7.
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ---------------------------------------------------------------- design token
W, H = 750, 2160
PAD = 48

BG = (255, 250, 244)
SURFACE = (255, 255, 255)
PRIMARY = (255, 107, 53)
PRIMARY_DARK = (224, 80, 30)
PRIMARY_SOFT = (255, 240, 227)
IMG_BG = (255, 232, 214)
IMG_ICON = (255, 189, 140)
TEXT = (36, 22, 20)
TEXT_SEC = (150, 120, 110)
DIVIDER = (240, 230, 222)
BLUE = (59, 130, 246)
BLUE_SOFT = (226, 238, 255)
GREEN = (34, 150, 90)
GREEN_SOFT = (223, 244, 233)
RED = (220, 60, 60)
RED_SOFT = (255, 231, 231)
AMBER = (240, 165, 30)
AMBER_SOFT = (255, 243, 219)
DARK = (43, 45, 66)

FONT_DIR = "/usr/share/fonts/truetype/google-fonts/"
FA_PATH = "/usr/share/fonts/opentype/font-awesome/FontAwesome.otf"
_FONT_FILES = {
    "l": "Poppins-Light.ttf",
    "r": "Poppins-Regular.ttf",
    "m": "Poppins-Medium.ttf",
    "b": "Poppins-Bold.ttf",
}
_cache = {}


def P(size, weight="r"):
    key = (size, weight)
    if key not in _cache:
        _cache[key] = ImageFont.truetype(FONT_DIR + _FONT_FILES[weight], size)
    return _cache[key]


def FA(size):
    key = (size, "fa")
    if key not in _cache:
        _cache[key] = ImageFont.truetype(FA_PATH, size)
    return _cache[key]


_ICON_HEX = {
    "home": "f015", "cube": "f1b2", "bag": "f290", "list": "f022",
    "chat": "f086", "user": "f007", "plus": "f067", "chart": "f080",
    "money": "f0d6", "star": "f005", "star_o": "f006", "chev_r": "f054",
    "chev_l": "f053", "chev_d": "f078", "bell": "f0f3", "camera": "f030",
    "truck": "f0d1", "pencil": "f040", "trash": "f1f8", "search": "f002",
    "tag": "f02b", "ticket": "f145", "picture": "f03e", "cog": "f013",
    "check": "f00c", "check_circle": "f058", "times": "f00d",
    "toggle_on": "f205", "toggle_off": "f204", "bank": "f19c",
    "archive": "f187", "line_chart": "f201", "eye": "f06e", "clock": "f017",
    "info": "f05a", "warn": "f06a", "refresh": "f021", "percent": "f295",
    "reply": "f112", "send": "f1d8", "calendar": "f073", "filter": "f0b0",
    "card": "f09d", "building": "f1ad", "upload": "f093", "up": "f062",
    "down": "f063", "shop": "f290", "wallet": "f0d6", "copy": "f0c5",
    "dots": "f142", "menu": "f0c9", "sliders": "f1de", "image": "f03e",
    "phone": "f095", "map": "f041", "flash": "f0e7", "gift": "f06b",
    "arrow_left": "f060", "download": "f019", "qr": "f029", "id": "f2c2",
    "history": "f1da", "megaphone": "f0a1", "heart": "f004",
    "circle": "f111", "circle_o": "f10c", "file": "f15c", "print": "f02f",
    "sort": "f0dc", "power": "f011", "lock": "f023", "envelope": "f0e0",
    "external": "f08e", "bolt": "f0e7", "cart": "f07a",
}
ICON = {k: chr(int(v, 16)) for k, v in _ICON_HEX.items()}


# ------------------------------------------------------------------ primitives
def new_screen(bg=BG):
    img = Image.new("RGB", (W, H), bg)
    return img, ImageDraw.Draw(img)


def rr(d, box, r, fill=None, outline=None, width=2):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def card(img, box, r=28, fill=SURFACE, shadow=True, outline=None, width=2):
    """Rounded card + soft drop shadow."""
    if shadow:
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        x0, y0, x1, y1 = box
        ld.rounded_rectangle((x0 + 2, y0 + 8, x1 + 2, y1 + 10), radius=r,
                             fill=(150, 110, 90, 46))
        layer = layer.filter(ImageFilter.GaussianBlur(9))
        img.paste(Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB"), (0, 0))
    d = ImageDraw.Draw(img)
    rr(d, box, r, fill=fill, outline=outline, width=width)
    return d


def text(d, xy, s, size=26, weight="r", fill=TEXT, anchor="la"):
    d.text(xy, s, font=P(size, weight), fill=fill, anchor=anchor)


def tw(s, size, weight="r"):
    return P(size, weight).getlength(s)


def icon(d, xy, name, size=30, fill=TEXT, anchor="lm"):
    d.text(xy, ICON[name], font=FA(size), fill=fill, anchor=anchor)


def iw(name, size):
    return FA(size).getlength(ICON[name])


def thumb(d, box, r=20, bg=IMG_BG, fg=IMG_ICON):
    """Placeholder gambar produk: kotak + matahari + gunung (sama seperti mockup pembeli)."""
    x0, y0, x1, y1 = box
    rr(d, box, r, fill=bg)
    w, h = x1 - x0, y1 - y0
    cr = w * 0.09
    d.ellipse((x0 + w * 0.22 - cr, y0 + h * 0.30 - cr, x0 + w * 0.22 + cr, y0 + h * 0.30 + cr), fill=fg)
    base = y1 - h * 0.22
    d.polygon([(x0 + w * 0.12, base), (x0 + w * 0.42, base - h * 0.34), (x0 + w * 0.72, base)], fill=fg)
    d.polygon([(x0 + w * 0.45, base), (x0 + w * 0.68, base - h * 0.24), (x0 + w * 0.90, base)], fill=fg)


def badge(d, xy, label, bg=PRIMARY, fg=(255, 255, 255), size=22, padx=20, pady=12, r=999, anchor="lt"):
    """Pill badge. xy = titik kiri-atas (anchor 'lt') atau kanan-atas ('rt')."""
    w = tw(label, size, "b") + padx * 2
    h = size + pady * 2
    x, y = xy
    if anchor == "rt":
        x -= w
    rr(d, (x, y, x + w, y + h), r, fill=bg)
    text(d, (x + w / 2, y + h / 2), label, size, "b", fg, anchor="mm")
    return w, h


def chip(d, xy, label, active=False, size=26, padx=28, h=64):
    w = tw(label, size, "b" if active else "r") + padx * 2
    x, y = xy
    rr(d, (x, y, x + w, y + h), 999, fill=PRIMARY if active else PRIMARY_SOFT)
    text(d, (x + w / 2, y + h / 2 + 1), label, size, "b" if active else "r",
         (255, 255, 255) if active else TEXT_SEC, anchor="mm")
    return w


def status_bar(d, dark=False):
    fg = (255, 255, 255) if dark else TEXT
    text(d, (PAD, 30), "9:41", 30, "b", fg)
    # sinyal + baterai
    x = W - PAD - 42
    d.rounded_rectangle((x, 30, x + 42, 54), radius=6, outline=fg, width=3)
    d.rounded_rectangle((x + 4, 34, x + 34, 50), radius=3, fill=fg)
    d.rounded_rectangle((x + 44, 37, x + 48, 47), radius=2, fill=fg)
    cx = x - 22
    for i in range(3):
        d.ellipse((cx - 9, 33, cx + 9, 51), fill=fg)
        cx -= 26


def app_bar(img, d, title, subtitle=None, back=True, right_icons=(), y=100):
    """Header halaman: tombol back + judul (+ subjudul) + ikon kanan."""
    x = PAD
    if back:
        icon(d, (x + 6, y + 26), "arrow_left", 34, TEXT, anchor="lm")
        x += 62
    text(d, (x, y), title, 40, "b", TEXT)
    if subtitle:
        text(d, (x, y + 54), subtitle, 24, "r", TEXT_SEC)
    rx = W - PAD
    for name in right_icons:
        icon(d, (rx, y + 26), name, 34, TEXT, anchor="rm")
        rx -= 74
    return y + (108 if subtitle else 78)


def section_title(d, y, title, action=None):
    text(d, (PAD, y), title, 32, "b", TEXT)
    if action:
        text(d, (W - PAD, y + 6), action, 26, "b", PRIMARY, anchor="ra")
    return y + 58


def divider(d, y, x0=PAD, x1=W - PAD, color=DIVIDER):
    d.line((x0, y, x1, y), fill=color, width=2)


def primary_button(img, box, label, icon_name=None, r=20, bg=PRIMARY, fg=(255, 255, 255), size=28):
    d = card(img, box, r=r, fill=bg, shadow=False)
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    if icon_name:
        total = iw(icon_name, size + 2) + 14 + tw(label, size, "b")
        icon(d, (cx - total / 2, cy + 1), icon_name, size + 2, fg, anchor="lm")
        text(d, (cx - total / 2 + iw(icon_name, size + 2) + 14, cy + 1), label, size, "b", fg, anchor="lm")
    else:
        text(d, (cx, cy + 1), label, size, "b", fg, anchor="mm")
    return d


def outline_button(d, box, label, icon_name=None, r=20, color=PRIMARY, size=28):
    rr(d, box, r, fill=None, outline=color, width=3)
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    if icon_name:
        total = iw(icon_name, size + 2) + 14 + tw(label, size, "b")
        icon(d, (cx - total / 2, cy + 1), icon_name, size + 2, color, anchor="lm")
        text(d, (cx - total / 2 + iw(icon_name, size + 2) + 14, cy + 1), label, size, "b", color, anchor="lm")
    else:
        text(d, (cx, cy + 1), label, size, "b", color, anchor="mm")


def field(d, y, label, value, placeholder=False, h=88, icon_name=None, suffix=None,
          chevron=False, x0=PAD, x1=W - PAD):
    """Input field ala form: label kecil + kotak berisi teks."""
    text(d, (x0, y), label, 24, "m", TEXT_SEC)
    box = (x0, y + 34, x1, y + 34 + h)
    rr(d, box, 18, fill=SURFACE, outline=DIVIDER, width=2)
    tx = x0 + 26
    if icon_name:
        icon(d, (tx, y + 34 + h / 2), icon_name, 28, TEXT_SEC, anchor="lm")
        tx += 46
    text(d, (tx, y + 34 + h / 2 + 1), value, 26, "r",
         (185, 170, 162) if placeholder else TEXT, anchor="lm")
    if suffix:
        text(d, (x1 - 26, y + 34 + h / 2 + 1), suffix, 26, "m", TEXT_SEC, anchor="rm")
    if chevron:
        icon(d, (x1 - 26, y + 34 + h / 2), "chev_d", 24, TEXT_SEC, anchor="rm")
    return y + 34 + h + 30


def toggle(d, xy, on=True, w=76, h=42):
    x, y = xy
    rr(d, (x, y, x + w, y + h), 999, fill=PRIMARY if on else (218, 208, 200))
    cx = x + w - h / 2 if on else x + h / 2
    d.ellipse((cx - h / 2 + 5, y + 5, cx + h / 2 - 5, y + h - 5), fill=(255, 255, 255))


def panel(img, box, r=32, fill=PRIMARY, decorate=None, shadow=True):
    """Kartu berwarna dengan dekorasi yang dipotong rapi mengikuti sudut membulat."""
    x0, y0, x1, y1 = [int(v) for v in box]
    w, h = x1 - x0, y1 - y0
    if shadow:
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).rounded_rectangle((x0 + 2, y0 + 10, x1 + 2, y1 + 12), radius=r,
                                               fill=(150, 110, 90, 60))
        layer = layer.filter(ImageFilter.GaussianBlur(11))
        img.paste(Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB"), (0, 0))
    tile = Image.new("RGB", (w, h), fill)
    if decorate:
        decorate(ImageDraw.Draw(tile), w, h)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=r, fill=255)
    img.paste(tile, (x0, y0), mask)
    return ImageDraw.Draw(img)


def ellipsize(s, max_w, size, weight="r"):
    if tw(s, size, weight) <= max_w:
        return s
    while s and tw(s + "...", size, weight) > max_w:
        s = s[:-1]
    return s.rstrip() + "..."


def rupiah(n):
    return "Rp" + f"{n:,}".replace(",", ".")


def bottom_nav(img, active="beranda"):
    """Bottom nav app seller: Beranda / Produk / Pesanan / Chat / Toko."""
    d = ImageDraw.Draw(img)
    top = H - 130
    d.rectangle((0, top, W, H), fill=SURFACE)
    d.line((0, top, W, top), fill=DIVIDER, width=2)
    items = [("beranda", "home", "Beranda", 0), ("produk", "cube", "Produk", 0),
             ("pesanan", "list", "Pesanan", 3), ("chat", "chat", "Chat", 2),
             ("toko", "shop", "Toko", 0)]
    slot = W / len(items)
    for i, (key, ic, label, badge_count) in enumerate(items):
        cx = slot * i + slot / 2
        on = key == active
        color = PRIMARY if on else TEXT_SEC
        icon(d, (cx, top + 46), ic, 36, color, anchor="mm")
        text(d, (cx, top + 76), label, 21, "b" if on else "r", color, anchor="ma")
        if badge_count:
            bx, by = cx + 22, top + 26
            rr(d, (bx, by, bx + 34, by + 30), 999, fill=RED)
            text(d, (bx + 17, by + 16), str(badge_count), 19, "b", (255, 255, 255), anchor="mm")
    return d


def save(img, path):
    img.save(path)
    print("saved", path)
