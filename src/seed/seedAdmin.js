const User = require('../models/user');
const bcrypt = require('bcryptjs');

module.exports = async function seedAdmin() {
  const existing = await User.findOne({ username: 'admin' }).lean().exec();
  if (!existing) {
    const hashed = await bcrypt.hash('admin123', 10);
    await User.create({
      username: 'admin',
      password: hashed,
      role: 'admin',
      displayName: 'Administrator',
      isActive: true,
    });
    console.log('Seeded default admin (username: admin password: admin123)');
  }
};
