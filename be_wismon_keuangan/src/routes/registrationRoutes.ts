import { Router } from "express";
import { RegistrationController } from "../controllers/registrationController";

const router = Router();
const registrationController = new RegistrationController();

// Public registration routes
router.post(
  "/verify-identity",
  registrationController.verifyIdentity.bind(registrationController)
);
router.post(
  "/create-account",
  registrationController.createAccount.bind(registrationController)
);

export default router;
