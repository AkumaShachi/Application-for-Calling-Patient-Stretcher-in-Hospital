const express = require('express');
const router = express.Router();
const pool = require('../Database');

router.post('/stretchers', async (req, res) => {
  const { name, quantity } = req.body;
  const trimmedName = typeof name === 'string' ? name.trim() : '';
  const parsedQuantity = quantity === undefined || quantity === null ? 0 : Number(quantity);

  if (!trimmedName) {
    return res.status(400).json({ message: 'Stretcher type name is required' });
  }

  if (!Number.isFinite(parsedQuantity) || parsedQuantity < 0) {
    return res.status(400).json({ message: 'Quantity must be a non-negative number' });
  }

  try {
    const [insertResult] = await pool.query(
      'INSERT INTO stretchertypes (str_type_name, str_quantity) VALUES (?, ?)',
      [trimmedName, Math.floor(parsedQuantity)]
    );

    const [rows] = await pool.query(
      'SELECT str_type_id, str_type_name, str_quantity FROM stretchertypes WHERE str_type_id = ?',
      [insertResult.insertId]
    );

    res.status(201).json({ message: 'Stretcher type added', stretcher: rows[0] });
  } catch (error) {
    console.error('Error adding stretcher type:', error);
    res.status(500).json({ message: 'Failed to add stretcher type', error: error.message });
  }
});

module.exports = router;
