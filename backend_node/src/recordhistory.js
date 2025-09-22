const express = require('express');
const router = express.Router();
const pool = require('./Database');

router.get('/recordHistory', async (req, res) => {
  const { username } = req.query;
  if (!username) return res.status(400).json({ message: 'username is required' });

  try {
    // หา num_U ของ porter
    const [userRows] = await pool.query('SELECT num_U FROM Users WHERE username = ?', [username]);
    if (userRows.length === 0) return res.status(404).json({ message: 'User not found' });
    const porterNumU = userRows[0].num_U;

    // ดึงเคสพร้อมข้อมูลอุปกรณ์ + JOIN ชื่อผู้เรียกและผู้รับผิดชอบ + ชื่อเปล
    const [cases] = await pool.query(`
  SELECT 
    r.*,
    s.equipment_name,
    st.type_name AS stretcher_type_name,
    up.fname_U AS assigned_porter_fname,
    up.lname_U AS assigned_porter_lname,
    ur.fname_U AS requested_by_fname,
    ur.lname_U AS requested_by_lname
  FROM RecordHistory r
  LEFT JOIN RecordEquipments re ON r.case_id = re.case_id
  LEFT JOIN Equipments s ON re.equipment_id = s.id
  LEFT JOIN StretcherTypes st ON r.stretcher_type_id = st.id
  LEFT JOIN Users up ON r.assigned_porter = up.num_U
  LEFT JOIN Users ur ON r.requested_by = ur.num_U
  WHERE r.assigned_porter = ?
`, [porterNumU]);


    // จัด group ให้เคสเดียวมีหลายอุปกรณ์
    const groupedCases = cases.reduce((acc, row) => {
      let existing = acc.find(c => c.case_id === row.case_id);
      if (existing) {
        if (row.equipment_name) existing.equipments.push(row.equipment_name);
      } else {
        acc.push({
          case_id: row.case_id,
          patient_id: row.patient_id,
          patient_type: row.patient_type,
          room_from: row.room_from,
          room_to: row.room_to,
          stretcher_type_id: row.stretcher_type_id,
          stretcher_type: row.stretcher_type_name ?? '-', // <-- เปลี่ยนตรงนี้
          status: row.status,
          requested_by: row.requested_by,
          requested_by_fname: row.requested_by_fname ?? '-',
          requested_by_lname: row.requested_by_lname ?? '-',
          assigned_porter: row.assigned_porter,
          assigned_porter_fname: row.assigned_porter_fname ?? '-',
          assigned_porter_lname: row.assigned_porter_lname ?? '-',
          created_at: row.created_at,
          completed_at: row.completed_at,
          notes: row.notes,
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
