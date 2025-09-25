const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('./Database');

router.post('/send-reset-pass', async (req, res) => {
  const emailRaw = typeof req.body.email === 'string' ? req.body.email.trim() : '';
  const tokenRaw = typeof req.body.token === 'string' ? req.body.token.trim() : '';
  const newPassword = typeof req.body.new_password === 'string' ? req.body.new_password : '';
  const confirmPassword = typeof req.body.confirm_password === 'string' ? req.body.confirm_password : '';

  if (!emailRaw || !tokenRaw || !newPassword || !confirmPassword) {
    return res.status(400).json({ success: false, error: 'กรุณากรอกข้อมูลครบถ้วน' });
  }

  if (newPassword !== confirmPassword) {
    return res.status(400).json({ success: false, error: 'รหัสผ่านไม่ตรงกัน' });
  }

  if (newPassword.length < 8) {
    return res.status(400).json({ success: false, error: 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' });
  }

  try {
    const [users] = await pool.query(
      'SELECT user_num FROM users WHERE user_email = ?',
      [emailRaw]
    );

    if (!users.length) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const userNum = users[0].user_num;

    const [resets] = await pool.query(
      'SELECT pr_id, pr_reset_token_hash, pr_token_expiry FROM passwordresets WHERE pr_user_id = ? ORDER BY pr_id DESC LIMIT 1',
      [userNum]
    );

    if (!resets.length) {
      return res.status(400).json({ success: false, error: 'Token ไม่ถูกต้อง' });
    }

    const reset = resets[0];

    const match = await bcrypt.compare(tokenRaw, reset.pr_reset_token_hash);
    if (!match) {
      return res.status(400).json({ success: false, error: 'Token ไม่ถูกต้อง' });
    }

    if (new Date(reset.pr_token_expiry) < new Date()) {
      await pool.query('DELETE FROM passwordresets WHERE pr_id = ?', [reset.pr_id]);
      return res.status(400).json({ success: false, error: 'Token หมดอายุ' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await pool.query('UPDATE users SET user_password_hash = ? WHERE user_num = ?', [hashedPassword, userNum]);
    await pool.query('DELETE FROM passwordresets WHERE pr_id = ?', [reset.pr_id]);

    res.json({ success: true, message: 'รีเซ็ตรหัสผ่านสำเร็จ' });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

module.exports = router;
