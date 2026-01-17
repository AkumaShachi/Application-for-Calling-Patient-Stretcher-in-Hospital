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

    // Map role name to role_id explicitly as requested
    // Nurse = 2, Porter = 3
    let role_id;
    if (role_U === 'nurse') {
      role_id = 2;
    } else if (role_U === 'porter') {
      role_id = 3;
    } else {
      // Fallback lookup if needed, or error
      const [roleResults] = await pool.query(
        'SELECT role_id FROM roles WHERE LOWER(role_name) = LOWER(?)',
        [role_U]
      );
      if (roleResults.length > 0) {
        role_id = roleResults[0].role_id;
      } else {
        return res.status(400).json({ status: 'error', message: 'Invalid role name' });
      }
    }

    // Insert Users
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

    // NOTE: Tables 'nurses' and 'porters' do not exist in the database based on logs.
    // Commenting out to prevent Error 500.
    /*
    if (role_U.toLowerCase() === 'nurse') {
      await pool.query('INSERT INTO nurses SET ?', {
        user_num,
        license_number: license_number || '-',
        department: department || '-',
        position: position || '-'
      });
    } else if (role_U.toLowerCase() === 'porter') {
      await pool.query('INSERT INTO porters SET ?', {
        user_num,
        shift: shift || '-',
        area: area || '-',
        position: position || '-'
      });
    }
    */

    return res.status(201).json({ 
      status: 'success', 
      message: 'User registered successfully' 
    });

  } catch (err) {
    console.error('Registration Error:', err.message);
    if (err.sqlMessage) console.error('SQL Error:', err.sqlMessage);

    // Handle Duplicate Entry
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ 
        status: 'error', 
        message: 'อีเมลหรือรหัสประจำตัวนี้ถูกใช้งานแล้ว (Email or ID already exists)' 
      });
    }
    
    return res.status(500).json({ 
      status: 'error', 
      message: 'Server error', 
      error: err.sqlMessage || err.message 
    });
  }
});

module.exports = router;
