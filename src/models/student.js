const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  prn: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  mobile: { type: String, required: true },
  parentMobile: { type: String, required: true },
  email: { type: String, required: true },
  batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', required: true },
});

module.exports = mongoose.model('Student', studentSchema);
