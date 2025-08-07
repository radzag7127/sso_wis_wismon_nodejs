# Wismon Keuangan Backend API Documentation

## Overview

Backend API untuk aplikasi Wismon Keuangan - sistem pembayaran mahasiswa Universitas Wirahusada.

### Database Architecture

- **wirahusada_sso**: Authentication dan authorization (7 tables)
- **wirahusada_wis**: Student dan staff management (7 tables)
- **wirahusada_wismon**: Financial transactions dan payment processing (20 tables)

## Authentication Endpoints

### POST /api/auth/login

Login mahasiswa menggunakan nama/NIM dan NRM.

**Request Body:**

```json
{
  "namam_nim": "string", // Nama mahasiswa atau NIM
  "nrm": "string" // Nomor Registrasi Mahasiswa
}
```

**Response:**

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt_token_here",
    "user": {
      "nrm": "student_nrm",
      "nim": "student_nim",
      "namam": "Student Full Name"
    }
  }
}
```

**Pencarian Nama Aman:**
Login mendukung pencarian nama yang case-insensitive dengan exact matching untuk keamanan:

- ✅ **Case-insensitive**: `Hanik Zaimatus Sholichah` = `hanik zaimatus sholichah`
- ✅ **Tanpa spasi**: `HanikZaimatusSholichah` akan cocok dengan `Hanik Zaimatus Sholichah`
- ✅ **Mixed case**: `hAnikzaimAtussholichAh` akan cocok dengan nama asli (tanpa spasi)
- ❌ **Partial match dihapus**: Untuk keamanan, tidak ada pencarian sebagian nama

**Authentication Flow:**

1. Coba cari berdasarkan NIM exact match
2. Jika tidak ditemukan, cari berdasarkan nama dengan exact match (case-insensitive)
3. Jika masih tidak ditemukan, coba cari dengan menghilangkan spasi (exact match, case-insensitive)

### GET /api/auth/profile

Mendapatkan profil mahasiswa yang sedang login.

**Headers:**

```
Authorization: Bearer <jwt_token>
```

**Response:**

```json
{
  "success": true,
  "data": {
    "nrm": "student_nrm",
    "nim": "student_nim",
    "namam": "Student Full Name",
    "tgdaftar": "registration_date",
    "tplahir": "birth_place"
  }
}
```

### POST /api/auth/verify

Verifikasi token JWT.

**Request Body:**

```json
{
  "token": "jwt_token_here"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "valid": true,
    "user": {
      "nrm": "student_nrm",
      "nim": "student_nim",
      "namam": "Student Full Name"
    }
  }
}
```

---

## 📋 Login Page Implementation (page1login.txt)

### `POST /api/auth/login`

**Purpose**: Student login authentication  
**Database Access**:

- Primary: `wirahusada_wis.mahasiswa` (student identification)
- Secondary: `wirahusada_sso.user` (future authentication enhancement)

**Request Body**:

```json
{
  "namam_nim": "string", // Student name OR NIM
  "nrm": "string" // Student registration number
}
```

**Response Success (200)**:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt_token_here",
    "user": {
      "nrm": "student_nrm",
      "nim": "student_nim",
      "namam": "student_name"
    }
  }
}
```

**Database Query Flow**:

1. Search by NIM + NRM: `SELECT * FROM mahasiswa WHERE nim = ? AND nrm = ?`
2. If not found, search by name: `SELECT * FROM mahasiswa WHERE namam LIKE ? AND nrm = ?`

---

## 🏠 Homepage Implementation (page2home.txt)

### `GET /api/auth/profile`

**Purpose**: Get student profile for homepage greeting ("hello, [student's namam]")  
**Database Access**: `wirahusada_wis.mahasiswa`  
**Authentication**: Required

**Response Success (200)**:

```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "nrm": "student_nrm",
    "nim": "student_nim",
    "namam": "student_name", // Used for homepage greeting
    "tgdaftar": "2023-01-15",
    "tplahir": "2001-05-20"
  }
}
```

**Database Query**: `SELECT nrm, nim, namam, tgdaftar, tplahir, kdagama FROM mahasiswa WHERE nrm = ?`

### `POST /api/auth/verify`

**Purpose**: Verify JWT token validity  
**Authentication**: Required

---

## 💰 Wismon Payment Page Implementation (page3wismon.txt)

### `GET /api/payments/history`

**Purpose**: Get payment history with filtering (Riwayat Pembayaran)  
**Database Access**:

- `wirahusada_wismon.transaksi` - Transaction records
- `wirahusada_wismon.t_pembayaranmahasiswa` - Student payment links
- `wirahusada_wismon.akun` - Account/payment method info

**Query Parameters**:

```
?page=1&limit=20&startDate=2024-01-01&endDate=2024-12-31&type=Ijazah&sortBy=tanggal&sortOrder=desc
```

**Response Success (200)**:

```json
{
  "success": true,
  "message": "Payment history retrieved successfully",
  "data": {
    "data": [
      {
        "id": "transaction_id",
        "tanggal": "24 Juni 2025",
        "tanggal_full": "24 Juni 2025, 10:30:15 WIB",
        "type": "KTI dan Wisuda",
        "jumlah": "Rp 1.750.000",
        "status": "LUNAS",
        "tx_id": "135842-AKD-20250624",
        "method": "101 - Tunai - Kas Akademi",
        "method_code": "101"
      }
    ],
    "total": 25,
    "page": 1,
    "limit": 20
  }
}
```

**Database Query**:

```sql
SELECT
  t.id, t.kode_transaksi as tx_id,
  DATE_FORMAT(t.tanggal, '%d %M %Y') as tanggal,
  DATE_FORMAT(t.tanggal, '%d %M %Y, %H:%i:%s WIB') as tanggal_full,
  a.nama_akun as type,
  CONCAT('Rp ', FORMAT(t.total, 0)) as jumlah,
  'LUNAS' as status,
  CONCAT(a.kode, ' - ', a.nama_akun) as method,
  a.kode as method_code
FROM transaksi t
INNER JOIN t_pembayaranmahasiswa tpm ON t.id = tpm.no
INNER JOIN akun a ON t.kodeakun = a.kode
WHERE tpm.nrm = ?
ORDER BY t.tanggal DESC
LIMIT ? OFFSET ?
```

### `GET /api/payments/summary`

**Purpose**: Get payment recapitulation (Rekapitulasi Pembayaran)  
**Database Access**: `wirahusada_wismon` (aggregated transaction data)

**Response Success (200)**:

```json
{
  "success": true,
  "message": "Payment summary retrieved successfully",
  "data": {
    "total_pembayaran": "Rp 2.300.000",
    "breakdown": {
      "Ijazah": "Rp 400.000",
      "KTI dan Wisuda": "Rp 1.750.000",
      "Lain-lain": "Rp 150.000"
    }
  }
}
```

**Database Query**:

```sql
SELECT
  a.nama_akun as payment_type,
  SUM(t.total) as total_amount
FROM transaksi t
INNER JOIN t_pembayaranmahasiswa tpm ON t.id = tpm.no
INNER JOIN akun a ON t.kodeakun = a.kode
WHERE tpm.nrm = ?
GROUP BY a.nama_akun, a.kode
ORDER BY total_amount DESC
```

### `GET /api/payments/detail/:id`

**Purpose**: Get detailed transaction information (Detail Transaksi)  
**Database Access**:

- `wirahusada_wismon` - Transaction details
- `wirahusada_wis.mahasiswa` - Student information

**Response Success (200)**:

```json
{
  "success": true,
  "message": "Transaction detail retrieved successfully",
  "data": {
    "id": "transaction_id",
    "tanggal": "24 Juni 2025",
    "tanggal_full": "24 Juni 2025, 10:30:15 WIB",
    "type": "KTI dan Wisuda",
    "jumlah": "Rp 1.750.000",
    "status": "LUNAS",
    "tx_id": "135842-AKD-20250624", // Copyable transaction ID
    "method": "101 - Tunai - Kas Akademi",
    "student_name": "Budi Santoso",
    "student_nim": "202201001",
    "student_prodi": "D3 Keperawatan",
    "payment_breakdown": {
      "KTI dan Wisuda": "Rp 1.750.000"
    }
  }
}
```

### `POST /api/payments/refresh`

**Purpose**: Refresh payment data (Refresh button)

**Response Success (200)**:

```json
{
  "success": true,
  "message": "Payment data refreshed successfully",
  "data": { "refreshed": true }
}
```

### `GET /api/payments/types`

**Purpose**: Get available payment types for filtering

**Response Success (200)**:

```json
{
  "success": true,
  "message": "Payment types retrieved successfully",
  "data": [
    "Tunai - Kas Akademi",
    "Cek - Bank BNI",
    "Ijazah",
    "KTI dan Wisuda",
    "Lain-lain"
  ]
}
```

---

## 🔧 System Endpoints

### `GET /health`

**Purpose**: Health check  
**Authentication**: Not required

### `GET /`

**Purpose**: API information and available endpoints  
**Authentication**: Not required

---

## 🗄️ Database Schema Relationships

### Key Foreign Key Relationships

- `t_pembayaranmahasiswa.nrm` → `wirahusada_wis.mahasiswa.nrm`
- `t_pembayaranmahasiswa.no` → `transaksi.id`
- `transaksi.kodeakun` → `akun.kode`

### Data Flow Patterns

1. **Authentication**: `wirahusada_wis.mahasiswa` for student validation
2. **Homepage**: `wirahusada_wis.mahasiswa` for greeting
3. **Payment History**: `wirahusada_wismon` tables joined for transaction data
4. **Payment Detail**: Cross-database join between `wirahusada_wismon` and `wirahusada_wis`

---

## 🚀 Frontend Integration Examples

### Login Implementation

```javascript
const login = async (namam_nim, nrm) => {
  const response = await fetch("/api/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ namam_nim, nrm }),
  });

  const result = await response.json();
  if (result.success) {
    localStorage.setItem("token", result.data.token);
    window.location.href = "/homepage";
  }
};
```

### Homepage Greeting

```javascript
const loadHomepage = async () => {
  const response = await fetch("/api/auth/profile", {
    headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
  });

  const result = await response.json();
  if (result.success) {
    document.getElementById(
      "greeting"
    ).textContent = `hello, ${result.data.namam}`;
  }
};
```

### Payment History with Filters

```javascript
const loadPaymentHistory = async (filters = {}) => {
  const params = new URLSearchParams(filters);
  const response = await fetch(`/api/payments/history?${params}`, {
    headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
  });

  const result = await response.json();
  if (result.success) {
    renderPaymentHistory(result.data.data);
  }
};

// Example usage with filters
loadPaymentHistory({
  page: 1,
  limit: 20,
  type: "Ijazah",
  sortBy: "tanggal",
  sortOrder: "desc",
});
```

### Transaction Detail

```javascript
const showTransactionDetail = async (transactionId) => {
  const response = await fetch(`/api/payments/detail/${transactionId}`, {
    headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
  });

  const result = await response.json();
  if (result.success) {
    populateDetailPage(result.data);
  }
};
```

---

## 🔐 Security Features

- **JWT Authentication**: 24-hour token expiration
- **CORS Protection**: Configured for specific origins
- **Input Validation**: All inputs validated and sanitized
- **SQL Injection Prevention**: Parameterized queries
- **Authorization Checks**: User can only access their own data

---

## ⚡ Performance Optimizations

- **Connection Pooling**: MySQL connection pools (limit: 10)
- **Pagination**: Default 20 items per page for history
- **Indexed Queries**: Database indexes on key columns
- **Request Logging**: For monitoring and debugging

---

## 🐛 Error Handling

All endpoints return consistent error format:

```json
{
  "success": false,
  "message": "Error description",
  "errors": ["detailed_error_1", "detailed_error_2"]
}
```

**Common HTTP Status Codes**:

- `200`: Success
- `400`: Bad Request (validation errors)
- `401`: Unauthorized (missing/invalid token)
- `403`: Forbidden (token expired)
- `404`: Not Found (resource not found)
- `500`: Internal Server Error

**Example Error Responses**:

```json
// Login failed
{
  "success": false,
  "message": "Student not found or invalid credentials",
  "errors": ["Student not found or invalid credentials"]
}

// Missing authentication
{
  "success": false,
  "message": "Access token required",
  "errors": ["Access token required"]
}

// Invalid transaction ID
{
  "success": false,
  "message": "Transaction not found",
  "errors": ["Transaction not found or does not belong to this user"]
}
```
