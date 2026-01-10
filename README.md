# GFM Backend (Node + Express + MongoDB Atlas)

This repository provides a centralized backend matching the existing SQLite app logic.

Quick start

1. Copy `.env.example` to `.env` and fill `MONGODB_URI` and `JWT_SECRET`.
2. Install dependencies:

```bash
npm install
```

3. Start server:

```bash
npm start
```

Seed: on first run a default admin (username: `admin`, password: `admin123`) is created.

APIs (high level)

- POST /api/auth/login {username,password} -> {token}
- Users (admin): CRUD under /api/users
- Batches: /api/batches
- Students: /api/students
- Assignments: /api/assignments
- Attendance: /api/attendance and /api/attendance/batch
- Follow-ups: /api/followups
- Reports: /api/reports/attendance

Deployment

- Use MongoDB Atlas free tier to create a cluster and set `MONGODB_URI`.
- Deploy to Render or Railway (free tiers) by connecting GitHub repo and setting env vars `MONGODB_URI` & `JWT_SECRET`.

Security & privacy

- Passwords are hashed with bcrypt.
- JWT used for auth; avoid long-lived tokens in production.
- Only minimal necessary fields stored.

Notes

- The code enforces the same business rules: unique attendance, 24-hour lock, single follow-up per attendance, assignment checks for marking/viewing.
