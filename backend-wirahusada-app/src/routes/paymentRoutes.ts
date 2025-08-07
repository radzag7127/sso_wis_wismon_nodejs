import { Router } from "express";
import { PaymentController } from "../controllers/paymentController";
import { authenticateToken } from "../utils/auth";

const router = Router();
const paymentController = new PaymentController();

// All payment routes require authentication
router.use(authenticateToken);

// Payment history with filtering and pagination
router.get(
  "/history",
  paymentController.getPaymentHistory.bind(paymentController)
);

// Payment summary/recapitulation
router.get(
  "/summary",
  paymentController.getPaymentSummary.bind(paymentController)
);

// Transaction detail
router.get(
  "/detail/:id",
  paymentController.getTransactionDetail.bind(paymentController)
);

// Refresh payment data
router.post(
  "/refresh",
  paymentController.refreshPaymentData.bind(paymentController)
);

// Get payment types for filtering
router.get("/types", paymentController.getPaymentTypes.bind(paymentController));

export default router;
