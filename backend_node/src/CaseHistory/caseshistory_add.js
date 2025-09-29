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

const parseDateOrThrow = (value, fieldName) => {
  if (value === undefined || value === null || value === '') {
    return null;
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw httpError(400, `Invalid ${fieldName}`);
  }

  return date;
};

const resolveUserId = async (connection, identifier, label) => {
  const trimmed = normalizeString(identifier);
  if (!trimmed) {
    return null;
  }

  const isNumeric = /^\d+$/.test(trimmed);
  const [rows] = await connection.query(
    `SELECT user_num FROM users WHERE ${isNumeric ? 'user_num = ?' : 'user_username = ?'}`,
    [isNumeric ? Number(trimmed) : trimmed]
  );

  if (!rows.length) {
    throw httpError(400, `${label} '${trimmed}' not found`);
  }

  return rows[0].user_num;
};

router.post('/cases/history', async (req, res) => {
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
    status,
    notes,
    equipmentIds,
    equipmentNames,
    createdAt,
    completedAt
  } = req.body;

  const patientIdValue = normalizeString(patientId);
  const patientTypeValue = normalizeString(patientType) || 'normal';
  const roomFromValue = normalizeString(roomFrom);
  const roomToValue = normalizeString(roomTo);
  const notesValue = normalizeString(notes) ?? null;

  if (!patientIdValue || !roomFromValue || !roomToValue) {
    return res.status(400).json({ message: 'patientId, roomFrom, and roomTo are required' });
  }

  const statusValue = (normalizeString(status) || 'completed').toLowerCase();
  if (!VALID_STATUSES.has(statusValue)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  const createdAtValue = parseDateOrThrow(createdAt, 'createdAt');
  const completedAtValue = parseDateOrThrow(completedAt, 'completedAt');

  const stretcherLookupRaw = normalizeString(stretcherTypeId ?? stretcherTypeName ?? stretcherType);
  const equipmentTokens = collectTokens(equipmentIds, equipmentNames);

  let connection;

  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const requesterId = await resolveUserId(connection, requestedBy, 'Requester');
    if (!requesterId) {
      throw httpError(400, 'requestedBy is required');
    }

    const assignedPorterId = await resolveUserId(connection, assignedPorter, 'Assigned porter');

    let stretcherTypeDbId = null;
    if (stretcherLookupRaw) {
      const isNumericStretcher = /^\d+$/.test(stretcherLookupRaw);
      const [stretcherRows] = await connection.query(
        `SELECT str_type_id FROM stretchertypes WHERE ${isNumericStretcher ? 'str_type_id = ?' : 'str_type_name = ?'}`,
        [isNumericStretcher ? Number(stretcherLookupRaw) : stretcherLookupRaw]
      );

      if (!stretcherRows.length) {
        throw httpError(400, 'Stretcher type not found');
      }

      stretcherTypeDbId = stretcherRows[0].str_type_id;
    }

    const columns = [
      'rhis_patient_id',
      'rhis_patient_type',
      'rhis_room_from',
      'rhis_room_to',
      'str_type_id',
      'rhis_status',
      'rhis_requested_by',
      'rhis_assigned_porter',
      'rhis_notes'
    ];
    const values = [
      patientIdValue,
      patientTypeValue,
      roomFromValue,
      roomToValue,
      stretcherTypeDbId,
      statusValue,
      requesterId,
      assignedPorterId,
      notesValue
    ];

    if (createdAtValue) {
      columns.push('rhis_created_at');
      values.push(createdAtValue);
    }

    if (completedAtValue) {
      columns.push('rhis_completed_at');
      values.push(completedAtValue);
    }

    const placeholders = columns.map(() => '?').join(', ');
    const [historyResult] = await connection.query(
      `INSERT INTO recordhistory (${columns.join(', ')}) VALUES (${placeholders})`,
      values
    );

    const historyId = historyResult.insertId;

    if (equipmentTokens.length) {
      const allNumeric = equipmentTokens.every((token) => /^\d+$/.test(token));
      const uniqueTokens = [...new Set(
        equipmentTokens.map((token) => (allNumeric ? Number(token) : token.toLowerCase()))
      )];

      const [equipmentRows] = await connection.query(
        `SELECT eqpt_id, eqpt_name FROM equipments WHERE ${allNumeric ? 'eqpt_id' : 'LOWER(eqpt_name)'} IN (?)`,
        [uniqueTokens]
      );

      if (equipmentRows.length !== uniqueTokens.length) {
        throw httpError(400, 'One or more equipments were not found');
      }

      const equipmentMap = new Map();
      for (const row of equipmentRows) {
        equipmentMap.set(String(row.eqpt_id), row.eqpt_id);
        equipmentMap.set(row.eqpt_name.toLowerCase(), row.eqpt_id);
      }

      const equipmentPlaceholders = [];
      const equipmentValues = [];

      for (const token of equipmentTokens) {
        const key = allNumeric ? String(Number(token)) : token.toLowerCase();
        const equipmentId = equipmentMap.get(key);
        if (!equipmentId) {
          throw httpError(400, `Equipment '${token}' not found`);
        }
        equipmentPlaceholders.push('(?, ?)');
        equipmentValues.push(historyId, equipmentId);
      }

      if (equipmentPlaceholders.length) {
        await connection.query(
          `INSERT INTO recordequipments (rhis__id, eqpt_id) VALUES ${equipmentPlaceholders.join(', ')}`,
          equipmentValues
        );
      }
    }

    await connection.commit();

    res.status(201).json({
      message: 'History record created',
      history: {
        historyId,
        patientId: patientIdValue,
        status: statusValue,
        stretcherTypeId: stretcherTypeDbId,
        requestedBy: requestedBy,
        assignedPorter: assignedPorter ?? null,
        equipmentCount: equipmentTokens.length
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
    res.status(statusCode).json({ message: error.message || 'Failed to create history record' });
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

module.exports = router;