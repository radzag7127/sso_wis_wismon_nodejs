import mysql from "mysql2/promise";
import dotenv from "dotenv";

dotenv.config();

export interface DatabaseConfig {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
  connectionLimit: number;
  acquireTimeout: number;
  timeout: number;
}

// SSO Database Configuration
const ssoDbConfig: DatabaseConfig = {
  host: process.env.DB_SSO_HOST || "127.0.0.1",
  port: parseInt(process.env.DB_SSO_PORT || "3306"),
  user: process.env.DB_SSO_USER || "root",
  password: process.env.DB_SSO_PASSWORD || "",
  database: process.env.DB_SSO_NAME || "wirahusada_sso",
  connectionLimit: 10,
  acquireTimeout: 60000,
  timeout: 60000,
};

// WIS Database Configuration
const wisDbConfig: DatabaseConfig = {
  host: process.env.DB_WIS_HOST || "127.0.0.1",
  port: parseInt(process.env.DB_WIS_PORT || "3306"),
  user: process.env.DB_WIS_USER || "root",
  password: process.env.DB_WIS_PASSWORD || "",
  database: process.env.DB_WIS_NAME || "wirahusada_wis",
  connectionLimit: 10,
  acquireTimeout: 60000,
  timeout: 60000,
};

// WISMON Database Configuration
const wismonDbConfig: DatabaseConfig = {
  host: process.env.DB_WISMON_HOST || "127.0.0.1",
  port: parseInt(process.env.DB_WISMON_PORT || "3306"),
  user: process.env.DB_WISMON_USER || "root",
  password: process.env.DB_WISMON_PASSWORD || "",
  database: process.env.DB_WISMON_NAME || "wirahusada_wismon",
  connectionLimit: 10,
  acquireTimeout: 60000,
  timeout: 60000,
};

// Create connection pools
export const ssoPool = mysql.createPool(ssoDbConfig);
export const wisPool = mysql.createPool(wisDbConfig);
export const wismonPool = mysql.createPool(wismonDbConfig);

// Test database connections
export const testConnections = async () => {
  const results = {
    sso: false,
    wis: false,
    wismon: false,
  };

  try {
    const ssoConnection = await ssoPool.getConnection();
    console.log("✅ SSO Database connected successfully");
    console.log(
      `📊 SSO Connected to: ${ssoDbConfig.host}:${ssoDbConfig.port}/${ssoDbConfig.database}`
    );
    ssoConnection.release();
    results.sso = true;
  } catch (error) {
    console.error("❌ SSO Database connection failed:", error);
  }

  try {
    const wisConnection = await wisPool.getConnection();
    console.log("✅ WIS Database connected successfully");
    console.log(
      `📊 WIS Connected to: ${wisDbConfig.host}:${wisDbConfig.port}/${wisDbConfig.database}`
    );
    wisConnection.release();
    results.wis = true;
  } catch (error) {
    console.error("❌ WIS Database connection failed:", error);
  }

  try {
    const wismonConnection = await wismonPool.getConnection();
    console.log("✅ WISMON Database connected successfully");
    console.log(
      `📊 WISMON Connected to: ${wismonDbConfig.host}:${wismonDbConfig.port}/${wismonDbConfig.database}`
    );
    wismonConnection.release();
    results.wismon = true;
  } catch (error) {
    console.error("❌ WISMON Database connection failed:", error);
  }

  return results;
};

// Execute query helper functions
export const executeSsoQuery = async (query: string, params?: any[]) => {
  try {
    const [results] = await ssoPool.execute(query, params);
    return results;
  } catch (error) {
    console.error("SSO Database query error:", error);
    throw error;
  }
};

export const executeWisQuery = async (query: string, params?: any[]) => {
  try {
    const [results] = await wisPool.execute(query, params);
    return results;
  } catch (error) {
    console.error("WIS Database query error:", error);
    throw error;
  }
};

export const executeWismonQuery = async (query: string, params?: any[]) => {
  console.log("🗄️ WISMON DB - Executing query:", {
    query: query.replace(/\s+/g, " ").trim(),
    params,
    paramsTypes: params?.map((p) => ({ value: p, type: typeof p })),
    timestamp: new Date().toISOString(),
  });

  try {
    const [results] = await wismonPool.execute(query, params);

    console.log("🗄️ WISMON DB - Query successful:", {
      resultCount: Array.isArray(results) ? results.length : "Not array",
      resultType: typeof results,
      firstResult: Array.isArray(results) ? results[0] : results,
    });

    return results;
  } catch (error) {
    console.error("🗄️ WISMON DB - Query error:", {
      error,
      query: query.replace(/\s+/g, " ").trim(),
      params,
      errorMessage: error instanceof Error ? error.message : "Unknown error",
    });
    throw error;
  }
};

// Export pools for direct access if needed
export { ssoDbConfig, wisDbConfig, wismonDbConfig };

// Keep backward compatibility
export const pool = ssoPool; // Default to SSO for auth
export const executeQuery = executeSsoQuery;
