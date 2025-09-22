const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('./Database'); // MySQL pool

// POST /send-reset-pass
router.post('/send-reset-pass', async (req, res) => {
  const { email, token, new_password, confirm_password } = req.body;

  if (!email || !token || !new_password || !confirm_password) {
    return res.status(400).json({ success: false, error: 'กรุณากรอกข้อมูลครบถ้วน' });
  }
  if (new_password !== confirm_password) {
    return res.status(400).json({ success: false, error: 'รหัสผ่านไม่ตรงกัน' });
  }
  if (new_password.length < 8) {
    return res.status(400).json({ success: false, error: 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' });
  }

  try {
    // 1. หา user_id จาก email
    const [users] = await pool.promise().query(
      'SELECT num_U FROM users WHERE email_U = ?', 
      [email]
    );
    if (!users.length) return res.status(404).json({ success: false, error: 'User not found' });

    const user_id = users[0].num_U;

    // 2. หา token ล่าสุดของ user
    const [resets] = await pool.promise().query(
      'SELECT * FROM PasswordResets WHERE user_id = ? ORDER BY id_PR DESC LIMIT 1',
      [user_id]
    );
    if (!resets.length) return res.status(400).json({ success: false, error: 'Token ไม่ถูกต้อง' });

    const reset = resets[0];

    // 3. ตรวจสอบ token กับ hash
    const match = await bcrypt.compare(token, reset.reset_token_hash);
    if (!match) return res.status(400).json({ success: false, error: 'Token ไม่ถูกต้อง' });

    // 4. ตรวจสอบหมดอายุ
    if (new Date(reset.token_expiry) < new Date()) {
      await pool.promise().query('DELETE FROM PasswordResets WHERE id_PR = ?', [reset.id_PR]);
      return res.status(400).json({ success: false, error: 'Token หมดอายุ' });
    }

    // 5. hash password ใหม่
    const hashedPassword = await bcrypt.hash(new_password, 10);

    // 6. update users
    await pool.promise().query('UPDATE users SET password_hash = ? WHERE num_U = ?', [hashedPassword, user_id]);

    // 7. ลบ token หลังใช้งาน
    await pool.promise().query('DELETE FROM PasswordResets WHERE id_PR = ?', [reset.id_PR]);

    res.json({ success: true, message: 'รีเซ็ตรหัสผ่านสำเร็จ' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Server error' });
  }
});

module.exports = router;
