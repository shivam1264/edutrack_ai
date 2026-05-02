import { db } from './firebase';
import { collection, getDocs } from 'firebase/firestore';

async function debugClasses() {
  console.log("Fetching classes...");
  const snap = await getDocs(collection(db, 'classes'));
  snap.docs.forEach(d => {
    console.log(`Class ID: ${d.id}`);
    console.log(`Data:`, d.data());
  });
  
  console.log("\nFetching students...");
  const uSnap = await getDocs(collection(db, 'users'));
  const students = uSnap.docs.filter(d => d.data().role === 'student');
  students.forEach(d => {
    console.log(`Student: ${d.data().name}, ClassID: ${d.data().class_id}, ClassIdProp: ${d.data().classId}`);
  });
}

debugClasses();
