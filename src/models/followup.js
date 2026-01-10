const mongoose = require('mongoose');

const followUpSchema = new mongoose.Schema({
  attendanceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Attendance', required: true, unique: true },
  reason: { type: String, required: true },
  // store GridFS file id reference
  proofFileId: { type: mongoose.Schema.Types.ObjectId },
  proofFilename: { type: String },
  timestamp: { type: Date, default: Date.now },
});

module.exports = mongoose.model('FollowUp', followUpSchema);
