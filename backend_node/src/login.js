const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');

const pool = require('./Database');

// router.get('/login/:username', (req, res) => {
//     pool.getConnection((err, connection) => {
//         if (err) throw err
//         console.log(`connected as id ${connection.threadId}`)

//         connection.query('SELECT * FROM users WHERE username = ?', [req.params.username], (err, rows) => {
//             connection.release() // return the connection to pool
//             if (!err) {
//                 if (rows.length > 0) {
//                     res.json({
//                         status: 'success',
//                         password: rows[0].password,
//                         role: rows[0].role_U
//                     });
//                 } else {
//                     res.status(401).json({ status: 'error', message: 'Unauthorized' });
//                 }
//             } else {
//                 console.log(err)
//             }
//         })
//     })
// })

// POST /login
router.post('/login', (req, res) => {
  const { username, password } = req.body;

  pool.query('SELECT * FROM users WHERE username = ?', [username], (err, rows) => {
    if (err) return res.status(500).json({ status: 'error', message: 'Database error' });
    if (rows.length === 0) return res.status(401).json({ status: 'error', message: 'User not found' });

    const user = rows[0];

    // เช็ค password hash
    bcrypt.compare(password, user.password, (err, isMatch) => {
      if (err) return res.status(500).json({ status: 'error', message: 'Compare error' });
      if (!isMatch) return res.status(401).json({ status: 'error', message: 'Invalid password' });

      res.json({
        status: 'success',
        message: 'Login successful',
        role: user.role_U
      });
    });
  });
});


module.exports = router;