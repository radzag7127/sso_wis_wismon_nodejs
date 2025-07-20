// src/services/akademikService.ts

import { executeWisakaQuery } from '../config/database';
import {
  Course,
  Transkrip,
  Khs,
  Krs,
  KrsCourse,
  DaftarMahasiswa,
} from '../types';

export class AkademikService {
  /**
   * Mengambil daftar semua mahasiswa (NRM dan Nama)
   */
  async getDaftarMahasiswa(): Promise<DaftarMahasiswa[]> {
    const sql = `
      SELECT
        a.nrm,
        m.namam
      FROM u4714151_wisaka.akademik AS a
      JOIN u4714151_wis.mahasiswa AS m ON a.nrm = m.nrm
      ORDER BY m.namam ASC;
    `;
    const results = await executeWisakaQuery(sql, []);
    return results as DaftarMahasiswa[];
  }

  /**
   * Mengambil transkrip akademik lengkap seorang mahasiswa
   */
  async getTranskrip(nrm: string): Promise<Transkrip> {
    const sql = `
      SELECT
        mk.namamk,
        mk.sks,
        krs.nilai,
        krs.bobotnilai,
        krs.semesterke AS semesterKe
      FROM
        krsmatakuliah AS krs
      JOIN
        matakuliah AS mk
      ON krs.kdmk = mk.kdmk
        AND krs.kurikulum = mk.kurikulum
      WHERE
        krs.nrm = ?
      ORDER BY
        krs.semesterke, mk.namamk;
    `;

    const courses = (await executeWisakaQuery(sql, [nrm])) as any[];

    if (courses.length === 0) {
      throw new Error('Tidak ada data transkrip ditemukan untuk mahasiswa ini.');
    }

    let totalSks = 0;
    let totalBobot = 0;

    courses.forEach(course => {
      if (course.bobotnilai !== null && course.sks != null) {
        totalSks += course.sks;
        totalBobot += (course.bobotnilai * course.sks);
      }
    });

    const ipk = totalSks > 0 ? (totalBobot / totalSks) : 0;

    return {
      ipk: ipk.toFixed(2),
      total_sks: totalSks,
      courses: courses,
    };
  }

  /**
   * Mengambil khs akademik lengkap seorang mahasiswa
   */
  async getKhs(nrm: string, semester: string): Promise<Khs> {
    const sql = `
      SELECT
        mk.namamk,
        mk.sks,
        krs.nilai,
        krs.bobotnilai
      FROM krsmatakuliah AS krs
      JOIN matakuliah AS mk ON krs.kdmk = mk.kdmk AND krs.kurikulum = mk.kurikulum
      WHERE krs.nrm = ? AND krs.semesterke = ?
      ORDER BY mk.namamk;
    `;
    const courses = (await executeWisakaQuery(sql, [nrm, semester])) as any[];
    if (courses.length === 0) {
      throw new Error(`Tidak ada data KHS ditemukan untuk semester ${semester}.`);
    }
    let totalSks = 0;
    let totalBobot = 0;
    courses.forEach(course => {
      if (course.bobotnilai !== null && course.sks != null) {
        totalSks += course.sks;
        totalBobot += (course.bobotnilai * course.sks);
      }
    });
    const ips = totalSks > 0 ? (totalBobot / totalSks) : 0;
    return {
      ips: ips.toFixed(2),
      total_sks: totalSks,
      courses: courses,
    };
  }

  /**
   * Mengambil Kartu Rencana Studi (KRS) per semester.
   * Query ini diperbaiki untuk menggunakan `krs.tahun` sebagai acuan join yang benar.
   */
  async getKrs(nrm: string, semesterKe: number, jenisSemester: number): Promise<Krs> {
    // ===== PERBAIKAN FINAL PADA QUERY =====
    // Mengubah kondisi JOIN `krs_mk.tahun` menjadi `krs.tahun` untuk memastikan
    // pencocokan tahun ajaran yang akurat.
    const query = `
      SELECT 
        krs.semesterke AS semesterKe,
        krs.semester AS jenisSemesterKode,
        krs.tahun AS tahunAjaran,
        mk.kdmk AS kodeMataKuliah,
        mk.namamk AS namaMataKuliah,
        mk.sks AS sks,
        kls_mhs.nama AS kelas
      FROM 
        krs
      JOIN 
        krsmatakuliah AS krs_mk ON krs.nrm = krs_mk.nrm 
                                AND krs.semesterke = krs_mk.semesterke 
                                AND krs.semester = krs_mk.semesterkrs
      JOIN 
        matakuliah AS mk ON krs_mk.kdmk = mk.kdmk 
                         AND krs_mk.kurikulum = mk.kurikulum
      LEFT JOIN 
        kelasmahasiswa AS kls_mhs ON krs_mk.nrm = kls_mhs.nrm
                                  AND krs.tahun = kls_mhs.tahun
                                  AND krs_mk.semesterkrs = kls_mhs.semester
                                  AND krs_mk.kdmk = kls_mhs.kdmk
                                  AND krs_mk.kurikulum = kls_mhs.kurikulum
      WHERE 
        krs.nrm = ? 
        AND krs.semesterke = ? 
        AND krs.semester = ?
      ORDER BY 
        mk.kdmk;
    `;

    const krsData = (await executeWisakaQuery(query, [nrm, semesterKe, jenisSemester])) as any[];

    if (krsData.length === 0) {
      throw new Error(`Tidak ada data KRS ditemukan untuk semester yang diminta.`);
    }

    const getJenisSemesterText = (kode: number): string => {
      switch (kode) {
        case 1: return 'Ganjil';
        case 2: return 'Genap';
        case 3: return 'Antara Pendek';
        case 4: return 'Antara Panjang';
        default: return 'Tidak Diketahui';
      }
    };

    const firstRow = krsData[0];
    const mataKuliahList: KrsCourse[] = krsData.map((row: any) => ({
      kodeMataKuliah: row.kodeMataKuliah,
      namaMataKuliah: row.namaMataKuliah,
      sks: row.sks,
      kelas: row.kelas || null,
    }));

    const totalSks = mataKuliahList.reduce((sum, course) => sum + (course.sks || 0), 0);

    const krsResult: Krs = {
      semesterKe: firstRow.semesterKe,
      jenisSemester: getJenisSemesterText(firstRow.jenisSemesterKode),
      tahunAjaran: `${firstRow.tahunAjaran}/${firstRow.tahunAjaran + 1}`,
      mataKuliah: mataKuliahList,
      totalSks: totalSks,
    };

    return krsResult;
  }
}
