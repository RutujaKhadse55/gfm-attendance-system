const mongoose = require('mongoose');

const assignmentSchema = new mongoose.Schema({
  teacherUsername: { type: String, required: true },
  batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', required: true },
  role: { type: String, default: 'attendance_teacher' },
}, { timestamps: true });

// Unique constraint matching (teacher_name, batch_id)
assignmentSchema.index({ teacherUsername: 1, batchId: 1 }, { unique: true });

module.exports = mongoose.model('Assignment', assignmentSchema);
