import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyAr3KS4FnywgFNwq655sA4m1F47B6fBp50",
  authDomain: "edutrack-ai-942c2.firebaseapp.com",
  projectId: "edutrack-ai-942c2",
  storageBucket: "edutrack-ai-942c2.firebasestorage.app",
  messagingSenderId: "943106194319",
  appId: "1:943106194319:web:5cf0afda8c8ea44be4a9fa",
  measurementId: "G-RXJHP2RZPS"
};

import { getStorage } from "firebase/storage";

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
export const storage = getStorage(app);

// Secondary app for managing user creation without logging out current user
const secondaryApp = initializeApp(firebaseConfig, "Secondary");
export const secondaryAuth = getAuth(secondaryApp);
