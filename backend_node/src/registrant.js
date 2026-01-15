const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('./Database');

const REQUIRED_FIELDS = [
  'id_U',
  'fname_U',
  'lname_U',
  'phone_U',
  'email_U',
  'username',
  'password',
  'role_U'
];

const normalizeString = (value) => (typeof value === 'string' ? value.trim() : value);

router.post('/registrant', async (req, res) => {
  const payload = req.body || {};

  const missingFields = REQUIRED_FIELDS.filter((field) => {
    const value = normalizeString(payload[field]);
    return !value;
  });

  if (missingFields.length) {
    return res.status(400).json({
      status: 'error',
      message: 'Missing required fields',
      missing: missingFields
    });
  }

  const idU = normalizeString(payload.id_U);
  const fnameU = normalizeString(payload.fname_U);
  const lnameU = normalizeString(payload.lname_U);
  const phoneU = normalizeString(payload.phone_U);
  const emailU = normalizeString(payload.email_U);
  const username = normalizeString(payload.username);
  const password = payload.password;
  const roleU = normalizeString(payload.role_U);

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    const [roleResults] = await pool.query(
      'SELECT role_id FROM roles WHERE LOWER(role_name) = ? LIMIT 1',
      [roleU.toLowerCase()]
    );

    if (!roleResults.length) {
      return res.status(400).json({ status: 'error', message: 'Invalid role name' });
    }

    const roleId = roleResults[0].role_id;

    const [emailRows] = await pool.query(
      'SELECT 1 FROM users WHERE user_email = ? LIMIT 1',
      [emailU]
    );

    if (emailRows.length) {
      return res.status(400).json({ status: 'error', message: 'Email already exists' });
    }

    const [usernameRows] = await pool.query(
      'SELECT 1 FROM users WHERE user_username = ? LIMIT 1',
      [username]
    );

    if (usernameRows.length) {
      return res.status(400).json({ status: 'error', message: 'Username already exists' });
    }

    const registrant = {
      user_id: idU,
      user_fname: fnameU,
      user_lname: lnameU,
      user_phone: phoneU,
      user_email: emailU,
      user_username: username,
      user_password_hash: hashedPassword,
      role_id: roleId
    };

    const [userResult] = await pool.query('INSERT INTO users SET ?', registrant);

    return res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      user_num: userResult.insertId
    });
  } catch (err) {
    console.error('Error registering user:', err);

    if (err.code === 'ER_DUP_ENTRY') {
      const duplicateField = err.sqlMessage && err.sqlMessage.includes('user_username')
        ? 'Username'
        : 'Email';
      const message = duplicateField === 'Email' ? 'Email already exists' : 'Username already exists';

      return res.status(400).json({ status: 'error', message });
    }

    return res.status(500).json({
      status: 'error',
      message: 'Server error'
    });
  }
});

module.exports = router;
