import { Router } from "express";
import { AuthController } from "../controllers/authController";
import { authenticateToken } from "../utils/auth";

const router = Router();
const authController = new AuthController();

// Public routes
router.post("/login", authController.login.bind(authController));

// Protected routes (require authentication)
router.get(
  "/profile",
  authenticateToken,
  authController.getProfile.bind(authController)
);
router.post(
  "/verify",
  authenticateToken,
  authController.verifyToken.bind(authController)
);

export default router;
