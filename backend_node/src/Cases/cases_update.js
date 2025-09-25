const express = require('express');
const router = express.Router();
const pool = require('../Database');

const VALID_STATUSES = new Set(['pending', 'in_progress', 'completed']);

const normalizeString = (value) => (typeof value === 'string' ? value.trim() : value);

router.put('/cases/:caseId', async (req, res) => {
  const caseId = Number(req.params.caseId);

  if (!Number.isInteger(caseId) || caseId <= 0) {
    return res.status(400).json({ message: 'Invalid case id' });
  }

  const statusValue = (normalizeString(req.body.status) || '').toLowerCase();

  if (!VALID_STATUSES.has(statusValue)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  const assignedPorterInput = req.body.assignedPorter;
  const notesInput = req.body.notes;

  try {
    let assignedPorterId;
    let shouldUpdatePorter = false;

    if (assignedPorterInput !== undefined) {
      shouldUpdatePorter = true;

      if (assignedPorterInput === null || normalizeString(assignedPorterInput) === '') {
        assignedPorterId = null;
      } else {
        const username = normalizeString(assignedPorterInput);
        const [porterRows] = await pool.query(
          'SELECT user_num FROM users WHERE user_username = ?',
          [username]
        );

        if (!porterRows.length) {
          return res.status(400).json({ message: `Assigned porter '${username}' not found` });
        }

        assignedPorterId = porterRows[0].user_num;
      }
    }

    const fields = ['case_status = ?'];
    const params = [statusValue];

    if (shouldUpdatePorter) {
      if (assignedPorterId === null) {
        fields.push('case_assigned_porter = NULL');
      } else {
        fields.push('case_assigned_porter = ?');
        params.push(assignedPorterId);
      }
    }

    if (notesInput !== undefined) {
      const notesValue = normalizeString(notesInput);
      fields.push('case_notes = ?');
      params.push(notesValue === '' ? null : notesValue);
    }

    if (statusValue === 'completed') {
      fields.push('case_completed_at = NOW()');
    } else {
      fields.push('case_completed_at = NULL');
    }

    params.push(caseId);

    const [result] = await pool.query(
      `UPDATE cases SET ${fields.join(', ')} WHERE case_id = ?`,
      params
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Case not found' });
    }

    const [rows] = await pool.query(
      `SELECT c.case_id, c.case_status, c.case_assigned_porter, c.case_completed_at,
              u.user_username AS assigned_porter_username
         FROM cases c
         LEFT JOIN users u ON c.case_assigned_porter = u.user_num
        WHERE c.case_id = ?`,
      [caseId]
    );

    const updatedCase = rows[0];

    res.json({
      message: 'Case updated',
      case: {
        caseId: updatedCase.case_id,
        status: updatedCase.case_status,
        assignedPorter: updatedCase.assigned_porter_username || null,
        completedAt: updatedCase.case_completed_at
      }
    });
  } catch (error) {
    console.error('Error updating case:', error);
    res.status(500).json({ message: 'Failed to update case' });
  }
});

module.exports = router;
