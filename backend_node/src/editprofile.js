// routes/user.js
const express = require('express');
const router = express.Router();
const pool = require('./Database'); // mysql2/promise
const multer = require('multer');
const path = require('path');

// ตั้งค่า storage สำหรับ multer
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/'); // โฟลเดอร์เก็บรูป
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    cb(null, `${req.params.username}_${Date.now()}${ext}`);
  }
});

const upload = multer({ storage });

// =====================
// GET /edituser/:username
// ดึงข้อมูลผู้ใช้สำหรับแก้ไข
// =====================
router.get('/edituser/:username', async (req, res) => {
  const { username } = req.params;

  try {
    const [results] = await pool.query(
      'SELECT user_fname AS fname_U, user_lname AS lname_U, user_email AS email_U, user_phone AS phone_U, user_profile_image AS profile_image FROM users WHERE user_username = ? LIMIT 1',
      [username]
    );

    if (!results.length) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = results[0];

    if (user.profile_image) {
      // ส่ง URL เต็ม
      user.profile_image = `http://192.168.1.4:4000${user.profile_image}`;
    }

    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// =====================
// PUT /user/:username
// อัปเดตข้อมูลผู้ใช้ + รูปภาพ
// =====================
router.put('/user/:username', upload.single('profile_image'), async (req, res) => {
  const { username } = req.params;
  const { fname_U, lname_U, email_U, phone_U } = req.body;

  if (!fname_U || !lname_U || !email_U || !phone_U) {
    return res.status(400).json({ error: 'Missing fields' });
  }

  let profile_image = null;
  if (req.file) {
    profile_image = `/uploads/${req.file.filename}`;
  }

  try {
    const [result] = await pool.query(
      `UPDATE users
       SET user_fname = ?, user_lname = ?, user_email = ?, user_phone = ?, user_profile_image = COALESCE(?, user_profile_image)
       WHERE user_username = ?`,
      [fname_U, lname_U, email_U, phone_U, profile_image, username]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const [updated] = await pool.query(
      'SELECT user_fname AS fname_U, user_lname AS lname_U, user_email AS email_U, user_phone AS phone_U, user_profile_image AS profile_image FROM users WHERE user_username = ? LIMIT 1',
      [username]
    );

    if (updated[0].profile_image) {
      updated[0].profile_image = `http://192.168.1.4:4000${updated[0].profile_image}`;
    }

    res.json({ message: 'Profile updated', user: updated[0] });
  } catch (err) {
    console.error(err);
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Email already in use' });
    }
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
