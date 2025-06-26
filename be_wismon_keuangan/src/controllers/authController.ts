import { Request, Response } from "express";
import { AuthService } from "../services/authService";
import { ApiResponse, LoginRequest } from "../types";

const authService = new AuthService();

export class AuthController {
  /**
   * POST /auth/login
   * Login endpoint for students
   */
  async login(req: Request, res: Response): Promise<void> {
    console.log("🔐 AUTH LOGIN - Request received:", {
      body: req.body,
      headers: req.headers,
      timestamp: new Date().toISOString(),
    });

    try {
      const { namam_nim, nrm }: LoginRequest = req.body;

      console.log("🔐 AUTH LOGIN - Extracted credentials:", {
        namam_nim,
        nrm,
        namam_nim_type: typeof namam_nim,
        nrm_type: typeof nrm,
      });

      if (!namam_nim || !nrm) {
        console.log("🔐 AUTH LOGIN - Missing credentials");
        res.status(400).json({
          success: false,
          message: "Student name/NIM and NRM are required",
          errors: ["namam_nim and nrm fields are required"],
        } as ApiResponse);
        return;
      }

      console.log("🔐 AUTH LOGIN - Attempting authentication...");
      const loginResult = await authService.login({ namam_nim, nrm });

      console.log("🔐 AUTH LOGIN - Authentication successful:", {
        hasToken: !!loginResult.token,
        userNrm: loginResult.user?.nrm,
        userNim: loginResult.user?.nim,
      });

      res.status(200).json({
        success: true,
        message: "Login successful",
        data: loginResult,
      } as ApiResponse);
    } catch (error) {
      console.error("🔐 AUTH LOGIN - Error:", error);

      const errorMessage =
        error instanceof Error ? error.message : "Login failed";
      const statusCode =
        errorMessage.includes("not found") || errorMessage.includes("invalid")
          ? 401
          : 500;

      res.status(statusCode).json({
        success: false,
        message: errorMessage,
        errors: [errorMessage],
      } as ApiResponse);
    }
  }

  /**
   * GET /auth/profile
   * Get current user profile (requires authentication)
   */
  async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user; // Set by authenticateToken middleware

      if (!user || !user.nrm) {
        res.status(401).json({
          success: false,
          message: "Authentication required",
          errors: ["User not found in request"],
        } as ApiResponse);
        return;
      }

      const student = await authService.getStudentProfile(user.nrm);

      if (!student) {
        res.status(404).json({
          success: false,
          message: "Student profile not found",
          errors: ["Student data not found"],
        } as ApiResponse);
        return;
      }

      res.status(200).json({
        success: true,
        message: "Profile retrieved successfully",
        data: {
          nrm: student.nrm,
          nim: student.nim,
          namam: student.namam,
          tgdaftar: student.tgdaftar,
          tplahir: student.tplahir,
        },
      } as ApiResponse);
    } catch (error) {
      console.error("Get profile error:", error);

      res.status(500).json({
        success: false,
        message: "Failed to retrieve profile",
        errors: [error instanceof Error ? error.message : "Unknown error"],
      } as ApiResponse);
    }
  }

  /**
   * POST /auth/verify
   * Verify JWT token
   */
  async verifyToken(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user; // Set by authenticateToken middleware

      res.status(200).json({
        success: true,
        message: "Token is valid",
        data: {
          nrm: user.nrm,
          nim: user.nim,
          namam: user.namam,
        },
      } as ApiResponse);
    } catch (error) {
      res.status(401).json({
        success: false,
        message: "Invalid token",
        errors: ["Token verification failed"],
      } as ApiResponse);
    }
  }
}
