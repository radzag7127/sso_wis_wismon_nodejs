// User and Authentication Types
export interface User {
  id: string;
  username: string;
  email?: string;
  created_at?: Date;
}

export interface UserRole {
  username: string;
  app: string;
  rid: string;
}

export interface Student {
  nrm: string;
  nim: string;
  namam: string;
  tgdaftar?: Date;
  tplahir?: Date;
  kdagama?: string;
  email?: string;
}

export interface Employee {
  nip: string;
  nama: string;
  kdagama?: string;
}

// Payment Types
export interface PaymentTransaction {
  id: string;
  kode_transaksi: string;
  tanggal: Date;
  total: number;
  status: string;
  jenistransaksi_id?: string;
  akun_debit?: string;
  akun_kredit?: string;
}

export interface PaymentType {
  id: string;
  kode: string;
  nama_jenis: string;
}

export interface Account {
  id: string;
  kode: string;
  nama_akun: string;
}

export interface StudentPayment {
  no: string;
  nrm: string;
  prodi?: string;
  semester?: string;
  tahun_akademik?: string;
  jumlah: number;
  tanggal_bayar: Date;
}

// API Response Types
export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  errors?: string[];
}

export interface LoginRequest {
  namam_nim: string; // Can be student name or NIM
  nrm: string;
}

export interface LoginResponse {
  token: string;
  user: {
    nrm: string;
    nim: string;
    namam: string;
  };
}

export interface PaymentHistoryQuery {
  page?: number;
  limit?: number;
  startDate?: string;
  endDate?: string;
  type?: string;
  sortBy?: "tanggal" | "jumlah" | "type";
  sortOrder?: "asc" | "desc";
}

export interface PaymentHistoryItem {
  id: string;
  tanggal: string;
  tanggal_full: string;
  type: string;
  jumlah: string;
  status: string;
  tx_id: string;
  method: string;
  method_code: string;
}

export interface PaymentSummary {
  total_pembayaran: string;
  breakdown: {
    [key: string]: string;
  };
}

export interface TransactionDetail extends PaymentHistoryItem {
  student_name: string;
  student_nim: string;
  student_prodi: string;
  payment_breakdown: {
    [key: string]: string;
  };
}






// --- Akademik ---
export interface Course {
  namamk: string;
  sks: number;
  nilai?: string;
  bobotNilai?: number;
  semesterKe?: number;
}

export interface Transkrip {
  ipk: string;
  total_sks: number;
  courses: Course[];
}

/**
 * Interface untuk data JWT payload yang disimpan di dalam token.
 * Digunakan untuk type safety saat mengakses data user dari token.
 */
export interface JWTPayload {
  nrm: string;
  nim: string;
  namam: string;
  iat?: number;
  exp?: number;
}



// ITU KRSCOURSE SAMA KHSCOURSE REDUNDANT, MUNGKIN BAKALAN TAK BENERIN KALAU UDAH SELESAI
/**
 * Interface untuk satu mata kuliah yang ada di dalam KRS.
 */
export interface KrsCourse {
  kodeMataKuliah: string;
  namaMataKuliah: string;
  sks: number;
  kelas: string | null; // Kelas bisa jadi null jika tidak ada data kelas yang cocok
}

/**
 * Interface untuk struktur data KRS yang akan dikirim sebagai respons API.
 */
export interface Krs {
  semesterKe: number;
  jenisSemester: string; // e.g., "Ganjil", "Genap"
  tahunAjaran: string; // e.g., "2023/2024"
  mataKuliah: KrsCourse[];
  totalSks: number;
}

/**
 * Merepresentasikan satu mata kuliah dalam Kartu Hasil Studi (KHS).
 */
export interface KhsCourse {
  nilai: string; // Nilai huruf (A, B, C, D, E)
  kodeMataKuliah: string;
  namaMataKuliah: string;
  sks: number;
  kelas: string | null;
}

/**
* Merepresentasikan rekapitulasi perhitungan IP dan SKS.
*/
export interface Rekapitulasi {
  ipSemester: string;      // Format: "Lulus / Beban" -> "3.50 / 3.25"
  sksSemester: string;     // Format: "Lulus / Beban" -> "18 / 20"
  ipKumulatif: string;     // Format: "Lulus / Beban"
  sksKumulatif: string;    // Format: "Lulus / Beban"
}

/**
* Merepresentasikan objek KHS secara keseluruhan yang akan dikirim sebagai respons.
*/
export interface Khs {
  semesterKe: number;
  jenisSemester: string;
  tahunAjaran: string;
  mataKuliah: KhsCourse[];
  rekapitulasi: Rekapitulasi;
}

export interface DaftarMahasiswa {
  nrm: string;
  nama: string;
}
