const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');

const pool = require('./Database');



router.post('/registrant', (req, res) => {

  const data = {
    "id_U": req.body.id_U,
    "fname_U": req.body.fname_U,
    "lname_U": req.body.lname_U,
    "phone_U": req.body.phone_U,
    "email_U": req.body.email_U,
    "role_U": req.body.role_U,
    "username": req.body.username,
    "password": req.body.password,
  };

  bcrypt.hash(data.password, 10, (err, hashedPassword) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ status: 'error', message: 'Hashing error' });
    }
    pool.getConnection((err, connection) => {
      if (err) throw err
      console.log(`connected as id ${connection.threadId}`)
      const registrant = { ...data, "password": hashedPassword };
      connection.query('INSERT INTO users SET ?', registrant, (err, rows) => {
        connection.release() // return the connection to pool
        if (!err) {
          res.send(rows)
        } else {
          console.log(err)
        }
      })
    })
  })
})

module.exports = router;