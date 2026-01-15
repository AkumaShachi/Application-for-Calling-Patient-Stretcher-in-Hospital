const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('./Database'); // ใช้ mysql2/promise

router.post('/registrant', async (req, res) => {
  const {
    id_U, fname_U, lname_U, phone_U, email_U, username, password,
    role_U, license_number, department, position, shift, area
  } = req.body;

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    // Lookup role case-insensitive
    const [roleResults] = await pool.query(
      'SELECT role_id FROM roles WHERE LOWER(role_name) = LOWER(?)',
      [role_U]
    );

    if (roleResults.length === 0) {
      return res.status(400).json({ status: 'error', message: 'Invalid role name' });
    }

    const role_id = roleResults[0].role_id;

    // Insert Users - ใช้ column names ที่ถูกต้อง
    const registrant = { 
      user_id: id_U, 
      user_fname: fname_U, 
      user_lname: lname_U, 
      user_phone: phone_U, 
      user_email: email_U, 
      user_username: username, 
      user_password_hash: hashedPassword, 
      role_id 
    };

    const [userResult] = await pool.query('INSERT INTO users SET ?', registrant);
    const user_num = userResult.insertId;

    // Insert role-specific table
    if (role_U.toLowerCase() === 'nurse') {
      await pool.query('INSERT INTO nurses SET ?', {
        user_num,
        license_number: license_number || null,
        department: department || null,
        position: position || null
      });
    } else if (role_U.toLowerCase() === 'porter') {
      await pool.query('INSERT INTO porters SET ?', {
        user_num,
        shift: shift || null,
        area: area || null,
        position: position || null
      });
    }

    return res.status(201).json({ 
      status: 'success', 
      message: 'User registered successfully' 
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ 
      status: 'error', 
      message: 'Server error', 
      error: err 
    });
  }
});

module.exports = router;
