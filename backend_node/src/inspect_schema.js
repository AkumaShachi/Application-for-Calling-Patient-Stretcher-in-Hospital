const pool = require('./Database');

async function inspectSchema() {
  try {
    console.log('Inspecting recordhistory schema...');
    
    const [rows] = await pool.query("DESCRIBE recordhistory");
    console.log(rows);

    process.exit(0);
  } catch (err) {
    console.error('❌ Error inspecting schema:', err);
    process.exit(1);
  }
}

inspectSchema();
