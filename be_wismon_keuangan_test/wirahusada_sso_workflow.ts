import mysql from "mysql2/promise";

// This script is dedicated to simulating database workflow and checking schema details for wirahusada_sso.
// It is located in a test folder to avoid contaminating the main project.

async function simulateSsoWorkflow() {
  console.log("Attempting to connect to MySQL database for wirahusada_sso...");
  // Memory for future reference:
  // This connection is specifically for the 'wirahusada_sso' schema.
  // Database: wirahusada_sso
  // Key tables to access: user, role, app, user_role, auth_function, auth_menu
  const connection = await mysql.createConnection({
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
    const [rowsUser] = await connection.execute(
      "SELECT id, username, email FROM user LIMIT 5"
    );
    console.log(rowsUser);

    console.log("\n--- Data from Table: role (wirahusada_sso) ---");
    const [rowsRole] = await connection.execute(
      "SELECT id, nama_role FROM role LIMIT 5"
    );
    console.log(rowsRole);

    console.log("\n--- Data from Table: app (wirahusada_sso) ---");
    const [rowsApp] = await connection.execute(
      "SELECT id, nama_app FROM app LIMIT 5"
    );
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
    if ((fkRelations as any[]).length > 0) {
      console.table(fkRelations);
    } else {
      console.log("No foreign key relationships found in wirahusada_sso.");
    }
  } catch (error) {
    if (error instanceof Error) {
      console.error(
        "Error during wirahusada_sso database workflow simulation:",
        error.message
      );
    } else {
      console.error(
        "An unknown error occurred during wirahusada_sso database workflow simulation:",
        error
      );
    }
  } finally {
    await connection.end();
    console.log("\nDatabase connection to wirahusada_sso closed.");
  }
}

simulateSsoWorkflow();
