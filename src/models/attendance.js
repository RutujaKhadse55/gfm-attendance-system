const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  studentPrn: { type: String, required: true },
  batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', required: true },
  date: { type: String, required: true }, // store YYYY-MM-DD or same string as clients send
  status: { type: String, enum: ['Present', 'Absent'], required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date },
  proofPath: { type: String },
}, { timestamps: false });

// Unique constraint student_prn + date
attendanceSchema.index({ studentPrn: 1, date: 1 }, { unique: true });

attendanceSchema.methods.isLocked = function() {
  const ageMs = Date.now() - this.createdAt.getTime();
  return ageMs > (24 * 60 * 60 * 1000);
};

module.exports = mongoose.model('Attendance', attendanceSchema);
