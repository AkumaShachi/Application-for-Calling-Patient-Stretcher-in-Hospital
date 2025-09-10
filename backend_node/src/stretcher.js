const express = require('express');
const router = express.Router();
const pool = require('./Database'); // MySQL pool

// =====================
// ดึงข้อมูลประเภทเปล (GET)
// =====================
router.get('/stretcher', async (req, res) => {
  try {
    const [results] = await pool.query('SELECT * FROM StretcherTypes');
    res.json(results);
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});
// =====================
// เพิ่มหรือแก้ไขเปล (POST/PUT)
// =====================
// ตัวอย่างเพิ่มเปลใหม่
router.post('/add/stretcher', async (req, res) => {
  const { type_name, quantity } = req.body;
  if (!type_name || quantity == null) {
    return res.status(400).json({ error: 'Missing type_name or quantity' });
  }

  try {
    const [result] = await pool.query(
      'INSERT INTO StretcherTypes (type_name, quantity) VALUES (?, ?)',
      [type_name, quantity]
    );

    res.json({ success: true, message: 'Stretcher added', id: result.insertId });
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// ตัวอย่างแก้ไขจำนวนเปล
router.put('/stretcher/:id', async (req, res) => {
  const { id } = req.params;
  const { type_name, quantity } = req.body;

  try {
    await pool.query(
      'UPDATE StretcherTypes SET type_name = ?, quantity = ? WHERE id = ?',
      [type_name, quantity, id]
    );

    res.json({ success: true, message: 'Stretcher updated' });
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
