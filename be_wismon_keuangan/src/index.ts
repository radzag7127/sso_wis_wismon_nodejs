import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { testConnections } from "./config/database";
import authRoutes from "./routes/authRoutes";
import paymentRoutes from "./routes/paymentRoutes";

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const CORS_ORIGIN = process.env.CORS_ORIGIN || "http://localhost:3000";

// Middleware - Allow multiple origins for development
const allowedOrigins = [
  "http://localhost:3000",
  "http://localhost:8080",
  "http://localhost:54128",
  /^http:\/\/localhost:\d+$/, // Allow any localhost port
];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps or curl requests)
      if (!origin) return callback(null, true);

      // Check if origin is in allowed list or matches localhost pattern
      const isAllowed = allowedOrigins.some((allowedOrigin) => {
        if (typeof allowedOrigin === "string") {
          return allowedOrigin === origin;
        } else {
          return allowedOrigin.test(origin);
        }
      });

      if (isAllowed) {
        callback(null, true);
      } else {
        callback(new Error("Not allowed by CORS"));
      }
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/payments", paymentRoutes);

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "development",
  });
});

// Basic route
app.get("/", (req, res) => {
  res.json({
    message: "Wismon Keuangan Backend API",
    status: "running",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    endpoints: {
      auth: {
        login: "POST /api/auth/login",
        profile: "GET /api/auth/profile",
        verify: "POST /api/auth/verify",
      },
      payments: {
        history: "GET /api/payments/history",
        summary: "GET /api/payments/summary",
        detail: "GET /api/payments/detail/:id",
        refresh: "POST /api/payments/refresh",
        types: "GET /api/payments/types",
      },
    },
  });
});

// Error handling middleware
app.use(
  (
    error: any,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    console.error("Unhandled error:", error);
    res.status(500).json({
      success: false,
      message: "Internal server error",
      errors: [
        process.env.NODE_ENV === "development"
          ? error.message
          : "Something went wrong",
      ],
    });
  }
);

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    success: false,
    message: "Endpoint not found",
    errors: [`${req.method} ${req.originalUrl} not found`],
  });
});

// Start server function
async function startServer() {
  try {
    console.log("🚀 Starting Wismon Keuangan Backend Server...");
    console.log(`📍 Environment: ${process.env.NODE_ENV || "development"}`);

    // Test database connections
    console.log("🔍 Testing database connections...");
    const dbResults = await testConnections();

    const successCount = Object.values(dbResults).filter(Boolean).length;
    const totalCount = Object.keys(dbResults).length;

    if (successCount === totalCount) {
      console.log("✅ All database connections successful!");
    } else {
      console.log(
        `⚠️  ${successCount}/${totalCount} database connections successful`
      );
      console.log("Database connection results:", dbResults);
    }

    // Start the server
    app.listen(PORT, () => {
      console.log("🎉 Server started successfully!");
      console.log(`📡 API endpoint: http://localhost:${PORT}`);
      console.log(`📋 API documentation: http://localhost:${PORT}`);
      console.log(`🔧 Health check: http://localhost:${PORT}/health`);
      console.log("");
      console.log("Available Endpoints:");
      console.log("  Authentication:");
      console.log("    POST /api/auth/login      - Student login");
      console.log("    GET  /api/auth/profile    - Get student profile");
      console.log("    POST /api/auth/verify     - Verify JWT token");
      console.log("  Payments:");
      console.log(
        "    GET  /api/payments/history     - Payment history with filters"
      );
      console.log("    GET  /api/payments/summary     - Payment summary/recap");
      console.log("    GET  /api/payments/detail/:id  - Transaction details");
      console.log("    POST /api/payments/refresh     - Refresh payment data");
      console.log(
        "    GET  /api/payments/types       - Available payment types"
      );
      console.log("");
      console.log("💡 Ready to accept requests!");
    });
  } catch (error) {
    console.error("💥 Failed to start server:", error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on("SIGTERM", () => {
  console.log("🛑 SIGTERM received. Shutting down gracefully...");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("🛑 SIGINT received. Shutting down gracefully...");
  process.exit(0);
});

// Handle unhandled promise rejections
process.on("unhandledRejection", (reason, promise) => {
  console.error("💥 Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});

// Start the server
startServer();
