// ─── EduTrack AI - Python Backend API Service ─────────────────────────────────
// All API calls to the Flask backend (predict_api.py) go through this file.
// Backend runs on: http://localhost:5000 (or deployed URL)

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000';

const callAPI = async (endpoint, payload = {}) => {
  const res = await fetch(`${API_BASE_URL}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(`API Error: ${res.status}`);
  return res.json();
};

// ─── Health Check ──────────────────────────────────────────────────────────────
export const checkHealth = async () => {
  const res = await fetch(`${API_BASE_URL}/health`);
  return res.json();
};

// ─── Predict Student Grade & Risk ─────────────────────────────────────────────
export const predictGrade = (data) =>
  callAPI('/predict', data);

// ─── AI Performance Analysis ──────────────────────────────────────────────────
export const analyzePerformance = (data) =>
  callAPI('/analyze-performance', data);

// ─── AI Quiz Generator ────────────────────────────────────────────────────────
export const generateQuiz = (data) =>
  callAPI('/generate-quiz', data);

// ─── AI Lesson Plan Generator ─────────────────────────────────────────────────
export const generateLessonPlan = (data) =>
  callAPI('/generate-lesson-plan', data);

// ─── AI Flashcard Generator ───────────────────────────────────────────────────
export const generateFlashcards = (data) =>
  callAPI('/generate-flashcards', data);

// ─── AI Study Plan Generator ──────────────────────────────────────────────────
export const generateStudyPlan = (data) =>
  callAPI('/generate-study-plan', data);

// ─── AI General Chat (Doubts) ─────────────────────────────────────────────────
export const generalChat = (message, context = 'teacher') =>
  callAPI('/general-chat', { message, context });

// ─── AI Smart Schedule ────────────────────────────────────────────────────────
export const generateSmartSchedule = (data) =>
  callAPI('/generate-smart-schedule', data);

// ─── AI Parent Report ─────────────────────────────────────────────────────────
export const generateParentReport = (data) =>
  callAPI('/generate-monthly-report', data);

// ─── Data CRUD Operations (New Architecture) ──────────────────────────────────
export const fetchStudents = async () => {
  const res = await fetch(`${API_BASE_URL}/api/students`);
  return res.json();
};

export const fetchAllUsers = async () => {
  const res = await fetch(`${API_BASE_URL}/api/users`);
  return res.json();
};

export const fetchClasses = async () => {
  const res = await fetch(`${API_BASE_URL}/api/classes`);
  return res.json();
};

export const fetchAssignments = async () => {
  const res = await fetch(`${API_BASE_URL}/api/assignments`);
  return res.json();
};

export const fetchPredictions = async () => {
  const res = await fetch(`${API_BASE_URL}/api/predictions`);
  return res.json();
};

export const markAttendance = (data) =>
  callAPI('/api/attendance', data);

export const checkSystemStatus = async () => {
  const res = await fetch(`${API_BASE_URL}/api/system-status`);
  return res.json();
};
