const express = require('express');
const router = express.Router();
const pool = require('./Database'); // MySQL pool

// =====================
// ดึงข้อมูลประเภทเปล
// =====================

router.get('/stretcher_types', (req, res) => {
  pool.query('SELECT * FROM StretcherTypes', (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(results);
  });
});

module.exports = router;