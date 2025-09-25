const express = require('express');
const router = express.Router();
const pool = require('../Database');

const normalizeString = (value) => (typeof value === 'string' ? value.trim() : value);

const buildProfileResponse = (row) => {
  const baseUrl = process.env.BASE_URL ? process.env.BASE_URL.replace(/\/$/, '') : '';
  const rawImagePath = row.user_profile_image || null;
  const profileImage = rawImagePath
    ? (baseUrl ? `${baseUrl}${rawImagePath}` : rawImagePath)
    : null;

  return {
    fname: row.user_fname,
    lname: row.user_lname,
    email: row.user_email,
    phone: row.user_phone,
    profile_image: profileImage
  };
};

router.get('/profile/:username', async (req, res) => {
  const username = normalizeString(req.params.username);

  if (!username) {
    return res.status(400).json({ message: 'Username is required' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT user_fname, user_lname, user_email, user_phone, user_profile_image
         FROM users
        WHERE user_username = ?
        LIMIT 1`,
      [username]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(buildProfileResponse(rows[0]));
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ message: 'Failed to fetch profile' });
  }
});

module.exports = router;
