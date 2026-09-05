// ==========================================================
// INDEPENDENT PRACTICE - SIMPLE SHOPPING CART
// ==========================================================
// Program untuk menyimpan produk (nama, harga, jumlah),
// menghitung subtotal, diskon, dan total pembayaran.

class Product {
  String name;
  double price;   // harga per item
  int quantity;   // jumlah pembelian

  Product(this.name, this.price, this.quantity);

  // Function untuk menghitung subtotal tiap produk
  double get subtotal => price * quantity;
}

// Function untuk menghitung total belanja sebelum diskon
double calculateTotalBelanja(List<Product> cart) {
  double total = 0;
  for (var item in cart) {
    total += item.subtotal;
  }
  return total;
}

// Function untuk menentukan persentase diskon berdasarkan total belanja
double getDiscountPercentage(double totalBelanja) {
  if (totalBelanja >= 500000) {
    return 0.20; // 20%
  } else if (totalBelanja >= 300000) {
    return 0.10; // 10%
  } else if (totalBelanja >= 100000) {
    return 0.05; // 5%
  } else {
    return 0.0; // tidak dapat diskon
  }
}

void main() {
  // Data produk di keranjang belanja
  List<Product> cart = [
    Product('Sepatu Running', 350000, 1),
    Product('Kaos Polos', 75000, 3),
    Product('Topi', 50000, 2),
    Product('Botol Minum', 40000, 1),
  ];

  print('=============== SIMPLE SHOPPING CART ===============');
  print(
      '${'Produk'.padRight(16)} ${'Harga'.padRight(10)} ${'Jml'.padRight(5)} Subtotal');
  print('------------------------------------------------------');

  // Loop untuk menampilkan tiap produk dan subtotalnya
  for (var item in cart) {
    print(
        '${item.name.padRight(16)} ${item.price.toStringAsFixed(0).padRight(10)} ${item.quantity.toString().padRight(5)} ${item.subtotal.toStringAsFixed(0)}');
  }

  // Menghitung total belanja sebelum diskon
  double totalBelanja = calculateTotalBelanja(cart);

  // Menentukan diskon berdasarkan total belanja (operator perbandingan di dalam function)
  double discountPercentage = getDiscountPercentage(totalBelanja);
  double discountAmount = totalBelanja * discountPercentage;

  // Menghitung total akhir setelah diskon
  double totalAkhir = totalBelanja - discountAmount;

  print('------------------------------------------------------');
  print('Subtotal Belanja : Rp ${totalBelanja.toStringAsFixed(0)}');

  // if/else untuk menampilkan informasi diskon
  if (discountPercentage > 0) {
    print(
        'Diskon           : ${(discountPercentage * 100).toStringAsFixed(0)}% (Rp ${discountAmount.toStringAsFixed(0)})');
  } else {
    print('Diskon           : Tidak ada diskon');
  }

  print('Total Pembayaran : Rp ${totalAkhir.toStringAsFixed(0)}');
}