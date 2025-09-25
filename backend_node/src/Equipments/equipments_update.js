const express = require('express');
const router = express.Router();
const pool = require('../Database');

router.put('/equipments/:id', async (req, res) => {
  const eqptId = Number(req.params.id);
  const { name, quantity } = req.body;

  if (!Number.isInteger(eqptId) || eqptId <= 0) {
    return res.status(400).json({ message: 'Invalid equipment id' });
  }

  const updates = [];
  const params = [];

  if (name !== undefined) {
    const trimmedName = typeof name === 'string' ? name.trim() : '';
    if (!trimmedName) {
      return res.status(400).json({ message: 'Equipment name cannot be empty' });
    }
    updates.push('eqpt_name = ?');
    params.push(trimmedName);
  }

  if (quantity !== undefined) {
    const parsedQuantity = Number(quantity);
    if (!Number.isFinite(parsedQuantity) || parsedQuantity < 0) {
      return res.status(400).json({ message: 'Quantity must be a non-negative number' });
    }
    updates.push('eqpt_quantity = ?');
    params.push(Math.floor(parsedQuantity));
  }

  if (!updates.length) {
    return res.status(400).json({ message: 'No fields provided to update' });
  }

  try {
    const [result] = await pool.query(
      `UPDATE equipments SET ${updates.join(', ')} WHERE eqpt_id = ?`,
      [...params, eqptId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Equipment not found' });
    }

    const [rows] = await pool.query(
      'SELECT eqpt_id, eqpt_name, eqpt_quantity FROM equipments WHERE eqpt_id = ?',
      [eqptId]
    );

    res.json({ message: 'Equipment updated', equipment: rows[0] });
  } catch (error) {
    console.error('Error updating equipment:', error);
    res.status(500).json({ message: 'Failed to update equipment', error: error.message });
  }
});

module.exports = router;
