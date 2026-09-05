// ==========================================================
// GUIDED PRACTICE - STUDENT GRADE TRACKER
// ==========================================================
// Program untuk menyimpan data mahasiswa (nama, nilai, kehadiran)
// lalu menentukan grade dan status kelulusan tiap mahasiswa.

class Student {
  String name;
  double score;      // nilai (0 - 100)
  double attendance;  // persentase kehadiran (0 - 100)

  Student(this.name, this.score, this.attendance);
}

// Function untuk menentukan grade huruf berdasarkan nilai
String getGrade(double score) {
  if (score >= 85) {
    return 'A';
  } else if (score >= 75) {
    return 'B';
  } else if (score >= 65) {
    return 'C';
  } else if (score >= 50) {
    return 'D';
  } else {
    return 'E';
  }
}

// Function untuk menentukan status kelulusan
// Syarat lulus: nilai >= 60 DAN kehadiran >= 75%
String getStatus(double score, double attendance) {
  if (score >= 60 && attendance >= 75) {
    return 'LULUS';
  } else {
    return 'TIDAK LULUS';
  }
}

void main() {
  // Data beberapa mahasiswa
  List<Student> students = [
    Student('Andi', 88, 90),
    Student('Budi', 55, 80),
    Student('Citra', 70, 65),
    Student('Dewi', 92, 95),
    Student('Eka', 48, 40),
  ];

  print('=========== STUDENT GRADE TRACKER ===========');
  print(
      '${'Nama'.padRight(10)} ${'Nilai'.padRight(8)} ${'Kehadiran'.padRight(11)} ${'Grade'.padRight(7)} Status');
  print('-----------------------------------------------------------');

  // Variable untuk menghitung ringkasan
  int totalLulus = 0;
  int totalTidakLulus = 0;
  double totalNilai = 0;

  // Loop untuk memproses tiap mahasiswa
  for (var student in students) {
    String grade = getGrade(student.score);
    String status = getStatus(student.score, student.attendance);

    // Operator perbandingan untuk menghitung jumlah lulus/tidak lulus
    if (status == 'LULUS') {
      totalLulus++;
    } else {
      totalTidakLulus++;
    }

    totalNilai += student.score;

    print(
        '${student.name.padRight(10)} ${student.score.toStringAsFixed(1).padRight(8)} ${student.attendance.toStringAsFixed(0).padRight(11)} ${grade.padRight(7)} $status');
  }

  double rataRata = totalNilai / students.length;

  print('-----------------------------------------------------------');
  print('Total Mahasiswa   : ${students.length}');
  print('Rata-rata Nilai   : ${rataRata.toStringAsFixed(2)}');
  print('Jumlah Lulus      : $totalLulus');
  print('Jumlah Tidak Lulus: $totalTidakLulus');
}