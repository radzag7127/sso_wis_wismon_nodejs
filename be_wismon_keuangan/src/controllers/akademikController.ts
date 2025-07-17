import { Request, Response } from 'express';
import { AkademikService } from '../services/akademikService';
import { ApiResponse } from '../types';


const akademikService = new AkademikService();

export class AkademikController {

    async getDaftarMahasiswa(req: Request, res: Response): Promise<void> {
        try {
            const data = await akademikService.getDaftarMahasiswa();
            res.status(200).json({
                success: true,
                message: "Daftar mahasiswa berhasil diambil",
                data: data
            } as ApiResponse);
        } catch (error) {
            res.status(500).json({
                success: false,
                message: "Gagal mengambil daftar mahasiswa",
                errors: [error instanceof Error ? error.message : "Unknown error"]
            } as ApiResponse);
        }
    }

    async getTranskrip(req: Request, res: Response): Promise<void> {
        try {
            const { nrm } = req.params;
            if (!nrm) {
                res.status(400).json({ success: false, message: "Parameter NRM dibutuhkan." });
                return;
            }
            const data = await akademikService.getTranskrip(nrm);
            res.status(200).json({ success: true, message: "Transkrip berhasil diambil", data });
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : "Unknown error";
            const statusCode = errorMessage.includes("ditemukan") ? 404 : 500;
            res.status(statusCode).json({ success: false, message: "Gagal mengambil transkrip", errors: [errorMessage] });
        }
    }

    async getKhs(req: Request, res: Response): Promise<void> {
        try {
            const { nrm, semester } = req.params;
            if (!nrm || !semester) {
                res.status(400).json({ success: false, message: "Parameter NRM dan semester dibutuhkan." });
                return;
            }
            const data = await akademikService.getKhs(nrm, semester);
            res.status(200).json({ success: true, message: `KHS semester ${semester} berhasil diambil`, data });
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : "Unknown error";
            const statusCode = errorMessage.includes("ditemukan") ? 404 : 500;
            res.status(statusCode).json({ success: false, message: "Gagal mengambil KHS", errors: [errorMessage] });
        }
    }

    async getAvailableKrsSemesters(req: Request, res: Response): Promise<void> {
        const user = (req as any).user;
        if (!user || !user.nrm) {
          res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak valid.' });
          return;
        }
        try {
          const semesters = await akademikService.getAvailableKrsSemesters(user.nrm);
          res.status(200).json({
            success: true,
            message: 'Daftar semester berhasil diambil',
            data: semesters,
          });
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          res.status(500).json({ success: false, message: 'Gagal mengambil daftar semester', errors: [errorMessage] });
        }
    }
    
      async getKrs(req: Request, res: Response): Promise<void> {
        const user = (req as any).user;
        const { tahun } = req.params; // Mengambil 'tahun' dari parameter URL
    
        if (!user || !user.nrm) {
          res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak valid.' });
          return;
        }
        if (!tahun) {
            res.status(400).json({ success: false, message: 'Parameter tahun ajaran dibutuhkan.' });
            return;
        }
    
        console.log(`AKADEMIK KRS - Request received for NRM: ${user.nrm}, Tahun: ${tahun}`);
    
        try {
          const data = await akademikService.getKrs(user.nrm, tahun);
          res.status(200).json({
            success: true,
            message: `Data KRS untuk tahun ajaran ${tahun} berhasil diambil`,
            data: data.courses,
          });
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          console.error(`AKADEMIK KRS - Error for NRM ${user.nrm}: ${errorMessage}`);
          const statusCode = errorMessage.includes('ditemukan') ? 404 : 500;
          res.status(statusCode).json({ success: false, message: 'Gagal mengambil KRS', errors: [errorMessage] });
        }
    }
}