/// Format angka jadi Rupiah, mis. 349000 -> "Rp349.000".
/// Sengaja tanpa package `intl` supaya tidak nambah dependency baru dulu.
String formatRupiah(int amount) {
  final str = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    final posFromEnd = str.length - i;
    buffer.write(str[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
  }
  return '${amount < 0 ? '-' : ''}Rp$buffer';
}
