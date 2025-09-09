const express = require('express');
const router = express.Router();
const pool = require('./Database'); // ตอนนี้เป็น promise version

router.post('/add_case', async (req, res) => {
  const {
    patientId,
    patientType,
    roomFrom,
    roomTo,
    stretcherTypeId,
    requestedBy,
    equipmentIds
  } = req.body;

  try {
    // 1. หา user id
    const [userRows] = await pool.query(
      'SELECT num_U FROM Users WHERE username = ?',
      [requestedBy]
    );
    if (userRows.length === 0) {
      return res.status(400).json({ message: 'ไม่พบผู้ใช้ requestedBy' });
    }
    const requestedById = userRows[0].num_U;

    // 2. หา stretcher_type_id
    let stretcherTypeDbId = null;
    if (stretcherTypeId) {
      const [stretcherRows] = await pool.query(
        'SELECT id FROM StretcherTypes WHERE type_name = ?',
        [stretcherTypeId]
      );
      if (stretcherRows.length === 0) {
        return res.status(400).json({ message: 'ไม่พบประเภทเปลที่ส่งมา' });
      }
      stretcherTypeDbId = stretcherRows[0].id;
    }

    // 3. Insert เคส
    const [caseResult] = await pool.query(
      `INSERT INTO Cases
       (patient_id, patient_type, room_from, room_to, stretcher_type_id, requested_by)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [patientId, patientType, roomFrom, roomTo, stretcherTypeDbId, requestedById]
    );
    const caseId = caseResult.insertId;

    // 4. Insert อุปกรณ์ (ถ้ามี)
    if (equipmentIds && Array.isArray(equipmentIds) && equipmentIds.length > 0) {
      const equipmentValues = equipmentIds.map(eid => [caseId, eid]);
      await pool.query(
        'INSERT INTO CaseEquipments (case_id, equipment_id) VALUES ?',
        [equipmentValues]
      );
    }

    res.status(200).json({ message: 'Case saved successfully', caseId });

  } catch (err) {
    console.error('Error inserting case:', err);
    res.status(500).json({ message: 'Failed to save case', error: err.message });
  }
});

module.exports = router;
