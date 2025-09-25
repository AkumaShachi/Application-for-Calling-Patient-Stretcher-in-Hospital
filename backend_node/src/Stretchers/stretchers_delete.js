const express = require('express');
const router = express.Router();
const pool = require('../Database');

router.delete('/stretchers/:id', async (req, res) => {
  const stretcherId = Number(req.params.id);

  if (!Number.isInteger(stretcherId) || stretcherId <= 0) {
    return res.status(400).json({ message: 'Invalid stretcher type id' });
  }

  try {
    const [result] = await pool.query(
      'DELETE FROM stretchertypes WHERE str_type_id = ?',
      [stretcherId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Stretcher type not found' });
    }

    res.json({ message: 'Stretcher type deleted', id: stretcherId });
  } catch (error) {
    if (error.code === 'ER_ROW_IS_REFERENCED_2' || error.errno === 1451) {
      return res.status(409).json({ message: 'Stretcher type is in use and cannot be deleted yet' });
    }
    console.error('Error deleting stretcher type:', error);
    res.status(500).json({ message: 'Failed to delete stretcher type', error: error.message });
  }
});

module.exports = router;
