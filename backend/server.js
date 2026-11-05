const express = require('express');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const cors = require('cors');

const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();
const app = express();

app.use(cors());
app.use(express.json());

// API Endpoint to receive requests from the Flutter App
app.post('/notify-absence', async (req, res) => {
  const { studentName, parentToken } = req.body;

  if (!parentToken) {
    return res.status(400).send({ success: false, message: 'No parent token provided' });
  }

  try {
    const message = {
      notification: {
        title: '🚨 Absence Alert',
        body: `${studentName} was marked absent today.`,
      },
      token: parentToken,
    };

    const response = await getMessaging().send(message);
    console.log('✅ Successfully sent notification:', response);
    res.status(200).send({ success: true, message: 'Notification sent!' });
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    res.status(500).send({ success: false, error: error.message });
  }
});

// Keep the Firestore listener for your terminal logs
db.collection('attendance_records').onSnapshot((snapshot) => {
  snapshot.docChanges().forEach((change) => {
    if (change.type === 'added') {
      const record = change.doc.data();
      const absentStudents = record.students.filter(student => student.isPresent === false);
      if (absentStudents.length > 0) {
        console.log(`\n🚨 [ALERT] Absentees detected for class on date: ${record.date}`);
        absentStudents.forEach(student => {
          console.log(`📱 Ready to notify parent of: ${student.name}`);
        });
      }
    }
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 Backend server running on http://localhost:${PORT}`);
});