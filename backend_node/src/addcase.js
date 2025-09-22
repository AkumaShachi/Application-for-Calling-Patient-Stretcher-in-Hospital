const express = require('express');
const router = express.Router();
const pool = require('./Database'); // mysql2/promise

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
    // 1. หา user id ของ requestedBy
    const [userRows] = await pool.query(
      'SELECT num_U FROM Users WHERE username = ?',
      [requestedBy]
    );
    if (userRows.length === 0) {
      return res.status(400).json({ message: 'ไม่พบผู้ใช้ requestedBy' });
    }
    const requestedById = userRows[0].num_U;

    // 2. หา stretcher_type_id + เช็ค quantity
    let stretcherTypeDbId = null;
    if (stretcherTypeId) {
      const [stretcherRows] = await pool.query(
        'SELECT id, quantity FROM StretcherTypes WHERE type_name = ?',
        [stretcherTypeId]
      );
      if (stretcherRows.length === 0) {
        return res.status(400).json({ message: 'ไม่พบประเภทเปลที่ส่งมา' });
      }
      if (stretcherRows[0].quantity <= 0) {
        return res.status(400).json({ message: `หมดเปลประเภท ${stretcherTypeId}` });
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

    // 4. ลด quantity ของเปลลง 1
    if (stretcherTypeDbId) {
      await pool.query(
        'UPDATE StretcherTypes SET quantity = quantity - 1 WHERE id = ?',
        [stretcherTypeDbId]
      );
    }

    // 5. แปลง equipmentIds ให้เป็น array
    let equipmentArray = [];
    if (equipmentIds) {
      equipmentArray = equipmentIds.split(',').map(e => e.trim());
    }

    const usedEquipment = [];
    const outOfStock = [];

    if (equipmentArray.length > 0) {
      // หา id + quantity ของอุปกรณ์
      const [equipRows] = await pool.query(
        'SELECT id, equipment_name, quantity FROM Equipments WHERE equipment_name IN (?)',
        [equipmentArray]
      );

      for (const eq of equipRows) {
        if (eq.quantity > 0) {
          // insert เข้า CaseEquipments
          await pool.query(
            'INSERT INTO CaseEquipments (case_id, equipment_id) VALUES (?, ?)',
            [caseId, eq.id]
          );
          // ลด quantity ลง 1
          await pool.query(
            'UPDATE Equipments SET quantity = quantity - 1 WHERE id = ?',
            [eq.id]
          );
          usedEquipment.push(eq.equipment_name);
        } else {
          outOfStock.push(eq.equipment_name);
        }
      }
    }

    res.status(200).json({
      message: 'Case saved successfully',
      caseId,
      usedEquipment,
      outOfStock
    });

  } catch (err) {
    console.error('Error inserting case:', err);
    res.status(500).json({ message: 'Failed to save case', error: err.message });
  }
});

module.exports = router;
