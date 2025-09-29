const express = require('express');
const router = express.Router();
const pool = require('../Database');

const buildProfileImageUrl = (rawPath) => {
  if (!rawPath) {
    return null;
  }

  const baseUrl = process.env.BASE_URL ? process.env.BASE_URL.replace(/\/$/, '') : '';
  return baseUrl ? `${baseUrl}${rawPath}` : rawPath;
};

const mapUserRow = (row) => ({
  user_id: row.user_id,
  user_fname: row.user_fname,
  user_lname: row.user_lname,
  user_phone: row.user_phone,
  user_email: row.user_email,
  user_profile_image: buildProfileImageUrl(row.user_profile_image),
  role_id: row.role_id,
  role_name: row.role_name,
});

router.get('/users', async (_req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT u.user_id,
              u.user_fname,
              u.user_lname,
              u.user_phone,
              u.user_email,
              u.user_profile_image,
              u.role_id,
              r.role_name
         FROM users u
         LEFT JOIN roles r ON r.role_id = u.role_id
        ORDER BY u.user_fname, u.user_lname`
    );

    res.json(rows.map(mapUserRow));
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Failed to fetch users' });
  }
});

module.exports = router;