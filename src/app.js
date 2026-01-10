require('dotenv').config();
const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const connectDB = require('./config/db');
const seedAdmin = require('./seed/seedAdmin');

const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const batchesRoutes = require('./routes/batches');
const studentsRoutes = require('./routes/students');
const assignmentsRoutes = require('./routes/assignments');
const attendanceRoutes = require('./routes/attendance');
const followupsRoutes = require('./routes/followups');
const reportsRoutes = require('./routes/reports');

const app = express();
app.use(morgan('dev'));
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/batches', batchesRoutes);
app.use('/api/students', studentsRoutes);
app.use('/api/assignments', assignmentsRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/followups', followupsRoutes);
app.use('/api/reports', reportsRoutes);

app.get('/', (req, res) => res.json({ok: true, message: 'GFM backend'}));

const PORT = process.env.PORT || 4000;

connectDB()
  .then(async () => {
    await seedAdmin();
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch((err) => {
    console.error('Failed to connect DB', err);
    process.exit(1);
  });
