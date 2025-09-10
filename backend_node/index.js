const express = require("express");
const cors = require('cors');
const app = express();

const pool = require('./src/Database'); 
const registrantRouter = require('./src/registrant');
const loginRouter = require('./src/login');
const forgetRouter = require('./src/forget');
const resetRouter = require('./src/reset');
const addcaseRouter = require('./src/addcase');
const getcaseRouter = require('./src/getcase');
const updatecaseRouter = require('./src/updatecase');
const stretcherRouter = require('./src/stretcher');
const equipmentsRouter = require('./src/equipments');
const RecordHistoryRouter = require('./src/recordhistory');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

// ใช้ router ปกติ
app.use(registrantRouter);
app.use(loginRouter);
app.use(forgetRouter);
app.use(resetRouter);
app.use(addcaseRouter);
app.use(getcaseRouter);
app.use(updatecaseRouter);
app.use(stretcherRouter);
app.use(equipmentsRouter);
app.use(RecordHistoryRouter);


const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
