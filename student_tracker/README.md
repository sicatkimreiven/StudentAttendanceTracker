# Student Attendance Tracker

A cross-platform mobile application built with Flutter, Node.js, and Firebase to digitize student attendance tracking, generate reports, and notify parents of absences.

## Features
- **Teacher Dashboard:** Mark students present or absent securely.
- **Admin Dashboard:** View real-time attendance summaries and reports.
- **Push Notifications:** Node.js backend listens to Firestore and triggers alerts for absentees.
- **Offline Mode:** Saves attendance locally if internet is unavailable.

## Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Node.js (Express)
- **Database:** Firebase (Firestore & Authentication)

## How to Run
1. Clone this repository.
2. **Frontend:** Run `flutter pub get`, then `flutter run -d chrome`.
3. **Backend:** Navigate to `backend/`, run `npm install`, add your `serviceAccountKey.json`, then run `node server.js`.

## Live Demo
You can access the live web version of the app here: [https://student-attendance-track-d259c.web.app](https://student-attendance-track-d259c.web.app)

## Key Features
- **Teacher Portal:** Create sections, get join codes, view all students, search/sort students, and view detailed attendance histories.
- **Parent Portal:** Enroll students using class codes, view their child's assigned section, and track their full attendance history.
- **Offline Mode:** Works seamlessly without internet by saving locally and syncing later.