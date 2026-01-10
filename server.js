const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/attendance_db', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ MongoDB Connected'))
.catch(err => console.error('❌ MongoDB Connection Error:', err));

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key_change_in_production';

// ==================== MODELS ====================

// User Model (Admin & Teachers)
const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['admin', 'teacher'], required: true },
  fullName: String,
  mobile: String,
  email: String,
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

// Student Model
const studentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  rollNumber: { type: String, required: true, unique: true },
  mobile: { type: String, required: true },
  parentMobile: { type: String, required: true },
  email: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

const Student = mongoose.model('Student', studentSchema);

// Attendance Model
const attendanceSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, required: true },
  status: { type: String, enum: ['Present', 'Absent'], required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Index for faster queries
attendanceSchema.index({ studentId: 1, date: 1 }, { unique: true });
const Attendance = mongoose.model('Attendance', attendanceSchema);

// Follow-Up Model
const followUpSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  notes: { type: String, required: true },
  documentUrls: [String],
  date: { type: Date, required: true },
  createdAt: { type: Date, default: Date.now }
});

const FollowUp = mongoose.model('FollowUp', followUpSchema);

// ==================== MIDDLEWARE ====================

// Auth Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// Admin Only Middleware
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ success: false, message: 'Admin access required' });
  }
  next();
};

// ==================== FILE UPLOAD ====================

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const upload = multer({ storage });

// ==================== ROUTES ====================

// ========== AUTH ROUTES ==========

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: user._id, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      token,
      user: {
        _id: user._id,
        username: user.username,
        role: user.role,
        fullName: user.fullName,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ========== STUDENT ROUTES ==========

// Get all students
app.get('/api/students', authenticateToken, async (req, res) => {
  try {
    const students = await Student.find().sort({ name: 1 });
    res.json({ success: true, students });
  } catch (error) {
    console.error('Get students error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Add single student
app.post('/api/students', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const student = new Student(req.body);
    await student.save();
    res.status(201).json({ success: true, message: 'Student added', student });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'Roll number already exists' });
    }
    console.error('Add student error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Import multiple students
app.post('/api/students/import', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { students } = req.body;
    let imported = 0;
    let duplicates = 0;

    for (const studentData of students) {
      try {
        const student = new Student(studentData);
        await student.save();
        imported++;
      } catch (error) {
        if (error.code === 11000) {
          duplicates++;
        }
      }
    }

    res.json({ success: true, imported, duplicates });
  } catch (error) {
    console.error('Import students error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ========== TEACHER ROUTES ==========

// Get all teachers
app.get('/api/teachers', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const teachers = await User.find({ role: 'teacher' }).select('-password');
    res.json({ success: true, teachers });
  } catch (error) {
    console.error('Get teachers error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Add teacher
app.post('/api/teachers', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { name, username, password, mobile, email } = req.body;

    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Username already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const teacher = new User({
      username,
      password: hashedPassword,
      role: 'teacher',
      fullName: name,
      mobile,
      email
    });

    await teacher.save();
    res.status(201).json({ success: true, message: 'Teacher added' });
  } catch (error) {
    console.error('Add teacher error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update teacher
app.put('/api/teachers/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { name, mobile, email } = req.body;
    await User.findByIdAndUpdate(req.params.id, {
      fullName: name,
      mobile,
      email
    });
    res.json({ success: true, message: 'Teacher updated' });
  } catch (error) {
    console.error('Update teacher error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Delete teacher
app.delete('/api/teachers/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Teacher deleted' });
  } catch (error) {
    console.error('Delete teacher error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ========== ATTENDANCE ROUTES ==========

// Mark attendance (batch)
app.post('/api/attendance', authenticateToken, async (req, res) => {
  try {
    const { attendance } = req.body;

    for (const record of attendance) {
      const { studentId, teacherId, date, status } = record;
      
      // Update or create attendance
      await Attendance.findOneAndUpdate(
        { studentId, date: new Date(date).setHours(0, 0, 0, 0) },
        { 
          studentId, 
          teacherId, 
          date: new Date(date).setHours(0, 0, 0, 0), 
          status,
          updatedAt: new Date()
        },
        { upsert: true, new: true }
      );
    }

    res.json({ success: true, message: 'Attendance marked successfully' });
  } catch (error) {
    console.error('Mark attendance error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get attendance by date
app.get('/api/attendance/date/:date', authenticateToken, async (req, res) => {
  try {
    const date = new Date(req.params.date).setHours(0, 0, 0, 0);
    const attendance = await Attendance.find({ date })
      .populate('studentId', 'name rollNumber mobile')
      .populate('teacherId', 'fullName');
    
    const formattedAttendance = attendance.map(a => ({
      _id: a._id,
      studentId: a.studentId._id,
      studentName: a.studentId.name,
      rollNumber: a.studentId.rollNumber,
      teacherId: a.teacherId._id,
      date: a.date,
      status: a.status,
      createdAt: a.createdAt,
      updatedAt: a.updatedAt
    }));

    res.json({ success: true, attendance: formattedAttendance });
  } catch (error) {
    console.error('Get attendance error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update single attendance
app.put('/api/attendance/:id', authenticateToken, async (req, res) => {
  try {
    const { status } = req.body;
    await Attendance.findByIdAndUpdate(req.params.id, { 
      status,
      updatedAt: new Date()
    });
    res.json({ success: true, message: 'Attendance updated' });
  } catch (error) {
    console.error('Update attendance error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ========== FOLLOW-UP ROUTES ==========

// Add follow-up
app.post('/api/followup', authenticateToken, upload.array('documents', 5), async (req, res) => {
  try {
    const { studentId, teacherId, notes, date } = req.body;
    const documentUrls = req.files ? req.files.map(file => `/uploads/${file.filename}`) : [];

    const followUp = new FollowUp({
      studentId,
      teacherId,
      notes,
      documentUrls,
      date: new Date(date)
    });

    await followUp.save();
    res.status(201).json({ success: true, message: 'Follow-up added' });
  } catch (error) {
    console.error('Add follow-up error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get follow-ups by student
app.get('/api/followup/student/:studentId', authenticateToken, async (req, res) => {
  try {
    const followUps = await FollowUp.find({ studentId: req.params.studentId })
      .populate('teacherId', 'fullName')
      .sort({ createdAt: -1 });
    res.json({ success: true, followUps });
  } catch (error) {
    console.error('Get follow-ups error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ========== REPORT ROUTES ==========

// Daily report
app.get('/api/reports/daily/:date', authenticateToken, async (req, res) => {
  try {
    const date = new Date(req.params.date).setHours(0, 0, 0, 0);
    const attendance = await Attendance.find({ date })
      .populate('studentId', 'name rollNumber mobile')
      .populate('teacherId', 'fullName');

    const reportData = {
      date: new Date(date),
      attendance: attendance.map(a => ({
        studentId: a.studentId._id,
        studentName: a.studentId.name,
        rollNumber: a.studentId.rollNumber,
        status: a.status,
        teacherName: a.teacherId.fullName
      })),
      summary: {
        total: attendance.length,
        present: attendance.filter(a => a.status === 'Present').length,
        absent: attendance.filter(a => a.status === 'Absent').length
      }
    };

    res.json(reportData);
  } catch (error) {
    console.error('Daily report error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Weekly report
app.get('/api/reports/weekly', authenticateToken, async (req, res) => {
  try {
    const { start, end } = req.query;
    const startDate = new Date(start).setHours(0, 0, 0, 0);
    const endDate = new Date(end).setHours(23, 59, 59, 999);

    const attendance = await Attendance.find({
      date: { $gte: startDate, $lte: endDate }
    })
    .populate('studentId', 'name rollNumber')
    .populate('teacherId', 'fullName');

    res.json({
      startDate,
      endDate,
      attendance: attendance.map(a => ({
        date: a.date,
        studentName: a.studentId.name,
        rollNumber: a.studentId.rollNumber,
        status: a.status
      }))
    });
  } catch (error) {
    console.error('Weekly report error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// ==================== INITIALIZATION ====================

// Create default admin user (run once)
const initializeAdmin = async () => {
  try {
    const adminExists = await User.findOne({ role: 'admin' });
    if (!adminExists) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      const admin = new User({
        username: 'admin',
        password: hashedPassword,
        role: 'admin',
        fullName: 'System Administrator'
      });
      await admin.save();
      console.log('✅ Default admin user created (username: admin, password: admin123)');
    }
  } catch (error) {
    console.error('Error creating admin:', error);
  }
};

// ==================== START SERVER ====================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  initializeAdmin();
});