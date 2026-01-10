# GFM App - Quick Start Guide (v1.1.0)

## What's New in This Version?

✨ **Major Features Added**
1. Attendance teacher can access ALL batches (no admin assignment needed)
2. Batch teacher can upload proof files (images & PDFs)
3. Better validation across entire app
4. Improved error messages
5. Enhanced user experience

---

## Quick Setup

### For Users
1. Download and install the app
2. Login with your credentials
3. You're ready to go!

### For Admins
```
Default Admin Login:
Username: admin
Password: admin123

IMPORTANT: Change this password after first login!
```

---

## First Time Setup (Admin Only)

### Step 1: Create Batches
1. Login as admin
2. Go to **Batches** tab
3. Click **Create New Batch**
4. Enter batch name (e.g., "Batch A", "CSE-2024")
5. Click **Create Batch**

### Step 2: Add Students
1. Go to **Students** tab
2. Click **Import Students from Excel**
3. Select Excel file with student data
4. Students assigned to batches

### Step 3: Create Teachers
1. Go to **Assignments** tab
2. Click **Create Teacher & Assign Batch**
3. Fill in:
   - **Username**: Unique ID (e.g., teacher001)
   - **Password**: Min 6 characters
   - **Role**: Choose Attendance or Batch Teacher
   - **Batch**: Select from dropdown
4. Click **Create & Assign**

---

## Using the App

### 👨‍🏫 As Attendance Teacher

**Mark Daily Attendance:**
1. Login with your credentials
2. Select a batch from dropdown
3. View all students (auto-loads)
4. Use toggle to mark Present/Absent
5. Click **Submit Attendance**
6. Confirm and submit

**Benefits:**
- Access to ALL batches
- No need to wait for admin assignment
- Covers more students

---

### 👥 As Batch Teacher

**Record Absence Follow-ups:**
1. Login with your credentials
2. Select date and batch
3. View absent students
4. Click **Record Follow-Up** on a student
5. Enter absence reason (e.g., "Medical - Fever")
6. Upload proof (optional but recommended):
   - **Capture Photo**: Use camera
   - **Upload Document**: Choose image/PDF
7. Click **Save Follow-Up**

**Proof File Types:**
- ✅ Images: JPG, JPEG, PNG
- ✅ Documents: PDF
- ✅ Max size: 10MB

---

## Common Tasks

### Create a Batch
1. Admin Dashboard → **Batches** tab
2. Click **Create New Batch**
3. Enter name, click **Create**
4. ✓ Batch ready to use

### Assign Teacher to Batch
1. Admin Dashboard → **Assignments** tab
2. Click **Create Teacher & Assign Batch**
3. Fill details, select batch
4. Click **Create & Assign**
5. ✓ Teacher can now login and work

### Mark Attendance
1. Attendance Teacher → Select batch
2. View student list (auto-loads)
3. Toggle each student
4. Review counts
5. Click **Submit Attendance**
6. ✓ Attendance recorded

### Record Follow-Up with Proof
1. Batch Teacher → Select date & batch
2. Click **Record Follow-Up** on student
3. Enter reason
4. Upload image or PDF
5. Click **Save Follow-Up**
6. ✓ Follow-up saved with proof

---

## Error Messages - Quick Fix

| Error | Fix |
|-------|-----|
| "Invalid credentials" | Check username/password |
| "Role mismatch" | Ensure correct login for your role |
| "Please select a batch" | Select batch before submitting |
| "Batch name already exists" | Use different name |
| "Password too short" | Use at least 6 characters |
| "File size too large" | Use smaller file (max 10MB) |

---

## Important Notes

### Attendance Teacher
- ✅ Can access ALL batches now (new feature!)
- ✅ Attendance locked after 24 hours
- ✅ Cannot edit old records
- ✓ Submit daily for best results

### Batch Teacher
- ✅ Upload proofs for documentation
- ✅ Proofs saved with student records
- ✅ Can use within 24 hours
- ✓ Record complete information

### Admin
- ✅ Can reset user passwords
- ✅ Can delete/modify batches
- ✅ Can create multiple roles
- ✓ Responsible for data integrity

---

## Tips & Best Practices

### Attendance
- ✓ Mark attendance daily
- ✓ Submit before end of day
- ✓ Review counts before submitting
- ✓ Check for locked records

### Proofs
- ✓ Upload clear, readable files
- ✓ Use PDF for official documents
- ✓ Use images for photos
- ✓ Keep file sizes small

### Security
- ✓ Change default passwords
- ✓ Never share credentials
- ✓ Logout after use
- ✓ Use strong passwords

---

## Database

The app uses local SQLite database:
- **Automatic backup**: None (manual recommended)
- **Data stored**: Device local storage
- **Encryption**: None (recommend adding)

---

## Getting Help

### Check Documentation
1. **QUICK_REFERENCE.md** - Complete user guide
2. **IMPROVEMENTS.md** - What changed
3. **DEPLOYMENT_SUMMARY.md** - Technical details

### Troubleshooting
1. Restart the app
2. Check your internet connection
3. Verify credentials
4. Check file formats/sizes
5. Contact admin

---

## Next Steps

### Immediate
- [ ] Change admin password
- [ ] Create initial batches
- [ ] Import student list
- [ ] Create teacher accounts

### Daily
- [ ] Mark attendance (Attendance Teachers)
- [ ] Record follow-ups (Batch Teachers)
- [ ] Upload proofs as needed
- [ ] Review reports (Admins)

### Weekly
- [ ] Check attendance trends
- [ ] Review follow-up status
- [ ] Update teacher assignments if needed

---

## Features at a Glance

| Feature | Attendance Teacher | Batch Teacher | Admin |
|---------|---|---|---|
| Mark Attendance | ✅ | ❌ | ✅ |
| All Batches | ✅ (NEW!) | ❌ | ✅ |
| Upload Proofs | ❌ | ✅ (NEW!) | ✅ |
| Record Follow-up | ❌ | ✅ | ✅ |
| View Reports | ✅ | ❌ | ✅ |
| Create Batches | ❌ | ❌ | ✅ |
| Create Teachers | ❌ | ❌ | ✅ |

---

## Version Information

**Current Version**: 1.1.0  
**Release Date**: January 2, 2026  
**Status**: ✅ Ready for Production  

**Key Improvements:**
- Attendance teacher has full batch access
- Batch teacher proof upload system
- Comprehensive form validation
- Better error messages
- Enhanced user experience

---

## Support

For issues:
1. Read the error message carefully
2. Check QUICK_REFERENCE.md
3. Restart the app
4. Contact your admin

---

**Last Updated**: January 2, 2026  
**Prepared for**: GFM Team  
**Status**: READY TO DEPLOY ✅
