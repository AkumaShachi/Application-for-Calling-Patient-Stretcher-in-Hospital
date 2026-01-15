const express = require('express');
const router = express.Router();
const pool = require('./Database');

router.get('/recordHistory', async (req, res) => {
  const { username } = req.query;
  if (!username) return res.status(400).json({ message: 'username is required' });

  try {
    // หา user_num ของ porter
    const [userRows] = await pool.query('SELECT user_num FROM users WHERE user_username = ?', [username]);
    if (userRows.length === 0) return res.status(404).json({ message: 'User not found' });
    const porterNumU = userRows[0].user_num;

    // ดึงเคสพร้อมข้อมูลอุปกรณ์ + JOIN ชื่อผู้เรียกและผู้รับผิดชอบ + ชื่อเปล
    const [cases] = await pool.query(`
  SELECT 
    r.rhis_id AS case_id,
    r.rhis_patient_id AS case_patient_id,
    r.rhis_patient_type AS case_patient_type,
    r.rhis_room_from AS case_room_from,
    r.rhis_room_to AS case_room_to,
    r.str_type_id,
    'completed' AS case_status,
    r.rhis_requested_by AS case_requested_by,
    r.rhis_assigned_porter AS case_assigned_porter,
    r.rhis_created_at AS case_created_at,
    r.rhis_completed_at AS case_completed_at,
    r.rhis_notes AS case_notes,
    'completed' AS status_check,
    s.eqpt_name AS equipment_name,
    st.str_type_name AS stretcher_type_name,
    up.user_fname AS assigned_porter_fname,
    up.user_lname AS assigned_porter_lname,
    ur.user_fname AS requested_by_fname,
    ur.user_lname AS requested_by_lname
  FROM recordhistory r
  LEFT JOIN recordequipments re ON r.rhis_id = re.rhis__id
  LEFT JOIN equipments s ON re.eqpt_id = s.eqpt_id
  LEFT JOIN stretchertypes st ON r.str_type_id = st.str_type_id
  LEFT JOIN users up ON r.rhis_assigned_porter = up.user_num
  LEFT JOIN users ur ON r.rhis_requested_by = ur.user_num
  WHERE r.rhis_assigned_porter = ?
`, [porterNumU]);


    // จัด group ให้เคสเดียวมีหลายอุปกรณ์
    const groupedCases = cases.reduce((acc, row) => {
      let existing = acc.find(c => c.case_id === row.case_id);
      if (existing) {
        if (row.equipment_name) existing.equipments.push(row.equipment_name);
      } else {
        acc.push({
          case_id: row.case_id,
          patient_id: row.case_patient_id,
          patient_type: row.case_patient_type,
          room_from: row.case_room_from,
          room_to: row.case_room_to,
          stretcher_type_id: row.str_type_id,
          stretcher_type: row.stretcher_type_name ?? '-',
          status: 'completed',
          requested_by: row.case_requested_by,
          requested_by_fname: row.requested_by_fname ?? '-',
          requested_by_lname: row.requested_by_lname ?? '-',
          assigned_porter: row.case_assigned_porter,
          assigned_porter_fname: row.assigned_porter_fname ?? '-',
          assigned_porter_lname: row.assigned_porter_lname ?? '-',
          created_at: row.case_created_at,
          completed_at: row.case_completed_at,
          notes: row.case_notes,
          equipments: row.equipment_name ? [row.equipment_name] : []
        });
      }
      return acc;
    }, []);

    res.json(groupedCases);

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to fetch completed cases', error: err.message });
  }
});

module.exports = router;
