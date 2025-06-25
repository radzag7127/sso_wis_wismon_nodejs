"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const promise_1 = __importDefault(require("mysql2/promise"));
const crypto_1 = __importDefault(require("crypto"));
// This script is dedicated to simulating database workflow and checking schema details for wirahusada_sso.
// It is located in a test folder to avoid contaminating the main project.
// Database connection configuration for wirahusada_sso
const ssoDbConfig = {
    host: "127.0.0.1",
    port: 3306,
    user: "root",
    password: "rahasia123",
    database: "wirahusada_sso",
};
// Function to hash a string using MD5
function hashMd5(input) {
    return crypto_1.default.createHash("md5").update(input).digest("hex");
}
// Function to simulate SSO login
async function simulateSsoLogin(username, passwordAttempt) {
    let connection;
    try {
        connection = await promise_1.default.createConnection(ssoDbConfig);
        console.log(`Attempting to log in as user: ${username}`);
        // Retrieve the stored hashed password for the given username
        const [rows] = (await connection.execute("SELECT password FROM user WHERE username = ?", [username]));
        if (rows.length === 0) {
            console.log(`Login failed: User '${username}' not found.`);
            return false;
        }
        const storedHashedPassword = rows[0].password;
        const enteredPasswordHash = hashMd5(passwordAttempt);
        if (enteredPasswordHash === storedHashedPassword) {
            console.log(`Login successful for user: ${username}`);
            return true;
        }
        else {
            console.log(`Login failed: Incorrect password for user: ${username}`);
            return false;
        }
    }
    catch (error) {
        console.error("Error during SSO login simulation:", error);
        return false;
    }
    finally {
        if (connection) {
            await connection.end();
        }
    }
}
// Simulate a login session
(async () => {
    console.log("--- SSO Login Simulation ---");
    // Successful login attempt
    await simulateSsoLogin("admin", "rahasia123"); // This should succeed
    console.log("\n");
    // Failed login attempt
    await simulateSsoLogin("admin", "wrongpassword"); // This should fail
    console.log("\n");
    // Non-existent user attempt
    await simulateSsoLogin("nonexistentuser", "anypassword"); // This should fail
})();
async function simulateSsoWorkflow() {
    console.log("Attempting to connect to MySQL database for wirahusada_sso...");
    // Memory for future reference:
    // This connection is specifically for the 'wirahusada_sso' schema.
    // Database: wirahusada_sso
    // Key tables to access: user, role, app, user_role, auth_function, auth_menu
    const connection = await promise_1.default.createConnection({
        host: "127.0.0.1",
        user: "root",
        password: "rahasia123",
        database: "wirahusada_sso",
        port: 3306,
    });
    console.log("Successfully connected to MySQL database (wirahusada_sso)!");
    try {
        // --- Accessing data from wirahusada_sso tables ---
        console.log("\n--- Data from Table: user (wirahusada_sso) ---");
        const [rowsUser] = await connection.execute("SELECT id, username, password FROM user LIMIT 5");
        console.log(rowsUser);
        console.log("\n--- Data from Table: role (wirahusada_sso) ---");
        const [rowsRole] = await connection.execute("SELECT id, nama_role FROM role LIMIT 5");
        console.log(rowsRole);
        console.log("\n--- Data from Table: app (wirahusada_sso) ---");
        const [rowsApp] = await connection.execute("SELECT id, nama_app FROM app LIMIT 5");
        console.log(rowsApp);
        // --- Foreign Key Relationships in wirahusada_sso ---
        console.log("\n--- Foreign Key Relationships in wirahusada_sso ---");
        // Memory for future reference:
        // This query retrieves all foreign key relationships within the 'wirahusada_sso' schema.
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
                REFERENCED_TABLE_SCHEMA = 'wirahusada_sso' AND
                REFERENCED_TABLE_NAME IS NOT NULL;
        `);
        if (fkRelations.length > 0) {
            console.table(fkRelations);
        }
        else {
            console.log("No foreign key relationships found in wirahusada_sso.");
        }
    }
    catch (error) {
        if (error instanceof Error) {
            console.error("Error during wirahusada_sso database workflow simulation:", error.message);
        }
        else {
            console.error("An unknown error occurred during wirahusada_sso database workflow simulation:", error);
        }
    }
    finally {
        await connection.end();
        console.log("\nDatabase connection to wirahusada_sso closed.");
    }
}
simulateSsoWorkflow();
//# sourceMappingURL=wirahusada_sso_workflow.js.map