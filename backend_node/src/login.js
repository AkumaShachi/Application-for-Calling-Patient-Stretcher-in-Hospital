const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('./Database');

router.post('/login', (req, res) => {
  const { username, password } = req.body;

  pool.query(
    `SELECT u.*, r.role_name FROM users u JOIN roles r ON u.role_id = r.id_R WHERE u.username = ?`,
    [username],
    (err, rows) => {
      if (err) return res.status(500).json({ status: 'error', message: 'Database error' });
      if (!rows.length) return res.status(401).json({ status: 'error', message: 'Invalid username or password' });

      bcrypt.compare(password, rows[0].password_hash, (err, match) => {
        if (err || !match) return res.status(401).json({ status: 'error', message: 'Invalid username or password' });
        res.json({ status: 'success', role: rows[0].role_name });
      });
    }
  );
});

module.exports = router;
