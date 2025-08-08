// src/utils/migrations.ts

import { executeWisakaQuery } from "../config/database";

export class DatabaseMigration {
  /**
   * Check if usulan_hapus column exists in krsmatakuliah table
   */
  private async checkUsulanHapusColumn(): Promise<boolean> {
    try {
      const sql = `
        SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
          AND TABLE_NAME = 'krsmatakuliah' 
          AND COLUMN_NAME = 'usulan_hapus'
      `;
      
      const result = await executeWisakaQuery(sql, []);
      const columns = result as any[];
      
      console.log("🔍 Migration Check - usulan_hapus column exists:", columns.length > 0);
      return columns.length > 0;
    } catch (error) {
      console.error("❌ Migration Check - Error checking usulan_hapus column:", error);
      throw error;
    }
  }

  /**
   * Add usulan_hapus column to krsmatakuliah table if it doesn't exist
   */
  private async addUsulanHapusColumn(): Promise<void> {
    try {
      const sql = `
        ALTER TABLE krsmatakuliah 
        ADD COLUMN usulan_hapus BOOLEAN NOT NULL DEFAULT FALSE
      `;
      
      await executeWisakaQuery(sql, []);
      console.log("✅ Migration Success - Added usulan_hapus column to krsmatakuliah table");
    } catch (error) {
      console.error("❌ Migration Error - Failed to add usulan_hapus column:", error);
      throw error;
    }
  }

  /**
   * Check if krsmatakuliah table has the expected structure
   */
  async checkTableStructure(): Promise<{
    hasUsulanHapus: boolean;
    tableExists: boolean;
    columnCount: number;
  }> {
    try {
      // First check if table exists
      const tableCheckSql = `
        SELECT COUNT(*) as count
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = DATABASE() 
          AND TABLE_NAME = 'krsmatakuliah'
      `;
      
      const tableResult = await executeWisakaQuery(tableCheckSql, []);
      const tableExists = (tableResult as any[])[0]?.count > 0;
      
      if (!tableExists) {
        throw new Error("krsmatakuliah table does not exist!");
      }

      // Check all columns
      const columnsSql = `
        SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
          AND TABLE_NAME = 'krsmatakuliah'
        ORDER BY ORDINAL_POSITION
      `;
      
      const columns = await executeWisakaQuery(columnsSql, []) as any[];
      const hasUsulanHapus = columns.some(col => col.COLUMN_NAME === 'usulan_hapus');
      
      console.log("📊 Table Structure Check:", {
        tableExists,
        hasUsulanHapus,
        columnCount: columns.length,
        columns: columns.map(col => ({
          name: col.COLUMN_NAME,
          type: col.COLUMN_TYPE,
          nullable: col.IS_NULLABLE,
          default: col.COLUMN_DEFAULT
        }))
      });

      return {
        hasUsulanHapus,
        tableExists,
        columnCount: columns.length
      };
    } catch (error) {
      console.error("❌ Table Structure Check Failed:", error);
      throw error;
    }
  }

  /**
   * Run migration to ensure usulan_hapus column exists
   */
  async runMigration(): Promise<{
    success: boolean;
    message: string;
    hadToMigrate: boolean;
  }> {
    try {
      console.log("🚀 Starting database migration check...");
      
      const structure = await this.checkTableStructure();
      
      if (!structure.tableExists) {
        return {
          success: false,
          message: "krsmatakuliah table does not exist",
          hadToMigrate: false
        };
      }

      if (structure.hasUsulanHapus) {
        console.log("✅ Migration Check - usulan_hapus column already exists, no migration needed");
        return {
          success: true,
          message: "usulan_hapus column already exists",
          hadToMigrate: false
        };
      }

      console.log("🔧 Migration - Adding usulan_hapus column...");
      await this.addUsulanHapusColumn();
      
      // Verify the migration was successful
      const postMigrationCheck = await this.checkUsulanHapusColumn();
      
      if (postMigrationCheck) {
        return {
          success: true,
          message: "Successfully added usulan_hapus column to krsmatakuliah table",
          hadToMigrate: true
        };
      } else {
        return {
          success: false,
          message: "Migration completed but column verification failed",
          hadToMigrate: true
        };
      }
    } catch (error) {
      console.error("❌ Migration Failed:", error);
      return {
        success: false,
        message: `Migration failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        hadToMigrate: false
      };
    }
  }

  /**
   * Initialize database migrations - call this on server startup
   */
  async initialize(): Promise<void> {
    try {
      const result = await this.runMigration();
      
      if (!result.success) {
        console.error("❌ Database Migration Failed:", result.message);
        throw new Error(`Database migration failed: ${result.message}`);
      }
      
      if (result.hadToMigrate) {
        console.log("✅ Database Migration Completed:", result.message);
      } else {
        console.log("ℹ️ Database Migration Skipped:", result.message);
      }
    } catch (error) {
      console.error("❌ Database Migration Initialization Failed:", error);
      throw error;
    }
  }
}

// Export singleton instance
export const databaseMigration = new DatabaseMigration();