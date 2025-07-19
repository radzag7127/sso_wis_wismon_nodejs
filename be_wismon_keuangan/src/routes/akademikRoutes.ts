// src/routes/akademikRoutes.ts

import { Router } from 'express';
import { AkademikController } from '../controllers/akademikController';
import { authenticateToken } from '../utils/auth'; // Pastikan authenticateToken di-import

const router = Router();
const akademikController = new AkademikController();

// Rute untuk mendapatkan daftar semua mahasiswa (contoh rute publik)
router.get('/mahasiswa/daftar', akademikController.getDaftarMahasiswa); //palingan gak dipakai, bisa dihapus harusnya?

// Rute untuk mendapatkan transkrip mahasiswa
router.get('/mahasiswa/transkrip', authenticateToken, akademikController.getTranskrip);

// Rute untuk mendapatkan KHS per semester
router.get('/mahasiswa/:nrm/khs/:semester', authenticateToken, akademikController.getKhs);

// Rute untuk mendapatkan KRS per semester
router.get('/mahasiswa/:nrm/khs/:semester', authenticateToken, akademikController.getKrs);

export default router;
