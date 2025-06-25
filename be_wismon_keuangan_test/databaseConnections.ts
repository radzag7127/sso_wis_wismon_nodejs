import { PoolOptions } from "mysql2/promise";

// Konfigurasi koneksi untuk database wirahusada_sso
export const ssoDbConfig: PoolOptions = {
  host: "127.0.0.1",
  user: "root",
  password: "rahasia123",
  database: "wirahusada_sso",
  port: 3306,
};

// Konfigurasi koneksi untuk database wirahusada_wis
export const wisDbConfig: PoolOptions = {
  host: "127.0.0.1",
  user: "root",
  password: "rahasia123",
  database: "wirahusada_wis",
  port: 3306,
};

// Konfigurasi koneksi untuk database wirahusada_wismon
export const wismonDbConfig: PoolOptions = {
  host: "127.0.0.1",
  user: "root",
  password: "rahasia123",
  database: "wirahusada_wismon",
  port: 3306,
};

console.log(
  "Database connection configurations for SSO, WIS, and Wismon are set up."
);
