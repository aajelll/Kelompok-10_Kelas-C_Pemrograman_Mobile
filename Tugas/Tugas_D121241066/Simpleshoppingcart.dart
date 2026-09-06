class Product {
  String name;
  double price;   // harga per item
  int quantity;   // jumlah pembelian

  Product(this.name, this.price, this.quantity);

  // menghitung subtotal tiap produk
  double get subtotal => price * quantity;
}

// menghitung total belanja sebelum diskon
double calculateTotalBelanja(List<Product> cart) {
  double total = 0;
  for (var item in cart) {
    total += item.subtotal;
  }
  return total;
}

// menentukan persentase diskon berdasarkan total belanja
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
    Product('Hirono Gendut', 275435, 2),
    Product('Boneka Sapi', 140000, 3),
    Product('Kopken', 62000, 2),
    Product('Cheese Cake', 89000, 1),
  ];

  print('SIMPLE SHOPPING CART');
  print(
      '${'Produk'.padRight(16)} ${'Harga'.padRight(10)} ${'Jml'.padRight(5)} Subtotal');
  print('------------------------------------------------------');

  // Loop menampilkan tiap produk dan subtotalnya
  for (var item in cart) {
    print(
        '${item.name.padRight(16)} ${item.price.toStringAsFixed(0).padRight(10)} ${item.quantity.toString().padRight(5)} ${item.subtotal.toStringAsFixed(0)}');
  }

  // total belanja sebelum diskon
  double totalBelanja = calculateTotalBelanja(cart);

  // diskon berdasarkan total belanja 
  double discountPercentage = getDiscountPercentage(totalBelanja);
  double discountAmount = totalBelanja * discountPercentage;

  // total akhir setelah diskon
  double totalAkhir = totalBelanja - discountAmount;

  print('------------------------------------------------------');
  print('Subtotal Belanja : Rp ${totalBelanja.toStringAsFixed(0)}');

  // menampilkan informasi diskon
  if (discountPercentage > 0) {
    print(
        'Diskon           : ${(discountPercentage * 100).toStringAsFixed(0)}% (Rp ${discountAmount.toStringAsFixed(0)})');
  } else {
    print('Diskon           : Tidak ada diskon');
  }

  print('Total Pembayaran : Rp ${totalAkhir.toStringAsFixed(0)}');
}