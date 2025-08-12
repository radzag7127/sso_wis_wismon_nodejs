import { executeSsoQuery, executeWisQuery } from "../config/database";
import { User, Student, LoginRequest, LoginResponse } from "../types";
import { generateToken } from "../utils/auth";

export class AuthService {
  // #1 Temporary login function, will be replaced with SSO login for the next stage development
  async findStudent(namam_nim: string, nrm: string): Promise<Student | null> {
    try {
      let query = `
        SELECT nrm, nim, namam, tgdaftar, tplahir, kdagama 
        FROM mahasiswa 
        WHERE nim = ? AND nrm = ?
      `;
      let results = (await executeWisQuery(query, [namam_nim, nrm])) as any[];

      if (results.length > 0) {
        return results[0] as Student;
      }
      // If not found by NIM, try by student name (exact match, case-insensitive)
      query = `
        SELECT nrm, nim, namam, tgdaftar, tplahir, kdagama 
        FROM mahasiswa 
        WHERE LOWER(namam) = LOWER(?) AND nrm = ?
      `;
      results = (await executeWisQuery(query, [namam_nim, nrm])) as any[];

      if (results.length > 0) {
        return results[0] as Student;
      }

      // Try with spaces removed (for cases like "HanikZaimatusSholichah" vs "Hanik Zaimatus Sholichah")
      // But still exact match after removing spaces
      const namam_nim_no_spaces = namam_nim.replace(/\s+/g, "");
      query = `
        SELECT nrm, nim, namam, tgdaftar, tplahir, kdagama 
        FROM mahasiswa 
        WHERE LOWER(REPLACE(namam, ' ', '')) = LOWER(?) AND nrm = ?
      `;
      results = (await executeWisQuery(query, [
        namam_nim_no_spaces,
        nrm,
      ])) as any[];

      if (results.length > 0) {
        return results[0] as Student;
      }

      return null;
    } catch (error) {
      console.error("Error finding student:", error);
      throw new Error("Database error while finding student");
    }
  }

  // Check if user exists in SSO system (optional for future authentication)

  async findSsoUser(username: string): Promise<User | null> {
    try {
      const query = `
        SELECT id, username, email, created_at 
        FROM user 
        WHERE username = ?
      `;
      const results = (await executeSsoQuery(query, [username])) as any[];

      if (results.length > 0) {
        return results[0] as User;
      }

      return null;
    } catch (error) {
      console.error("Error finding SSO user:", error);
      return null;
    }
  }

  async login(loginData: LoginRequest): Promise<LoginResponse> {
    const { namam_nim, nrm } = loginData;

    if (!namam_nim || !nrm) {
      throw new Error("Student name/NIM and NRM are required");
    }

    // Find student in WIS database
    const student = await this.findStudent(namam_nim, nrm);

    if (!student) {
      throw new Error("Student not found or invalid credentials");
    }

    // Generate JWT token
    const token = generateToken({
      nrm: student.nrm,
      nim: student.nim,
      namam: student.namam,
    });

    return {
      token,
      user: {
        nrm: student.nrm,
        nim: student.nim,
        namam: student.namam,
      },
    };
  }

  // Get student profile by NRM (for authenticated requests)
  async getStudentProfile(nrm: string): Promise<Student | null> {
    try {
      const query = `
        SELECT nrm, nim, namam, tgdaftar, tplahir, kdagama 
        FROM mahasiswa 
        WHERE nrm = ?
      `;
      const results = (await executeWisQuery(query, [nrm])) as any[];

      if (results.length > 0) {
        return results[0] as Student;
      }

      return null;
    } catch (error) {
      console.error("Error getting student profile:", error);
      throw new Error("Database error while getting student profile");
    }
  }
}
