import * as aiClient from './ai_client';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://10.44.40.102:5000';

const callAPI = async (endpoint, payload = {}) => {
  try {
    const res = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    if (!res.ok) throw new Error(`API Error: ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn(`Backend call to ${endpoint} failed, using client-side AI fallback.`);
    // Client-side fallbacks for AI tasks
    if (endpoint === '/predict') return aiClient.predictGradeClient(payload);
    if (endpoint === '/analyze-performance') return aiClient.analyzePerformanceClient(payload);
    if (endpoint === '/generate-quiz') return aiClient.generateQuizClient(payload);
    if (endpoint === '/general-chat') return aiClient.generalChatClient(payload.message, payload.context);
    
    throw err;
  }
};

// --- Health Check ---
export const checkHealth = async () => {
  try {
    const res = await fetch(`${API_BASE_URL}/health`);
    return await res.json();
  } catch (e) {
    return { status: 'offline', message: 'Using Client-Side AI Engine' };
  }
};

// --- Predict Student Grade & Risk ---
export const predictGrade = (data) => aiClient.predictGradeClient(data);

// --- AI Performance Analysis ---
export const analyzePerformance = (data) => aiClient.analyzePerformanceClient(data);

// --- AI Quiz Generator ---
export const generateQuiz = (data) => aiClient.generateQuizClient(data);

// --- AI Lesson Plan Generator ---
export const generateLessonPlan = (data) => aiClient.generalChatClient(`Generate a lesson plan for: ${JSON.stringify(data)}`, 'teacher');

// --- AI Flashcard Generator ---
export const generateFlashcards = (data) => aiClient.analyzePerformanceClient({ ...data, task: 'flashcards' });

// --- AI Study Plan Generator ---
export const generateStudyPlan = (data) => aiClient.generalChatClient(`Generate a study plan for: ${JSON.stringify(data)}`, 'teacher');

// --- AI General Chat (Doubts) ---
export const generalChat = (message, context = 'teacher') => aiClient.generalChatClient(message, context);

// --- AI Smart Schedule ---
export const generateSmartSchedule = (data) => aiClient.generalChatClient(`Generate a smart schedule: ${JSON.stringify(data)}`, 'teacher');

// --- AI Parent Report ---
export const generateParentReport = (data) => aiClient.generalChatClient(`Generate a parent report: ${JSON.stringify(data)}`, 'parent');

// --- Data CRUD Operations (Direct Firestore Fallback) ---
// Note: App.jsx mostly uses direct Firestore listeners, these are legacy or fallbacks.
export const fetchStudents = async () => {
  try {
    const res = await fetch(`${API_BASE_URL}/api/students`);
    return await res.json();
  } catch (e) { return []; }
};

export const fetchAllUsers = async () => {
  try {
    const res = await fetch(`${API_BASE_URL}/api/users`);
    return await res.json();
  } catch (e) { return []; }
};

export const fetchClasses = async () => {
  try {
    const res = await fetch(`${API_BASE_URL}/api/classes`);
    return await res.json();
  } catch (e) { return []; }
};

export const fetchAssignments = async () => {
  try {
    const res = await fetch(`${API_BASE_URL}/api/assignments`);
    return await res.json();
  } catch (e) { return []; }
};

export const fetchPredictions = async () => {
  try {
    const res = await fetch(`${API_BASE_URL}/api/predictions`);
    return await res.json();
  } catch (e) { return []; }
};

export const markAttendance = async (data) => {
  // Try backend first for centralized logging, else it's handled by direct Firestore in App.jsx (if implemented)
  return callAPI('/api/attendance', data);
};

export const checkSystemStatus = async () => {
  try {
    const res = await fetch(`${API_BASE_URL}/api/system-status`);
    return await res.json();
  } catch (e) {
    return { status: 'online', backend: 'Client-Side (Standalone)', database: 'Firestore (Direct)' };
  }
};

