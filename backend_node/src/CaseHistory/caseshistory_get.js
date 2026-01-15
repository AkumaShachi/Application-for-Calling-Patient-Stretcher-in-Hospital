const express = require('express');
const router = express.Router();
const pool = require('../Database');

const baseHistoryQuery = `
  SELECT
    rh.rhis_id AS history_id,
    rh.rhis_patient_id AS patient_id,
    rh.rhis_patient_type AS patient_type,
    rh.rhis_room_from AS room_from,
    rh.rhis_room_to AS room_to,
    rh.str_type_id,
    st.str_type_name AS stretcher_type,
    rh.rhis_status AS status,
    rh.rhis_created_at AS created_at,
    rh.rhis_completed_at AS completed_at,
    rh.rhis_notes AS notes,
    req.user_username AS requested_by_username,
    req.user_fname AS requested_by_fname,
    req.user_lname AS requested_by_lname,
    porter.user_username AS assigned_porter_username,
    porter.user_fname AS assigned_porter_fname,
    porter.user_lname AS assigned_porter_lname,
    eq.equipments
  FROM recordhistory rh
  LEFT JOIN users req ON rh.rhis_requested_by = req.user_num
  LEFT JOIN users porter ON rh.rhis_assigned_porter = porter.user_num
  LEFT JOIN stretchertypes st ON rh.str_type_id = st.str_type_id
  LEFT JOIN (
    SELECT
      re.rhis__id AS rhis_id,
      GROUP_CONCAT(DISTINCT e.eqpt_name ORDER BY e.eqpt_name SEPARATOR ', ') AS equipments
    FROM recordequipments re
    LEFT JOIN equipments e ON re.eqpt_id = e.eqpt_id
    GROUP BY re.rhis__id
  ) eq ON eq.rhis_id = rh.rhis_id
`;

const buildHistoryQuery = (whereClause = '') => `${baseHistoryQuery} ${whereClause} ORDER BY rh.rhis_created_at DESC`;

router.get('/cases/history', async (req, res) => {
  try {
    const [rows] = await pool.query(buildHistoryQuery());
    res.json(rows);
  } catch (error) {
    console.error('Error fetching case history:', error);
    res.status(500).json({ message: 'Failed to fetch case history' });
  }
});

router.get('/cases/history/:historyId', async (req, res) => {
  const historyId = Number(req.params.historyId);

  if (!Number.isInteger(historyId) || historyId <= 0) {
    return res.status(400).json({ message: 'Invalid history id' });
  }

  try {
    const [rows] = await pool.query(
      buildHistoryQuery('WHERE rh.rhis_id = ?'),
      [historyId]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'History record not found' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('Error fetching case history by id:', error);
    res.status(500).json({ message: 'Failed to fetch case history' });
  }
});

module.exports = router;
