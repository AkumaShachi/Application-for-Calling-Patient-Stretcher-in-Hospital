const pool = require('./src/Database');

async function checkNurses() {
  try {
    const [rows] = await pool.query('SELECT user_num, user_fname, role_id FROM users WHERE role_id = 2');
    console.log('Nurses found:', rows.length);
    console.log(rows);
    process.exit(0);
  } catch (err) {
    console.error('Error:', err);
    process.exit(1);
  }
}

checkNurses();
