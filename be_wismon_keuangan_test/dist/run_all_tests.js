"use strict";
// Comprehensive Database Workflow Test Runner
// This script runs all database schema tests in sequence
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const promise_1 = __importDefault(require("mysql2/promise"));
const databaseConnections_1 = require("./databaseConnections");
async function testDatabaseConnection(config, schemaName) {
    try {
        console.log(`\n🔍 Testing connection to ${schemaName}...`);
        const connection = await promise_1.default.createConnection(config);
        // Test basic connectivity
        const [result] = await connection.execute("SELECT 1 as test");
        // Get table count
        const [tables] = await connection.execute(`SELECT COUNT(*) as table_count FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?`, [config.database]);
        await connection.end();
        const tableCount = tables[0].table_count;
        console.log(`✅ ${schemaName} connection successful - ${tableCount} tables found`);
        return true;
    }
    catch (error) {
        console.log(`❌ ${schemaName} connection failed:`, error instanceof Error ? error.message : error);
        return false;
    }
}
async function runComprehensiveTests() {
    console.log("🚀 Starting Comprehensive Database Workflow Tests");
    console.log("=" + "=".repeat(60));
    const results = {
        sso: false,
        wis: false,
        wismon: false,
    };
    // Test all database connections
    results.sso = await testDatabaseConnection(databaseConnections_1.ssoDbConfig, "wirahusada_sso");
    results.wis = await testDatabaseConnection(databaseConnections_1.wisDbConfig, "wirahusada_wis");
    results.wismon = await testDatabaseConnection(databaseConnections_1.wismonDbConfig, "wirahusada_wismon");
    // Summary report
    console.log("\n📊 Test Summary Report");
    console.log("=" + "=".repeat(60));
    console.log(`SSO Database (wirahusada_sso):     ${results.sso ? "✅ PASS" : "❌ FAIL"}`);
    console.log(`WIS Database (wirahusada_wis):     ${results.wis ? "✅ PASS" : "❌ FAIL"}`);
    console.log(`WISMON Database (wirahusada_wismon): ${results.wismon ? "✅ PASS" : "❌ FAIL"}`);
    const totalPassed = Object.values(results).filter((r) => r).length;
    const totalTests = Object.values(results).length;
    console.log(`\n🎯 Overall Result: ${totalPassed}/${totalTests} databases accessible`);
    if (totalPassed === totalTests) {
        console.log("🎉 All database connections are working properly!");
        console.log("\n📋 Available individual test scripts:");
        console.log("   • npx ts-node wirahusada_sso_workflow.ts");
        console.log("   • npx ts-node wirahusada_wis_workflow.ts");
        console.log("   • npx ts-node wirahusada_wismon_workflow.ts");
        console.log("   • npx ts-node simulate_db_workflow.ts");
    }
    else {
        console.log("⚠️  Some database connections failed. Please check your database setup.");
    }
    console.log("\n" + "=".repeat(60));
}
// Execute the comprehensive tests
runComprehensiveTests().catch((error) => {
    console.error("💥 Critical error during testing:", error);
    process.exit(1);
});
//# sourceMappingURL=run_all_tests.js.map