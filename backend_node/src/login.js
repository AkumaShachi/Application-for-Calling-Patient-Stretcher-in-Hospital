const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('./Database'); // mysql2/promise

// Login
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    const [rows] = await pool.query(
      `SELECT u.*, r.role_name 
       FROM users u 
       JOIN roles r ON u.role_id = r.role_id 
       WHERE u.user_username = ?`,
      [username]
    );

    if (!rows.length) {
      return res.status(401).json({ status: 'error', message: 'Invalid username or password' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.user_password_hash);

    if (!match) {
      return res.status(401).json({ status: 'error', message: 'Invalid username or password' });
    }

    res.json({ status: 'success', role: user.role_name });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: 'error', message: 'Server error' });
  }
});

// Get user profile
router.get('/user/:username', async (req, res) => {
  const { username } = req.params;

  try {
    const [results] = await pool.query(
      `SELECT user_fname AS fname_U, user_lname AS lname_U, user_email AS email_U, user_phone AS phone_U, user_profile_image AS profile_image
       FROM users
       WHERE user_username = ?
       LIMIT 1`,
      [username]
    );

    if (!results.length) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(results[0]); // ส่ง profile_image ด้วย
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});



module.exports = router;
