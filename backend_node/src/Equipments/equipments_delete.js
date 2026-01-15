const express = require('express');
const router = express.Router();
const pool = require('../Database');

router.delete('/equipments/:id', async (req, res) => {
  const eqptId = Number(req.params.id);

  if (!Number.isInteger(eqptId) || eqptId <= 0) {
    return res.status(400).json({ message: 'Invalid equipment id' });
  }

  try {
    const [result] = await pool.query(
      'DELETE FROM equipments WHERE eqpt_id = ?',
      [eqptId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Equipment not found' });
    }

    res.json({ message: 'Equipment deleted', id: eqptId });
  } catch (error) {
    if (error.code === 'ER_ROW_IS_REFERENCED_2' || error.errno === 1451) {
      return res.status(409).json({ message: 'Equipment is in use and cannot be deleted yet' });
    }
    console.error('Error deleting equipment:', error);
    res.status(500).json({ message: 'Failed to delete equipment', error: error.message });
  }
});

module.exports = router;
