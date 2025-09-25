const express = require('express');
const router = express.Router();
const pool = require('../Database');

const VALID_STATUSES = new Set(['pending', 'in_progress', 'completed']);

const httpError = (status, message) => {
  const error = new Error(message);
  error.status = status;
  return error;
};

const normalizeString = (value) => (typeof value === 'string' ? value.trim() : value);

const collectTokens = (...sources) => {
  const tokens = [];
  for (const source of sources) {
    if (source === undefined || source === null) {
      continue;
    }

    if (Array.isArray(source)) {
      tokens.push(...source);
      continue;
    }

    if (typeof source === 'string') {
      tokens.push(...source.split(','));
      continue;
    }

    tokens.push(source);
  }

  return tokens
    .map((token) => normalizeString(token))
    .filter((token) => token !== undefined && token !== null && token !== '');
};

router.post('/cases', async (req, res) => {
  const {
    patientId,
    patientType,
    roomFrom,
    roomTo,
    stretcherTypeId,
    stretcherTypeName,
    stretcherType,
    requestedBy,
    assignedPorter,
    equipmentIds,
    equipmentNames,
    status,
    notes
  } = req.body;

  const patientIdValue = normalizeString(patientId);
  const patientTypeValue = normalizeString(patientType) || 'normal';
  const roomFromValue = normalizeString(roomFrom);
  const roomToValue = normalizeString(roomTo);
  const requestedByValue = normalizeString(requestedBy);
  const notesValue = normalizeString(notes) ?? null;

  const statusValue = (normalizeString(status) || 'pending').toLowerCase();

  if (!patientIdValue || !roomFromValue || !roomToValue || !requestedByValue) {
    return res.status(400).json({ message: 'patientId, roomFrom, roomTo, and requestedBy are required' });
  }

  if (!VALID_STATUSES.has(statusValue)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  const stretcherLookupRaw = normalizeString(stretcherTypeId ?? stretcherTypeName ?? stretcherType);
  const equipmentTokens = collectTokens(equipmentIds, equipmentNames);

  let connection;

  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const [requesterRows] = await connection.query(
      'SELECT user_num FROM users WHERE user_username = ?',
      [requestedByValue]
    );
    if (!requesterRows.length) {
      throw httpError(400, `Requester '${requestedByValue}' not found`);
    }
    const requesterId = requesterRows[0].user_num;

    let stretcherTypeDbId = null;
    if (stretcherLookupRaw) {
      const isNumericStretcher = /^\d+$/.test(stretcherLookupRaw);
      const [stretcherRows] = await connection.query(
        `SELECT str_type_id, str_quantity FROM stretchertypes WHERE ${isNumericStretcher ? 'str_type_id = ?' : 'str_type_name = ?'} FOR UPDATE`,
        [isNumericStretcher ? Number(stretcherLookupRaw) : stretcherLookupRaw]
      );

      if (!stretcherRows.length) {
        throw httpError(400, 'Stretcher type not found');
      }

      if (stretcherRows[0].str_quantity < 1) {
        throw httpError(409, 'Selected stretcher type is out of stock');
      }

      stretcherTypeDbId = stretcherRows[0].str_type_id;
    }

    let assignedPorterId = null;
    if (assignedPorter !== undefined && assignedPorter !== null && `${assignedPorter}`.trim() !== '') {
      const assignedPorterValue = `${assignedPorter}`.trim();
      const [porterRows] = await connection.query(
        'SELECT user_num FROM users WHERE user_username = ?',
        [assignedPorterValue]
      );

      if (!porterRows.length) {
        throw httpError(400, `Assigned porter '${assignedPorterValue}' not found`);
      }

      assignedPorterId = porterRows[0].user_num;
    }

    const equipmentRequests = [];
    if (equipmentTokens.length) {
      const allNumeric = equipmentTokens.every((token) => /^\d+$/.test(token));
      const queryTokens = [...new Set(
        equipmentTokens.map((token) => (allNumeric ? Number(token) : token))
      )];

      const [equipmentRows] = await connection.query(
        `SELECT eqpt_id, eqpt_name, eqpt_quantity FROM equipments WHERE ${allNumeric ? 'eqpt_id' : 'eqpt_name'} IN (?) FOR UPDATE`,
        [queryTokens]
      );

      const counts = new Map();
      equipmentTokens.forEach((token) => {
        const key = allNumeric ? Number(token) : token.toLowerCase();
        counts.set(key, (counts.get(key) || 0) + 1);
      });

      if (equipmentRows.length !== counts.size) {
        throw httpError(400, 'One or more equipments were not found');
      }

      for (const row of equipmentRows) {
        const key = allNumeric ? row.eqpt_id : row.eqpt_name.toLowerCase();
        const requestedQty = counts.get(key) || 0;

        if (row.eqpt_quantity < requestedQty) {
          throw httpError(409, `Equipment '${row.eqpt_name}' is out of stock`);
        }

        equipmentRequests.push({
          id: row.eqpt_id,
          name: row.eqpt_name,
          quantity: requestedQty
        });
      }
    }

    const [caseResult] = await connection.query(
      `INSERT INTO cases
        (case_patient_id, case_patient_type, case_room_from, case_room_to, str_type_id, case_status, case_requested_by, case_assigned_porter, case_notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        patientIdValue,
        patientTypeValue,
        roomFromValue,
        roomToValue,
        stretcherTypeDbId,
        statusValue,
        requesterId,
        assignedPorterId,
        notesValue
      ]
    );

    const caseId = caseResult.insertId;

    if (stretcherTypeDbId) {
      await connection.query(
        'UPDATE stretchertypes SET str_quantity = str_quantity - 1 WHERE str_type_id = ?',
        [stretcherTypeDbId]
      );
    }

    if (equipmentRequests.length) {
      const placeholders = [];
      const values = [];

      for (const request of equipmentRequests) {
        if (request.quantity < 1) {
          continue;
        }

        for (let i = 0; i < request.quantity; i += 1) {
          placeholders.push('(?, ?)');
          values.push(caseId, request.id);
        }

        await connection.query(
          'UPDATE equipments SET eqpt_quantity = eqpt_quantity - ? WHERE eqpt_id = ?',
          [request.quantity, request.id]
        );
      }

      if (placeholders.length) {
        await connection.query(
          `INSERT INTO caseequipments (case_id, eqpt_id) VALUES ${placeholders.join(', ')}`,
          values
        );
      }
    }

    await connection.commit();

    res.status(201).json({
      message: 'Case created',
      case: {
        caseId,
        status: statusValue,
        stretcherTypeId: stretcherTypeDbId,
        requestedBy: requestedByValue,
        assignedPorter: assignedPorter ?? null,
        equipment: equipmentRequests.map((item) => ({
          id: item.id,
          name: item.name,
          quantity: item.quantity
        }))
      }
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (rollbackError) {
        console.error('Rollback failed:', rollbackError);
      }
    }

    const statusCode = error.status || 500;
    res.status(statusCode).json({
      message: error.message || 'Failed to create case'
    });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

module.exports = router;
