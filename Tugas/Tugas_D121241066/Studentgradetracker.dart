class Student {
  String name;
  double score;      // nilai (0 - 100)
  double attendance;  // persentase kehadiran (0 - 100)

  Student(this.name, this.score, this.attendance);
}

// menentukan grade huruf berdasarkan nilai
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

// menentukan status kelulusan
String getStatus(double score, double attendance) {
  if (score >= 60 && attendance >= 75) {
    return 'LULUS';
  } else {
    return 'TIDAK LULUS';
  }
}

void main() {
  // data mahasiswa
  List<Student> students = [
    Student('Ajel', 88, 90),
    Student('Hana', 98, 94),
    Student('Mello', 82, 90),
    Student('Abid', 50, 25),
    Student('Jael', 48, 40),
  ];

  print('STUDENT GRADE TRACKER');
  print(
      '${'Nama'.padRight(10)} ${'Nilai'.padRight(8)} ${'Kehadiran'.padRight(11)} ${'Grade'.padRight(7)} Status');
  print('-----------------------------------------------------------');

  // menghitung ringkasan
  int totalLulus = 0;
  int totalTidakLulus = 0;
  double totalNilai = 0;

  // memproses tiap mahasiswa
  for (var student in students) {
    String grade = getGrade(student.score);
    String status = getStatus(student.score, student.attendance);

    // menghitung jumlah lulus/tidak lulus
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