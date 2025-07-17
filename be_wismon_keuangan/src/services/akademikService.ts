import { executeWisakaQuery } from '../config/database';
import { 
    Course,
    Transkrip, 
    Khs, 
    Krs, 
    DaftarMahasiswa 
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
        const results = await executeWisakaQuery(sql);
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
                krs.nrm = ? AND krs.status = 1
            ORDER BY 
                krs.semesterke, mk.namamk;
        `;
        const courses = await executeWisakaQuery(sql, [nrm]) as any[];

        if (courses.length === 0) {
            throw new Error('Tidak ada data transkrip ditemukan untuk mahasiswa ini.');
        }

        let totalSks = 0;
        let totalBobot = 0;
        courses.forEach(course => {
            if (course.bobotnilai !== null && course.sks !== null) {
                totalSks += course.sks;
                totalBobot += (course.bobotnilai * course.sks);
            }
        });

        const ipk = totalSks > 0 ? (totalBobot / totalSks) : 0;

        return {
            ipk: ipk.toFixed(2),
            total_sks: totalSks,
            courses: courses
        };
    }

    /**
     * Mengambil Kartu Hasil Studi (KHS) per semester
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
        const courses = await executeWisakaQuery(sql, [nrm, semester]) as any[];

        if (courses.length === 0) {
            throw new Error(`Tidak ada data KHS ditemukan untuk semester ${semester}.`);
        }
        
        let totalSks = 0;
        let totalBobot = 0;
        courses.forEach(course => {
            if (course.bobotnilai !== null && course.sks !== null) {
                totalSks += course.sks;
                totalBobot += (course.bobotnilai * course.sks);
            }
        });

        const ips = totalSks > 0 ? (totalBobot / totalSks) : 0;

        return {
            ips: ips.toFixed(2),
            total_sks: totalSks,
            courses: courses
        };
    }

    /**
     * Mengambil daftar semester (tahun ajaran) yang memiliki KRS untuk seorang mahasiswa.
     */
    async getAvailableKrsSemesters(nrm: string): Promise<string[]> {
        const sql = `
        SELECT DISTINCT tahun
        FROM krsmatakuliah
        WHERE nrm = ?
        ORDER BY tahun DESC;
        `;
        console.log(`WISAKA DB - Fetching available KRS semesters for NRM: ${nrm}`);
        const results = (await executeWisakaQuery(sql, [nrm])) as any[];
        return results.map((row) => row.tahun);
    }

    /**
     * Mengambil Kartu Rencana Studi (KRS) untuk semester/tahun ajaran tertentu.
     */
    async getKrs(nrm: string, tahun: string): Promise<Krs> {
        const sql = `
        SELECT
            krs.kdmk AS kode,
            mk.namamk AS nama,
            mk.sks
        FROM krsmatakuliah AS krs
        JOIN matakuliah AS mk ON krs.kdmk = mk.kdmk AND krs.kurikulum = mk.kurikulum
        WHERE krs.nrm = ? AND krs.tahun = ?
        ORDER BY mk.namamk;
        `;

        console.log(`WISAKA DB - Fetching KRS for NRM: ${nrm}, Semester/Tahun: ${tahun}`);
        const courses = (await executeWisakaQuery(sql, [nrm, tahun])) as any[];

        if (courses.length === 0) {
        console.warn(`WISAKA DB - No KRS data found for NRM: ${nrm} in semester ${tahun}.`);
        return { total_sks: 0, courses: [] };
        }

        const totalSks = courses.reduce((sum, course) => sum + (course.sks || 0), 0);
        console.log(`WISAKA DB - Found ${courses.length} courses with total ${totalSks} SKS for NRM: ${nrm}`);

        return {
        total_sks: totalSks,
        courses: courses,
        };
    }
}
