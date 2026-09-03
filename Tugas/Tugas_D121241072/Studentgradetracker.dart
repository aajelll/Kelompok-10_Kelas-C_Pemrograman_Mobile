// STUDENT GRADE TRACKER

// Function untuk menentukan grade
String tentukanGrade(double nilai) {
  if (nilai >= 85) {
    return "A";
  } else if (nilai >= 75) {
    return "B";
  } else if (nilai >= 65) {
    return "C";
  } else if (nilai >= 50) {
    return "D";
  } else {
    return "E";
  }
}

// Function untuk menentukan status kelulusan
String tentukanStatus(double nilai, double kehadiran) {
  if (nilai >= 65 && kehadiran >= 75) {
    return "LULUS";
  } else {
    return "TIDAK LULUS";
  }
}

void main() {
  // Data mahasiswa
  List<Map<String, dynamic>> mahasiswa = [
    {
      "nama": "Nabila",
      "nilai": 90.0,
      "kehadiran": 95.0
    },
    {
      "nama": "Andi",
      "nilai": 78.0,
      "kehadiran": 85.0
    },
    {
      "nama": "Siti",
      "nilai": 68.0,
      "kehadiran": 80.0
    },
    {
      "nama": "Budi",
      "nilai": 55.0,
      "kehadiran": 70.0
    },
  ];

  print("===== STUDENT GRADE TRACKER =====");

  // Loop untuk memproses setiap mahasiswa
  for (var siswa in mahasiswa) {
    String nama = siswa["nama"];
    double nilai = siswa["nilai"];
    double kehadiran = siswa["kehadiran"];

    String grade = tentukanGrade(nilai);
    String status = tentukanStatus(nilai, kehadiran);

    print("\nNama       : $nama");
    print("Nilai      : $nilai");
    print("Kehadiran  : $kehadiran%");
    print("Grade      : $grade");
    print("Status     : $status");
  }
}