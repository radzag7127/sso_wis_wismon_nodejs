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

  async getKhs(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { semester } = req.params;

      if (!user || !user.nrm) {
        res.status(401).json({ success: false, message: 'Akses ditolak.' });
        return;
      }
      if (!semester) {
        res.status(400).json({ success: false, message: 'Parameter semester dibutuhkan.' });
        return;
      }
      const data = await akademikService.getKhs(user.nrm, semester);
      res.status(200).json({ success: true, message: `KHS semester ${semester} berhasil diambil`, data });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const statusCode = errorMessage.includes('ditemukan') ? 404 : 500;
      res.status(statusCode).json({ success: false, message: 'Gagal mengambil KHS', errors: [errorMessage] });
    }
  }

  async getKrs(req: Request, res: Response): Promise<void> {
    try {
      // 1. Ambil data pengguna dari token
      const user = (req as any).user as JWTPayload;
      if (!user || !user.nrm) {
        res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak valid.' });
        return;
      }
      const nrm = user.nrm;

      // 2. Ambil parameter dari query string (bukan params)
      const { semesterKe, jenisSemester } = req.query;

      // 3. Validasi input
      if (!semesterKe || !jenisSemester) {
        res.status(400).json({
          success: false,
          message: 'Parameter `semesterKe` dan `jenisSemester` wajib diisi pada query URL.',
        });
        return;
      }

      const semesterKeNum = parseInt(semesterKe as string, 10);
      const jenisSemesterNum = parseInt(jenisSemester as string, 10);

      if (isNaN(semesterKeNum) || isNaN(jenisSemesterNum)) {
        res.status(400).json({
          success: false,
          message: 'Parameter `semesterKe` dan `jenisSemester` harus berupa angka.',
        });
        return;
      }

      // 4. Panggil service dengan parameter yang sudah disesuaikan
      const data = await akademikService.getKrs(nrm, semesterKeNum, jenisSemesterNum);

      // 5. Kirim respon sukses dengan seluruh data Krs
      res.status(200).json({
        success: true,
        message: 'Data KRS berhasil diambil',
        data: data,
      });

    } catch (error) {
      // 6. Tangani error secara konsisten
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const statusCode = errorMessage.toLowerCase().includes('ditemukan') ? 404 : 500;
      res.status(statusCode).json({
        success: false,
        message: 'Gagal mengambil data KRS',
        errors: [errorMessage]
      });
    }
  }
}
