// routes/cases.js
const express = require('express');
const router = express.Router();
const pool = require('./Database'); // path ถูกต้อง

router.put('/cases/:caseId', async (req, res) => {
  const { caseId } = req.params;
  const { status, assignedPorter } = req.body;

  console.log("[PORTER CASE] Updating case:", caseId, "to status:", status, "assigned_porter:", assignedPorter);

  if (!['pending', 'in_progress', 'completed'].includes(status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  try {
    let porterNumU = null;

    // แปลง username → num_U
    if (assignedPorter) {
      const [rows] = await pool.query(
        'SELECT num_U FROM Users WHERE username = ?',
        [assignedPorter]
      );

      if (rows.length === 0) {
        return res.status(400).json({ message: `Porter '${assignedPorter}' not found` });
      }

      porterNumU = rows[0].num_U;
    }

    // 🔹 ถ้า completed → ย้ายไป RecordHistory + คืนอุปกรณ์
    if (status === 'completed') {
      console.log(`🔹 Moving case ${caseId} to RecordHistory`);

      // ดึงข้อมูลเคสปัจจุบัน
      const [caseRows] = await pool.query('SELECT * FROM Cases WHERE case_id = ?', [caseId]);
      if (caseRows.length === 0) {
        return res.status(404).json({ message: 'Case not found' });
      }
      const c = caseRows[0];

      // ดึงอุปกรณ์ที่ใช้จาก CaseEquipments
      const [equipRows] = await pool.query(
        'SELECT equipment_id FROM CaseEquipments WHERE case_id = ?',
        [caseId]
      );

      // คืนของให้ Equipments (เพิ่ม quantity ทีละ 1)
      for (const e of equipRows) {
        await pool.query(
          'UPDATE Equipments SET quantity = quantity + 1 WHERE id = ?',
          [e.equipment_id]
        );
      }

      // ย้ายเคสไป RecordHistory
      const [resultHistory] = await pool.query(
        `INSERT INTO RecordHistory
          (case_id, patient_id, patient_type, room_from, room_to, stretcher_type_id, status, requested_by, assigned_porter, created_at, completed_at, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)`,
        [
          c.case_id,
          c.patient_id,
          c.patient_type,
          c.room_from,
          c.room_to,
          c.stretcher_type_id,
          'completed',
          c.requested_by,
          porterNumU ?? c.assigned_porter,
          c.created_at,
          c.notes
        ]
      );
      console.log(`✅ Case ${caseId} inserted into RecordHistory`);

      // ใช้ case_id เดิมเป็น key ใน RecordHistory
      const recordHistoryCaseId = c.case_id;

      // ย้ายอุปกรณ์ไป RecordEquipments (อ้างอิง RecordHistory)
      for (const e of equipRows) {
        await pool.query(
          'INSERT INTO RecordEquipments (case_id, equipment_id) VALUES (?, ?)',
          [recordHistoryCaseId, e.equipment_id]
        );
      }

      // ลบเคสจาก Cases และ CaseEquipments
      await pool.query('DELETE FROM CaseEquipments WHERE case_id = ?', [caseId]);
      await pool.query('DELETE FROM Cases WHERE case_id = ?', [caseId]);
      console.log(`✅ Case ${caseId} deleted from Cases & CaseEquipments`);

      return res.json({ message: 'Case completed, moved to RecordHistory, and equipment returned' });
    }

    // 🔹 อัปเดต status สำหรับ pending / in_progress
    let query = 'UPDATE Cases SET status = ?';
    const params = [status];

    if (porterNumU !== null) {
      query += ', assigned_porter = ?';
      params.push(porterNumU);
    }

    query += ' WHERE case_id = ?';
    params.push(caseId);

    const [result] = await pool.query(query, params);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Case not found' });
    }

    console.log(`✅ Case ${caseId} updated to ${status}`);
    res.json({ message: 'Status updated successfully' });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to update status', error: err.message });
  }
});

module.exports = router;
