"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.wismonDbConfig = exports.wisDbConfig = exports.ssoDbConfig = void 0;
// Konfigurasi koneksi untuk database wirahusada_sso
exports.ssoDbConfig = {
    host: "127.0.0.1",
    user: "root",
    password: "rahasia123",
    database: "wirahusada_sso",
    port: 3306,
};
// Konfigurasi koneksi untuk database wirahusada_wis
exports.wisDbConfig = {
    host: "127.0.0.1",
    user: "root",
    password: "rahasia123",
    database: "wirahusada_wis",
    port: 3306,
};
// Konfigurasi koneksi untuk database wirahusada_wismon
exports.wismonDbConfig = {
    host: "127.0.0.1",
    user: "root",
    password: "rahasia123",
    database: "wirahusada_wismon",
    port: 3306,
};
console.log("Database connection configurations for SSO, WIS, and Wismon are set up.");
//# sourceMappingURL=databaseConnections.js.map