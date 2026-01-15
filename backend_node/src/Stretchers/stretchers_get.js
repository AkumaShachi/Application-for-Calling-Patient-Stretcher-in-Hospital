const express = require('express');
const router = express.Router();
const pool = require('../Database');

router.get('/stretchers', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT str_type_id, str_type_name, str_quantity FROM stretchertypes ORDER BY str_type_name'
    );
    res.json(rows);
  } catch (error) {
    console.error('Error fetching stretcher types:', error);
    res.status(500).json({ message: 'Failed to fetch stretcher types', error: error.message });
  }
});

module.exports = router;
