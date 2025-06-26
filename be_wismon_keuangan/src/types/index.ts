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
