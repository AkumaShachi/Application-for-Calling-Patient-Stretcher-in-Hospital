const express = require('express');
const router = express.Router();
const pool = require('../Database');

router.get('/equipments', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT eqpt_id, eqpt_name, eqpt_quantity FROM equipments ORDER BY eqpt_name'
    );
    res.json(rows);
  } catch (error) {
    console.error('Error fetching equipments:', error);
    res.status(500).json({ message: 'Failed to fetch equipments', error: error.message });
  }
});

module.exports = router;
