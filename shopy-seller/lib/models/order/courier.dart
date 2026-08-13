class Courier {
  final String code;
  final String service;
  final String label;
  final int price;
  final String eta;

  const Courier({
    required this.code,
    required this.service,
    required this.label,
    required this.price,
    required this.eta,
  });
}

/// Tabel tarif kurir statis — cerminan `Couriers` di backend
/// (`shopy-api/Models/Orders/CourierOption.cs`, TASKSELLER.md Fase 4).
const kCouriers = [
  Courier(code: 'JNE', service: 'REG', label: 'JNE Reguler', price: 15000, eta: '2-3 hari'),
  Courier(code: 'JNT', service: 'EZ', label: 'J&T Express', price: 14000, eta: '2-4 hari'),
  Courier(code: 'SICEPAT', service: 'REG', label: 'SiCepat REG', price: 16000, eta: '1-3 hari'),
];
