// This script is for simulating database workflow and checking schema details.
// It is located in a test folder to avoid contaminating the main project.

import mysql from "mysql2/promise";

async function simulateWorkflow() {
  console.log("Attempting to connect to MySQL database...");
  const connection = await mysql.createConnection({
    host: "127.0.0.1",
    user: "root",
    password: "rahasia123",
    database: "wirahusada_wis",
    port: 3306,
  });

  console.log("Successfully connected to MySQL database!");

  try {
    console.log("\n--- Data from Table: mahasiswa ---");
    const [rowsMahasiswa] = await connection.execute(
      "SELECT nim, namam FROM mahasiswa LIMIT 5"
    );
    console.log(rowsMahasiswa);

    console.log("\n--- Data from Table: pegawai ---");
    const [rowsPegawai] = await connection.execute(
      "SELECT nip, nama FROM pegawai LIMIT 5"
    );
    console.log(rowsPegawai);

    console.log("\n--- Data from Table: user_mahasiswa ---");
    const [rowsUserMahasiswa] = await connection.execute(
      "SELECT * FROM user_mahasiswa LIMIT 5"
    );
    console.log(rowsUserMahasiswa);

    console.log("\n--- Data from Table: user_pegawai ---");
    const [rowsUserPegawai] = await connection.execute(
      "SELECT * FROM user_pegawai LIMIT 5"
    );
    console.log(rowsUserPegawai);

    console.log("\n--- Foreign Key Relationships in wirahusada_wis ---");
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
    if ((fkRelations as any[]).length > 0) {
      console.table(fkRelations);
    } else {
      console.log("No foreign key relationships found in wirahusada_wis.");
    }
  } catch (error) {
    if (error instanceof Error) {
      console.error(
        "Error during database workflow simulation:",
        error.message
      );
    } else {
      console.error(
        "An unknown error occurred during database workflow simulation:",
        error
      );
    }
  } finally {
    await connection.end();
    console.log("\nDatabase connection closed.");
  }
}

simulateWorkflow();
