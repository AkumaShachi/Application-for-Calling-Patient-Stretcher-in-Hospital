const express = require('express');
const router = express.Router();
const pool = require('./Database'); // mysql2/promise

// ดึงเคสทั้งหมด
router.get('/cases/nurse/all', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT c.case_id, 
              c.case_patient_id AS patient_id, 
              c.case_patient_type AS patient_type, 
              c.case_room_from AS room_from, 
              c.case_room_to AS room_to,
              c.str_type_id,
              st.str_type_name AS stretcher_type, 
              c.case_status AS status, 
              c.case_created_at AS created_at,
              GROUP_CONCAT(e.eqpt_name SEPARATOR ', ') AS equipment,
              GROUP_CONCAT(e.eqpt_id SEPARATOR ',') AS equipment_ids,
              u.user_fname AS fname_U, 
              u.user_lname AS lname_U
       FROM cases c
       LEFT JOIN users u ON c.case_requested_by = u.user_num
       LEFT JOIN stretchertypes st ON c.str_type_id = st.str_type_id
       LEFT JOIN caseequipments ce ON c.case_id = ce.case_id
       LEFT JOIN equipments e ON ce.eqpt_id = e.eqpt_id
       GROUP BY c.case_id
       ORDER BY c.case_created_at DESC`
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});

// ดึงเคสของ nurse โดย username (เฉพาะที่ยังไม่เสร็จ)
router.get('/cases/nurse/:username', async (req, res) => {
  try {
    const username = req.params.username;
    const [userRows] = await pool.query(
      'SELECT user_num FROM users WHERE user_username = ?',
      [username]
    );

    if (userRows.length === 0) return res.status(404).json({ message: 'User not found' });
    const userId = userRows[0].user_num;

    const [rows] = await pool.query(
      `SELECT c.case_id, 
              c.case_patient_id AS patient_id, 
              c.case_patient_type AS patient_type, 
              c.case_room_from AS room_from, 
              c.case_room_to AS room_to,
              st.str_type_name AS stretcher_type, 
              c.case_status AS status, 
              c.case_created_at AS created_at,
              GROUP_CONCAT(e.eqpt_name SEPARATOR ', ') AS equipment,
              u.user_fname AS fname_U, 
              u.user_lname AS lname_U
       FROM cases c
       LEFT JOIN users u ON c.case_requested_by = u.user_num
       LEFT JOIN stretchertypes st ON c.str_type_id = st.str_type_id
       LEFT JOIN caseequipments ce ON c.case_id = ce.case_id
       LEFT JOIN equipments e ON ce.eqpt_id = e.eqpt_id
       WHERE c.case_requested_by = ?
       GROUP BY c.case_id
       ORDER BY c.case_created_at DESC`,
      [userId]
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});

// ดึงเคสทั้งหมดของ nurse (รวมที่เสร็จแล้วจาก recordhistory)
router.get('/cases/nurse/:username/history', async (req, res) => {
  try {
    const username = req.params.username;
    const [userRows] = await pool.query(
      'SELECT user_num FROM users WHERE user_username = ?',
      [username]
    );

    if (userRows.length === 0) return res.status(404).json({ message: 'User not found' });
    const userId = userRows[0].user_num;

    // ดึงเคสปัจจุบัน
    const [currentCases] = await pool.query(
      `SELECT c.case_id, 
              c.case_patient_id AS patient_id, 
              c.case_patient_type AS patient_type, 
              c.case_room_from AS room_from, 
              c.case_room_to AS room_to,
              st.str_type_name AS stretcher_type, 
              c.case_status AS status, 
              c.case_created_at AS created_at,
              NULL AS completed_at,
              GROUP_CONCAT(e.eqpt_name SEPARATOR ', ') AS equipment,
              u.user_fname AS fname_U, 
              u.user_lname AS lname_U
       FROM cases c
       LEFT JOIN users u ON c.case_requested_by = u.user_num
       LEFT JOIN stretchertypes st ON c.str_type_id = st.str_type_id
       LEFT JOIN caseequipments ce ON c.case_id = ce.case_id
       LEFT JOIN equipments e ON ce.eqpt_id = e.eqpt_id
       WHERE c.case_requested_by = ?
       GROUP BY c.case_id`,
      [userId]
    );

    // ดึงเคสที่เสร็จแล้วจาก recordhistory
    const [completedCases] = await pool.query(
      `SELECT r.rhis_id AS case_id, 
              r.rhis_patient_id AS patient_id, 
              r.rhis_patient_type AS patient_type, 
              r.rhis_room_from AS room_from, 
              r.rhis_room_to AS room_to,
              st.str_type_name AS stretcher_type, 
              'completed' AS status, 
              r.rhis_created_at AS created_at,
              r.rhis_completed_at AS completed_at,
              GROUP_CONCAT(e.eqpt_name SEPARATOR ', ') AS equipment,
              u.user_fname AS fname_U, 
              u.user_lname AS lname_U
       FROM recordhistory r
       LEFT JOIN users u ON r.rhis_requested_by = u.user_num
       LEFT JOIN stretchertypes st ON r.str_type_id = st.str_type_id
       LEFT JOIN recordequipments re ON r.rhis_id = re.rhis__id
       LEFT JOIN equipments e ON re.eqpt_id = e.eqpt_id
       WHERE r.rhis_requested_by = ?
       GROUP BY r.rhis_id`,
      [userId]
    );

    // รวมและเรียงลำดับตามเวลา
    const allCases = [...currentCases, ...completedCases];
    allCases.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    res.json(allCases);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});

//=====================================================================================================================================================================

router.get('/cases/porter/all', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT c.case_id, 
              c.case_patient_id AS patient_id, 
              c.case_patient_type AS patient_type, 
              c.case_room_from AS room_from, 
              c.case_room_to AS room_to,
              st.str_type_name AS stretcher_type, 
              c.case_status AS status, 
              c.case_created_at AS created_at,
              u.user_fname AS fname_U, 
              u.user_lname AS lname_U
       FROM cases c
       LEFT JOIN users u ON c.case_requested_by = u.user_num
       LEFT JOIN stretchertypes st ON c.str_type_id = st.str_type_id
       ORDER BY c.case_created_at DESC`
    );

    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});

// ดึงเคสของ porter ตาม username (assigned_porter)
router.get('/cases/porter/:username', async (req, res) => {
  const { username } = req.params;

  try {
    // หา user_num ของ porter
    const [userRows] = await pool.query(
      'SELECT user_num FROM users WHERE user_username = ?',
      [username]
    );

    if (userRows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }
    const user_num = userRows[0].user_num;

    // ดึงเคสทั้งหมดของ porter พร้อมข้อมูลครบถ้วน
    const [cases] = await pool.query(
      `SELECT 
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
          u_requester.user_username AS requested_by_username,
          u_requester.user_fname AS requested_by_fname,
          u_requester.user_lname AS requested_by_lname,
          u_porter.user_username AS assigned_porter_username,
          u_porter.user_fname AS assigned_porter_fname,
          u_porter.user_lname AS assigned_porter_lname,
          GROUP_CONCAT(e.eqpt_name SEPARATOR ', ') AS equipments
       FROM cases c
       LEFT JOIN users u_requester ON c.case_requested_by = u_requester.user_num
       LEFT JOIN users u_porter ON c.case_assigned_porter = u_porter.user_num
       LEFT JOIN stretchertypes st ON c.str_type_id = st.str_type_id
       LEFT JOIN caseequipments ce ON c.case_id = ce.case_id
       LEFT JOIN equipments e ON ce.eqpt_id = e.eqpt_id
       WHERE c.case_assigned_porter = ? OR c.case_status = 'pending'
       GROUP BY c.case_id
       ORDER BY c.case_created_at DESC`,
      [user_num]
    );

    res.json(cases);

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch cases', error: err.message });
  }
});





// =====================
// GET /cases/admin/all
// ดึงเคสทั้งหมดสำหรับ Admin (รวมเคสที่เสร็จจาก recordhistory)
// =====================
router.get('/cases/admin/all', async (req, res) => {
  try {
    // ดึงเคสปัจจุบันจาก cases table
    const [currentCases] = await pool.query(
      `SELECT c.case_id, 
              c.case_patient_id AS patient_id, 
              c.case_patient_type AS patient_type, 
              c.case_room_from, 
              c.case_room_to,
              st.str_type_id,
              st.str_type_name, 
              c.case_status, 
              c.case_created_at,
              c.case_completed_at,
              c.case_notes,
              u_requester.user_username AS requested_by_username,
              u_requester.user_fname AS fname_U, 
              u_requester.user_lname AS lname_U,
              u_porter.user_username AS assigned_porter_username,
              u_porter.user_fname AS assigned_porter_fname,
              u_porter.user_lname AS assigned_porter_lname,
              GROUP_CONCAT(e.eqpt_name SEPARATOR ', ') AS equipment,
              GROUP_CONCAT(e.eqpt_id SEPARATOR ',') AS equipment_ids,
              'active' AS source
       FROM cases c
       LEFT JOIN users u_requester ON c.case_requested_by = u_requester.user_num
       LEFT JOIN users u_porter ON c.case_assigned_porter = u_porter.user_num
       LEFT JOIN stretchertypes st ON c.str_type_id = st.str_type_id
       LEFT JOIN caseequipments ce ON c.case_id = ce.case_id
       LEFT JOIN equipments e ON ce.eqpt_id = e.eqpt_id
       GROUP BY c.case_id
       ORDER BY c.case_created_at DESC`
    );

    // ดึงเคสที่เสร็จแล้วจาก recordhistory
    const [completedCases] = await pool.query(
      `SELECT 
              r.rhis_id AS case_id,
              r.rhis_patient_id AS patient_id, 
              r.rhis_patient_type AS patient_type, 
              r.rhis_room_from AS case_room_from, 
              r.rhis_room_to AS case_room_to,
              r.str_type_id,
              st.str_type_name, 
              'completed' AS case_status, 
              r.rhis_created_at AS case_created_at,
              r.rhis_completed_at AS case_completed_at,
              NULL AS case_notes,
              u_requester.user_username AS requested_by_username,
              u_requester.user_fname AS fname_U, 
              u_requester.user_lname AS lname_U,
              u_porter.user_username AS assigned_porter_username,
              u_porter.user_fname AS assigned_porter_fname,
              u_porter.user_lname AS assigned_porter_lname,
              GROUP_CONCAT(e.eqpt_name SEPARATOR ', ') AS equipment,
              NULL AS equipment_ids,
              'history' AS source
       FROM recordhistory r
       LEFT JOIN users u_requester ON r.rhis_requested_by = u_requester.user_num
       LEFT JOIN users u_porter ON r.rhis_assigned_porter = u_porter.user_num
       LEFT JOIN stretchertypes st ON r.str_type_id = st.str_type_id
       LEFT JOIN recordequipments re ON r.rhis_id = re.rhis__id
       LEFT JOIN equipments e ON re.eqpt_id = e.eqpt_id
       GROUP BY r.rhis_id
       ORDER BY r.rhis_completed_at DESC`
    );

    // รวมทั้งสอง arrays และเรียงตามเวลา
    const allCases = [...currentCases, ...completedCases];
    
    // เรียงตาม created_at ล่าสุดก่อน
    allCases.sort((a, b) => {
      const dateA = new Date(a.case_created_at || 0);
      const dateB = new Date(b.case_created_at || 0);
      return dateB - dateA;
    });

    res.json(allCases);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch admin cases', error: err.message });
  }
});


module.exports = router;
