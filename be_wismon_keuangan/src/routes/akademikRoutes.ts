import { Router } from 'express';
import { AkademikController } from '../controllers/akademikController';
import { authenticateToken } from "../utils/auth";

const router = Router();
const akademikController = new AkademikController();

// // Rute untuk mendapatkan daftar semua mahasiswa
// router.get('/mahasiswa/daftar', akademikController.getDaftarMahasiswa);
// // Rute untuk mendapatkan transkrip lengkap mahasiswa
// router.get('/mahasiswa/:nrm/transkrip', akademikController.getTranskrip);
// // Rute untuk mendapatkan KHS per semester
// router.get('/mahasiswa/:nrm/khs/:semester', akademikController.getKhs);
// // Rute untuk mendapatkan KRS per semester
// router.get('/mahasiswa/:nrm/krs/:semester', akademikController.getKrs);

// --- RUTE BARU UNTUK MENGAMBIL DAFTAR SEMESTER ---
router.get('/krs-semesters', authenticateToken, akademikController.getAvailableKrsSemesters);

// --- PERUBAHAN RUTE KRS UNTUK MENERIMA PARAMETER TAHUN ---
router.get('/krs/:tahun', authenticateToken, akademikController.getKrs);

export default router;
