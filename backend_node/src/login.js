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
       JOIN roles r ON u.role_id = r.id_R 
       WHERE u.username = ?`,
      [username]
    );

    if (!rows.length) {
      return res.status(401).json({ status: 'error', message: 'Invalid username or password' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash);

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
      'SELECT fname_U, lname_U FROM Users WHERE username = ? LIMIT 1',
      [username]
    );

    if (!results.length) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(results[0]); // { fname_U: '...', lname_U: '...' }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
