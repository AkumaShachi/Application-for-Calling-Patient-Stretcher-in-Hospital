const express = require('express');
const router = express.Router();
const pool = require('../Database');

const baseCaseQuery = `
  SELECT
    c.case_id,
    c.case_patient_id AS patient_id,
    c.case_patient_type AS patient_type,
    c.case_room_from AS room_from,
    c.case_room_to AS room_to,
    st.str_type_name AS stretcher_type,
    c.case_status AS status,
    c.case_created_at AS created_at,
    c.case_completed_at AS completed_at,
    c.case_notes AS notes,
    req.user_username AS requested_by_username,
    req.user_fname AS requested_by_fname,
    req.user_lname AS requested_by_lname,
    porter.user_username AS assigned_porter_username,
    porter.user_fname AS assigned_porter_fname,
    porter.user_lname AS assigned_porter_lname,
    eq.equipments
    FROM cases c
    LEFT JOIN users req ON c.case_requested_by = req.user_num
    LEFT JOIN users porter ON c.case_assigned_porter = porter.user_num
    LEFT JOIN stretchertypes st ON c.str_type_id = st.str_type_id
    LEFT JOIN (
    SELECT ce.case_id, GROUP_CONCAT(DISTINCT e.eqpt_name ORDER BY e.eqpt_name SEPARATOR ', ') AS equipments
    FROM caseequipments ce
    LEFT JOIN equipments e ON ce.eqpt_id = e.eqpt_id
    GROUP BY ce.case_id
  ) eq ON eq.case_id = c.case_id
`;

const buildCaseQuery = (whereClause = '') => `${baseCaseQuery} ${whereClause} ORDER BY c.case_created_at DESC`;

const findUserNumByUsername = async (username) => {
  const [rows] = await pool.query(
    'SELECT user_num FROM users WHERE user_username = ?',
    [username]
  );
  return rows[0]?.user_num ?? null;
};

router.get('/cases/nurse/all', async (req, res) => {
  try {
    const [rows] = await pool.query(buildCaseQuery());
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Failed to fetch cases', error: error.message });
  }
});

router.get('/cases/nurse/:username', async (req, res) => {
  try {
    const userNum = await findUserNumByUsername(req.params.username);
    if (!userNum) {
      return res.status(404).json({ message: 'User not found' });
    }

    const [rows] = await pool.query(
      buildCaseQuery('WHERE c.case_requested_by = ?'),
      [userNum]
    );
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Failed to fetch cases', error: error.message });
  }
});

router.get('/cases/porter/all', async (req, res) => {
  try {
    const [rows] = await pool.query(buildCaseQuery());
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Failed to fetch cases', error: error.message });
  }
});

router.get('/cases/porter/:username', async (req, res) => {
  try {
    const userNum = await findUserNumByUsername(req.params.username);
    if (!userNum) {
      return res.status(404).json({ message: 'User not found' });
    }

    const [rows] = await pool.query(
      buildCaseQuery('WHERE (c.case_assigned_porter = ? OR c.case_status = \'pending\')'),
      [userNum]
    );
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Failed to fetch cases', error: error.message });
  }
});

module.exports = router;
