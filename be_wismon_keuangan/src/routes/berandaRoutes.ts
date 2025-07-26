import { Router } from "express";
import { BerandaController } from "../controllers/berandaController";
import { authenticateToken } from "../utils/auth";

const router = Router();
const berandaController = new BerandaController();

// All beranda routes require authentication
router.use(authenticateToken);

// Get aggregated beranda data
router.get("/", berandaController.getBerandaData.bind(berandaController));

// Get announcements for hero carousel
router.get(
  "/announcements",
  berandaController.getAnnouncements.bind(berandaController)
);

export default router;
