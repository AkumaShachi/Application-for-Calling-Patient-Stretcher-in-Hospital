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
  
  console.log('📌 [POST] /add_case Request:', req.body);

  try {
    // 1. หา user_num ของ requestedBy
    const [userRows] = await pool.query(
      'SELECT user_num FROM users WHERE user_username = ?',
      [requestedBy]
    );
    if (userRows.length === 0) {
      console.warn(`⚠️ User not found: ${requestedBy}`);
      return res.status(400).json({ message: 'ไม่พบผู้ใช้ requestedBy' });
    }
    const requestedById = userRows[0].user_num;

    // 2. หา str_type_id + เช็ค quantity
    let stretcherTypeDbId = null;
    if (stretcherTypeId) {
      const [stretcherRows] = await pool.query(
        'SELECT str_type_id, str_quantity FROM stretchertypes WHERE str_type_name = ?',
        [stretcherTypeId]
      );
      if (stretcherRows.length === 0) {
        console.warn(`⚠️ Stretcher type not found: ${stretcherTypeId}`);
        return res.status(400).json({ message: 'ไม่พบประเภทเปลที่ส่งมา' });
      }
      if (stretcherRows[0].str_quantity <= 0) {
        console.warn(`⚠️ Stretcher out of stock: ${stretcherTypeId}`);
        return res.status(400).json({ message: `หมดเปลประเภท ${stretcherTypeId}` });
      }
      stretcherTypeDbId = stretcherRows[0].str_type_id;
    }

    // 3. Insert เคส - ใช้ column names ที่ถูกต้อง
    const [caseResult] = await pool.query(
      `INSERT INTO cases
       (case_patient_id, case_patient_type, case_room_from, case_room_to, str_type_id, case_requested_by)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [patientId, patientType, roomFrom, roomTo, stretcherTypeDbId, requestedById]
    );
    const caseId = caseResult.insertId;

    // 4. ลด quantity ของเปลลง 1
    if (stretcherTypeDbId) {
      await pool.query(
        'UPDATE stretchertypes SET str_quantity = str_quantity - 1 WHERE str_type_id = ?',
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
      // หา eqpt_id + quantity ของอุปกรณ์
      const [equipRows] = await pool.query(
        'SELECT eqpt_id, eqpt_name, eqpt_quantity FROM equipments WHERE eqpt_name IN (?)',
        [equipmentArray]
      );

      for (const eq of equipRows) {
        if (eq.eqpt_quantity > 0) {
          // insert เข้า caseequipments
          await pool.query(
            'INSERT INTO caseequipments (case_id, eqpt_id) VALUES (?, ?)',
            [caseId, eq.eqpt_id]
          );
          // ลด quantity ลง 1
          await pool.query(
            'UPDATE equipments SET eqpt_quantity = eqpt_quantity - 1 WHERE eqpt_id = ?',
            [eq.eqpt_id]
          );
          usedEquipment.push(eq.eqpt_name);
        } else {
          outOfStock.push(eq.eqpt_name);
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
