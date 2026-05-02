
import { db } from './firebase';
import { collection, getDocs, limit, query } from 'firebase/firestore';

async function debugQuizResults() {
  console.log("Fetching quiz_results...");
  const q = query(collection(db, 'quiz_results'), limit(5));
  const snap = await getDocs(q);
  if (snap.empty) {
    console.log("No documents in quiz_results collection.");
  } else {
    snap.docs.forEach(doc => {
      console.log("Doc ID:", doc.id);
      console.log("Data:", JSON.stringify(doc.data(), null, 2));
    });
  }
}

debugQuizResults();
