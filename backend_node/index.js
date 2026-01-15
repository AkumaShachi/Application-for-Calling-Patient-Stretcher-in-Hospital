const express = require("express");
const cors = require('cors');
const app = express();

const registrantRouter = require('./src/registrant');
const loginRouter = require('./src/login');
const forgetRouter = require('./src/forget');
const resetRouter = require('./src/reset');

const addcaseRouter = require('./src/Cases/cases_add');
const checkcaseRouter = require('./src/Cases/cases_check');
const delcaseRouter = require('./src/Cases/cases_delete');
const getcaseRouter = require('./src/Cases/cases_get');
const updcaseRouter = require('./src/Cases/cases_update');

const addeqptRouter = require('./src/Equipments/equipments_add');
const deleqptRouter = require('./src/Equipments/equipments_delete');
const geteqptRouter = require('./src/Equipments/equipments_get');
const updeqptRouter = require('./src/Equipments/equipments_update');

const addstrRouter = require('./src/Stretchers/stretchers_add');
const delstrRouter = require('./src/Stretchers/stretchers_delete');
const getstrRouter = require('./src/Stretchers/stretchers_get');
const updstrRouter = require('./src/Stretchers/stretchers_update');

const getproRouter = require('./src/Profile/profile_get');
const getusersRouter = require('./src/Employee/employee_get');
const updproRouter = require('./src/Profile/profile_update');

const getrhisRouter = require('./src/CaseHistory/caseshistory_get');
const addrhisRouter = require('./src/CaseHistory/caseshistory_add');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());

app.use('/uploads', express.static('uploads'));

// ใช้ router ปกติ
app.use(registrantRouter);
app.use(loginRouter);
app.use(forgetRouter);
app.use(resetRouter);

app.use(addcaseRouter);
app.use(checkcaseRouter);
app.use(delcaseRouter);
app.use(getcaseRouter);
app.use(updcaseRouter);

app.use(addeqptRouter);
app.use(deleqptRouter);
app.use(geteqptRouter);
app.use(updeqptRouter);

app.use(addstrRouter);
app.use(delstrRouter);
app.use(getstrRouter);
app.use(updstrRouter);

app.use(getproRouter);
app.use(getusersRouter);
app.use(updproRouter);

app.use(getrhisRouter);
app.use(addrhisRouter);

// const PORT = process.env.PORT || 4000;
// app.listen(PORT, () => {
//   console.log(`Server is running on port ${PORT}`);
// });

// // ...existing code...

const PORT = process.env.PORT || 4000;
const HOST = '0.0.0.0'; // Define the host

app.listen(PORT, HOST, () => { // Pass the host to app.listen
  console.log(`Server is running on port ${PORT} and listening on all interfaces (0.0.0.0)`);
});
