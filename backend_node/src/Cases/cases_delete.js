const express = require('express');
const router = express.Router();
const pool = require('../Database');

const isValidId = (value) => Number.isInteger(value) && value > 0;

router.delete('/cases/:caseId', async (req, res) => {
  const caseId = Number(req.params.caseId);

  if (!isValidId(caseId)) {
    return res.status(400).json({ message: 'Invalid case id' });
  }

  let connection;

  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [caseRows] = await connection.query(
      'SELECT case_id, str_type_id FROM cases WHERE case_id = ? FOR UPDATE',
      [caseId]
    );

    if (!caseRows.length) {
      await connection.rollback();
      return res.status(404).json({ message: 'Case not found' });
    }

    const caseRecord = caseRows[0];

    const [equipmentRows] = await connection.query(
      'SELECT eqpt_id FROM caseequipments WHERE case_id = ? FOR UPDATE',
      [caseId]
    );

    if (equipmentRows.length) {
      const equipmentCounts = new Map();

      for (const row of equipmentRows) {
        const current = equipmentCounts.get(row.eqpt_id) || 0;
        equipmentCounts.set(row.eqpt_id, current + 1);
      }

      for (const [equipmentId, quantity] of equipmentCounts.entries()) {
        await connection.query(
          'UPDATE equipments SET eqpt_quantity = eqpt_quantity + ? WHERE eqpt_id = ?',
          [quantity, equipmentId]
        );
      }

      await connection.query(
        'DELETE FROM caseequipments WHERE case_id = ?',
        [caseId]
      );
    }

    if (caseRecord.str_type_id !== null) {
      await connection.query(
        'UPDATE stretchertypes SET str_quantity = str_quantity + 1 WHERE str_type_id = ?',
        [caseRecord.str_type_id]
      );
    }

    await connection.query(
      'DELETE FROM cases WHERE case_id = ?',
      [caseId]
    );

    await connection.commit();

    res.json({ message: 'Case deleted' });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (rollbackError) {
        console.error('Rollback failed:', rollbackError);
      }
    }

    console.error('Error deleting case:', error);
    res.status(500).json({ message: 'Failed to delete case' });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

module.exports = router;
