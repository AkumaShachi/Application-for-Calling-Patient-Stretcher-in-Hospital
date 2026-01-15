const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('./Database');

router.post('/login', async (req, res) => {
  const usernameRaw = typeof req.body.username === 'string' ? req.body.username.trim() : '';
  const password = req.body.password || '';

  if (!usernameRaw || typeof password !== 'string' || password === '') {
    return res.status(400).json({ status: 'error', message: 'Username and password are required' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT u.user_num,
              u.user_username,
              u.user_password_hash,
              u.user_fname,
              u.user_lname,
              u.user_email,
              u.user_phone,
              u.user_profile_image,
              r.role_name
         FROM users u
         JOIN roles r ON u.role_id = r.role_id
        WHERE u.user_username = ?
        LIMIT 1`,
      [usernameRaw]
    );

    if (!rows.length) {
      return res.status(401).json({ status: 'error', message: 'Invalid username or password' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.user_password_hash);

    if (!match) {
      return res.status(401).json({ status: 'error', message: 'Invalid username or password' });
    }

    res.json({
      status: 'success',
      role: user.role_name,
      user: {
        id: user.user_num,
        username: user.user_username,
        fname: user.user_fname,
        lname: user.user_lname,
        email: user.user_email,
        phone: user.user_phone,
        profile_image: user.user_profile_image,
        fname_U: user.user_fname,
        lname_U: user.user_lname,
        email_U: user.user_email,
        phone_U: user.user_phone
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ status: 'error', message: 'Server error' });
  }
});

router.get('/user/:user_username', async (req, res) => {
  const usernameRaw = req.params.user_username ?? req.params.username;
  const username = typeof usernameRaw === 'string' ? usernameRaw.trim() : '';

  if (!username) {
    return res.status(400).json({ error: 'Username is required' });
  }

  try {
    const [results] = await pool.query(
      `SELECT user_fname AS fname,
              user_lname AS lname,
              user_email AS email,
              user_phone AS phone,
              user_profile_image AS profile_image,
              user_fname AS fname_U,
              user_lname AS lname_U,
              user_email AS email_U,
              user_phone AS phone_U
         FROM users
        WHERE user_username = ?
        LIMIT 1`,
      [username]
    );

    if (!results.length) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(results[0]);
  } catch (err) {
    console.error('Fetch user error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
