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

    // แปลง username → user_num
    if (assignedPorter) {
      const [rows] = await pool.query(
        'SELECT user_num FROM users WHERE user_username = ?',
        [assignedPorter]
      );

      if (rows.length === 0) {
        return res.status(400).json({ message: `Porter '${assignedPorter}' not found` });
      }

      porterNumU = rows[0].user_num;
    }

    // 🔹 ถ้า completed → ย้ายไป RecordHistory + คืนอุปกรณ์
    if (status === 'completed') {
      const connection = await pool.getConnection();
      try {
        await connection.beginTransaction();
        
        console.log(`🔹 Moving case ${caseId} to RecordHistory`);

        // ดึงข้อมูลเคสปัจจุบัน (ใช้ connection)
        const [caseRows] = await connection.query('SELECT * FROM cases WHERE case_id = ? FOR UPDATE', [caseId]);
        if (caseRows.length === 0) {
          console.error(`❌ Case ${caseId} not found`);
          await connection.rollback();
          return res.status(404).json({ message: 'Case not found' });
        }
        const c = caseRows[0];

        // ดึงอุปกรณ์ที่ใช้จาก caseequipments
        const [equipRows] = await connection.query(
          'SELECT eqpt_id FROM caseequipments WHERE case_id = ?',
          [caseId]
        );

        // คืนของให้ equipments (เพิ่ม quantity ทีละ 1)
        for (const e of equipRows) {
          await connection.query(
            'UPDATE equipments SET eqpt_quantity = eqpt_quantity + 1 WHERE eqpt_id = ?',
            [e.eqpt_id]
          );
        }
        
        console.log('✅ Equipment returned');

        // ย้ายเคสไป recordhistory
        let recordHistoryId;
        try {
          const [insertResult] = await connection.query(
              `INSERT INTO recordhistory
                (rhis_patient_id, rhis_patient_type, rhis_room_from, rhis_room_to, str_type_id, rhis_status, rhis_requested_by, rhis_assigned_porter, rhis_created_at, rhis_completed_at, rhis_notes)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)`,
              [
                c.case_patient_id,
                c.case_patient_type,
                c.case_room_from,
                c.case_room_to,
                c.str_type_id,
                'completed',
                c.case_requested_by,
                porterNumU ?? c.case_assigned_porter,
                c.case_created_at,
                c.case_notes
              ]
          );
          recordHistoryId = insertResult.insertId;
          console.log(`✅ Case ${caseId} moved to recordhistory (New ID: ${recordHistoryId})`);
        } catch (insertErr) {
             console.error(`❌ Failed to insert into recordhistory:`, insertErr);
             throw insertErr;
        }

        // ย้ายอุปกรณ์ไป recordequipments โดยใช้ ID ใหม่จาก recordhistory
        for (const e of equipRows) {
          await connection.query(
            'INSERT INTO recordequipments (rhis__id, eqpt_id) VALUES (?, ?)',
            [recordHistoryId, e.eqpt_id]
          );
        }

        // ลบเคสจาก cases และ caseequipments
        await connection.query('DELETE FROM caseequipments WHERE case_id = ?', [caseId]);
        await connection.query('DELETE FROM cases WHERE case_id = ?', [caseId]);
        
        await connection.commit();
        console.log(`✅ Case ${caseId} completed and moved successfully (Transaction Committed)`);

        return res.json({ message: 'Case completed, moved to recordhistory, and equipment returned' });

      } catch (err) {
        await connection.rollback();
        console.error('❌ Transaction Failed:', err);
        throw err; // Send to outer catch
      } finally {
        connection.release();
      }
    }

    // 🔹 อัปเดต status สำหรับ pending / in_progress
    let query = 'UPDATE cases SET case_status = ?';
    const params = [status];

    if (porterNumU !== null) {
      query += ', case_assigned_porter = ?';
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
