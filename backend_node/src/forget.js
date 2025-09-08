require('dotenv').config();
const express = require('express');
const router = express.Router();
const fetch = require('node-fetch'); // v2
const bcrypt = require('bcrypt');
const pool = require('./Database'); // MySQL pool

// POST /send-email
router.post('/send-email', async (req, res) => {
  const { user_email } = req.body;
  if (!user_email) return res.status(400).json({ success: false, error: 'Missing user_email' });

  try {
    // 1. หา user
    const [users] = await pool.promise().query(
      'SELECT num_U FROM users WHERE email_U = ?', 
      [user_email]
    );
    if (!users.length) return res.status(404).json({ success: false, error: 'User not found' });

    const user_id = users[0].num_U;

    // 2. สร้าง token + expiry
    const token = Math.floor(100000 + Math.random() * 900000).toString();
    const now = new Date();
    const expiry = new Date(now.getTime() + 30 * 60000); // 30 นาที

    // 2.1 hash token
    const hashedToken = await bcrypt.hash(token, 10);

    // 3. ลบ token เก่าออกก่อน
    await pool.promise().query('DELETE FROM PasswordResets WHERE user_id = ?', [user_id]);

    // 4. บันทึก token ใหม่
    await pool.promise().query(
      'INSERT INTO PasswordResets (user_id, reset_token_hash, token_expiry) VALUES (?, ?, ?)',
      [user_id, hashedToken, expiry]
    );

    // 5. ส่ง email ผ่าน EmailJS
    const response = await fetch('https://api.emailjs.com/api/v1.0/email/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        service_id: process.env.EMAILJS_SERVICE_ID,
        template_id: process.env.EMAILJS_TEMPLATE_ID,
        user_id: process.env.EMAILJS_USER_ID,
        accessToken: process.env.EMAILJS_ACCESS_TOKEN,
        template_params: {
          user_email,
          token_passcode: token,
          token_time_create: formatDateToCustom(now),
          token_delete_at: formatDateToCustom(expiry),
        },
      }),
    });

    const text = await response.text();
    if (!response.ok) throw new Error(text);

    res.json({ success: true, message: 'Email sent successfully' });
  } catch (err) {
    console.error('EmailJS error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

function formatDateToCustom(d) {
  const pad = (n) => n.toString().padStart(2, '0');
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())} ${pad(d.getDate())}/${pad(d.getMonth()+1)}/${d.getFullYear()}`;
}

module.exports = router;
