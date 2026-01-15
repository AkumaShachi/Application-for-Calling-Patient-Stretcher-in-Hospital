const express = require('express');
const router = express.Router();
const pool = require('../Database');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

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

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads'),
  filename: (req, file, cb) => {
    const username = normalizeString(req.params.username) || 'user';
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${username}_${Date.now()}${ext}`);
  }
});

const upload = multer({ storage });

const removeFileIfExists = async (filePath) => {
  if (!filePath) {
    return;
  }

  try {
    await fs.promises.unlink(filePath);
  } catch (error) {
    if (error.code !== 'ENOENT') {
      console.warn('Could not remove file:', filePath, error.message);
    }
  }
};

router.put('/profile/:username', upload.single('profile_image'), async (req, res) => {
  const username = normalizeString(req.params.username);

  if (!username) {
    await removeFileIfExists(req.file && path.join('uploads', req.file.filename));
    return res.status(400).json({ message: 'Username is required' });
  }

  const fname = normalizeString(req.body.fname);
  const lname = normalizeString(req.body.lname);
  const email = normalizeString(req.body.email);
  const phone = normalizeString(req.body.phone);

  if (!fname || !lname || !email || !phone) {
    await removeFileIfExists(req.file && path.join('uploads', req.file.filename));
    return res.status(400).json({ message: 'fname, lname, email, and phone are required' });
  }

  const newProfileImagePath = req.file ? `/uploads/${req.file.filename}` : null;

  try {
    const params = [fname, lname, email, phone];
    let sql = `UPDATE users SET user_fname = ?, user_lname = ?, user_email = ?, user_phone = ?`;

    if (newProfileImagePath) {
      sql += ', user_profile_image = ?';
      params.push(newProfileImagePath);
    }

    sql += ' WHERE user_username = ?';
    params.push(username);

    const [result] = await pool.query(sql, params);

    if (result.affectedRows === 0) {
      await removeFileIfExists(req.file && path.join('uploads', req.file.filename));
      return res.status(404).json({ message: 'User not found' });
    }

    const [rows] = await pool.query(
      `SELECT user_fname, user_lname, user_email, user_phone, user_profile_image
         FROM users
        WHERE user_username = ?
        LIMIT 1`,
      [username]
    );

    res.json({ message: 'Profile updated', profile: buildProfileResponse(rows[0]) });
  } catch (error) {
    await removeFileIfExists(req.file && path.join('uploads', req.file.filename));

    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Email already in use' });
    }

    console.error('Error updating profile:', error);
    res.status(500).json({ message: 'Failed to update profile' });
  }
});

module.exports = router;
