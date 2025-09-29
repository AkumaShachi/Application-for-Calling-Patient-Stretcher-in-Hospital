// routes/cases.js
const express = require('express');
const router = express.Router();
const pool = require('../Database'); // mysql2/promise

// ✅ เช็คว่ามี patient_id อยู่แล้วใน DB หรือยัง
router.get('/cases/check/:patientId', async (req, res) => {
  const { patientId } = req.params;
  try {
    const [rows] = await pool.query(
      'SELECT COUNT(*) as count FROM cases WHERE case_patient_id = ?',
      [patientId]
    );

    if (rows[0].count > 0) {
      return res.json({ exists: true });
    } else {
      return res.json({ exists: false });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
