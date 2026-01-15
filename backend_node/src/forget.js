require('dotenv').config();
const express = require('express');
const router = express.Router();
const fetch = require('node-fetch');
const bcrypt = require('bcrypt');
const pool = require('./Database');

router.post('/send-email', async (req, res) => {
  const { user_email } = req.body;
  if (!user_email) return res.status(400).json({ success: false, error: 'Missing user_email' });

  try {
    const [users] = await pool.query('SELECT user_num FROM users WHERE user_email = ?', [user_email]);
    if (!users.length) return res.status(404).json({ success: false, error: 'User not found' });
    const user_id = users[0].user_num;

    const token = Math.floor(100000 + Math.random() * 900000).toString();
    const now = new Date();
    const expiry = new Date(now.getTime() + 30 * 60000);

    const hashedToken = await bcrypt.hash(token, 10);

    await pool.query('DELETE FROM passwordresets WHERE user_id = ?', [user_id]);
    await pool.query('INSERT INTO passwordresets (user_id, reset_token_hash, token_expiry) VALUES (?, ?, ?)',
      [user_id, hashedToken, expiry]
    );

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
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())} ${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}`;
}

module.exports = router;
