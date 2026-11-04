const express = require('express');
const admin = require('firebase-admin'); // Make sure this is 'firebase-admin'
const cors = require('cors');

// 1. Initialize Firebase Admin with the Service Account Key
// Make sure the serviceAccountKey.json file is in the same folder as this file!
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const app = express();

app.use(cors());
app.use(express.json());

// 2. Simple API health check endpoint
app.get('/', (req, res) => {
  res.send('Student Tracker Backend is running perfectly!');
});

// 3. Listen for new attendance records in Firestore
// This acts as the trigger for your Push Notifications requirement
console.log("Starting backend server and listening to Firestore...");

db.collection('attendance_records').onSnapshot((snapshot) => {
  snapshot.docChanges().forEach((change) => {
    
    // We only care when a NEW attendance record is added
    if (change.type === 'added') {
      const record = change.doc.data();
      
      // Check if there are any students marked as absent (isPresent: false)
      const absentStudents = record.students.filter(student => student.isPresent === false);
      
      if (absentStudents.length > 0) {
        console.log(`\n🚨 [ALERT] Absentees detected for class on date: ${record.date}`);
        
        absentStudents.forEach(student => {
          console.log(`📱 Triggering Push Notification to Parent of: ${student.name}`);
          
          // IN A REAL APP: 
          // You would query Firestore here to get the parent's FCM device token,
          // and then use admin.messaging().send() to send the actual notification.
        });
      } else {
        console.log(`\n✅ [INFO] All students present for date: ${record.date}`);
      }
    }
  });
});

// 4. Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 Backend server running on http://localhost:${PORT}`);
  console.log(`Waiting for new attendance records to trigger notifications...\n`);
});