// src/services/akademikService.ts

import { executeWisakaQuery } from '../config/database';
import {
  Course,
  Transkrip,
  Khs,
  KhsCourse,
  Rekapitulasi,
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
     * Mengambil Kartu Hasil Studi (KHS) mahasiswa, lengkap dengan rekapitulasi IP dan SKS.
     * Fungsi ini mengadopsi struktur dari getKrs dan mengembangkannya untuk kebutuhan KHS.
     */
  async getKhs(nrm: string, semesterKe: number): Promise<Khs> {
    // Query ini mengambil SEMUA riwayat studi mahasiswa untuk memungkinkan perhitungan kumulatif.
    // Data untuk semester spesifik akan difilter dan diproses di dalam kode.
    const query = `
        SELECT
            k.semesterke,
            k.semester AS jenisSemesterKode,
            k.tahun,
            km.nilai,
            km.bobotnilai,
            km.status,
            mk.kdmk,
            mk.namamk,
            mk.sks,
            kls.nama AS kelas
        FROM
            krsmatakuliah km
        JOIN
            matakuliah mk ON km.kdmk = mk.kdmk AND km.kurikulum = mk.kurikulum
        LEFT JOIN
            krs k ON km.nrm = k.nrm AND km.semesterke = k.semesterke
        LEFT JOIN
            kelasmahasiswa kls ON km.nrm = kls.nrm 
            AND k.tahun = kls.tahun 
            AND km.semesterkrs = kls.semester 
            AND km.kdmk = kls.kdmk
        WHERE
            km.nrm = ?
        ORDER BY
            k.semesterke, mk.kdmk;
    `;

    const allCoursesHistory = (await executeWisakaQuery(query, [nrm])) as any[];

    if (allCoursesHistory.length === 0) {
        throw new Error("Tidak ada data riwayat studi ditemukan untuk mahasiswa ini.");
    }

    // --- Inisialisasi Variabel Kalkulasi ---
    let sksSemesterBeban = 0, sksSemesterLulus = 0;
    let totalBobotSemester = 0, totalBobotLulusSemester = 0;

    let sksKumulatifBeban = 0, sksKumulatifLulus = 0;
    let totalBobotKumulatif = 0, totalBobotLulusKumulatif = 0;

    const mataKuliahList: KhsCourse[] = [];
    let semesterInfo: any = null;

    // --- Proses Semua Data dalam Satu Iterasi ---
    for (const course of allCoursesHistory) {
        const sks = Number(course.sks) || 0;
        const bobotNilai = Number(course.bobotnilai) || 0;
        const isLulus = course.status === 1;

        // 1. Kalkulasi untuk semester yang dipilih
        if (course.semesterke === semesterKe) {
            if (!semesterInfo) {
                semesterInfo = course; // Simpan info semester dari baris pertama yang cocok
            }

            sksSemesterBeban += sks;
            totalBobotSemester += sks * bobotNilai;
            if (isLulus) {
                sksSemesterLulus += sks;
                totalBobotLulusSemester += sks * bobotNilai;
            }
            
            mataKuliahList.push({
                nilai: course.nilai || '-',
                kodeMataKuliah: course.kdmk,
                namaMataKuliah: course.namamk,
                sks: sks,
                kelas: course.kelas || null
            });
        }

        // 2. Kalkulasi untuk data kumulatif (hingga semester yang dipilih)
        if (course.semesterke <= semesterKe) {
            sksKumulatifBeban += sks;
            totalBobotKumulatif += sks * bobotNilai;
            if (isLulus) {
                sksKumulatifLulus += sks;
                totalBobotLulusKumulatif += sks * bobotNilai;
            }
        }
    }

    if (!semesterInfo) {
        throw new Error(`Tidak ada data KHS ditemukan untuk semester ${semesterKe}.`);
    }

    // --- Kalkulasi Final IP & SKS ---
    const ipSemesterBeban = sksSemesterBeban > 0 ? (totalBobotSemester / sksSemesterBeban) : 0;
    const ipSemesterLulus = sksSemesterLulus > 0 ? (totalBobotLulusSemester / sksSemesterLulus) : 0;
    const ipKumulatifBeban = sksKumulatifBeban > 0 ? (totalBobotKumulatif / sksKumulatifBeban) : 0;
    const ipKumulatifLulus = sksKumulatifLulus > 0 ? (totalBobotLulusKumulatif / sksKumulatifLulus) : 0;

    const rekapitulasi: Rekapitulasi = {
        ipSemester: `${ipSemesterLulus.toFixed(2)} / ${ipSemesterBeban.toFixed(2)}`,
        sksSemester: `${sksSemesterLulus} / ${sksSemesterBeban}`,
        ipKumulatif: `${ipKumulatifLulus.toFixed(2)} / ${ipKumulatifBeban.toFixed(2)}`,
        sksKumulatif: `${sksKumulatifLulus} / ${sksKumulatifBeban}`
    };

    // Helper function untuk mendapatkan nama semester, sama seperti di getKrs
    const getJenisSemesterText = (kode: number): string => {
        return kode === 1 ? 'Ganjil' : (kode === 2 ? 'Genap' : 'Antara');
    };

    // --- Menyusun Objek Respons Final ---
    const khsResult: Khs = {
        semesterKe: semesterInfo.semesterke,
        jenisSemester: getJenisSemesterText(semesterInfo.jenisSemesterKode),
        tahunAjaran: `${semesterInfo.tahun}/${semesterInfo.tahun + 1}`,
        mataKuliah: mataKuliahList,
        rekapitulasi: rekapitulasi,
    };

    return khsResult;
  }

  /**
   * Mengambil Kartu Rencana Studi (KRS) per semester.
   * Query ini diperbaiki untuk menggunakan krs.tahun sebagai acuan join yang benar.
   * REVISED: This function now only requires semesterKe.
   */
  async getKrs(nrm: string, semesterKe: number): Promise<Krs> {
    // Determine jenisSemester (1 for Ganjil, 2 for Genap) based on semesterKe
    const jenisSemester = semesterKe % 2 === 0 ? 2 : 1;

    // The SQL query remains the same but uses the internally derived jenisSemester
    const query = `
      SELECT
        krs.semesterke AS semesterKe,
        krs.semester AS jenisSemesterKode,
        krs.tahun AS tahunAjaran,
        mk.kdmk AS kodeMataKuliah,
        mk.namamk AS namaMataKuliah,
        mk.sks AS sks,
        kls_mhs.nama AS kelas
      FROM krs
      JOIN krsmatakuliah AS krs_mk ON krs.nrm = krs_mk.nrm
        AND krs.semesterke = krs_mk.semesterke
        AND krs.semester = krs_mk.semesterkrs
        AND krs.tahun = krs_mk.tahun
      JOIN matakuliah AS mk ON krs_mk.kdmk = mk.kdmk
        AND krs_mk.kurikulum = mk.kurikulum
      LEFT JOIN kelasmahasiswa AS kls_mhs ON krs_mk.nrm = kls_mhs.nrm
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
      throw new Error("Tidak ada data KRS ditemukan untuk semester yang diminta.");
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
