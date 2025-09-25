const express = require('express');
const router = express.Router();
const pool = require('../Database');

router.put('/stretchers/:id', async (req, res) => {
  const stretcherId = Number(req.params.id);
  const { name, quantity } = req.body;

  if (!Number.isInteger(stretcherId) || stretcherId <= 0) {
    return res.status(400).json({ message: 'Invalid stretcher type id' });
  }

  const updates = [];
  const params = [];

  if (name !== undefined) {
    const trimmedName = typeof name === 'string' ? name.trim() : '';
    if (!trimmedName) {
      return res.status(400).json({ message: 'Stretcher type name cannot be empty' });
    }
    updates.push('str_type_name = ?');
    params.push(trimmedName);
  }

  if (quantity !== undefined) {
    const parsedQuantity = Number(quantity);
    if (!Number.isFinite(parsedQuantity) || parsedQuantity < 0) {
      return res.status(400).json({ message: 'Quantity must be a non-negative number' });
    }
    updates.push('str_quantity = ?');
    params.push(Math.floor(parsedQuantity));
  }

  if (!updates.length) {
    return res.status(400).json({ message: 'No fields provided to update' });
  }

  try {
    const [result] = await pool.query(
      `UPDATE stretchertypes SET ${updates.join(', ')} WHERE str_type_id = ?`,
      [...params, stretcherId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Stretcher type not found' });
    }

    const [rows] = await pool.query(
      'SELECT str_type_id, str_type_name, str_quantity FROM stretchertypes WHERE str_type_id = ?',
      [stretcherId]
    );

    res.json({ message: 'Stretcher type updated', stretcher: rows[0] });
  } catch (error) {
    console.error('Error updating stretcher type:', error);
    res.status(500).json({ message: 'Failed to update stretcher type', error: error.message });
  }
});

module.exports = router;
