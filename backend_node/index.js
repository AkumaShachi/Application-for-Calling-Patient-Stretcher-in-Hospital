const express = require("express");
const cors = require('cors');
const app = express();

const pool = require('./src/Database'); 
const registrantRouter = require('./src/registrant');
const loginRouter = require('./src/login');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(cors());

app.use(registrantRouter);
app.use(loginRouter);

app.get('/', (req, res) => {
  pool.getConnection((err, connection) => {
    if (err) throw err
    console.log(`connected as id ${connection.threadId}`)

    connection.query('SELECT * from users', (err, rows) => {
      connection.release() // return the connection to pool

      if (!err) {
        res.send(rows)
      } else {
        console.log(err)
      }
    })
  })
})

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});