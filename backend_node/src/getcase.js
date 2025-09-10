const express = require('express');
const router = express.Router();
const pool = require('./Database'); // mysql2/promise

// ดึงเคสทั้งหมด
router.get('/cases/nurse/all', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT c.case_id, c.patient_id, c.patient_type, c.room_from, c.room_to,
       st.type_name AS stretcher_type, c.status, c.created_at,
       GROUP_CONCAT(e.equipment_name SEPARATOR ', ') AS equipment,
       u.fname_U, u.lname_U
FROM Cases c
       LEFT JOIN Users u ON c.requested_by = u.num_U
       LEFT JOIN StretcherTypes st ON c.stretcher_type_id = st.id
       LEFT JOIN CaseEquipments ce ON c.case_id = ce.case_id
       LEFT JOIN Equipments e ON ce.equipment_id = e.id
       GROUP BY c.case_id
       ORDER BY c.created_at DESC`
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});

// ดึงเคสของ nurse โดย username
router.get('/cases/nurse/:username', async (req, res) => {
  try {
    const username = req.params.username;
    const [userRows] = await pool.query(
      'SELECT num_U FROM Users WHERE username = ?',
      [username]
    );

    if (userRows.length === 0) return res.status(404).json({ message: 'User not found' });
    const userId = userRows[0].num_U;

    const [rows] = await pool.query(
      `SELECT c.case_id, c.patient_id, c.patient_type, c.room_from, c.room_to,
              st.type_name AS stretcher_type, c.status, c.created_at,
              GROUP_CONCAT(e.equipment_name SEPARATOR ', ') AS equipment,
              u.fname_U, u.lname_U
       FROM Cases c
       LEFT JOIN Users u ON c.requested_by = u.num_U
       LEFT JOIN StretcherTypes st ON c.stretcher_type_id = st.id
       LEFT JOIN CaseEquipments ce ON c.case_id = ce.case_id
       LEFT JOIN Equipments e ON ce.equipment_id = e.id
       WHERE c.requested_by = ?
       GROUP BY c.case_id
       ORDER BY c.created_at DESC`,
      [userId]
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});

//=====================================================================================================================================================================

router.get('/cases/porter/all', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT c.*, u.fname_U, u.lname_U
       FROM Cases c
       LEFT JOIN Users u ON c.requested_by = u.num_U
       ORDER BY c.created_at DESC`
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});

// ดึงเคสของ porter ตาม username (assigned_porter)
// ดึงเคสของ porter ตาม username (assigned_porter)
router.get('/cases/porter/:username', async (req, res) => {
  const { username } = req.params;

  try {
    // หา num_U ของ porter
    const [userRows] = await pool.query(
      'SELECT num_U FROM Users WHERE username = ?',
      [username]
    );

    if (userRows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    const num_U = userRows[0].num_U;

    // ดึงเคสทั้งหมดของ porter พร้อมข้อมูลครบถ้วน
    const [cases] = await pool.query(
      `SELECT 
          c.case_id,
          c.patient_id,
          c.patient_type,
          c.room_from,
          c.room_to,
          st.type_name AS stretcher_type,
          c.status,
          c.created_at,
          c.completed_at,
          c.notes,
          u_requester.username AS requested_by_username,
          u_requester.fname_U AS requested_by_fname,
          u_requester.lname_U AS requested_by_lname,
          u_porter.username AS assigned_porter_username,
          u_porter.fname_U AS assigned_porter_fname,
          u_porter.lname_U AS assigned_porter_lname,
          GROUP_CONCAT(e.equipment_name SEPARATOR ', ') AS equipments
       FROM Cases c
       LEFT JOIN Users u_requester ON c.requested_by = u_requester.num_U
       LEFT JOIN Users u_porter ON c.assigned_porter = u_porter.num_U
       LEFT JOIN StretcherTypes st ON c.stretcher_type_id = st.id
       LEFT JOIN CaseEquipments ce ON c.case_id = ce.case_id
       LEFT JOIN Equipments e ON ce.equipment_id = e.id
       WHERE c.assigned_porter = ? OR c.status = 'pending'
       GROUP BY c.case_id
       ORDER BY c.created_at DESC`,
      [num_U]
    );

    res.json(cases);

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});




module.exports = router;
