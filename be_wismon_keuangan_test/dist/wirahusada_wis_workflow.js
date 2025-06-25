"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const promise_1 = __importDefault(require("mysql2/promise"));
// This script is dedicated to simulating database workflow and checking schema details for wirahusada_wis.
// It is located in a test folder to avoid contaminating the main project.
async function simulateWisWorkflow() {
    console.log("Attempting to connect to MySQL database for wirahusada_wis...");
    // Memory for future reference:
    // This connection is specifically for the 'wirahusada_wis' schema.
    // Database: wirahusada_wis
    // Key tables to access: mahasiswa, pegawai, user_mahasiswa, user_pegawai, agama, kota_kabupaten, propinsi
    const connection = await promise_1.default.createConnection({
        host: "127.0.0.1",
        user: "root",
        password: "rahasia123",
        database: "wirahusada_wis",
        port: 3306,
    });
    console.log("Successfully connected to MySQL database (wirahusada_wis)!");
    try {
        // --- Accessing data from wirahusada_wis tables ---
        console.log("\n--- Data from Table: mahasiswa (wirahusada_wis) ---");
        const [rowsMahasiswa] = await connection.execute("SELECT nim, namam FROM mahasiswa LIMIT 5");
        console.log(rowsMahasiswa);
        console.log("\n--- Data from Table: pegawai (wirahusada_wis) ---");
        const [rowsPegawai] = await connection.execute("SELECT nip, nama FROM pegawai LIMIT 5");
        console.log(rowsPegawai);
        console.log("\n--- Data from Table: user_mahasiswa (wirahusada_wis) ---");
        const [rowsUserMahasiswa] = await connection.execute("SELECT * FROM user_mahasiswa LIMIT 5");
        console.log(rowsUserMahasiswa);
        console.log("\n--- Data from Table: user_pegawai (wirahusada_wis) ---");
        const [rowsUserPegawai] = await connection.execute("SELECT * FROM user_pegawai LIMIT 5");
        console.log(rowsUserPegawai);
        // --- Foreign Key Relationships in wirahusada_wis ---
        console.log("\n--- Foreign Key Relationships in wirahusada_wis ---");
        // Memory for future reference:
        // This query retrieves all foreign key relationships within the 'wirahusada_wis' schema.
        // Useful for understanding table dependencies and data integrity.
        const [fkRelations] = await connection.execute(`
            SELECT
                TABLE_NAME,
                COLUMN_NAME,
                CONSTRAINT_NAME,
                REFERENCED_TABLE_NAME,
                REFERENCED_COLUMN_NAME
            FROM
                INFORMATION_SCHEMA.KEY_COLUMN_USAGE
            WHERE
                REFERENCED_TABLE_SCHEMA = 'wirahusada_wis' AND
                REFERENCED_TABLE_NAME IS NOT NULL;
        `);
        if (fkRelations.length > 0) {
            console.table(fkRelations);
        }
        else {
            console.log("No foreign key relationships found in wirahusada_wis.");
        }
    }
    catch (error) {
        if (error instanceof Error) {
            console.error("Error during wirahusada_wis database workflow simulation:", error.message);
        }
        else {
            console.error("An unknown error occurred during wirahusada_wis database workflow simulation:", error);
        }
    }
    finally {
        await connection.end();
        console.log("\nDatabase connection to wirahusada_wis closed.");
    }
}
simulateWisWorkflow();
//# sourceMappingURL=wirahusada_wis_workflow.js.map