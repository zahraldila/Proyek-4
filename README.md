# LogBook App – Implementasi Single Responsibility Principle (SRP)

## Deskripsi Proyek

Proyek ini merupakan pengembangan aplikasi Counter sederhana menggunakan Flutter dengan menerapkan prinsip **Single Responsibility Principle (SRP)**. Pada tahap awal, aplikasi hanya memiliki fungsi dasar untuk menambah dan mengurangi angka. Selanjutnya, aplikasi dikembangkan menjadi lebih kompleks dengan fitur **Multi-Step Counter** dan **History Logger**.

Tujuan dari proyek ini adalah untuk memahami bagaimana pemisahan tanggung jawab dalam kode dapat mempermudah proses pengembangan dan penambahan fitur baru tanpa merusak struktur yang sudah ada.

---

## Struktur dan Penerapan SRP

Aplikasi ini dibagi menjadi dua bagian utama:

### 1. CounterController

File ini bertanggung jawab terhadap:

* Logika perhitungan (increment dan decrement)
* Pengaturan nilai step
* Reset nilai counter
* Penyimpanan dan pengelolaan riwayat aktivitas

Controller tidak memiliki kode tampilan (UI). Semua proses bisnis ditempatkan di sini agar terpisah dari bagian presentasi.

### 2. CounterView

File ini bertanggung jawab terhadap:

* Menampilkan tampilan aplikasi
* Menerima input dari pengguna
* Menampilkan riwayat aktivitas
* Menampilkan dialog dan notifikasi

Dengan pemisahan ini, setiap file memiliki satu tanggung jawab yang jelas sesuai prinsip SRP.

---

## Task 1 – Multi-Step Counter

Pada task pertama, counter dimodifikasi agar tidak hanya bertambah atau berkurang satu angka, tetapi mengikuti nilai **step** yang dapat diubah oleh pengguna.

### Implementasi:

* Menambahkan variabel private `_step` pada `CounterController`
* Membuat method `setStep()` untuk mengubah nilai step
* Mengubah method `increment()` dan `decrement()` agar menggunakan nilai `_step`
* Menambahkan `TextField` pada tampilan untuk mengatur step

### Validasi:

* Step tidak boleh bernilai 0 atau negatif
* Jika input tidak valid, akan muncul pesan error
* Tombol + dan − akan dinonaktifkan jika step tidak valid

---

## Task 2 – History Logger

Pada task kedua, aplikasi dikembangkan agar dapat mencatat setiap perubahan nilai counter.

### Implementasi:

* Menggunakan `List<String>` untuk menyimpan riwayat aktivitas
* Setiap aksi (increment, decrement, reset, perubahan step) otomatis menambahkan log baru
* Log menampilkan waktu dan deskripsi aksi
* Riwayat dibatasi maksimal 5 aktivitas terakhir
* Data lama akan dihapus secara otomatis jika melebihi batas

Fitur ini membantu pengguna melihat aktivitas terbaru yang telah dilakukan pada aplikasi.

---

## Homework – UI & UX Improvement

Beberapa perbaikan tambahan dilakukan untuk meningkatkan tampilan dan pengalaman pengguna.

### UI Polishing

* Menggunakan tema soft pastel biru
* Memberikan warna berbeda pada riwayat:

  * Tambah → Hijau
  * Kurang → Merah
  * Reset → Biru
* Layout dibuat lebih rapi dan modern

### UX Improvement

* Menambahkan dialog konfirmasi sebelum reset
* Menampilkan SnackBar setelah reset berhasil
* Validasi input step secara langsung
* Tombol dinonaktifkan jika input tidak valid

---

## Self Reflection – Peran SRP dalam Pengembangan Fitur

Prinsip SRP sangat membantu ketika saya menambahkan fitur History Logger. Karena sejak awal logika sudah dipisahkan dari tampilan, saya hanya perlu menambahkan struktur data dan manipulasi riwayat pada `CounterController`, tanpa harus banyak mengubah struktur utama UI.

Hal ini membuat proses pengembangan lebih terarah dan meminimalkan risiko kesalahan. Jika logika dan tampilan digabung dalam satu file, penambahan fitur seperti History Logger kemungkinan akan membuat kode menjadi sulit dibaca dan sulit dirawat.

Dengan menerapkan SRP, kode menjadi lebih modular, lebih mudah dipahami, dan lebih mudah dikembangkan ke depannya.
