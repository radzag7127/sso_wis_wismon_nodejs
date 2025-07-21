// src/controllers/akademikController.ts

import { Request, Response } from 'express';
import { AkademikService } from '../services/akademikService';
import { ApiResponse, JWTPayload } from '../types';


const akademikService = new AkademikService();

export class AkademikController {
  async getDaftarMahasiswa(req: Request, res: Response): Promise<void> {
    try {
      const data = await akademikService.getDaftarMahasiswa();
      res.status(200).json({
        success: true,
        message: 'Daftar mahasiswa berhasil diambil',
        data: data,
      } as ApiResponse);
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Gagal mengambil daftar mahasiswa',
        errors: [error instanceof Error ? error.message : 'Unknown error'],
      } as ApiResponse);
    }
  }

  async getTranskrip(req: Request, res: Response): Promise<void> {
    try {
        // 1. Ambil data pengguna dari token yang sudah diproses oleh middleware 'authenticateToken'
        const user = (req as any).user;

        // 2. Validasi: Pastikan pengguna terotentikasi dan data NRM ada di dalam token
        if (!user || !user.nrm) {
            res.status(401).json({ 
                success: false, 
                message: 'Akses ditolak. Pengguna tidak terotentikasi atau token tidak valid.' 
            });
            return;
        }

        // 3. Panggil Service: Gunakan NRM dari token untuk memanggil service
        const nrm = user.nrm;
        const data = await akademikService.getTranskrip(nrm);

        // 4. Kirim Respon Sukses
        res.status(200).json({ 
            success: true, 
            message: 'Transkrip berhasil diambil', 
            data 
        });

    } catch (error) {
        // 5. Tangani Error
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        const statusCode = errorMessage.toLowerCase().includes('ditemukan') ? 404 : 500;
        res.status(statusCode).json({ 
            success: false, 
            message: 'Gagal mengambil transkrip', 
            errors: [errorMessage] 
        });
    }
}

    /**
     * Controller untuk mengambil Kartu Hasil Studi (KHS).
     * Disesuaikan agar konsisten dengan getKrs.
     */
    async getKhs(req: Request, res: Response): Promise<void> {
      try {
          // 1. Ambil data pengguna dari token JWT
          const user = (req as any).user as JWTPayload;
          if (!user || !user.nrm) {
              res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak valid.' });
              return;
          }
          const nrm = user.nrm;

          // 2. Ambil parameter 'semesterKe' dari query URL (contoh: /khs?semesterKe=3)
          const { semesterKe } = req.query;

          // 3. Validasi input 'semesterKe'
          if (!semesterKe) {
              res.status(400).json({
                  success: false,
                  message: 'Parameter semesterKe wajib diisi pada query URL.',
              });
              return;
          }

          const semesterKeNum = parseInt(semesterKe as string, 10);
          if (isNaN(semesterKeNum)) {
              res.status(400).json({
                  success: false,
                  message: 'Parameter semesterKe harus berupa angka.',
              });
              return;
          }

          // 4. Panggil service dengan parameter yang sudah divalidasi
          const data = await akademikService.getKhs(nrm, semesterKeNum);

          // 5. Kirim respons sukses
          res.status(200).json({
              success: true,
              message: `KHS semester ${semesterKeNum} berhasil diambil`,
              data: data,
          });

      } catch (error) {
          // 6. Tangani error dari service
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          // Jika pesan error mengandung 'ditemukan', anggap sebagai 404 Not Found
          const statusCode = errorMessage.toLowerCase().includes('ditemukan') ? 404 : 500;
          
          res.status(statusCode).json({
              success: false,
              message: 'Gagal mengambil data KHS',
              errors: [errorMessage],
          });
      }
  }

  async getKrs(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user as JWTPayload;
      if (!user || !user.nrm) {
        res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak valid.' });
        return;
      }
      const nrm = user.nrm;
      
      const { semesterKe } = req.query;

      if (!semesterKe) {
        res.status(400).json({
          success: false,
          message: 'Parameter semesterKe wajib diisi pada query URL.',
        });
        return;
      }

      const semesterKeNum = parseInt(semesterKe as string, 10);
      if (isNaN(semesterKeNum)) {
        res.status(400).json({
          success: false,
          message: 'Parameter semesterKe harus berupa angka.',
        });
        return;
      }

      // Call the service with the simplified parameters
      const data = await akademikService.getKrs(nrm, semesterKeNum);

      res.status(200).json({
        success: true,
        message: 'Data KRS berhasil diambil',
        data: data,
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const statusCode = errorMessage.toLowerCase().includes('ditemukan') ? 404 : 500;
      res.status(statusCode).json({
        success: false,
        message: 'Gagal mengambil data KRS',
        errors: [errorMessage],
      });
    }
  }
}
