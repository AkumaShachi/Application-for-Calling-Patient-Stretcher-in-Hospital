const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('./Database');

router.post('/registrant', async (req, res) => {
  const { id_U, fname_U, lname_U, phone_U, email_U, username, password, role_U } = req.body;

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    pool.query('SELECT id_R FROM roles WHERE role_name = ?', [role_U], (err, results) => {
      if (err) return res.status(500).json({ status: 'error', message: 'Role lookup error', error: err });
      if (results.length === 0) return res.status(400).json({ status: 'error', message: 'Invalid role name' });

      const role_id = results[0].id_R;
      const registrant = { id_U, fname_U, lname_U, phone_U, email_U, username, password_hash: hashedPassword, role_id };

      pool.query('INSERT INTO users SET ?', registrant, (err, rows) => {
        if (err) {
          console.error("Insert error:", err);
          return res.status(500).json({ status: 'error', message: 'Insert error', error: err });
        }

        res.status(201).json({ status: 'success', message: 'User registered', data: rows });
      });
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: 'Server error', error: err });
  }
});

module.exports = router;
