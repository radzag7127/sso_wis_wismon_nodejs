// src/routes/akademikRoutes.ts

import { Router } from 'express';
import { AkademikController } from '../controllers/akademikController';
import { authenticateToken } from '../utils/auth'; // Pastikan authenticateToken di-import

const router = Router();
const akademikController = new AkademikController();

// Rute untuk mendapatkan daftar semua mahasiswa (contoh rute publik)
router.get('/mahasiswa/daftar', akademikController.getDaftarMahasiswa); //palingan gak dipakai, bisa dihapus harusnya?

// Rute baru untuk mendapatkan info semester mahasiswa
router.get('/mahasiswa/info', authenticateToken, akademikController.getMahasiswaInfo);




// Rute untuk mendapatkan transkrip mahasiswa
router.get('/mahasiswa/transkrip', authenticateToken, akademikController.getTranskrip);

// Rute untuk mengajukan/membatalkan usulan penghapusan
router.post("/mahasiswa/transkrip/usul-hapus",authenticateToken,(req, res) => akademikController.updateUsulanHapus(req, res));

// Rute untuk mendapatkan KHS per semester
router.get('/mahasiswa/khs', authenticateToken, akademikController.getKhs);

// Rute untuk mendapatkan KRS per semester
router.get('/mahasiswa/krs', authenticateToken, akademikController.getKrs);

export default router;