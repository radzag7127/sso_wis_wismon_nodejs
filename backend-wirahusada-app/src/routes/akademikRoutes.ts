// src/routes/akademikRoutes.ts

import { Router } from 'express';
import { AkademikController } from '../controllers/akademikController';
import { authenticateToken } from '../utils/auth';
import { validateAcademic, validateGeneral } from '../middleware/validation';

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

// Rute untuk mendapatkan KHS per semester dengan validasi query parameters
router.get('/mahasiswa/khs', 
  authenticateToken, 
  ...validateGeneral.pagination,
  akademikController.getKhs
);

// Rute untuk mendapatkan KRS per semester dengan validasi query parameters
router.get('/mahasiswa/krs', 
  authenticateToken, 
  ...validateGeneral.pagination,
  akademikController.getKrs
);

export default router;