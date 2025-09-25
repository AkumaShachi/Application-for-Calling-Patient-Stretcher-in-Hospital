const express = require('express');
const router = express.Router();
const pool = require('../Database');

router.post('/equipments', async (req, res) => {
  const { name, quantity } = req.body;
  const trimmedName = typeof name === 'string' ? name.trim() : '';
  const parsedQuantity = quantity === undefined || quantity === null ? 0 : Number(quantity);

  if (!trimmedName) {
    return res.status(400).json({ message: 'Equipment name is required' });
  }

  if (!Number.isFinite(parsedQuantity) || parsedQuantity < 0) {
    return res.status(400).json({ message: 'Quantity must be a non-negative number' });
  }

  try {
    const [insertResult] = await pool.query(
      'INSERT INTO equipments (eqpt_name, eqpt_quantity) VALUES (?, ?)',
      [trimmedName, Math.floor(parsedQuantity)]
    );

    const [rows] = await pool.query(
      'SELECT eqpt_id, eqpt_name, eqpt_quantity FROM equipments WHERE eqpt_id = ?',
      [insertResult.insertId]
    );

    res.status(201).json({ message: 'Equipment added', equipment: rows[0] });
  } catch (error) {
    console.error('Error adding equipment:', error);
    res.status(500).json({ message: 'Failed to add equipment', error: error.message });
  }
});

module.exports = router;
