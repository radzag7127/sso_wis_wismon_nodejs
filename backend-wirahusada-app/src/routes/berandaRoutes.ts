import { Router } from "express";
import { BerandaController } from "../controllers/berandaController";
import { authenticateToken } from "../utils/auth";
import { authCacheMiddleware, noCacheMiddleware } from "../middleware/cacheControl";

const router = Router();
const berandaController = new BerandaController();

// Apply cache control middleware to prevent stale authentication responses
router.use(authCacheMiddleware);

// All beranda routes require authentication
router.use(authenticateToken);

// Get aggregated beranda data - critical endpoint for session cache issues
router.get("/", 
  noCacheMiddleware, // Extra cache prevention for the main beranda endpoint
  berandaController.getBerandaData.bind(berandaController)
);

// Get announcements for hero carousel
router.get(
  "/announcements",
  berandaController.getAnnouncements.bind(berandaController)
);

export default router;
