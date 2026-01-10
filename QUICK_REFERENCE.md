# GFM App - Quick Reference Guide

## User Roles & Permissions

### 👨‍💼 Admin
- Create and manage batches
- Create teachers (Attendance Teachers & Batch Teachers)
- Assign teachers to batches
- View attendance reports
- View dashboard with statistics

### 📝 Attendance Teacher
- **NEW**: Access to ALL batches (no assignment needed)
- Mark daily attendance for students
- View attendance summary by date
- Generate attendance reports

### 👥 Batch Teacher
- View absent students for a specific date
- **NEW**: Upload proof (images or PDFs) for absence follow-ups
- Record absence reasons with proof attachments
- Call/Email students and parents
- Track follow-up completion

---

## Key Features & How to Use

### 1. ATTENDANCE MARKING (Attendance Teacher)

**Step 1**: Login with your credentials
- Username & Password required
- Role must be "Attendance Teacher"

**Step 2**: Select a Batch
- Drop-down shows all available batches
- No admin assignment needed!

**Step 3**: Mark Attendance
- Use toggle switch to mark Present (✓) or Absent (✗)
- See real-time count updates
- Locked records (24h old) cannot be edited

**Step 4**: Submit
- Review counts in confirmation dialog
- Click "Submit Attendance"
- Success message shows number of records updated

### 2. ABSENCE FOLLOW-UP & PROOF UPLOAD (Batch Teacher)

**Step 1**: Login as Batch Teacher
- Username & Password required
- Role must be "Batch Teacher"

**Step 2**: Select Date & Batch
- Choose the date for absence follow-up
- Select assigned batch
- View absent students list

**Step 3**: Record Follow-Up
- Click "Record Follow-Up" on a student
- Enter absence reason (minimum 5 characters)
- **NEW**: Upload proof (image or PDF)

**Step 4**: Upload Proof
- Option 1: **Capture Photo** - Use phone camera
- Option 2: **Upload Document** - Select image/PDF from files
- Max file size: 10MB
- Supported formats: JPG, JPEG, PNG, PDF

**Step 5**: Save
- Proof is saved alongside attendance record
- Confirmation message shows success
- Follow-up marked as complete

---

## Validation Rules

### Attendance Teacher - Submission
- ✓ Batch must be selected
- ✓ Student list cannot be empty
- ✓ At least one student must have valid attendance
- ✓ Locked records are skipped automatically

### Batch Teacher - Follow-Up
- ✓ Absence reason required
- ✓ Minimum 5 characters in reason
- ✓ Proof is optional but recommended
- ✓ Max file size: 10MB

### Admin - Batch Creation
- ✓ Batch name required
- ✓ Minimum 3 characters
- ✓ Must be unique (no duplicates)

### Admin - Teacher Creation
- ✓ Username required (min 3 characters, unique)
- ✓ Password required (min 6 characters)
- ✓ Role must be selected (Attendance or Batch Teacher)
- ✓ Must assign to a batch
- ✓ Batch must exist first

---

## Error Messages & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "Invalid credentials" | Wrong username/password | Check your login details |
| "Role mismatch" | Your account is for different role | Contact admin for correct account |
| "Batch name must be at least 3 characters" | Too short | Enter longer batch name |
| "Username already exists" | Username taken | Use different username |
| "Password must be at least 6 characters" | Too short | Use stronger password |
| "Please select a batch" | No batch chosen | Select batch from dropdown |
| "File size must be less than 10MB" | File too large | Choose smaller file |
| "All records are locked" | All attendance 24h+ old | Cannot edit old records |

---

## Batch Teacher - Proof Upload Guide

### Supported File Types
- ✅ **Images**: JPG, JPEG, PNG
  - Medical photos
  - Doctor's letter photos
  - Student ID proof
  
- ✅ **Documents**: PDF
  - Medical certificates
  - Official letters
  - Hospital discharge papers

### File Upload Process
1. Click "Record Follow-Up" on student
2. Enter absence reason (e.g., "Medical - Fever")
3. Click "Capture Photo" OR "Upload Document"
4. Take picture / Select file
5. Preview appears automatically
6. Click "Save Follow-Up"
7. Success! Proof is saved

### Best Practices
- ✓ Take clear, well-lit photos
- ✓ Ensure documents are readable
- ✓ Name files descriptively
- ✓ Keep file sizes reasonable
- ✓ Upload within 24 hours if possible

---

## Dashboard Statistics (Admin)

### Quick Stats
- **Total Students**: Count of all enrolled students
- **Batches**: Number of active batches
- **Teachers**: Unique teacher count
- **Assignments**: Total batch-teacher assignments

### Attendance Summary (by Date)
- **Present**: Students marked present
- **Absent**: Students marked absent
- **Rate**: Percentage of present students
- **Select Date**: View historical data

---

## Reports

### Attendance Reports (Admin)
- Select date range
- Filter by batch (optional)
- View detailed attendance records
- Export to file (planned feature)

### Follow-Up History (Batch Teacher)
- See all recorded follow-ups
- View proof attachments
- Track completion status

---

## Keyboard Shortcuts & Tips

### Login Screen
- Tab: Move between fields
- Enter: Submit login
- Escape: Clear form

### Attendance Marking
- Select Batch → View students loads automatically
- Toggle Switch: Quick Present/Absent change
- Review counts before submit

### File Upload
- PNG/JPG: Best for photos (smaller size)
- PDF: Best for official documents
- Max resolution: 1920x1080

---

## Security Tips

### Password Management
- Use minimum 6 characters (preferably 8+)
- Mix uppercase, lowercase, numbers
- Never share your password
- Change password regularly

### Data Privacy
- Proofs are stored locally on phone
- Attendance records are secured in database
- Always logout after use
- Clear app cache if storage is full

---

## Troubleshooting

### App Won't Login
- ✓ Check internet connection
- ✓ Verify username & password
- ✓ Ensure correct role selected
- ✓ Contact admin if account not found

### Attendance Won't Submit
- ✓ Select a batch first
- ✓ Ensure students are loaded
- ✓ Check for locked records (24h old)
- ✓ Verify at least one student is marked

### File Upload Fails
- ✓ Check file size (max 10MB)
- ✓ Ensure file format is supported
- ✓ Check device storage space
- ✓ Try uploading different file

### Database Issues
- ✓ Force close and reopen app
- ✓ Clear app cache
- ✓ Restart device
- ✓ Contact admin if persists

---

## Attendance Teacher - All Batches Access

### What Changed
- **Before**: Could only see assigned batches
- **Now**: Can see and mark attendance for ALL batches

### Benefits
- ✓ More flexibility in scheduling
- ✓ No dependency on admin assignment
- ✓ Can help other batches if needed
- ✓ Better attendance coverage

### How It Works
- Login as Attendance Teacher
- Drop-down shows ALL available batches
- Select any batch to mark attendance
- Mark attendance normally

---

## Admin - Teacher Role Assignment

### Two Types of Teachers Available

#### 1️⃣ Attendance Teacher
- Marks daily attendance
- Accesses all batches
- Views attendance summaries
- Generates reports

#### 2️⃣ Batch Teacher
- Manages absence follow-ups
- Uploads proof of absence
- Contacts students/parents
- Tracks completion

### Creating Teachers
1. Go to Admin → Assignments tab
2. Click "Create Teacher & Assign Batch"
3. Fill in details:
   - Username (unique)
   - Display Name (optional)
   - Password (min 6 chars)
   - Select Role
   - Select Batch
4. Click "Create & Assign"
5. Success! Teacher can now login

---

## Files & Data Storage

### Where Data is Stored
- **Database**: SQLite (local device)
- **Proofs**: App Documents folder
- **Backups**: None (manual backup recommended)

### Proof File Locations
- Images: `/documents/proofs/proof_[timestamp].jpg`
- PDFs: `/documents/proofs/proof_[timestamp].pdf`

### Data Retention
- Attendance records: Permanent
- Proofs: Permanent
- Locked records: Cannot edit after 24 hours

---

## Performance Tips

### For Faster Operation
- ✓ Close unused apps
- ✓ Maintain 500MB+ free space
- ✓ Use WiFi for large file uploads
- ✓ Clear app cache monthly

### Database
- ✓ Compact database: Restart app monthly
- ✓ Large batches: Use pagination
- ✓ Reports: Generate during off-hours

---

## Contact & Support

### For Help
1. Check error message carefully - it has guidance
2. Review this guide (search by error)
3. Contact your admin
4. Provide:
   - Your role
   - What you were doing
   - Error message received

### Admin Contact
- Username: admin
- Default Password: admin123
- Can reset other users' passwords

---

**Version**: 1.1.0
**Last Updated**: January 2, 2026
**Next Update**: [Planned features will be added here]
