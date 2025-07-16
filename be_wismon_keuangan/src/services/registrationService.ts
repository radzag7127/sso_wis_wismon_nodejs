import { executeSsoQuery, executeWisQuery } from "../config/database";
import { Student, User } from "../types";
import crypto from "crypto";

export interface Stage1Request {
  nama: string;
  nim: string;
  nrm: string;
  tglahir: string; // YYYY-MM-DD format
}

export interface Stage1Response {
  success: boolean;
  message: string;
  studentData?: {
    nama: string;
    nim: string;
    nrm: string;
  };
}

export interface Stage2Request {
  // Stage 1 verified data
  nama: string;
  nim: string;
  nrm: string;
  tglahir: string;
  // Stage 2 new data
  username: string;
  email: string;
  password: string;
}

export interface Stage2Response {
  success: boolean;
  message: string;
}

export class RegistrationService {
  /**
   * Stage 1: Verify student identity against wis.mahasiswa
   * Check if account already exists
   */
  async verifyIdentity(data: Stage1Request): Promise<Stage1Response> {
    try {
      const { nama, nim, nrm, tglahir } = data;

      // Validate required fields
      if (!nama || !nim || !nrm || !tglahir) {
        return {
          success: false,
          message: "Semua field harus diisi",
        };
      }

      // Validate date format (YYYY-MM-DD)
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
      if (!dateRegex.test(tglahir)) {
        return {
          success: false,
          message: "Format tanggal lahir harus YYYY-MM-DD",
        };
      }

      // Find student in mahasiswa table with case-insensitive and space-insensitive name matching
      const student = await this.findStudentByIdentity(nama, nim, nrm, tglahir);

      if (!student) {
        return {
          success: false,
          message: "Data tidak ditemukan di database mahasiswa",
        };
      }

      // Check if account already exists in user_mahasiswa or sso.user
      const existingAccount = await this.checkExistingAccount(
        nim,
        student.namam
      );

      if (existingAccount) {
        return {
          success: false,
          message: "Akun dengan data ini sudah terdaftar",
        };
      }

      return {
        success: true,
        message: "Data mahasiswa berhasil diverifikasi",
        studentData: {
          nama: student.namam,
          nim: student.nim,
          nrm: student.nrm,
        },
      };
    } catch (error) {
      console.error("Error in verifyIdentity:", error);
      return {
        success: false,
        message: "Terjadi kesalahan sistem. Silakan coba lagi.",
      };
    }
  }

  /**
   * Stage 2: Create account after identity verification
   * Check username uniqueness and prepare for email verification
   */
  async createAccount(data: Stage2Request): Promise<Stage2Response> {
    try {
      const { username, email, password } = data;

      // Validate required fields
      if (!username || !email || !password) {
        return {
          success: false,
          message: "Username, email, dan password harus diisi",
        };
      }

      // Validate username format (alphanumeric only)
      const usernameRegex = /^[a-zA-Z0-9]+$/;
      if (!usernameRegex.test(username)) {
        return {
          success: false,
          message: "Username hanya boleh mengandung huruf dan angka",
        };
      }

      // Check username uniqueness
      const usernameExists = await this.checkUsernameExists(username);

      if (usernameExists) {
        return {
          success: false,
          message: "Username sudah digunakan",
        };
      }

      // 🚨 FIREBASE EMAIL VERIFICATION RESTRICTION REMOVED FOR TESTING
      // 🔥 TODO: When Firebase is ready, move this INSERT logic to a separate function
      //    that gets called ONLY after successful email verification

      // Hash the password using MD5 for consistency with existing system
      const hashedPassword = this.hashPassword(password);

      // Insert data into database tables
      await this.insertUserData(
        data.nama,
        data.nim,
        data.nrm,
        username,
        email,
        hashedPassword
      );

      return {
        success: true,
        message: "Registrasi berhasil! Akun Anda telah dibuat.",
      };
    } catch (error) {
      console.error("Error in createAccount:", error);
      return {
        success: false,
        message: "Terjadi kesalahan sistem. Silakan coba lagi.",
      };
    }
  }

  /**
   * Find student by identity data with case-insensitive and space-insensitive name matching
   */
  private async findStudentByIdentity(
    nama: string,
    nim: string,
    nrm: string,
    tglahir: string
  ): Promise<Student | null> {
    try {
      // Query by NIM and NRM first, then filter by name and birth date
      let query = `
        SELECT nrm, nim, namam, tgdaftar, tglahir, kdagama 
        FROM mahasiswa 
        WHERE nim = ? AND nrm = ? AND tglahir = ?
      `;
      let results = (await executeWisQuery(query, [
        nim,
        nrm,
        tglahir,
      ])) as any[];

      // Filter by name with case-insensitive and space-insensitive matching
      const filteredResults = results.filter((student: any) => {
        const dbName = student.namam.toLowerCase().replace(/\s+/g, "");
        const inputName = nama.toLowerCase().replace(/\s+/g, "");
        return dbName === inputName;
      });

      if (filteredResults.length > 0) {
        return filteredResults[0] as Student;
      }

      return null;
    } catch (error) {
      console.error("Error finding student by identity:", error);
      throw error;
    }
  }

  /**
   * Check if account already exists in user_mahasiswa or sso.user
   */
  private async checkExistingAccount(
    nim: string,
    namam: string
  ): Promise<boolean> {
    try {
      // Check in user_mahasiswa table
      const userMahasiswaQuery = `
        SELECT username FROM user_mahasiswa WHERE nim = ?
      `;
      const userMahasiswaResults = (await executeWisQuery(userMahasiswaQuery, [
        nim,
      ])) as any[];

      if (userMahasiswaResults.length > 0) {
        return true;
      }

      // Check in sso.user table by finding if any user has this student's name
      const ssoUserQuery = `
        SELECT username FROM user WHERE name = ?
      `;
      const ssoUserResults = (await executeSsoQuery(ssoUserQuery, [
        namam,
      ])) as any[];

      if (ssoUserResults.length > 0) {
        return true;
      }

      return false;
    } catch (error) {
      console.error("Error checking existing account:", error);
      throw error;
    }
  }

  /**
   * Check if username already exists in user_mahasiswa or sso.user
   */
  private async checkUsernameExists(username: string): Promise<boolean> {
    try {
      // Check in user_mahasiswa table
      const userMahasiswaQuery = `
        SELECT username FROM user_mahasiswa WHERE username = ?
      `;
      const userMahasiswaResults = (await executeWisQuery(userMahasiswaQuery, [
        username,
      ])) as any[];

      if (userMahasiswaResults.length > 0) {
        return true;
      }

      // Check in sso.user table
      const ssoUserQuery = `
        SELECT username FROM user WHERE username = ?
      `;
      const ssoUserResults = (await executeSsoQuery(ssoUserQuery, [
        username,
      ])) as any[];

      if (ssoUserResults.length > 0) {
        return true;
      }

      return false;
    } catch (error) {
      console.error("Error checking username existence:", error);
      throw error;
    }
  }

  /**
   * Insert user data into database tables after successful verification
   * 🔥 TODO: When Firebase is ready, this should only be called after email verification
   */
  private async insertUserData(
    nama: string,
    nim: string,
    nrm: string,
    username: string,
    email: string,
    hashedPassword: string
  ): Promise<void> {
    try {
      // Insert into wirahusada_wis.user_mahasiswa
      const userMahasiswaQuery = `
        INSERT INTO user_mahasiswa (username, nim) VALUES (?, ?)
      `;
      await executeWisQuery(userMahasiswaQuery, [username, nim]);

      // Insert into wirahusada_sso.user
      const ssoUserQuery = `
        INSERT INTO user (username, password, name, enabled) VALUES (?, ?, ?, 1)
      `;
      await executeSsoQuery(ssoUserQuery, [username, hashedPassword, nama]);

      // Insert into wirahusada_sso.user_role (assign Student role for Wismon app)
      const userRoleQuery = `
        INSERT INTO user_role (username, app, rid) VALUES (?, 'wmon', 'stu')
      `;
      await executeSsoQuery(userRoleQuery, [username]);

      console.log("✅ User data successfully inserted:", {
        username,
        nim,
        app: "wmon",
        role: "stu",
      });
    } catch (error) {
      console.error("❌ Error inserting user data:", error);
      throw new Error("Gagal menyimpan data ke database");
    }
  }

  /**
   * Create MD5 hash for password (for consistency with existing system)
   */
  private hashPassword(password: string): string {
    return crypto.createHash("md5").update(password).digest("hex");
  }
}
