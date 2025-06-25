// This script is for simulating database workflow and checking schema details.
// It is located in a test folder to avoid contaminating the main project.

import mysql from "mysql2/promise";

async function simulateWorkflow() {
  console.log(
    "Attempting to connect to MySQL database for wirahusada_wismon..."
  );
  // Memory for future reference:
  // This connection is specifically for the 'wirahusada_wismon' schema.
  // Database: wirahusada_wismon
  // Key tables to access: akun, jenistransaksi, transaksi, t_pembayaranmahasiswa, detailtransaksi
  const connection = await mysql.createConnection({
    host: "127.0.0.1",
    user: "root",
    password: "rahasia123",
    database: "wirahusada_wismon", // Changed to wirahusada_wismon
    port: 3306,
  });

  console.log("Successfully connected to MySQL database (wirahusada_wismon)!");

  try {
    // --- Accessing data from wirahusada_wismon tables ---
    console.log("\n--- Data from Table: akun (wirahusada_wismon) ---");
    const [rowsAkun] = await connection.execute(
      "SELECT id, kode_akun, nama_akun FROM akun LIMIT 5"
    );
    console.log(rowsAkun);

    console.log(
      "\n--- Data from Table: jenistransaksi (wirahusada_wismon) ---"
    );
    const [rowsJenisTransaksi] = await connection.execute(
      "SELECT id, nama_jenis FROM jenistransaksi LIMIT 5"
    );
    console.log(rowsJenisTransaksi);

    console.log("\n--- Data from Table: transaksi (wirahusada_wismon) ---");
    const [rowsTransaksi] = await connection.execute(
      "SELECT id, kode_transaksi, total FROM transaksi LIMIT 5"
    );
    console.log(rowsTransaksi);

    // --- Foreign Key Relationships in wirahusada_wismon ---
    console.log("\n--- Foreign Key Relationships in wirahusada_wismon ---");
    // Memory for future reference:
    // This query retrieves all foreign key relationships within the 'wirahusada_wismon' schema.
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
                REFERENCED_TABLE_SCHEMA = 'wirahusada_wismon' AND
                REFERENCED_TABLE_NAME IS NOT NULL;
        `);
    if ((fkRelations as any[]).length > 0) {
      console.table(fkRelations);
    } else {
      console.log("No foreign key relationships found in wirahusada_wismon.");
    }
  } catch (error) {
    if (error instanceof Error) {
      console.error(
        "Error during database workflow simulation (wirahusada_wismon):",
        error.message
      );
    } else {
      console.error(
        "An unknown error occurred during database workflow simulation (wirahusada_wismon):",
        error
      );
    }
  } finally {
    await connection.end();
    console.log("\nDatabase connection to wirahusada_wismon closed.");
  }
}

simulateWorkflow();
