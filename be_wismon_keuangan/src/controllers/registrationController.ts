import { Request, Response } from "express";
import {
  RegistrationService,
  Stage1Request,
  Stage2Request,
} from "../services/registrationService";
import { ApiResponse } from "../types";

const registrationService = new RegistrationService();

export class RegistrationController {
  /**
   * POST /registration/verify-identity
   * Stage 1: Verify student identity
   */
  async verifyIdentity(req: Request, res: Response): Promise<void> {
    console.log("📝 REGISTRATION STAGE 1 - Request received:", {
      body: req.body,
      timestamp: new Date().toISOString(),
    });

    try {
      const { nama, nim, nrm, tglahir }: Stage1Request = req.body;

      console.log("📝 REGISTRATION STAGE 1 - Identity verification:", {
        nama: nama ? "***" : undefined, // Hide sensitive data in logs
        nim,
        nrm,
        tglahir,
      });

      const result = await registrationService.verifyIdentity({
        nama,
        nim,
        nrm,
        tglahir,
      });

      console.log("📝 REGISTRATION STAGE 1 - Verification result:", {
        success: result.success,
        message: result.message,
        hasStudentData: !!result.studentData,
      });

      const statusCode = result.success ? 200 : 400;
      res.status(statusCode).json({
        success: result.success,
        message: result.message,
        data: result.studentData,
      } as ApiResponse);
    } catch (error) {
      console.error("📝 REGISTRATION STAGE 1 - Error:", error);
      res.status(500).json({
        success: false,
        message: "Terjadi kesalahan sistem. Silakan coba lagi.",
        errors: ["Internal server error during identity verification"],
      } as ApiResponse);
    }
  }

  /**
   * POST /registration/create-account
   * Stage 2: Create account after identity verification
   */
  async createAccount(req: Request, res: Response): Promise<void> {
    console.log("📝 REGISTRATION STAGE 2 - Request received:", {
      body: {
        ...req.body,
        password: req.body.password ? "***" : undefined, // Hide password in logs
      },
      timestamp: new Date().toISOString(),
    });

    try {
      const {
        nama,
        nim,
        nrm,
        tglahir,
        username,
        email,
        password,
      }: Stage2Request = req.body;

      console.log("📝 REGISTRATION STAGE 2 - Account creation:", {
        nama: nama ? "***" : undefined,
        nim,
        nrm,
        username,
        email,
        hasPassword: !!password,
      });

      const result = await registrationService.createAccount({
        nama,
        nim,
        nrm,
        tglahir,
        username,
        email,
        password,
      });

      console.log("📝 REGISTRATION STAGE 2 - Creation result:", {
        success: result.success,
        message: result.message,
      });

      const statusCode = result.success ? 200 : 400;
      res.status(statusCode).json({
        success: result.success,
        message: result.message,
      } as ApiResponse);
    } catch (error) {
      console.error("📝 REGISTRATION STAGE 2 - Error:", error);
      res.status(500).json({
        success: false,
        message: "Terjadi kesalahan sistem. Silakan coba lagi.",
        errors: ["Internal server error during account creation"],
      } as ApiResponse);
    }
  }
}
