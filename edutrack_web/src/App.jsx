import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
  checkHealth,
  analyzePerformance,
  generateQuiz,
  generateLessonPlan,
  generalChat,
  predictGrade,
  fetchStudents,
  fetchClasses,
  fetchAssignments,
  fetchAllUsers,
  fetchPredictions,
  markAttendance,
  checkSystemStatus
} from './services/api';
import { auth, db, storage, secondaryAuth } from './firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import {
  collection,
  query,
  onSnapshot,
  addDoc,
  serverTimestamp,
  where,
  doc,
  setDoc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  deleteDoc,
  updateDoc,
  Timestamp,
  collectionGroup
} from "firebase/firestore";
import { onAuthStateChanged, signOut, createUserWithEmailAndPassword } from 'firebase/auth';
import {
  LayoutDashboard,
  Users,
  BookOpen,
  Calendar,
  Bell,
  Settings,
  Search,
  UserCircle,
  TrendingUp,
  Clock,
  LogOut,
  ShieldCheck,
  ShieldAlert,
  Cpu,
  Brain,
  MapPin,
  Globe,
  Grid,
  BarChart3,
  History,
  HeartPulse,
  MessageSquare,
  Trash,
  Edit2,
  AlertTriangle,
  Database,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ToggleRight,
  PieChart as LucidePieChart,
  CheckCircle,
  FileText,
  HelpCircle,
  Zap,
  GraduationCap,
  Camera,
  Megaphone,
  PanelLeftClose,
  PanelLeft,
  Phone,
  XCircle,
  Layers,
  PlusCircle,
  ClipboardList
} from 'lucide-react';
import {
  PieChart, Pie, Cell,
  BarChart, Bar,
  AreaChart, Area,
  Radar, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis,
  XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid
} from 'recharts';
import { motion } from 'framer-motion';
import Login from './Login';
import Announcements from './components/Announcements';
import Messages from './components/Messages';
import QuizResults from './components/QuizResults';
import StudentAnalytics from './components/StudentAnalytics';
import SchoolAnalytics from './components/SchoolAnalytics';
import AssignmentsHub from './components/AssignmentsHub';
import AttendanceHub from './components/AttendanceHub';
import IntelligenceHub from './components/IntelligenceHub';
import RiskMonitorHub from './components/RiskMonitorHub';
import DoubtHub from './components/DoubtHub';
import QuizHub from './components/QuizHub';
import BulkGradingHub from './components/BulkGradingHub';
import logo from './assets/Edu_track-logo.png';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }
  componentDidCatch(error, errorInfo) {
    console.error("ErrorBoundary caught an error", error, errorInfo);
  }
  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: '40px', background: '#1e293b', color: 'white', minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <h1 style={{ color: '#f43f5e', fontSize: '48px', marginBottom: '20px' }}>System Crash Detected</h1>
          <p style={{ fontSize: '18px', opacity: 0.8, marginBottom: '32px' }}>{this.state.error?.toString()}</p>
          <button onClick={() => window.location.reload()} style={{ padding: '16px 32px', background: '#3b82f6', border: 'none', borderRadius: '12px', color: 'white', fontWeight: 'bold', cursor: 'pointer' }}>Reboot System</button>
        </div>
      );
    }
    return this.props.children;
  }
}

// App.jsx continued...
function App() {
  console.log("App Rendering...");
  const [user, setUser] = useState(null);
  const [role, setRole] = useState(null);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [stats, setStats] = useState({ students: 0, assignments: 0, classes: 0 });
  const [classes, setClasses] = useState([]);
  const [students, setStudents] = useState([]);
  const [assignments, setAssignments] = useState([]);
  const [recentActivity, setRecentActivity] = useState([]);
  const [selectedClass, setSelectedClass] = useState(null);
  const [loading, setLoading] = useState(true);
  const [attendanceArchive, setAttendanceArchive] = useState([]);
  const [allUsers, setAllUsers] = useState([]);
  const [newMemberRole, setNewMemberRole] = useState('student');
  const [predictions, setPredictions] = useState([]);


  const [isAnalyzing, setIsAnalyzing] = useState(false);

  const [showIntelligenceResults, setShowIntelligenceResults] = useState(false);
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'dark');
  const [userSearchQuery, setUserSearchQuery] = useState('');
  const [userRoleFilter, setUserRoleFilter] = useState('student');
  const [attendanceClassFilter, setAttendanceClassFilter] = useState('');
  const [teacherStats, setTeacherStats] = useState({});
  const [alertTarget, setAlertTarget] = useState('all');
  const [alertClassId, setAlertClassId] = useState('');
  const [doubtStats, setDoubtStats] = useState({ total: 0, answered: 0, pending: 0 });
  const [timetables, setTimetables] = useState([]);
  const [timetableClassFilter, setTimetableClassFilter] = useState('');
  const [timetableDay, setTimetableDay] = useState('Monday');
  const [showAddPeriodModal, setShowAddPeriodModal] = useState(false);
  const [editPeriodIndex, setEditPeriodIndex] = useState(null);
  const [backendError, setBackendError] = useState(null);
  const [backendOnline, setBackendOnline] = useState(false);
  const [isBackendChecking, setIsBackendChecking] = useState(true);
  const [doubts, setDoubts] = useState([]);
  const [quizzes, setQuizzes] = useState([]);
  const [leaves, setLeaves] = useState([]);
  const [lessonPlans, setLessonPlans] = useState([]);
  const [notes, setNotes] = useState([]);
  // --- Backend AI State ---
  const [aiInsights, setAiInsights] = useState(null);
  const [aiInsightsLoading, setAiInsightsLoading] = useState(false);
  const [dashboardAiAnalysis, setDashboardAiAnalysis] = useState(null);
  const [dashboardAiLoading, setDashboardAiLoading] = useState(false);
  const [quizResults, setQuizResults] = useState([]);
  const [aiQuizLoading, setAiQuizLoading] = useState(false);
  const [aiPlanLoading, setAiPlanLoading] = useState(false);
  const [generatedPlan, setGeneratedPlan] = useState('');
  const [aiDoubtLoading, setAiDoubtLoading] = useState({});
  const [fullUserData, setFullUserData] = useState(null);
  const [teacherSpecs, setTeacherSpecs] = useState([]);
  const [teacherClasses, setTeacherClasses] = useState([]);
  const [profileTab, setProfileTab] = useState('identity');
  const [syncingImage, setSyncingImage] = useState(false);
<<<<<<< HEAD
=======
  const [quizDraftQuestions, setQuizDraftQuestions] = useState([]);
  const [isGeneratingQuiz, setIsGeneratingQuiz] = useState(false);
  const [brainDnaData, setBrainDnaData] = useState([]);
  const [healthStatus, setHealthStatus] = useState(null);

  // Assignment States
  const [assignmentFile, setAssignmentFile] = useState(null);
  const [isUploadingAssignment, setIsUploadingAssignment] = useState(false);
  const [assignmentFileUrl, setAssignmentFileUrl] = useState('');
  const [submissions, setSubmissions] = useState([]);
  const [assignmentTab, setAssignmentTab] = useState('all');

>>>>>>> 82a22ca (Professionalize Bulk Grading Hub with Auto-Sync and fix System Crash hook violation)

  // Computed Chart Data
  const [attendanceChartData, setAttendanceChartData] = useState([]);
  const [performanceChartData, setPerformanceChartData] = useState([]);
  const [recentAlerts, setRecentAlerts] = useState([]);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const profileMenuRef = useRef(null);
  const profilePopupRef = useRef(null);

  // Close profile menu on outside click
  useEffect(() => {
    if (!showProfileMenu) return;
    const handleClickOutside = (e) => {
      const clickedInsideButton = profileMenuRef.current && profileMenuRef.current.contains(e.target);
      const clickedInsidePopup = profilePopupRef.current && profilePopupRef.current.contains(e.target);
      if (!clickedInsideButton && !clickedInsidePopup) {
        setShowProfileMenu(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [showProfileMenu]);

  // Settings State
  const [autoNotifyParents, setAutoNotifyParents] = useState(true);
  const [attendanceThreshold, setAttendanceThreshold] = useState(75.0);
  // --- Attendance marking state (React-driven, not DOM-driven) ---
  const [attStatusMap, setAttStatusMap] = useState({}); // { [studentId]: 'present'|'absent'|'late' }
  const [attDate, setAttDate] = useState(new Date().toISOString().split('T')[0]);
  const [attSaving, setAttSaving] = useState(false);
  const [attLoading, setAttLoading] = useState(false);
  const [aiModel, setAiModel] = useState('Gemini-1.5-Pro');
  const [editingUser, setEditingUser] = useState(null);
  const [showEditUserModal, setShowEditUserModal] = useState(false);
  const [editingHub, setEditingHub] = useState(null);
  const [showEditHubModal, setShowEditHubModal] = useState(false);
  const [tempParentChildRoll, setTempParentChildRoll] = useState('');
  const [newParentChildRoll, setNewParentChildRoll] = useState('');

  // Determine which classes this user can see/access
  const visibleClasses = useMemo(() => {
    if (role === 'admin') return classes;
    if (role === 'teacher') {
      const allowedUnits = fullUserData?.academicUnits || [];
      const allowedClassId = fullUserData?.classId || '';
      const allowedIdsFromStr = allowedClassId.split(',').map(s => s.trim()).filter(Boolean);
      const combined = Array.from(new Set([...allowedUnits, ...allowedIdsFromStr]));

      if (combined.length === 0) return []; // No classes allotted

      return classes.filter(c =>
        combined.includes(c.id) ||
        combined.includes(c.displayName)
      );
    }
    return classes; // Fallback
  }, [classes, role, fullUserData]);

  // Ensure selectedClass is valid for teachers
  useEffect(() => {
    if (role === 'teacher' && visibleClasses.length > 0 && !selectedClass) {
      setSelectedClass(visibleClasses[0].id);
    }
  }, [visibleClasses, role, selectedClass]);


  const handleAssignmentFileChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setAssignmentFile(file);
    setIsUploadingAssignment(true);
    try {
      const storageRef = ref(storage, `assignments/${user.uid}/${Date.now()}_${file.name}`);
      await uploadBytes(storageRef, file);
      const url = await getDownloadURL(storageRef);
      setAssignmentFileUrl(url);
    } catch (err) {
      alert('File Upload Failed: ' + err.message);
    } finally {
      setIsUploadingAssignment(false);
    }
  };

  const handleSaveConfig = async () => {

    try {
      await setDoc(doc(db, 'system_config', 'global'), {
        aiModel,
        attendanceThreshold,
        autoNotifyParents,
        updatedAt: serverTimestamp()
      }, { merge: true });

      // Log the activity
      await addDoc(collection(db, 'activity_logs'), {
        action: 'System Configuration Updated',
        type: 'system',
        user: fullUserData?.name || user?.email || 'Admin',
        timestamp: serverTimestamp()
      });

      alert('System configuration synced successfully!');
    } catch (err) {
      console.error('Error saving config:', err);
      alert('Failed to sync configuration.');
    }
  };

  useEffect(() => {
    document.body.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  // --- Backend Health Check on Mount ---
  useEffect(() => {
    checkHealth()
      .then((res) => {
        setBackendOnline(res.status === 'ok' || res.status === 'offline');
        if (res.status === 'offline') console.log("EduTrack: Running in Standalone AI Mode");
      })
      .catch(() => {
        setBackendOnline(true); // Always online in standalone mode
      });
  }, []);

  useEffect(() => {
    const unsubAuth = onAuthStateChanged(auth, (currentUser) => {
      if (currentUser) {
        // Real-time listener for current user's document
        const userDocRef = doc(db, 'users', currentUser.uid);
        const unsubUserDoc = onSnapshot(userDocRef, (docSnap) => {
          if (docSnap.exists()) {
            const data = docSnap.data();
            const userRole = data.role || 'student';

            if (userRole !== 'admin' && userRole !== 'teacher') {
              signOut(auth);
              setUser(null);
              setRole(null);
              alert("Access Denied: Web Dashboard is restricted to Admin & Faculty. Please use the Mobile App.");
            } else {
              setUser(currentUser);
              setRole(userRole);
              setFullUserData({ id: currentUser.uid, ...data });
            }
          } else {
            setUser(null);
            setRole(null);
          }
          setLoading(false);
        });

        return () => unsubUserDoc();
      } else {
        setUser(null);
        setRole(null);
        setLoading(false);
      }
    });
    return () => unsubAuth();
  }, []);

  // History API Integration for Back Button Support
  useEffect(() => {
    const handlePopState = (event) => {
      if (event.state && event.state.tab) {
        setActiveTab(event.state.tab);
      } else {
        const urlParams = new URLSearchParams(window.location.search);
        const tab = urlParams.get('tab') || 'dashboard';
        setActiveTab(tab);
      }
    };

    window.addEventListener('popstate', handlePopState);

    // Set initial state
    const urlParams = new URLSearchParams(window.location.search);
    const initialTab = urlParams.get('tab');
    if (initialTab && initialTab !== activeTab) {
      setActiveTab(initialTab);
    } else if (!window.history.state?.tab) {
      window.history.replaceState({ tab: 'dashboard' }, '', '?tab=dashboard');
    }

    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  useEffect(() => {
    // Compute Teacher Stats reactively from synced arrays
    const newStats = {};
    const teachers = (allUsers || []).filter(u => u.role === 'teacher');

    (teachers || []).forEach(t => {
      newStats[t.id] = {
        doubts: (doubts || []).filter(d => d.answeredBy === (t.name || '')).length,
        notes: (notes || []).filter(n => n.teacherId === t.id).length,
        assigns: (assignments || []).filter(a => a.teacher_id === t.id).length,
        quizzes: (quizzes || []).filter(q => q.teacher_id === t.id).length,
        plans: (lessonPlans || []).filter(p => p.teacherId === t.id).length
      };
    });

    setTeacherStats(newStats);
  }, [allUsers, doubts, notes, assignments, quizzes, lessonPlans]);

  const handleTabChange = (tab) => {
    if (tab !== 'intelligence') {
      setShowIntelligenceResults(false);
      setIsAnalyzing(false);
    }
    window.history.pushState({ tab }, '', `?tab=${tab}`);
    setActiveTab(tab);
  };

  useEffect(() => {
    if (!user) return;

    const fetchData = async () => {
      setBackendError(null);
      try {
        const status = await checkSystemStatus();
        setBackendOnline(true);
        if (status.backend && status.backend.includes('Standalone')) {
          // Silently running in standalone mode
        } else if (status.database && typeof status.database === 'string' && status.database.includes('Disconnected')) {
          setBackendError("Database Node Disconnected in Backend.");
        }
      } catch (err) {
        setBackendOnline(true); // Default to true for client-side AI
      }
    };

    fetchData();

    // ─── Real-time Firestore Synchronizers ──────────────────────────────────
    // Core Collections Sync
    const unsubClasses = onSnapshot(collection(db, 'classes'), (snap) => {
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      setClasses(data);
      setStats(prev => ({ ...prev, classes: data.length }));
    });

    const unsubUsers = onSnapshot(collection(db, 'users'), (snap) => {
      const data = snap.docs.map(d => {
        const userData = d.data();
        return {
          id: d.id,
          ...userData,
          // Mobile uses mastery_score (0-1), Web uses mastery (0-100)
          mastery: userData.mastery ?? (userData.mastery_score ? userData.mastery_score * 100 : 0)
        };
      });
      setAllUsers(data);
      const studentList = data.filter(u => u.role === 'student');
      setStudents(studentList);
      setStats(prev => ({ ...prev, students: studentList.length }));
    });

    const unsubAssignments = onSnapshot(collection(db, 'assignments'), (snap) => {
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      setAssignments(data);
      setStats(prev => ({ ...prev, assignments: data.length }));
    });

    const unsubDoubts = onSnapshot(collection(db, 'doubts'), (snap) => {
      const data = (snap.docs || []).map(d => ({ id: d.id, ...d.data() }));
      setDoubts(data);
      const answered = (data || []).filter(d => d.status === 'answered' || d.status === 'ai_answered').length;
      const pending = (data || []).filter(d => d.status === 'pending').length;
      setDoubtStats({ total: data.length, answered, pending });
    });

    const unsubAttendance = onSnapshot(collection(db, 'attendance'), (snap) => {
      setAttendanceArchive(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubQuizzes = onSnapshot(collection(db, 'quizzes'), (snap) => {
      setQuizzes(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubNotes = onSnapshot(collection(db, 'notes'), (snap) => {
      setNotes(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubLessonPlans = onSnapshot(collection(db, 'lesson_plans'), (snap) => {
      setLessonPlans(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubTimetable = onSnapshot(collection(db, 'timetable'), (snap) => {
      setTimetables(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubQuizResults = onSnapshot(collectionGroup(db, 'quiz_results'), (snap) => {
      setQuizResults((snap.docs || []).map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubSubmissions = onSnapshot(collection(db, 'submissions'), (snap) => {
      setSubmissions((snap.docs || []).map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubLogs = onSnapshot(query(collection(db, 'activity_logs'), orderBy('timestamp', 'desc'), limit(10)), (snap) => {
      setRecentAlerts(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    }, (error) => {
      console.error("Activity logs sync error:", error);
    });

    const unsubConfig = onSnapshot(doc(db, 'system_config', 'global'), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        if (data.aiModel) setAiModel(data.aiModel);
        if (data.attendanceThreshold !== undefined) setAttendanceThreshold(data.attendanceThreshold);
        if (data.autoNotifyParents !== undefined) setAutoNotifyParents(data.autoNotifyParents);
      }
    });

    // Predictions (Real-time Sync)
    const unsubPredictions = onSnapshot(collection(db, 'predictions'), (snap) => {
      setPredictions(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });


    const unsubBrainDna = onSnapshot(collectionGroup(db, 'brain_dna'), (snap) => {
      setBrainDnaData(snap.docs.map(d => {
        const data = d.data();
        const rawMastery = data.mastery ?? data.mastery_score ?? 0;
        return {
          id: d.id,
          ...data,
          mastery: rawMastery <= 1 ? rawMastery * 100 : rawMastery,
          subject: data.subject || 'General'
        };
      }));
    });

    const unsubSystemHealth = onSnapshot(doc(db, 'system_health', 'realtime'), (snap) => {
      if (snap.exists()) setHealthStatus(snap.data());
    });



    return () => {
      unsubClasses();
      unsubUsers();
      unsubAssignments();
      unsubDoubts();
      unsubAttendance();
      unsubQuizzes();
      unsubNotes();
      unsubLessonPlans();
      unsubTimetable();
      unsubQuizResults();
      unsubSubmissions();
      unsubBrainDna();
      unsubPredictions();
      unsubSystemHealth();
      if (typeof unsubLogs === 'function') unsubLogs();
      if (typeof unsubConfig === 'function') unsubConfig();
    };
  }, [user, role, fullUserData]);

  // Trigger AI analysis for the dashboard automatically
  useEffect(() => {
    if (user && (role === 'admin' || role === 'teacher') && !dashboardAiAnalysis && (stats?.students || 0) > 0) {
      const runDashboardAnalysis = async () => {
        setDashboardAiLoading(true);
        try {
          const avgAttendance = (attendanceArchive || []).length > 0
            ? Math.round((attendanceArchive || []).filter(r => r.status === 'present').length / (attendanceArchive || []).length * 100)
            : 85;

          const result = await analyzePerformance({
            task: 'analysis',
            total_students: stats?.students || 0,
            total_teachers: (allUsers || []).filter(u => u.role === 'teacher').length,
            total_assignments: stats?.assignments || 0,
            attendance_pct: avgAttendance,
            high_risk_count: (predictions || []).filter(p => p?.risk_level === 'high').length,
            medium_risk_count: (predictions || []).filter(p => p?.risk_level === 'medium').length,
          });
          setDashboardAiAnalysis(result);
        } catch (e) {
          console.error("Dashboard AI analysis failed", e);
        } finally {
          setDashboardAiLoading(false);
        }
      };
      runDashboardAnalysis();
    }
  }, [user, role, backendOnline, stats, attendanceArchive, predictions, dashboardAiAnalysis]);

  // Process Real-time Data for Charts
  useEffect(() => {
    if (attendanceArchive.length > 0) {
      const grouped = attendanceArchive.reduce((acc, curr) => {
        const date = curr.date?.toDate?.()?.toLocaleDateString('en-US', { weekday: 'short' }) || 'Day';
        if (!acc[date]) acc[date] = { name: date, present: 0, total: 0 };
        acc[date].total++;
        if (curr.status === 'present') acc[date].present++;
        return acc;
      }, {});

      const chartData = Object.values(grouped).map(d => ({
        name: d.name,
        value: Math.round((d.present / d.total) * 100)
      })).slice(-7);
      setAttendanceChartData(chartData);
    } else {
      setAttendanceChartData([
        { name: 'Mon', value: 85 }, { name: 'Tue', value: 88 }, { name: 'Wed', value: 92 },
        { name: 'Thu', value: 87 }, { name: 'Fri', value: 94 }, { name: 'Sat', value: 90 }
      ]);
    }
  }, [attendanceArchive]);

  useEffect(() => {
    if (students.length > 0) {
      const perf = { 'A+': 0, 'A': 0, 'B': 0, 'C': 0 };
      students.forEach(s => {
        // Find student's average quiz performance
        const studentResults = quizResults.filter(r => r.student_id === s.id || r.studentId === s.id);
        let score = 75; // Default

        if (studentResults.length > 0) {
          const totalPct = studentResults.reduce((acc, r) => {
            const pct = r.total > 0 ? (r.score / r.total) * 100 : 0;
            return acc + pct;
          }, 0);
          score = totalPct / studentResults.length;
        } else if (s.mastery) {
          score = s.mastery;
        }

        if (score >= 90) perf['A+']++;
        else if (score >= 75) perf['A']++;
        else if (score >= 60) perf['B']++;
        else perf['C']++;
      });
      setPerformanceChartData(Object.entries(perf).map(([name, count]) => ({ name, count })));
    } else {
      setPerformanceChartData([
        { name: 'A+', count: 12 }, { name: 'A', count: 25 }, { name: 'B', count: 18 }, { name: 'C', count: 8 }
      ]);
    }
  }, [students, quizResults]);

  useEffect(() => {
    if (predictions.length > 0) {
      const alerts = predictions.slice(0, 3).map(p => ({
        msg: p.analysis || 'System Pulse Detected',
        time: 'Just now',
        color: p.risk_level === 'high' ? '#f43f5e' : '#10b981'
      }));
      setRecentAlerts(alerts);
    } else {
      setRecentAlerts([
        { msg: 'Global Attendance Pulse Detected', time: '2m ago', color: '#10b981' },
        { msg: 'New Faculty Node Provisioned', time: '15m ago', color: '#3b82f6' },
        { msg: 'Risk Monitor Flagged 3 Students', time: '1h ago', color: '#f43f5e' }
      ]);
    }
  }, [predictions]);

  if (loading) return <div className="login-container"><h2 className="gradient-text">Loading EduTrack AI...</h2></div>;

  if (!user) {
    return <Login onLogin={(u, r) => { setUser(u); setRole(r); }} />;
  }

  const handleLogout = () => signOut(auth);

  // Load existing attendance from Firestore for the selected class + date
  const loadExistingAttendance = async (classId, dateStr) => {
    if (!classId || !dateStr) return;
    setAttLoading(true);
    try {
      const q = query(
        collection(db, 'attendance'),
        where('class_id', '==', classId),
        where('date_string', '==', dateStr)
      );
      const snap = await getDocs(q);
      const map = {};
      snap.docs.forEach(d => {
        map[d.data().student_id] = d.data().status; // 'present' | 'absent' | 'late'
      });
      setAttStatusMap(map);
    } catch (e) {
      console.error('Error loading attendance:', e);
    }
    setAttLoading(false);
  };

  // Called when class or date changes in attendance tab
  const handleAttClassChange = async (classId) => {
    setSelectedClass(classId);
    setAttStatusMap({});
    if (classId) await loadExistingAttendance(classId, attDate);
  };

  const handleAttDateChange = async (dateStr) => {
    if (!dateStr) return;
    setAttDate(dateStr);
    setAttStatusMap({});
    if (selectedClass) await loadExistingAttendance(selectedClass, dateStr);
  };

  const shiftAttDate = (days) => {
    const d = new Date(attDate);
    d.setDate(d.getDate() + days);
    const newDateStr = d.toISOString().split('T')[0];
    const today = new Date().toISOString().split('T')[0];
    handleAttDateChange(newDateStr);
  };

  const setStudentStatus = (studentId, status) => {
    setAttStatusMap(prev => ({ ...prev, [studentId]: status }));
  };

  const saveAllAttendance = async (classStudents) => {
    if (!selectedClass) return;
    const unmarked = classStudents.filter(s => !attStatusMap[s.id]);
    if (unmarked.length === classStudents.length) {
      alert('Please mark at least one student before saving.');
      return;
    }
    setAttSaving(true);
    try {
      const teacherName = fullUserData?.name || user?.email || 'Web-Teacher';
      for (const s of classStudents) {
        const status = attStatusMap[s.id];
        if (!status) continue; // skip unmarked

        await markAttendance({
          student_id: s.id,
          class_id: selectedClass,
          date_string: attDate,
          status: status,
          marked_by: teacherName
        });
      }
      const saved = classStudents.filter(s => attStatusMap[s.id]).length;
      alert(`Attendance saved for ${saved} student${saved !== 1 ? 's' : ''}! Synced with mobile app.`);
    } catch (e) {
      console.error('Save failed:', e);
      alert('Error saving attendance: ' + e.message);
    }
    setAttSaving(false);
  };

  const renderContent = () => {
<<<<<<< HEAD
=======

    if (!role) return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: '20px' }}>
        <div className="spinning-loader" style={{ width: '40px', height: '40px', border: '3px solid rgba(255,255,255,0.05)', borderTopColor: 'var(--primary)', borderRadius: '50%' }}></div>
        <p style={{ color: 'var(--text-dim)', fontWeight: '700' }}>Synchronizing Security Context...</p>
      </div>
    );

>>>>>>> 82a22ca (Professionalize Bulk Grading Hub with Auto-Sync and fix System Crash hook violation)
    // STUDENT VIEW
    if (role === 'student') {
      return (
        <div style={{ maxWidth: '900px', margin: '0 auto' }}>
          <header style={{ marginBottom: '40px' }}>
            <h2 style={{ fontSize: '32px' }}>Hello, <span className="gradient-text">{user.displayName || 'Student'}</span></h2>
            <p style={{ color: 'var(--text-dim)' }}>Your learning progress at a glance.</p>
          </header>

          <div className="stats-grid">
            <div className="glass-card stat-item">
              <BookOpen color="#3b82f6" />
              <div className="stat-value">{stats.assignments}</div>
              <div className="stat-label">Total Assignments</div>
            </div>
            <div className="glass-card stat-item">
              <Calendar color="#ec4899" />
              <div className="stat-value">92%</div>
              <div className="stat-label">Attendance Record</div>
            </div>
          </div>

          <div className="glass-card" style={{ marginTop: '24px', padding: '24px' }}>
            <h3>Your Recent Assignments</h3>
            <div style={{ marginTop: '16px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {(assignments || []).map(a => (
                <div key={a.id} style={{ padding: '16px', borderRadius: '12px', background: 'rgba(255,255,255,0.03)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontWeight: '600' }}>{String(a.title || 'Untitled')}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-dim)' }}>
                      {String(a.subject || 'General')} | Due: {a.due_date && typeof a.due_date.toDate === 'function' ? a.due_date.toDate().toLocaleDateString() : String(a.due_date || 'TBD')}
                    </div>
                  </div>
                  <button style={{ padding: '8px 16px', fontSize: '12px' }}>View Details</button>
                </div>
              ))}
            </div>
          </div>
        </div>
      );
    }

    // ADMIN/TEACHER VIEW
    switch (activeTab) {
      case 'dashboard':
        if (role === 'teacher') {
          return (
            <>
              <header style={{ marginBottom: '40px' }}>
                <h2 style={{ fontSize: '32px' }}>Faculty <span className="gradient-text">Portal</span></h2>
                <p style={{ color: 'var(--text-dim)' }}>Academic Insights & Class Analytics</p>
              </header>

              {/* AI PERFORMANCE OVERVIEW */}
              {(dashboardAiLoading || dashboardAiAnalysis) && (
                <motion.div
                  initial={{ opacity: 0, y: -20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="glass-card"
                  style={{
                    padding: '24px',
                    marginBottom: '24px',
                    background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.05), rgba(168, 85, 247, 0.05))',
                    border: '1px solid rgba(139, 92, 246, 0.2)',
                    position: 'relative',
                    overflow: 'hidden'
                  }}
                >
                  {dashboardAiLoading ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px', color: 'var(--text-dim)' }}>
                      <div className="spinning-loader" style={{ width: '20px', height: '20px', border: '2px solid rgba(255,255,255,0.1)', borderTopColor: '#8b5cf6', borderRadius: '50%' }}></div>
                      <span style={{ fontSize: '14px', fontWeight: '600' }}>AI is scanning academic nodes...</span>
                    </div>
                  ) : (
                    <>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                          <div style={{ padding: '8px', background: 'rgba(139, 92, 246, 0.1)', borderRadius: '10px', color: '#8b5cf6' }}>
                            <Zap size={20} />
                          </div>
                          <div>
                            <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '800' }}>AI Performance Matrix</h3>
                            <p style={{ margin: 0, fontSize: '11px', color: 'var(--text-dim)' }}>Latest intelligence from Groq Llama-3</p>
                          </div>
                        </div>
                        <div style={{
                          padding: '6px 12px',
                          borderRadius: '20px',
                          fontSize: '11px',
                          fontWeight: '900',
                          background: (dashboardAiAnalysis.risk_level || 'Low').toLowerCase() === 'high' ? 'rgba(239,68,68,0.1)' : 'rgba(16,185,129,0.1)',
                          color: (dashboardAiAnalysis.risk_level || 'Low').toLowerCase() === 'high' ? '#ef4444' : '#10b981',
                          border: `1px solid ${(dashboardAiAnalysis.risk_level || 'Low').toLowerCase() === 'high' ? 'rgba(239,68,68,0.2)' : 'rgba(16,185,129,0.2)'}`
                        }}>
                          RISK: {dashboardAiAnalysis.risk_level || 'LOW'}
                        </div>
                      </div>
                      <p style={{ fontSize: '14px', lineHeight: '1.6', color: 'var(--text-main)', marginBottom: '16px', opacity: 0.9 }}>
                        {dashboardAiAnalysis.summary}
                      </p>
                      <div style={{ display: 'flex', gap: '12px' }}>
                        <button
                          onClick={() => handleTabChange('intelligence')}
                          style={{ padding: '8px 16px', borderRadius: '8px', background: 'rgba(139, 92, 246, 0.1)', color: '#8b5cf6', border: 'none', fontSize: '12px', fontWeight: '700', cursor: 'pointer' }}
                        >
                          View Full AI Report
                        </button>
                        <button
                          onClick={() => { setDashboardAiAnalysis(null); }}
                          style={{ padding: '8px 16px', borderRadius: '8px', background: 'transparent', color: 'var(--text-dim)', border: '1px solid var(--glass-border)', fontSize: '12px', fontWeight: '700', cursor: 'pointer' }}
                        >
                          Re-Analyze
                        </button>
                      </div>
                    </>
                  )}
                </motion.div>
              )}

              <div className="stats-grid">
                {[
                  { label: 'Class Average', value: '78.5%', icon: <TrendingUp size={20} />, color: '#10b981' },
                  { label: 'Total Students', value: stats.students, icon: <Users size={20} />, color: '#3b82f6' },
                  { label: 'Pending Reviews', value: '5', icon: <AlertTriangle size={20} />, color: '#f59e0b' },
                ].map((item, i) => (
                  <motion.div key={i} initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="glass-card stat-item">
                    <div style={{ color: item.color }}>{item.icon}</div>
                    <div className="stat-value">{item.value}</div>
                    <div className="stat-label">{item.label}</div>
                  </motion.div>
                ))}
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', marginTop: '24px' }}>
                {/* Class DNA Radar Chart */}
                <div className="glass-card" style={{ padding: '24px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
                    <div style={{ padding: '8px', background: 'rgba(139, 92, 246, 0.1)', borderRadius: '12px', color: '#8b5cf6' }}>
                      <Brain size={20} />
                    </div>
                    <h3 style={{ margin: 0 }}>Class Knowledge DNA</h3>
                  </div>
                  <div style={{ height: '260px' }}>
                    <ResponsiveContainer width="100%" height="100%">
                      <RadarChart cx="50%" cy="50%" outerRadius="60%" data={(() => {
                        const subjectMap = {};
                        const defaultSubjects = ['Math', 'Science', 'English', 'History', 'Physics', 'Arts'];
                        defaultSubjects.forEach(s => {
                          subjectMap[s] = { subject: s, mastery: 0, count: 0 };
                        });

                        brainDnaData.forEach(d => {
                          const sub = d.subject || 'General';
                          if (!subjectMap[sub]) subjectMap[sub] = { subject: sub, mastery: 0, count: 0 };
                          subjectMap[sub].mastery += (d.mastery || 0);
                          subjectMap[sub].count++;
                        });

                        return Object.values(subjectMap).map(s => ({
                          subject: s.subject,
                          A: s.count > 0 ? Math.round(s.mastery / s.count) : 0,
                          fullMark: 100
                        }));
                      })()}>
                        <PolarGrid stroke="var(--glass-border)" />
                        <PolarAngleAxis dataKey="subject" tick={{ fill: 'var(--text-dim)', fontSize: 14, fontWeight: '800' }} />
                        <PolarRadiusAxis angle={30} domain={[0, 100]} tick={false} axisLine={false} />
                        <Radar
                          name="Class Mastery"
                          dataKey="A"
                          stroke="#8b5cf6"
                          strokeWidth={3}
                          fill="url(#radarGrad)"
                          fillOpacity={0.6}
                          animationDuration={1500}
                        />
                        <Tooltip
                          contentStyle={{ background: 'rgba(15, 23, 42, 0.9)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px', backdropFilter: 'blur(10px)', color: '#fff' }}
                          itemStyle={{ color: '#8b5cf6', fontWeight: '900' }}
                        />
                        <defs>
                          <linearGradient id="radarGrad" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.8} />
                            <stop offset="95%" stopColor="#6366f1" stopOpacity={0.2} />
                          </linearGradient>
                        </defs>
                      </RadarChart>
                    </ResponsiveContainer>
                  </div>
                </div>

                {/* Academic Stars - Compact & Professional */}
                <div className="glass-card" style={{ padding: '16px 18px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h3 style={{ margin: 0, fontSize: '13px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Academic Stars</h3>
                    <div style={{ padding: '4px 8px', borderRadius: '6px', background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', fontSize: '10px', fontWeight: '900' }}>TOP 1%</div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {students.slice(0, 4).map((s, i) => (
                      <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 12px', borderRadius: '10px', background: 'var(--glass-surface)', border: '1px solid var(--glass-border)' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <span style={{ fontSize: '12px', fontWeight: '900', color: '#10b981', opacity: 0.6 }}>0{i + 1}</span>
                          <span style={{ fontWeight: '700', fontSize: '13px', color: 'var(--text-main)' }}>{s.name}</span>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontSize: '13px', fontWeight: '900', color: '#10b981' }}>98%</div>
                          <div style={{ fontSize: '9px', color: 'var(--text-dim)', fontWeight: '600' }}>Mastery</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '24px', marginTop: '24px' }}>
                {/* Attention Needed - Compact & Professional */}
                <div className="glass-card" style={{ padding: '16px 18px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h3 style={{ margin: 0, fontSize: '13px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Critical Nodes</h3>
                    <div style={{ padding: '4px 8px', borderRadius: '6px', background: 'rgba(244, 63, 94, 0.1)', color: '#f43f5e', fontSize: '10px', fontWeight: '900' }}>RISK LIST</div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {students.slice(-4).map((s, i) => (
                      <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 12px', borderRadius: '10px', background: 'var(--glass-surface)', border: '1px solid var(--glass-border)' }}>
                        <span style={{ fontWeight: '700', fontSize: '13px', color: 'var(--text-main)' }}>{s.name}</span>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontSize: '13px', fontWeight: '900', color: '#f43f5e' }}>42%</div>
                          <div style={{ fontSize: '9px', color: 'var(--text-dim)', fontWeight: '600' }}>Under-perf</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Student Directory */}
                <div className="glass-card" style={{ padding: '24px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                    <h3>Student Directory</h3>
                    <div style={{ position: 'relative' }}>
                      <Search size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
                      <input
                        placeholder="Search student..."
                        style={{ padding: '8px 12px 8px 36px', fontSize: '13px', borderRadius: '8px', width: '200px' }}
                      />
                    </div>
                  </div>
                  <div style={{ maxHeight: '250px', overflowY: 'auto' }}>
                    <table style={{ width: '100%', textAlign: 'left' }}>
                      <thead style={{ position: 'sticky', top: 0, background: 'var(--card-bg)', zIndex: 1 }}>
                        <tr style={{ color: 'var(--text-dim)', fontSize: '12px' }}>
                          <th style={{ padding: '12px' }}>STUDENT</th>
                          <th style={{ padding: '12px' }}>CLASS</th>
                          <th style={{ padding: '12px' }}>MASTERY</th>
                        </tr>
                      </thead>
                      <tbody>
                        {(students || []).map(s => {
                          const studentClass = (classes || []).find(c =>
                            c.id === (s.classId || s.class_id) ||
                            c.displayName === (s.classId || s.class_id || s.className)
                          );
                          const className = studentClass
                            ? (studentClass.standard ? (studentClass.section ? `${studentClass.standard} - ${studentClass.section}` : studentClass.standard) : (studentClass.name || studentClass.className || 'Class'))
                            : (s.classId || s.class_id || '-');

                          return (
                            <tr key={s.id} style={{ borderTop: '1px solid var(--glass-border)', fontSize: '14px' }}>
                              <td style={{ padding: '12px', fontWeight: '600' }}>{s.name}</td>
                              <td style={{ padding: '12px' }}>{className}</td>
                              <td style={{ padding: '12px' }}>
                                <div style={{ width: '60px', height: '6px', background: 'rgba(255,255,255,0.1)', borderRadius: '3px' }}>
                                  <div style={{ width: `${s.mastery || 75}%`, height: '100%', background: '#3b82f6', borderRadius: '3px' }} />
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </>
          );
        }

        // Default Admin Dashboard
        return (
          <>
            <header style={{ marginBottom: '40px' }}>
              <h2 style={{ fontSize: '32px' }}>EduTrack <span className="gradient-text">Live Dashboard</span></h2>
              <p style={{ color: 'var(--text-dim)' }}>Interconnected with your Mobile App</p>
            </header>

            {/* AI PERFORMANCE OVERVIEW - Compact */}
            {(dashboardAiLoading || dashboardAiAnalysis) && (
              <motion.div
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                className="glass-card"
                style={{
                  padding: '16px 20px',
                  marginBottom: '20px',
                  background: 'linear-gradient(135deg, rgba(59, 130, 246, 0.05), rgba(16, 185, 129, 0.05))',
                  border: '1px solid rgba(59, 130, 246, 0.2)',
                  position: 'relative',
                  overflow: 'hidden'
                }}
              >
                {dashboardAiLoading ? (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px', color: 'var(--text-dim)' }}>
                    <div style={{ width: '16px', height: '16px', border: '2px solid rgba(255,255,255,0.1)', borderTopColor: '#3b82f6', borderRadius: '50%', animation: 'spin 1s linear infinite' }}></div>
                    <span style={{ fontSize: '13px', fontWeight: '700' }}>Aggregating Matrix Data...</span>
                  </div>
                ) : (
                  <>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ padding: '6px', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '8px', color: '#3b82f6' }}>
                          <Zap size={16} />
                        </div>
                        <div>
                          <h3 style={{ margin: 0, fontSize: '14px', fontWeight: '800' }}>Institutional AI Matrix</h3>
                          <p style={{ margin: 0, fontSize: '10px', color: 'var(--text-dim)' }}>Node Analysis Active</p>
                        </div>
                      </div>
                      <div style={{
                        padding: '4px 10px',
                        borderRadius: '20px',
                        fontSize: '10px',
                        fontWeight: '900',
                        background: (dashboardAiAnalysis.risk_level || 'Low').toLowerCase() === 'high' ? 'rgba(239,68,68,0.1)' : 'rgba(16,185,129,0.1)',
                        color: (dashboardAiAnalysis.risk_level || 'Low').toLowerCase() === 'high' ? '#ef4444' : '#10b981',
                        border: `1px solid ${(dashboardAiAnalysis.risk_level || 'Low').toLowerCase() === 'high' ? 'rgba(239,68,68,0.2)' : 'rgba(16,185,129,0.2)'}`
                      }}>
                        {(dashboardAiAnalysis.risk_level || 'HEALTHY').toUpperCase()}
                      </div>
                    </div>
                    <p style={{ fontSize: '13px', lineHeight: '1.5', color: 'var(--text-main)', marginBottom: '12px', opacity: 0.85 }}>
                      {dashboardAiAnalysis.summary}
                    </p>
                    <div style={{ display: 'flex', gap: '10px' }}>
                      <button
                        onClick={() => handleTabChange('intelligence')}
                        style={{ padding: '6px 14px', borderRadius: '6px', background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6', border: 'none', fontSize: '11px', fontWeight: '800', cursor: 'pointer' }}
                      >
                        Intel Node
                      </button>
                      <button
                        onClick={() => { setDashboardAiAnalysis(null); }}
                        style={{ padding: '6px 14px', borderRadius: '6px', background: 'transparent', color: 'var(--text-dim)', border: '1px solid var(--glass-border)', fontSize: '11px', fontWeight: '800', cursor: 'pointer' }}
                      >
                        Recalibrate
                      </button>
                    </div>
                  </>
                )}
              </motion.div>
            )}
            <div className="stats-grid">
              {[
                { label: 'Total Students', value: students.length, icon: <Users size={20} />, color: '#ec4899' },
                { label: 'Teachers Active', value: allUsers.filter(u => u.role === 'teacher').length, icon: <UserCircle size={20} />, color: '#8b5cf6' },
                { label: 'Active Hubs', value: classes.length, icon: <Cpu size={20} />, color: '#06b6d4' },
                { label: 'AI Predictions', value: '98%', icon: <Brain size={20} />, color: '#10b981' }
              ].map((item, i) => (
                <motion.div key={i} initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="glass-card stat-item-compact" style={{ background: 'var(--glass-surface)', border: '1px solid var(--glass-border)' }}>
                  <div style={{ color: item.color, width: '32px', height: '32px', borderRadius: '8px', background: `${item.color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    {React.cloneElement(item.icon, { size: 16 })}
                  </div>
                  <div>
                    <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{item.label}</div>
                    <div style={{ fontSize: '18px', fontWeight: '900', color: 'var(--text-main)', marginTop: '2px' }}>{item.value}</div>
                  </div>
                </motion.div>
              ))}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '16px', marginTop: '16px' }}>
              {/* Attendance Trends */}
              <div className="glass-card" style={{ padding: '16px 18px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '14px' }}>
                  <div style={{ padding: '6px', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '10px', color: '#3b82f6' }}>
                    <TrendingUp size={16} />
                  </div>
                  <h3 style={{ margin: 0, fontSize: '15px', fontWeight: 700 }}>Attendance Velocity</h3>
                </div>
                <div style={{ height: '200px' }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={attendanceChartData}>
                      <defs>
                        <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.6} />
                          <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                      <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '700' }} />
                      <YAxis domain={[0, 100]} axisLine={false} tickLine={false} tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '700' }} width={30} />
                      <Tooltip
                        contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '12px', color: 'var(--text-main)', backdropFilter: 'blur(10px)' }}
                        itemStyle={{ color: '#3b82f6', fontWeight: '900' }}
                        labelStyle={{ color: 'var(--text-main)', fontWeight: '800' }}
                      />
                      <Area type="monotone" dataKey="value" stroke="#3b82f6" fillOpacity={1} fill="url(#colorValue)" strokeWidth={3} animationDuration={1500} />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </div>

              {/* Performance Hub */}
              <div className="glass-card" style={{ padding: '16px 18px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '14px' }}>
                  <div style={{ padding: '6px', background: 'rgba(16, 185, 129, 0.1)', borderRadius: '10px', color: '#10b981' }}>
                    <BarChart3 size={16} />
                  </div>
                  <h3 style={{ margin: 0, fontSize: '15px', fontWeight: 700 }}>Performance Hub</h3>
                </div>
                <div style={{ height: '200px' }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={performanceChartData} barSize={30}>
                      <defs>
                        <linearGradient id="perfGrad" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="0%" stopColor="#10b981" stopOpacity={1} />
                          <stop offset="100%" stopColor="#059669" stopOpacity={0.4} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                      <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '800' }} />
                      <YAxis hide />
                      <Tooltip
                        cursor={{ fill: 'rgba(255,255,255,0.05)' }}
                        contentStyle={{ background: 'rgba(15, 23, 42, 0.9)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px', backdropFilter: 'blur(8px)' }}
                      />
                      <Bar dataKey="count" fill="url(#perfGrad)" radius={[6, 6, 0, 0]} animationDuration={2000} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '16px', marginTop: '16px' }}>
              {/* Class Knowledge DNA Radar Chart */}
              <div className="glass-card" style={{ padding: '16px 18px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '14px' }}>
                  <div style={{ padding: '6px', background: 'rgba(139, 92, 246, 0.1)', borderRadius: '10px', color: '#8b5cf6' }}>
                    <Brain size={16} />
                  </div>
                  <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 800 }}>Class Knowledge DNA</h3>
                </div>
                <div style={{ height: '260px' }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <RadarChart cx="50%" cy="50%" outerRadius="60%" data={(() => {
                      const subjectMap = {};
                      const defaultSubjects = ['Math', 'Science', 'English', 'History', 'Physics', 'Arts'];
                      defaultSubjects.forEach(s => {
                        subjectMap[s] = { subject: s, mastery: 0, count: 0 };
                      });

                      brainDnaData.forEach(d => {
                        const sub = d.subject || 'General';
                        if (!subjectMap[sub]) subjectMap[sub] = { subject: sub, mastery: 0, count: 0 };
                        subjectMap[sub].mastery += (d.mastery || 0);
                        subjectMap[sub].count++;
                      });

                      return Object.values(subjectMap).map(s => ({
                        subject: s.subject,
                        A: s.count > 0 ? Math.round(s.mastery / s.count) : 0,
                        fullMark: 100
                      }));
                    })()}>
                      <PolarGrid stroke="var(--glass-border)" />
                      <PolarAngleAxis dataKey="subject" tick={{ fill: 'var(--text-dim)', fontSize: 13, fontWeight: '800' }} />
                      <PolarRadiusAxis angle={30} domain={[0, 100]} tick={false} axisLine={false} />
                      <Radar
                        name="Institutional Mastery"
                        dataKey="A"
                        stroke="#8b5cf6"
                        strokeWidth={3}
                        fill="url(#adminRadarGrad)"
                        fillOpacity={0.6}
                        animationDuration={2000}
                      />
                      <defs>
                        <linearGradient id="adminRadarGrad" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.8} />
                          <stop offset="95%" stopColor="#6366f1" stopOpacity={0.2} />
                        </linearGradient>
                      </defs>
                      <Tooltip contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '12px', color: 'var(--text-main)', backdropFilter: 'blur(10px)' }} />
                    </RadarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {/* System Telemetry - Compact & Professional */}
                <div className="glass-card" style={{ padding: '14px 16px', flex: 1, display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h3 style={{ fontSize: '11px', margin: 0, display: 'flex', alignItems: 'center', gap: '6px', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.8px', color: 'var(--text-dim)' }}>
                      <Globe size={12} color="#f43f5e" /> System Telemetry
                    </h3>
                    <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#10b981', boxShadow: '0 0 10px #10b981' }}></div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                    {recentAlerts.length > 0 ? recentAlerts.map((alert, i) => (
                      <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 10px', background: 'rgba(255,255,255,0.02)', borderRadius: '8px', borderLeft: `2px solid ${alert.color || '#3b82f6'}`, fontSize: '12px' }}>
                        <span style={{ fontWeight: '600', opacity: 0.9 }}>{alert.msg || alert.message || alert.action || 'Log Entry'}</span>
                        <span style={{ fontSize: '9px', color: 'var(--text-dim)', fontWeight: '700', whiteSpace: 'nowrap', marginLeft: '10px' }}>{alert.time || 'NOW'}</span>
                      </div>
                    )) : (
                      <div style={{ textAlign: 'center', padding: '16px', color: 'var(--text-dim)', fontSize: '11px' }}>Clear of anomalies</div>
                    )}
                  </div>
                </div>

                {/* Quick Navigation Card */}
                <div className="glass-card" style={{
                  padding: '14px 16px',
                  background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.05), rgba(168, 85, 247, 0.05))',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: '12px',
                  border: '1px solid rgba(99, 102, 241, 0.1)'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <Cpu size={16} />
                    </div>
                    <div>
                      <h4 style={{ margin: 0, fontSize: '13px', fontWeight: '800' }}>Control Center</h4>
                      <p style={{ margin: 0, color: 'var(--text-dim)', fontSize: '10px', fontWeight: '500' }}>Admin Matrix</p>
                    </div>
                  </div>
                  <button
                    onClick={() => handleTabChange('management')}
                    style={{ padding: '8px 16px', borderRadius: '8px', background: 'var(--primary)', color: 'white', fontWeight: '800', border: 'none', cursor: 'pointer', fontSize: '11px' }}
                  >
                    Enter
                  </button>
                </div>
              </div>
            </div>
          </>
        );

      case 'management':
        return (
          <>
            <header style={{ marginBottom: '40px' }}>
              <h2 style={{ fontSize: '32px' }}>System <span className="gradient-text">Control Center</span></h2>
              <p style={{ color: 'var(--text-dim)' }}>Core Administrative Operations & Protocols</p>
            </header>

            <div className="glass-card" style={{ padding: '32px' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
                {[
                  { id: 'history', label: 'Add New', icon: <Users size={32} />, color: '#ec4899', desc: 'Deploy new accounts' },
                  { id: 'manage_users', label: 'Manage Users', icon: <UserCircle size={32} />, color: '#8b5cf6', desc: 'Control permissions' },
                  { id: 'manage_classes', label: 'Manage Classes', icon: <BookOpen size={32} />, color: '#06b6d4', desc: 'Hub configurations' },
                  { id: 'attendance_archive', label: 'Attendance Archive', icon: <Clock size={32} />, color: '#f59e0b', desc: 'Historical logs' },
                  { id: 'intelligence', label: 'Intelligence', icon: <Brain size={32} />, color: '#10b981', desc: 'AI node monitoring' },
                  { id: 'teacher_tracking', label: 'Teacher Tracking', icon: <MapPin size={32} />, color: '#3b82f6', desc: 'Real-time telemetry' },
                  { id: 'institution_stats', label: 'Institution Stats', icon: <BarChart3 size={32} />, color: '#d946ef', desc: 'Big data analytics' },
                  { id: 'master_timetable', label: 'Master Timetable', icon: <Grid size={32} />, color: '#eab308', desc: 'Schedule matrix' },
                  { id: 'manage_assignments', label: 'Assignments', icon: <BookOpen size={32} />, color: '#6366f1', desc: 'Academic missions' },
                  { id: 'risk_monitor', label: 'Risk Monitor', icon: <HeartPulse size={32} />, color: '#f43f5e', desc: 'Student safety' },
                ].map(mod => (
                  <motion.div
                    key={mod.id}
                    whileHover={{ scale: 1.02, translateY: -5 }}
                    onClick={() => handleTabChange(mod.id)}
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '16px',
                      padding: '24px',
                      background: 'var(--card-bg)',
                      border: '1px solid var(--glass-border)',
                      borderRadius: '24px',
                      cursor: 'pointer',
                      transition: 'all 0.3s ease',
                      alignItems: 'center',
                      textAlign: 'center'
                    }}
                    className="hover-glow"
                  >
                    <div style={{
                      width: '64px', height: '64px', borderRadius: '18px',
                      background: `${mod.color}10`, color: mod.color,
                      display: 'flex', alignItems: 'center', justifyContent: 'center'
                    }}>
                      {mod.icon}
                    </div>
                    <div>
                      <h4 style={{ margin: '0 0 4px 0', fontSize: '16px', fontWeight: '800' }}>{mod.label}</h4>
                      <p style={{ margin: 0, fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600' }}>{mod.desc}</p>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          </>
        );

      case 'attendance':
        return (
          <AttendanceHub
            classes={visibleClasses}
            students={students}
            selectedClass={selectedClass}
            attDate={attDate}
            attStatusMap={attStatusMap}
            attLoading={attLoading}
            attSaving={attSaving}
            handleAttClassChange={handleAttClassChange}
            handleAttDateChange={handleAttDateChange}
            shiftAttDate={shiftAttDate}
            setStudentStatus={setStudentStatus}
            saveAllAttendance={saveAllAttendance}
            setAttStatusMap={setAttStatusMap}
          />
        );


      case 'students':
        return (
          <div className="glass-card" style={{ padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2>Student Directory</h2>
              <button onClick={async () => {
                const name = prompt('Name:');
                const email = prompt('Email:');
                const classId = prompt('Class ID:');
                if (name && email) {
                  await addDoc(collection(db, 'users'), {
                    name, email, classId, role: 'student', createdAt: serverTimestamp()
                  });
                }
              }}>+ Add Student</button>
            </div>
            <table style={{ width: '100%', textAlign: 'left' }}>
              <thead>
                <tr style={{ color: 'var(--text-dim)' }}>
                  <th style={{ padding: '12px' }}>NAME</th>
                  <th style={{ padding: '12px' }}>EMAIL</th>
                  <th style={{ padding: '12px' }}>CLASS ID</th>
                </tr>
              </thead>
              <tbody>
                {students.map(s => (
                  <tr key={s.id} style={{ borderTop: '1px solid var(--glass-border)' }}>
                    <td style={{ padding: '12px' }}>{s.name}</td>
                    <td style={{ padding: '12px' }}>{s.email}</td>
                    <td style={{ padding: '12px' }}>{s.classId || 'N/A'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        );

      case 'history':
        return (
          <div className="glass-card" style={{ padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2>Add New</h2>
            </div>

            <div style={{ marginBottom: '40px', background: 'rgba(255,255,255,0.02)', borderRadius: '24px', overflow: 'hidden', boxShadow: '0 8px 32px rgba(0,0,0,0.2)', border: '1px solid var(--glass-border)' }}>
              {/* Header Gradient */}
              <div style={{
                background: 'linear-gradient(135deg, var(--primary), var(--secondary))',
                padding: '40px 30px',
                position: 'relative',
                color: 'white',
                borderBottom: '1px solid var(--glass-border)'
              }}>
                <div style={{ position: 'absolute', right: '-20px', top: '-20px', opacity: 0.15 }}>
                  <Users size={150} color="white" />
                </div>
                <h2 style={{ fontSize: '28px', fontWeight: '800', marginBottom: '8px', position: 'relative', zIndex: 1, textShadow: '0 4px 15px rgba(0,0,0,0.3)', color: 'white' }}>Register Class Member</h2>
                <p style={{ fontSize: '14px', color: 'rgba(255,255,255,0.8)', position: 'relative', zIndex: 1 }}>Onboard new students, teachers, or parents</p>
              </div>

              <div style={{ padding: '30px' }}>
                <form onSubmit={async (e) => {
                  e.preventDefault();
                  const formData = new FormData(e.target);
                  const email = formData.get('email');
                  const password = formData.get('password');
                  const name = formData.get('name');
                  const phone = formData.get('phone');
                  const facultyId = formData.get('facultyId');
                  const studentId = formData.get('studentId');
                  const gender = formData.get('gender');
                  const dob = formData.get('dob');
                  const relationship = formData.get('relationship');
                  const qualification = formData.get('qualification');
                  const classId = newMemberRole === 'teacher' ? teacherClasses.join(', ') : formData.get('classId');
                  const childrenUids = formData.get('childrenUids');
                  const linkedStudentClass = formData.get('linkedStudentClass');
                  const linkedStudentRollNo = formData.get('linkedStudentRollNo');
                  const specialization = newMemberRole === 'teacher' ? teacherSpecs.join(', ') : formData.get('specialization');
                  const academicUnits = formData.get('academicUnits');

                  try {
                    const userCred = await createUserWithEmailAndPassword(secondaryAuth, email, password);
                    await setDoc(doc(db, 'users', userCred.user.uid), {
                      name,
                      email,
                      phone: phone || null,
                      facultyId: facultyId || null,
                      studentId: studentId || null,
                      gender: gender || null,
                      dob: dob || null,
                      relationship: relationship || null,
                      qualification: qualification || null,
                      role: newMemberRole,
                      classId: classId || null,
                      childrenUids: childrenUids ? childrenUids.split(',').map(u => u.trim()) : null,
                      linkedStudentClass: linkedStudentClass || null,
                      linkedStudentRollNo: linkedStudentRollNo || null,
                      specialization: specialization ? specialization.split(',').map(s => s.trim()) : null,
                      academicUnits: newMemberRole === 'teacher' ? teacherClasses : (academicUnits ? academicUnits.split(',').map(u => u.trim()) : null),
                      schoolId: 'SCH001',
                      createdAt: serverTimestamp()
                    });

                    // CRITICAL: Sign out from secondary instance so it doesn't interfere
                    await signOut(secondaryAuth);

                    alert('Hub Member Registered Successfully!');
                    setTeacherSpecs([]);
                    setTeacherClasses([]);
                    e.target.reset();
                  } catch (err) {
                    alert('Error registering member: ' + err.message);
                  }
                }}>
                  {/* Designation Priority */}
                  <div style={{ marginBottom: '32px' }}>
                    <p style={{ fontSize: '13px', fontWeight: '700', color: 'var(--text-dim)', marginBottom: '16px', textTransform: 'uppercase', letterSpacing: '1px' }}>Designation Priority</p>
                    <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
                      {[
                        { id: 'student', label: 'Student', icon: <BookOpen size={16} /> },
                        { id: 'teacher', label: 'Faculty', icon: <Cpu size={16} /> },
                        { id: 'parent', label: 'Parent', icon: <Users size={16} /> },
                        { id: 'admin', label: 'Admin', icon: <ShieldCheck size={16} /> }
                      ].map(role => (
                        <button
                          key={role.id}
                          type="button"
                          onClick={() => setNewMemberRole(role.id)}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '8px',
                            padding: '12px 24px',
                            borderRadius: '12px',
                            fontWeight: '600',
                            fontSize: '14px',
                            transition: 'all 0.2s',
                            background: newMemberRole === role.id ? '#6366f1' : 'var(--input-bg)',
                            color: newMemberRole === role.id ? 'white' : 'var(--text-dim)',
                            border: newMemberRole === role.id ? '1px solid #6366f1' : '1px solid var(--glass-border)',
                            boxShadow: newMemberRole === role.id ? '0 4px 15px rgba(99, 102, 241, 0.4)' : 'none'
                          }}
                        >
                          {role.icon} {role.label}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Identification Details */}
                  <div style={{ background: 'var(--card-bg)', padding: '24px', borderRadius: '20px', border: '1px solid var(--glass-border)', marginBottom: '24px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '20px' }}>
                      <span style={{ color: 'var(--text-dim)' }}><Users size={14} /></span>
                      <span style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', letterSpacing: '1.2px', textTransform: 'uppercase' }}>Identification Details</span>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                      <div style={{ position: 'relative' }}>
                        <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1' }}><Users size={18} /></span>
                        <input name="name" placeholder="Full Official Name" required style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }} />
                      </div>

                      {(newMemberRole === 'teacher' || newMemberRole === 'student' || newMemberRole === 'parent' || newMemberRole === 'admin') && (
                        <div style={{ display: 'grid', gridTemplateColumns: newMemberRole === 'admin' ? '1fr' : '1fr 1fr', gap: '16px' }}>
                          <div style={{ position: 'relative' }}>
                            <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1' }}><Phone size={18} /></span>
                            <input name="phone" placeholder={newMemberRole === 'student' ? "Parent/Guardian Phone" : (newMemberRole === 'parent' ? "Primary Phone Number" : "Mobile Number")} style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }} />
                          </div>
                          {newMemberRole !== 'admin' && (
                            <div style={{ position: 'relative' }}>
                              <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1' }}><ShieldCheck size={18} /></span>
                              {newMemberRole === 'parent' ? (
                                <select name="relationship" style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }}>
                                  <option value="">Select Relationship</option>
                                  <option value="Father">Father</option>
                                  <option value="Mother">Mother</option>
                                  <option value="Guardian">Guardian / Other</option>
                                </select>
                              ) : (
                                <input name={newMemberRole === 'student' ? "studentId" : "facultyId"} placeholder={newMemberRole === 'student' ? "Student Roll No / ID" : "Faculty ID / Code"} style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }} />
                              )}
                            </div>
                          )}
                        </div>
                      )}

                      <div style={{ position: 'relative' }}>
                        <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1', fontWeight: 'bold' }}>@</span>
                        <input name="email" type="email" autoComplete="new-email" placeholder="Corporate/Personal Email" required style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }} />
                      </div>

                      {(newMemberRole === 'teacher' || newMemberRole === 'student' || newMemberRole === 'parent' || newMemberRole === 'admin') && (
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                          <div style={{ position: 'relative' }}>
                            <select name="gender" style={{ width: '100%', padding: '16px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }}>
                              <option value="">Select Gender</option>
                              <option value="Male">Male</option>
                              <option value="Female">Female</option>
                              <option value="Other">Other</option>
                            </select>
                          </div>
                          <div style={{ position: 'relative' }}>
                            <input name="dob" type="date" placeholder="Date of Birth" style={{ width: '100%', padding: '16px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }} />
                          </div>
                        </div>
                      )}

                      <div style={{ position: 'relative' }}>
                        <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1' }}>&gt;</span>
                        <input name="password" type="password" autoComplete="new-password" placeholder="Initial Access Password" required minLength="6" style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }} />
                      </div>

                      {newMemberRole === 'teacher' && (
                        <div style={{ position: 'relative' }}>
                          <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1' }}><BookOpen size={18} /></span>
                          <input name="qualification" placeholder="Qualification (e.g. B.Ed, M.Tech)" style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }} />
                        </div>
                      )}
                    </div>
                  </div>
                  {/* Relational Mapping */}
                  {(newMemberRole !== 'admin') && (
                    <div style={{ background: 'var(--card-bg)', padding: '24px', borderRadius: '20px', border: '1px solid var(--glass-border)', marginBottom: '24px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '20px' }}>
                        <span style={{ color: 'var(--text-dim)' }}>Link</span>
                        <span style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', letterSpacing: '1.2px', textTransform: 'uppercase' }}>Relational Mapping</span>
                      </div>

                      {(newMemberRole === 'student' || newMemberRole === 'teacher') ? (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                          {newMemberRole === 'student' && (
                            <div style={{ background: 'rgba(255,255,255,0.02)', padding: '16px', borderRadius: '14px', border: '1px solid var(--glass-border)' }}>
                              <p style={{ fontSize: '12px', fontWeight: '800', color: 'var(--text-dim)', marginBottom: '12px', textTransform: 'uppercase' }}>
                                Primary Educational Hub
                              </p>
                              <div style={{ position: 'relative' }}>
                                <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1' }}><Cpu size={20} /></span>
                                <select name="classId" required={newMemberRole === 'student'} style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }}>
                                  <option value="" style={{ color: 'var(--text-main)', background: 'var(--bg-gradient-start)' }}>Select a standardized hub</option>
                                  {classes.map(c => <option key={c.id} value={c.id} style={{ color: 'var(--text-main)', background: 'var(--bg-gradient-start)' }}>{c.displayName || `${c.standard} - ${c.section}`}</option>)}
                                </select>
                              </div>
                            </div>
                          )}

                          {newMemberRole === 'teacher' && (
                            <>
                              <div style={{ background: 'rgba(255,255,255,0.02)', padding: '16px', borderRadius: '14px', border: '1px solid var(--glass-border)' }}>
                                <p style={{ fontSize: '12px', fontWeight: '800', color: 'var(--text-dim)', marginBottom: '12px', textTransform: 'uppercase' }}>Subject Specialization</p>
                                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                                  {['Physics', 'Chemistry', 'Mathematics', 'Biology', 'English', 'Hindi', 'Computer Science', 'History', 'Geography', 'Economics', 'Art', 'Music', 'Physical Education'].map(subject => {
                                    const isSelected = teacherSpecs.includes(subject);
                                    return (
                                      <button
                                        key={subject}
                                        type="button"
                                        onClick={() => {
                                          if (isSelected) setTeacherSpecs(prev => prev.filter(s => s !== subject));
                                          else setTeacherSpecs(prev => [...prev, subject]);
                                        }}
                                        style={{
                                          padding: '8px 16px',
                                          borderRadius: '20px',
                                          fontSize: '12px',
                                          fontWeight: '700',
                                          cursor: 'pointer',
                                          transition: 'all 0.2s',
                                          background: isSelected ? 'rgba(16, 185, 129, 0.1)' : 'transparent',
                                          color: isSelected ? '#10b981' : 'var(--text-dim)',
                                          border: `1px solid ${isSelected ? '#10b981' : 'var(--glass-border)'}`,
                                        }}
                                      >
                                        {subject}
                                      </button>
                                    );
                                  })}
                                </div>
                              </div>
                              <div style={{ background: 'rgba(255,255,255,0.02)', padding: '16px', borderRadius: '14px', border: '1px solid var(--glass-border)' }}>
                                <p style={{ fontSize: '12px', fontWeight: '800', color: 'var(--text-dim)', marginBottom: '12px', textTransform: 'uppercase' }}>Assigned Academic Units (Hubs)</p>
                                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                                  {classes.map(c => {
                                    const label = c.displayName || `${c.standard} - ${c.section}`;
                                    const isSelected = teacherClasses.includes(label);
                                    return (
                                      <button
                                        key={c.id}
                                        type="button"
                                        onClick={() => {
                                          if (isSelected) setTeacherClasses(prev => prev.filter(cl => cl !== label));
                                          else setTeacherClasses(prev => [...prev, label]);
                                        }}
                                        style={{
                                          padding: '8px 16px',
                                          borderRadius: '20px',
                                          fontSize: '11px',
                                          fontWeight: '700',
                                          cursor: 'pointer',
                                          transition: 'all 0.2s',
                                          background: isSelected ? 'rgba(59, 130, 246, 0.1)' : 'transparent',
                                          color: isSelected ? '#3b82f6' : 'var(--text-dim)',
                                          border: `1px solid ${isSelected ? '#3b82f6' : 'var(--glass-border)'}`,
                                        }}
                                      >
                                        {label}
                                      </button>
                                    );
                                  })}
                                </div>
                              </div>
                            </>
                          )}
                        </div>
                      ) : (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                            <div style={{ position: 'relative' }}>
                              <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1' }}><Cpu size={18} /></span>
                              <select name="linkedStudentClass" required={newMemberRole === 'parent'} style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }}>
                                <option value="">Select Child's Class</option>
                                {classes.map(c => <option key={c.id} value={c.displayName || c.id}>{c.displayName || `${c.standard} - ${c.section}`}</option>)}
                              </select>
                            </div>
                            <div style={{ position: 'relative' }}>
                              <span style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#6366f1' }}><Users size={18} /></span>
                              <input
                                name="linkedStudentRollNo"
                                value={newParentChildRoll}
                                onChange={(e) => setNewParentChildRoll(e.target.value)}
                                placeholder="Child's Roll No"
                                required={newMemberRole === 'parent'}
                                style={{ width: '100%', padding: '16px 16px 16px 48px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontSize: '15px', outline: 'none' }}
                              />
                            </div>
                          </div>

                          {/* New Member Creation Real-time Search */}
                          {newParentChildRoll && (
                            <div style={{ padding: '12px', background: 'rgba(99, 102, 241, 0.1)', borderRadius: '12px', border: '1px solid rgba(99, 102, 241, 0.2)', display: 'flex', alignItems: 'center', gap: '12px' }}>
                              {(() => {
                                const matched = allUsers.find(u =>
                                  u.role === 'student' &&
                                  (String(u.rollNo) == String(newParentChildRoll) ||
                                    String(u.roll_no) == String(newParentChildRoll) ||
                                    String(u.studentId) == String(newParentChildRoll))
                                );
                                if (matched) {
                                  return (
                                    <>
                                      <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 'bold' }}>
                                        {matched.name?.charAt(0)}
                                      </div>
                                      <div>
                                        <div style={{ fontSize: '13px', fontWeight: '700', color: 'var(--text-main)' }}>{matched.name}</div>
                                        <div style={{ fontSize: '11px', color: 'var(--primary)', fontWeight: '600' }}>Linked to: {matched.classId || matched.className || 'General'}</div>
                                      </div>
                                    </>
                                  );
                                }
                                return <div style={{ fontSize: '12px', color: '#ef4444', fontWeight: '600' }}>Student not found with this Roll Number</div>;
                              })()}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  )}

                  <button type="submit" style={{
                    width: '100%',
                    padding: '18px',
                    background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                    color: 'white',
                    borderRadius: '16px',
                    fontSize: '16px',
                    fontWeight: '800',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '10px',
                    border: 'none',
                    cursor: 'pointer',
                    boxShadow: '0 8px 20px rgba(99, 102, 241, 0.4)',
                    transition: 'transform 0.2s'
                  }}>
                    <Users size={18} /> Initialize Account Creation
                  </button>
                </form>
              </div>
            </div>
          </div>
        );

      case 'attendance_archive':
        return (
          <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
            <div style={{ background: 'var(--card-bg)', padding: '32px 32px 0 32px', borderBottom: '1px solid var(--glass-border)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
                <h2 style={{ margin: 0, fontSize: '24px', fontWeight: '900' }}>Attendance Archive</h2>
              </div>

              <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
                <div style={{ flex: 1 }}>
                  <p style={{ margin: '0 0 8px 0', fontSize: '11px', fontWeight: 'bold', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px' }}>Academic Hub Selection</p>
                  <select
                    value={attendanceClassFilter}
                    onChange={(e) => setAttendanceClassFilter(e.target.value)}
                    style={{ width: '100%', padding: '16px', borderRadius: '16px', background: 'var(--input-bg)', border: '1px solid var(--glass-border)', color: 'var(--text-main)', outline: 'none', fontSize: '15px' }}
                  >
                    <option value="" style={{ background: 'var(--bg-gradient-start)' }}>Select an Academic Hub</option>
                    {classes.map(c => (
                      <option key={c.id} value={c.id} style={{ background: 'var(--bg-gradient-start)' }}>{c.displayName}</option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            <div style={{ padding: '32px', background: 'rgba(0,0,0,0.01)', minHeight: '400px' }}>
              {(() => {
                if (!attendanceClassFilter || attendanceClassFilter === '') {
                  return (
                    <div style={{ textAlign: 'center', padding: '60px 20px', color: 'var(--text-dim)' }}>
                      <Calendar size={64} style={{ opacity: 0.2, marginBottom: '16px' }} />
                      <p style={{ fontWeight: 'bold', color: 'var(--text-main)', fontSize: '16px' }}>Select an institutional hub to view historical presence logs.</p>
                    </div>
                  );
                }

                const filteredRecords = attendanceArchive
                  .filter(r => r.class_id === attendanceClassFilter);

                if (filteredRecords.length === 0) {
                  return (
                    <div style={{ textAlign: 'center', padding: '60px 20px', color: 'var(--text-dim)' }}>
                      <History size={64} style={{ opacity: 0.2, marginBottom: '16px' }} />
                      <p style={{ fontWeight: 'bold', color: 'var(--text-main)', fontSize: '16px' }}>No presence logs detected for this hub.</p>
                    </div>
                  );
                }

                const groupedByDate = filteredRecords.reduce((acc, record) => {
                  const dateStr = record.date_string || (record.date?.toDate?.()?.toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })) || 'Recent Log';
                  if (!acc[dateStr]) acc[dateStr] = [];
                  acc[dateStr].push(record);
                  return acc;
                }, {});

                return (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                    {Object.entries(groupedByDate).map(([dateStr, records]) => {
                      const presentCount = records.filter(r => r.status === 'present').length;
                      const absentCount = records.filter(r => r.status === 'absent').length;

                      return (
                        <details key={dateStr} style={{ background: 'var(--card-bg)', borderRadius: '24px', border: '1px solid var(--glass-border)', overflow: 'hidden', boxShadow: '0 8px 30px rgba(0,0,0,0.04)' }}>
                          <summary style={{ padding: '24px', cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center', outline: 'none', listStyle: 'none' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                              <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: 'rgba(59, 130, 246, 0.08)', color: '#3b82f6', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Calendar size={28} />
                              </div>
                              <div>
                                <h4 style={{ margin: 0, fontSize: '18px', fontWeight: '900', color: 'var(--text-main)' }}>{dateStr}</h4>
                                <p style={{ margin: '4px 0 0 0', fontSize: '12px', color: 'var(--text-dim)', fontWeight: 'bold' }}>Detailed Presence Ledger</p>
                              </div>
                            </div>
                            <div style={{ display: 'flex', gap: '12px' }}>
                              <span style={{ padding: '8px 16px', borderRadius: '12px', fontSize: '13px', fontWeight: '900', background: 'rgba(16, 185, 129, 0.1)', color: '#10b981' }}>PRESENT: {presentCount}</span>
                              <span style={{ padding: '8px 16px', borderRadius: '12px', fontSize: '13px', fontWeight: '900', background: 'rgba(244, 63, 94, 0.1)', color: '#f43f5e' }}>ABSENT: {absentCount}</span>
                            </div>
                          </summary>

                          <div style={{ padding: '0 24px 24px 24px', background: 'transparent' }}>
                            <div style={{ overflowX: 'auto', borderRadius: '16px', border: '1px solid var(--glass-border)' }}>
                              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                                <thead>
                                  <tr style={{ background: 'var(--glass-surface)', borderBottom: '1px solid var(--glass-border)' }}>
                                    <th style={{ padding: '16px 20px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px' }}>Student Member</th>
                                    <th style={{ padding: '16px 20px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px' }}>Hub ID</th>
                                    <th style={{ padding: '16px 20px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px', textAlign: 'center' }}>Status</th>
                                    <th style={{ padding: '16px 20px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px', textAlign: 'right' }}>Faculty Attribution</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {records.map(record => {
                                    const student = allUsers.find(u => u.id === record.student_id);
                                    const isPresent = record.status === 'present';
                                    const hub = classes.find(c => c.id === record.class_id);

                                    return (
                                      <tr key={record.id} style={{ borderBottom: '1px solid var(--glass-border)' }}>
                                        <td style={{ padding: '16px 20px' }}>
                                          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: isPresent ? '#10b98120' : '#f43f5e20', color: isPresent ? '#10b981' : '#f43f5e', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                              <UserCircle size={18} />
                                            </div>
                                            <div>
                                              <div style={{ fontSize: '14px', fontWeight: '800', color: 'var(--text-main)' }}>{student?.name || 'Unknown Node'}</div>
                                              <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: 'bold' }}>ID: {record.student_id.substring(0, 8).toUpperCase()}</div>
                                            </div>
                                          </div>
                                        </td>
                                        <td style={{ padding: '16px 20px', fontSize: '13px', fontWeight: '700', color: 'var(--text-dim)' }}>
                                          {hub?.displayName || record.class_id}
                                        </td>
                                        <td style={{ padding: '16px 20px', textAlign: 'center' }}>
                                          <span style={{ padding: '6px 12px', borderRadius: '8px', fontSize: '11px', fontWeight: '900', background: isPresent ? 'rgba(16, 185, 129, 0.1)' : 'rgba(244, 63, 94, 0.1)', color: isPresent ? '#10b981' : '#f43f5e', textTransform: 'uppercase' }}>
                                            {record.status}
                                          </span>
                                        </td>
                                        <td style={{ padding: '16px 20px', textAlign: 'right', fontSize: '12px', color: 'var(--text-dim)', fontWeight: '600' }}>
                                          {record.marked_by || 'System Auto'}
                                        </td>
                                      </tr>
                                    );
                                  })}
                                </tbody>
                              </table>
                            </div>
                          </div>
                        </details>
                      );
                    })}
                  </div>
                );
              })()}
            </div>
          </div>
        );

      case 'manage_users': {
        const userStats = {
          all: (allUsers || []).length,
          student: (allUsers || []).filter(u => u.role === 'student').length,
          teacher: (allUsers || []).filter(u => u.role === 'teacher').length,
          parent: (allUsers || []).filter(u => u.role === 'parent').length,
          admin: (allUsers || []).filter(u => u.role === 'admin').length
        };

        return (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            {/* Header Section */}
            <div className="glass-card" style={{ padding: '32px', background: 'var(--card-bg)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
                <div>
                  <h2 style={{ fontSize: '28px', fontWeight: '900', margin: 0 }}>Hub <span className="gradient-text">Personnel</span></h2>
                  <p style={{ color: 'var(--text-dim)', margin: '4px 0 0 0' }}>Monitor and manage institutional access permissions.</p>
                </div>
                <div style={{ display: 'flex', gap: '12px' }}>
                  {['student', 'teacher', 'parent', 'admin'].map(r => (
                    <div key={r} style={{ padding: '10px 16px', borderRadius: '14px', background: 'var(--glass-surface)', border: '1px solid var(--glass-border)', textAlign: 'center' }}>
                      <div style={{ fontSize: '18px', fontWeight: '900', color: 'var(--primary)' }}>{userStats[r]}</div>
                      <div style={{ fontSize: '10px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase' }}>{r}s</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Toolbar */}
              <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                <div style={{ position: 'relative', flex: 1 }}>
                  <Search size={20} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
                  <input
                    type="text"
                    placeholder="Search by name, email or ID..."
                    value={userSearchQuery}
                    onChange={(e) => setUserSearchQuery(e.target.value)}
                    style={{
                      width: '100%',
                      padding: '16px 16px 16px 48px',
                      borderRadius: '16px',
                      background: 'var(--input-bg)',
                      border: '1px solid var(--glass-border)',
                      color: 'var(--text-main)',
                      outline: 'none',
                      fontSize: '15px'
                    }}
                  />
                </div>
                <div style={{ display: 'flex', background: 'var(--glass-surface)', padding: '6px', borderRadius: '14px', border: '1px solid var(--glass-border)' }}>
                  {['student', 'teacher', 'parent', 'admin'].map(r => (
                    <button
                      key={r}
                      onClick={() => setUserRoleFilter(r)}
                      style={{
                        padding: '10px 20px',
                        borderRadius: '10px',
                        background: userRoleFilter === r ? 'var(--primary)' : 'transparent',
                        color: userRoleFilter === r ? 'white' : 'var(--text-dim)',
                        border: 'none',
                        fontWeight: '800',
                        cursor: 'pointer',
                        fontSize: '12px',
                        textTransform: 'uppercase',
                        transition: 'all 0.2s'
                      }}
                    >
                      {r}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Users List (Professional Table View) */}
            <div className="glass-card" style={{ padding: '0', overflow: 'hidden', background: 'var(--card-bg)', border: '1px solid var(--glass-border)' }}>
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                  <thead>
                    <tr style={{ background: 'var(--glass-surface)', borderBottom: '1px solid var(--glass-border)' }}>
                      <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '1px' }}>Member</th>
                      <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '1px' }}>Role</th>
                      <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '1px' }}>ID / Contact</th>
                      <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '1px' }}>Academic Info</th>
                      <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: 'var(--text-main)', textTransform: 'uppercase', letterSpacing: '1px', textAlign: 'right' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(() => {
                      const filteredUsers = allUsers
                        .filter(u => u.role === userRoleFilter)
                        .filter(u =>
                          (u.name || '').toLowerCase().includes(userSearchQuery.toLowerCase()) ||
                          (u.email || '').toLowerCase().includes(userSearchQuery.toLowerCase()) ||
                          (u.facultyId || '').toLowerCase().includes(userSearchQuery.toLowerCase()) ||
                          (u.studentId || '').toLowerCase().includes(userSearchQuery.toLowerCase())
                        );

                      if (filteredUsers.length === 0) {
                        return (
                          <tr>
                            <td colSpan="5" style={{ textAlign: 'center', padding: '100px 0', color: 'var(--text-dim)' }}>
                              <Users size={48} style={{ opacity: 0.1, marginBottom: '16px' }} />
                              <p style={{ fontWeight: 'bold', color: 'var(--text-main)', margin: 0 }}>No {userRoleFilter}s found</p>
                              <p style={{ fontSize: '12px' }}>Try adjusting your search query</p>
                            </td>
                          </tr>
                        );
                      }

                      return filteredUsers.map(u => {
                        const roleColors = {
                          student: { color: '#6366f1', bg: 'rgba(99, 102, 241, 0.1)' },
                          teacher: { color: '#10b981', bg: 'rgba(16, 185, 129, 0.1)' },
                          parent: { color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.1)' },
                          admin: { color: '#ef4444', bg: 'rgba(239, 68, 68, 0.1)' }
                        };
                        const theme = roleColors[u.role] || roleColors.student;

                        return (
                          <tr key={u.id} style={{ borderBottom: '1px solid var(--glass-border)', transition: 'background 0.2s', cursor: 'default' }} onMouseEnter={(e) => e.currentTarget.style.background = 'var(--glass-surface)'} onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}>
                            <td style={{ padding: '12px 24px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: theme.bg, color: theme.color, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', fontWeight: '900', border: `1px solid ${theme.color}20`, overflow: 'hidden' }}>
                                  {(u.avatar_url || u.photoURL || u.profileImage || u.avatar || u.imageUrl || u.image || u.profile_image || u.avatarUrl || u.profilePic || u.profile_pic) ? (
                                    <img src={u.avatar_url || u.photoURL || u.profileImage || u.avatar || u.imageUrl || u.image || u.profile_image || u.avatarUrl || u.profilePic || u.profile_pic} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="" />
                                  ) : (
                                    (u.name || u.email || 'U')[0].toUpperCase()
                                  )}
                                </div>
                                <div>
                                  <div style={{ fontWeight: '700', fontSize: '14px', color: 'var(--text-main)' }}>{u.name || 'Unknown'}</div>
                                  <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>{u.email}</div>
                                </div>
                              </div>
                            </td>
                            <td style={{ padding: '12px 24px' }}>
                              <span style={{ padding: '4px 10px', borderRadius: '6px', background: theme.bg, color: theme.color, fontSize: '9px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                {u.role}
                              </span>
                            </td>
                            <td style={{ padding: '12px 24px' }}>
                              <div style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-main)' }}>{u.studentId || u.rollNo || u.roll_no || u.facultyId || u.phone || '--'}</div>
                              <div style={{ fontSize: '10px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>{u.role === 'student' ? 'Roll Number' : (u.role === 'teacher' ? 'Faculty Code' : 'Contact')}</div>
                            </td>
                            <td style={{ padding: '12px 24px' }}>
                              <div style={{ fontSize: '13px', fontWeight: '600', color: 'var(--text-main)' }}>
                                {u.role === 'teacher' ? (
                                  Array.isArray(u.specialization) ? u.specialization.join(', ') : (u.specialization || '--')
                                ) : (
                                  u.role === 'parent' ? (u.linkedStudentRollNo ? `Child: ${u.linkedStudentRollNo}` : '--') : (() => {
                                    const targetId = u.classId || u.class_id || u.className;
                                    const matchedClass = (classes || []).find(c => c.id === targetId || c.name === targetId || c.className === targetId);
                                    if (matchedClass) {
                                      return matchedClass.displayName || (matchedClass.standard ? (matchedClass.section ? `${matchedClass.standard} - ${matchedClass.section}` : matchedClass.standard) : (matchedClass.name || targetId));
                                    }
                                    return targetId || '--';
                                  })()
                                )}
                              </div>
                              <div style={{ fontSize: '10px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>
                                {u.role === 'teacher' ? 'Specialization' : (u.role === 'student' ? 'Assigned Hub' : 'Linkage')}
                              </div>
                            </td>
                            <td style={{ padding: '12px 24px', textAlign: 'right' }}>
                              <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                                <button
                                  onClick={() => {
                                    setEditingUser(u);
                                    if (u.role === 'teacher') {
                                      setTeacherSpecs(Array.isArray(u.specialization) ? [...u.specialization] : []);
                                      setTeacherClasses(Array.isArray(u.academicUnits) ? [...u.academicUnits] : []);
                                    }
                                    if (u.role === 'parent') {
                                      setTempParentChildRoll(u.linkedStudentRollNo || '');
                                    }
                                    setShowEditUserModal(true);
                                  }}
                                  className="action-btn-mini btn-blue"
                                  style={{ padding: '8px 12px', borderRadius: '8px', fontSize: '11px', fontWeight: '800', gap: '6px' }}
                                >
                                  <Edit2 size={14} strokeWidth={2.5} /> Edit
                                </button>
                                <button
                                  onClick={async () => {
                                    if (window.confirm(`Delete ${u.name}?`)) {
                                      await deleteDoc(doc(db, 'users', u.id));
                                    }
                                  }}
                                  className="action-btn-mini btn-red"
                                  style={{ padding: '8px', borderRadius: '8px' }}
                                >
                                  <Trash size={14} strokeWidth={2.5} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      });
                    })()}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        );
      }

      case 'manage_classes':
        return (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
            {/* Header & Stats Summary */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
              <div>
                <h1 style={{ margin: 0, fontSize: '32px', fontWeight: '900', letterSpacing: '-1px' }}>Hub Management</h1>
                <p style={{ margin: '4px 0 0 0', color: 'var(--text-dim)', fontSize: '15px', fontWeight: '500' }}>Establish and monitor academic neural nodes.</p>
              </div>
              <div style={{ display: 'flex', gap: '12px' }}>
                <div className="glass-card stat-item-compact" style={{ border: '1px solid var(--glass-border)', background: 'var(--glass-surface)' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Layers size={16} />
                  </div>
                  <div>
                    <div style={{ fontSize: '16px', fontWeight: '900', color: 'var(--text-main)' }}>{classes.length}</div>
                    <div style={{ fontSize: '9px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase' }}>Total Hubs</div>
                  </div>
                </div>
                <div className="glass-card stat-item-compact" style={{ border: '1px solid var(--glass-border)', background: 'var(--glass-surface)' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Users size={16} />
                  </div>
                  <div>
                    <div style={{ fontSize: '16px', fontWeight: '900', color: 'var(--text-main)' }}>{allUsers.filter(u => u.role === 'student').length}</div>
                    <div style={{ fontSize: '9px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase' }}>Nodes</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Establish Hub Section - Moved to Top */}
            <div className="glass-card" style={{ padding: '32px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
                <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: '#3b82f6', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 8px 16px rgba(59, 130, 246, 0.2)' }}>
                  <PlusCircle size={20} />
                </div>
                <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '800' }}>New Academic Class</h3>
              </div>

              <form onSubmit={async (e) => {
                e.preventDefault();
                const formData = new FormData(e.target);
                const standard = formData.get('standard');
                const section = formData.get('section');
                const displayName = section ? `${standard} - ${section}` : standard;

                try {
                  await addDoc(collection(db, 'classes'), {
                    schoolId: 'SCH001',
                    standard,
                    section: section || null,
                    displayName,
                    createdAt: serverTimestamp()
                  });
                  alert('Hub Established Successfully!');
                  e.target.reset();
                } catch (err) {
                  alert('Error: ' + err.message);
                }
              }} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr auto', gap: '20px', alignItems: 'flex-end' }}>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Academic Standard</label>
                  <select name="standard" required style={{ width: '100%', padding: '14px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', fontWeight: '600' }}>
                    <option value="">Select Level</option>
                    {['Pre-Primary', 'KG', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th', '11th', '12th'].map(s => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Section Identifier</label>
                  <input name="section" placeholder="e.g. A, B, Alpha" style={{ width: '100%', boxSizing: 'border-box', padding: '14px', borderRadius: '14px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none' }} />
                </div>

                <button type="submit" style={{ padding: '16px 32px', background: '#3b82f6', color: 'white', borderRadius: '14px', border: 'none', fontWeight: '900', cursor: 'pointer', boxShadow: '0 10px 20px rgba(59, 130, 246, 0.2)', fontSize: '14px' }}> + New Class </button>
              </form>
            </div>

            {/* Active Hubs Table - Moved Below */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                <h3 style={{ margin: 0, fontSize: '20px', fontWeight: '800' }}>Active Academic Nodes</h3>
                <div style={{ fontSize: '13px', color: 'var(--text-dim)', fontWeight: '600' }}>Live Institution Roster</div>
              </div>

              {classes.length === 0 ? (
                <div className="glass-card" style={{ textAlign: 'center', padding: '60px', color: 'var(--text-dim)' }}>
                  <Cpu size={48} style={{ opacity: 0.3, marginBottom: '20px' }} />
                  <p style={{ fontSize: '18px', fontWeight: '700', margin: 0 }}>No Hubs Active</p>
                  <p style={{ fontSize: '13px', opacity: 0.8 }}>Use the sidebar to establish your first academic hub.</p>
                </div>
              ) : (
                <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ background: 'rgba(255,255,255,0.02)', borderBottom: '1px solid var(--glass-border)' }}>
                        <th style={{ padding: '16px 24px', textAlign: 'left', fontSize: '11px', fontWeight: '800', textTransform: 'uppercase', color: 'var(--text-main)', letterSpacing: '1px' }}>Hub Identifier</th>
                        <th style={{ padding: '16px 24px', textAlign: 'left', fontSize: '11px', fontWeight: '800', textTransform: 'uppercase', color: 'var(--text-main)', letterSpacing: '1px' }}>Enrolled Nodes</th>
                        <th style={{ padding: '16px 24px', textAlign: 'left', fontSize: '11px', fontWeight: '800', textTransform: 'uppercase', color: 'var(--text-main)', letterSpacing: '1px' }}>Status</th>
                        <th style={{ padding: '16px 24px', textAlign: 'right', fontSize: '11px', fontWeight: '800', textTransform: 'uppercase', color: 'var(--text-main)', letterSpacing: '1px' }}>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {classes.map(cls => {
                        const studentCount = allUsers.filter(u =>
                          u.role === 'student' && (
                            u.classId === cls.id ||
                            u.class_id === cls.id ||
                            u.classId === cls.displayName ||
                            u.class_id === cls.displayName ||
                            u.className === cls.displayName
                          )
                        ).length;
                        return (
                          <tr key={cls.id} style={{ borderBottom: '1px solid var(--glass-border)', transition: 'background 0.2s' }} onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.01)'} onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}>
                            <td style={{ padding: '16px 24px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(59, 130, 246, 0.08)', color: '#3b82f6', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                  <Cpu size={18} />
                                </div>
                                <div>
                                  <div style={{ fontSize: '14px', fontWeight: '800', color: 'var(--text-main)' }}>{cls.displayName}</div>
                                  <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '700' }}>ID: {cls.id.substring(0, 8).toUpperCase()}</div>
                                </div>
                              </div>
                            </td>
                            <td style={{ padding: '16px 24px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <Users size={14} style={{ color: '#3b82f6' }} />
                                <span style={{ fontSize: '14px', fontWeight: '700' }}>{studentCount} Students</span>
                              </div>
                            </td>
                            <td style={{ padding: '16px 24px' }}>
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '4px 10px', borderRadius: '20px', background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', fontSize: '11px', fontWeight: '800' }}>
                                <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#10b981' }} />
                                Active
                              </div>
                            </td>
                            <td style={{ padding: '16px 24px', textAlign: 'right' }}>
                              <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                                <button
                                  onClick={() => {
                                    setEditingHub(cls);
                                    setShowEditHubModal(true);
                                  }}
                                  className="action-btn-mini btn-blue"
                                  style={{ padding: '8px 12px', borderRadius: '10px', gap: '6px', fontSize: '11px', fontWeight: '800' }}
                                >
                                  <Edit2 size={16} strokeWidth={2.5} /> Edit
                                </button>
                                <button
                                  onClick={async () => {
                                    if (window.confirm('Archive this academic hub?')) {
                                      await deleteDoc(doc(db, 'classes', cls.id));
                                    }
                                  }}
                                  className="action-btn-mini btn-red"
                                  style={{ padding: '8px', borderRadius: '10px' }}
                                >
                                  <Trash size={16} strokeWidth={2.5} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        );

      case 'attendance_archive': {
        const filteredArchive = attendanceArchive.filter(record => {
          const dateMatch = !attDate || record.date_string === attDate;
          const classMatch = !attendanceClassFilter || record.class_id === attendanceClassFilter;
          return dateMatch && classMatch;
        });

        return (
          <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
            <div style={{ background: 'linear-gradient(135deg, #f59e0b, #d97706)', padding: '32px', borderBottom: '1px solid var(--glass-border)', display: 'flex', alignItems: 'center', gap: '16px' }}>
              <div style={{ padding: '16px', background: 'rgba(255,255,255,0.2)', borderRadius: '16px', color: 'white' }}>
                <Clock size={32} />
              </div>
              <div>
                <h2 style={{ margin: '0 0 8px 0', color: 'white', fontSize: '24px', fontWeight: '900' }}>Attendance Archive</h2>
                <p style={{ margin: 0, color: 'rgba(255,255,255,0.9)', fontSize: '14px' }}>Historical presence telemetry and verified logs</p>
              </div>
            </div>

            <div style={{ padding: '24px', background: 'var(--card-bg)', borderBottom: '1px solid var(--glass-border)', display: 'flex', flexWrap: 'wrap', gap: '20px', alignItems: 'flex-end' }}>
              <div style={{ flex: '1', minWidth: '200px' }}>
                <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '1px' }}>Timeline Filter</label>
                <input type="date" value={attDate} onChange={(e) => setAttDate(e.target.value)} style={{ width: '100%', padding: '14px', borderRadius: '12px', background: 'var(--glass-surface)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', boxSizing: 'border-box' }} />
              </div>
              <div style={{ flex: '1', minWidth: '200px' }}>
                <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '1px' }}>Hub Selection</label>
                <select value={attendanceClassFilter} onChange={(e) => setAttendanceClassFilter(e.target.value)} style={{ width: '100%', padding: '14px', borderRadius: '12px', background: 'var(--glass-surface)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', boxSizing: 'border-box' }}>
                  <option value="" style={{ background: 'var(--bg-gradient-start)' }}>All Academic Hubs</option>
                  {classes.map(cls => <option key={cls.id} value={cls.id} style={{ background: 'var(--bg-gradient-start)' }}>{cls.displayName}</option>)}
                </select>
              </div>
              <button onClick={() => { setAttDate(''); setAttendanceClassFilter(''); }} style={{ padding: '14px 24px', borderRadius: '12px', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontWeight: 'bold', cursor: 'pointer' }}>Reset</button>
            </div>

            <div style={{ padding: '24px', background: 'var(--card-bg)', minHeight: '400px' }}>
              {filteredArchive.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '100px 20px', color: 'var(--text-dim)' }}>
                  <History size={64} style={{ opacity: 0.2, marginBottom: '20px' }} />
                  <h3 style={{ margin: 0, color: 'var(--text-main)' }}>No Records Found</h3>
                  <p style={{ margin: '8px 0 0 0', fontSize: '14px' }}>Adjust filters to explore historical logs.</p>
                </div>
              ) : (
                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                    <thead>
                      <tr style={{ borderBottom: '2px solid var(--glass-border)', color: 'var(--text-dim)', fontSize: '12px', textTransform: 'uppercase' }}>
                        <th style={{ padding: '16px' }}>Student Identifier</th>
                        <th style={{ padding: '16px' }}>Date</th>
                        <th style={{ padding: '16px' }}>Hub / Class</th>
                        <th style={{ padding: '16px' }}>Status</th>
                        <th style={{ padding: '16px' }}>Verified By</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredArchive.map(record => {
                        const student = students.find(s => s.id === record.student_id);
                        const hub = classes.find(c => c.id === record.class_id);
                        const statusColors = { 'present': { bg: 'rgba(16, 185, 129, 0.1)', text: '#10b981' }, 'absent': { bg: 'rgba(239, 68, 68, 0.1)', text: '#ef4444' }, 'late': { bg: 'rgba(245, 158, 11, 0.1)', text: '#f59e0b' } };
                        const colors = statusColors[record.status] || { bg: 'rgba(255,255,255,0.1)', text: 'var(--text-main)' };
                        return (
                          <tr key={record.id} style={{ borderBottom: '1px solid var(--glass-border)', fontSize: '14px' }}>
                            <td style={{ padding: '16px' }}>
                              <div style={{ fontWeight: 'bold', color: 'var(--text-main)' }}>{student?.name || 'Unknown Student'}</div>
                              <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>ID: {record.student_id.substring(0, 8)}</div>
                            </td>
                            <td style={{ padding: '16px', color: 'var(--text-dim)' }}>{record.date_string}</td>
                            <td style={{ padding: '16px' }}>{hub?.displayName || 'Legacy Hub'}</td>
                            <td style={{ padding: '16px' }}>
                              <span style={{ padding: '6px 12px', borderRadius: '8px', fontSize: '11px', fontWeight: '900', background: colors.bg, color: colors.text, textTransform: 'uppercase' }}>{record.status}</span>
                            </td>
                            <td style={{ padding: '16px', color: 'var(--text-dim)', fontSize: '13px' }}>{record.marked_by || 'System Auto'}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        );
      }

      case 'teacher_tracking': {
        const teachers = allUsers.filter(u => u.role === 'teacher');
        return (
          <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
            <div style={{
              background: 'linear-gradient(135deg, #C026D3, #E879F9)',
              padding: '32px',
              borderBottom: '1px solid var(--glass-border)',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center'
            }}>
              <div>
                <h2 style={{ margin: '0 0 8px 0', color: 'white', fontSize: '24px', fontWeight: '900' }}>Teacher Performance</h2>
                <p style={{ margin: 0, color: 'rgba(255,255,255,0.8)', fontSize: '13px' }}>Live activity and engagement metrics</p>
              </div>
              <div style={{ background: 'rgba(255,255,255,0.2)', padding: '12px 24px', borderRadius: '12px', color: 'white', fontWeight: 'bold' }}>
                Total Faculty: {teachers.length}
              </div>
            </div>

            <div style={{ padding: '24px', background: 'var(--card-bg)', minHeight: '400px' }}>
              {teachers.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '60px 20px', color: 'var(--text-dim)' }}>
                  <Users size={64} style={{ opacity: 0.3, marginBottom: '16px' }} />
                  <p style={{ fontWeight: 'bold', color: 'var(--text-main)', fontSize: '16px' }}>No teachers found.</p>
                </div>
              ) : (
                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 12px', textAlign: 'left' }}>
                    <thead>
                      <tr style={{ color: 'var(--text-main)', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '1px' }}>
                        <th style={{ padding: '0 16px 12px 16px', fontWeight: 'bold' }}>Faculty Member</th>
                        <th style={{ padding: '0 16px 12px 16px', fontWeight: 'bold', textAlign: 'center' }}>Assigns</th>
                        <th style={{ padding: '0 16px 12px 16px', fontWeight: 'bold', textAlign: 'center' }}>Quizzes</th>
                        <th style={{ padding: '0 16px 12px 16px', fontWeight: 'bold', textAlign: 'center' }}>Doubts</th>
                        <th style={{ padding: '0 16px 12px 16px', fontWeight: 'bold', textAlign: 'center' }}>Notes</th>
                        <th style={{ padding: '0 16px 12px 16px', fontWeight: 'bold', textAlign: 'center' }}>Plans</th>
                        <th style={{ padding: '0 16px 12px 16px', fontWeight: 'bold', textAlign: 'right' }}>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {teachers.map(t => {
                        const teacherLocalStats = (teacherStats || {})[t.id] || { assigns: 0, quizzes: 0, doubts: 0, notes: 0, plans: 0 };

                        return (
                          <tr key={t.id} style={{ background: 'var(--glass-surface)', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
                            <td style={{ padding: '16px', borderRadius: '16px 0 0 16px', border: '1px solid var(--glass-border)', borderRight: 'none' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                                <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: 'rgba(192, 38, 211, 0.1)', color: '#C026D3', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '18px', fontWeight: '900', overflow: 'hidden' }}>
                                  {(t.avatar_url || t.photoURL || t.profileImage || t.avatar || t.imageUrl || t.image || t.profile_image || t.avatarUrl || t.profilePic || t.profile_pic) ? (
                                    <img src={t.avatar_url || t.photoURL || t.profileImage || t.avatar || t.imageUrl || t.image || t.profile_image || t.avatarUrl || t.profilePic || t.profile_pic} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="" />
                                  ) : (
                                    (t.name || 'T').charAt(0).toUpperCase()
                                  )}
                                </div>
                                <div>
                                  <h4 style={{ margin: 0, fontSize: '15px', fontWeight: '800', color: 'var(--text-main)' }}>{t.name}</h4>
                                  <p style={{ margin: '2px 0 0 0', fontSize: '11px', color: 'var(--text-dim)' }}>{t.email}</p>
                                </div>
                              </div>
                            </td>

                            <td style={{ padding: '16px', borderTop: '1px solid var(--glass-border)', borderBottom: '1px solid var(--glass-border)', textAlign: 'center' }}>
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '6px 12px', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '8px', color: '#3b82f6' }}>
                                <BookOpen size={14} />
                                <span style={{ fontWeight: '800', fontSize: '14px' }}>{teacherLocalStats.assigns}</span>
                              </div>
                            </td>

                            <td style={{ padding: '16px', borderTop: '1px solid var(--glass-border)', borderBottom: '1px solid var(--glass-border)', textAlign: 'center' }}>
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '6px 12px', background: 'rgba(245, 158, 11, 0.1)', borderRadius: '8px', color: '#f59e0b' }}>
                                <TrendingUp size={14} />
                                <span style={{ fontWeight: '800', fontSize: '14px' }}>{teacherLocalStats.quizzes}</span>
                              </div>
                            </td>

                            <td style={{ padding: '16px', borderTop: '1px solid var(--glass-border)', borderBottom: '1px solid var(--glass-border)', textAlign: 'center' }}>
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '6px 12px', background: 'rgba(124, 58, 237, 0.1)', borderRadius: '8px', color: '#7c3aed' }}>
                                <UserCircle size={14} />
                                <span style={{ fontWeight: '800', fontSize: '14px' }}>{teacherLocalStats.doubts}</span>
                              </div>
                            </td>

                            <td style={{ padding: '16px', borderTop: '1px solid var(--glass-border)', borderBottom: '1px solid var(--glass-border)', textAlign: 'center' }}>
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '6px 12px', background: 'rgba(5, 150, 105, 0.1)', borderRadius: '8px', color: '#059669' }}>
                                <Grid size={14} />
                                <span style={{ fontWeight: '800', fontSize: '14px' }}>{stats.notes}</span>
                              </div>
                            </td>

                            <td style={{ padding: '16px', borderTop: '1px solid var(--glass-border)', borderBottom: '1px solid var(--glass-border)', textAlign: 'center' }}>
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '6px 12px', background: 'rgba(29, 78, 216, 0.1)', borderRadius: '8px', color: '#1d4ed8' }}>
                                <Brain size={14} />
                                <span style={{ fontWeight: '800', fontSize: '14px' }}>{stats.plans}</span>
                              </div>
                            </td>

                            <td style={{ padding: '16px', borderRadius: '0 16px 16px 0', border: '1px solid var(--glass-border)', borderLeft: 'none', textAlign: 'right' }}>
                              <span style={{ padding: '6px 12px', borderRadius: '8px', fontSize: '11px', fontWeight: '800', background: 'rgba(34, 197, 94, 0.1)', color: '#22c55e', letterSpacing: '0.5px' }}>
                                ACTIVE
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        );
      }

      case 'global_alerts':
        return (
          <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
            <div style={{
              background: 'linear-gradient(135deg, #b91c1c, #ef4444)',
              padding: '32px',
              borderBottom: '1px solid var(--glass-border)',
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              position: 'relative',
              overflow: 'hidden'
            }}>
              <div style={{ position: 'absolute', right: '-20px', top: '-20px', opacity: 0.2, color: 'white' }}>
                <Zap size={120} />
              </div>
              <div style={{ padding: '16px', background: 'rgba(255,255,255,0.2)', borderRadius: '16px', color: 'white', position: 'relative', zIndex: 1 }}>
                <Zap size={32} />
              </div>
              <div style={{ position: 'relative', zIndex: 1 }}>
                <h2 style={{ margin: '0 0 8px 0', color: 'white', fontSize: '24px', fontWeight: '900', letterSpacing: '0.5px' }}>Emergency Command Center</h2>
                <p style={{ margin: 0, color: 'rgba(255,255,255,0.9)', fontSize: '14px', fontWeight: '600' }}>Direct priority broadcast to all active mobile nodes.</p>
              </div>
            </div>

            <div style={{ padding: '32px', background: 'var(--card-bg)' }}>
              <form onSubmit={async (e) => {
                e.preventDefault();
                const title = e.target.title.value;
                const text = e.target.message.value;

                if (alertTarget === 'class' && !alertClassId) {
                  alert('Please select a target class first.');
                  return;
                }

                try {
                  const payload = {
                    title: title,
                    message: text,
                    type: 'emergency_broadcast',
                    priority: 'high',
                    target: alertTarget,
                    timestamp: serverTimestamp(),
                    sender_id: 'admin_command'
                  };
                  if (alertTarget === 'class') {
                    payload.class_id = alertClassId;
                  }

                  await addDoc(collection(db, 'notifications'), payload);
                  alert('Alert broadcasted successfully to mobile devices!');
                  e.target.reset();
                  setAlertTarget('all');
                  setAlertClassId('');
                } catch (err) { alert('Error broadcasting: ' + err.message); }
              }} style={{ display: 'grid', gap: '24px', maxWidth: '800px', margin: '0 auto' }}>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                  <div>
                    <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Target Audience</label>
                    <select
                      value={alertTarget}
                      onChange={(e) => setAlertTarget(e.target.value)}
                      style={{ width: '100%', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none' }}
                    >
                      <option value="all" style={{ color: 'var(--text-main)', background: 'var(--card-bg)' }}>All School Members</option>
                      <option value="teachers" style={{ color: 'var(--text-main)', background: 'var(--card-bg)' }}>Teachers Only</option>
                      <option value="class" style={{ color: 'var(--text-main)', background: 'var(--card-bg)' }}>Specific Class</option>
                    </select>
                  </div>

                  {alertTarget === 'class' ? (
                    <div>
                      <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Select Hub / Class</label>
                      <select
                        value={alertClassId}
                        onChange={(e) => setAlertClassId(e.target.value)}
                        required
                        style={{ width: '100%', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid #3b82f6', outline: 'none' }}
                      >
                        <option value="" style={{ color: 'var(--text-main)', background: 'var(--card-bg)' }}>-- Choose Target Class --</option>
                        {classes.map(cls => (
                          <option key={cls.id} value={cls.id} style={{ color: 'var(--text-main)', background: 'var(--card-bg)' }}>
                            {cls.displayName}
                          </option>
                        ))}
                      </select>
                    </div>
                  ) : <div />}
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Alert Title</label>
                  <input name="title" required placeholder="e.g., Tomorrow is a Holiday" style={{ width: '100%', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', fontSize: '16px', boxSizing: 'border-box' }} />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Message Body</label>
                  <textarea name="message" required placeholder="Type your detailed announcement here..." style={{ width: '100%', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', minHeight: '150px', fontSize: '15px', resize: 'vertical', boxSizing: 'border-box' }}></textarea>
                </div>

                <button type="submit" style={{ padding: '18px', background: 'linear-gradient(135deg, #ef4444, #b91c1c)', color: 'white', borderRadius: '12px', border: 'none', fontWeight: '900', cursor: 'pointer', fontSize: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '12px', textTransform: 'uppercase', letterSpacing: '1px', boxShadow: '0 8px 20px rgba(239, 68, 68, 0.3)' }}>
                  <Bell size={20} />
                  Transmit Broadcast
                </button>
              </form>
            </div>
          </div>
        );

      case 'institution_stats':
        return (
          <div className="glass-card" style={{ padding: '32px', background: 'var(--card-bg)' }}>
            <SchoolAnalytics
              students={students}
              allUsers={allUsers}
              classes={classes}
              attendanceArchive={attendanceArchive}
              assignments={assignments}
              quizzes={quizzes}
            />
          </div>
        );

      case 'master_timetable': {
        const activeClassId = timetableClassFilter || (classes.length > 0 ? classes[0].id : '');
        const currentTimetable = timetables.find(t => t.classId === activeClassId || t.id === activeClassId);
        const periods = currentTimetable?.[timetableDay] || [];

        return (
          <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
            <div style={{
              background: 'linear-gradient(135deg, #0f766e, #14b8a6)',
              padding: '32px',
              borderBottom: '1px solid var(--glass-border)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: '16px'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                <div style={{ padding: '16px', background: 'rgba(255,255,255,0.2)', borderRadius: '16px', color: 'white' }}>
                  <Calendar size={32} />
                </div>
                <div>
                  <h2 style={{ margin: '0 0 8px 0', color: 'white', fontSize: '24px', fontWeight: '900' }}>Timetable Manager</h2>
                  <p style={{ margin: 0, color: 'rgba(255,255,255,0.9)', fontSize: '14px' }}>AI-Conflict prevention active</p>
                </div>
              </div>
              <button
                onClick={() => {
                  if (!activeClassId) {
                    alert('Please select or create an Academic Class first.');
                    return;
                  }
                  setEditPeriodIndex(null);
                  setShowAddPeriodModal(true);
                }}
                style={{ background: 'white', color: '#0f766e', border: 'none', padding: '12px 24px', borderRadius: '12px', fontWeight: '900', fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
              >
                + Add Period
              </button>
            </div>

            <div style={{ padding: '32px', background: 'var(--card-bg)' }}>
              {/* Class Selector */}
              {classes.length > 0 ? (
                <div style={{ marginBottom: '24px' }}>
                  <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Select Academic Class</label>
                  <select
                    value={activeClassId}
                    onChange={(e) => setTimetableClassFilter(e.target.value)}
                    style={{ width: '100%', maxWidth: '400px', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none' }}
                  >
                    {classes.map(cls => (
                      <option key={cls.id} value={cls.id} style={{ color: 'var(--text-main)', background: 'var(--card-bg)' }}>
                        {cls.displayName}
                      </option>
                    ))}
                  </select>
                </div>
              ) : (
                <p style={{ color: 'var(--text-dim)' }}>No classes established yet.</p>
              )}

              {/* Day Tabs */}
              <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '16px', marginBottom: '16px', borderBottom: '1px solid var(--glass-border)' }}>
                {['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'].map(day => {
                  const isSelected = timetableDay === day;
                  return (
                    <button
                      key={day}
                      onClick={() => setTimetableDay(day)}
                      style={{
                        padding: '10px 20px',
                        background: isSelected ? '#0f766e' : 'var(--glass-surface)',
                        color: isSelected ? 'white' : 'var(--text-main)',
                        border: isSelected ? 'none' : '1px solid var(--glass-border)',
                        borderRadius: '20px',
                        fontWeight: '800',
                        fontSize: '14px',
                        cursor: 'pointer',
                        transition: 'all 0.2s',
                        boxShadow: isSelected ? '0 4px 12px rgba(15, 118, 110, 0.3)' : 'none'
                      }}
                    >
                      {day}
                    </button>
                  );
                })}
              </div>

              {/* Periods List */}
              {periods.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '60px 20px', color: 'var(--text-dim)' }}>
                  <Calendar size={48} style={{ opacity: 0.3, marginBottom: '16px' }} />
                  <p style={{ fontWeight: 'bold', color: 'var(--text-main)', fontSize: '16px' }}>Empty Schedule</p>
                  <p style={{ fontSize: '13px' }}>No periods assigned for this day.</p>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                  {periods.sort((a, b) => a.startTime - b.startTime).map((p, i) => {
                    // Format time helper
                    const formatTime = (mins) => {
                      const h = Math.floor(mins / 60);
                      const m = mins % 60;
                      const ampm = h >= 12 ? 'PM' : 'AM';
                      const formattedH = h % 12 === 0 ? 12 : h % 12;
                      const formattedM = m < 10 ? `0${m}` : m;
                      return `${formattedH}:${formattedM} ${ampm}`;
                    };

                    return (
                      <div key={i} style={{ display: 'flex', alignItems: 'center', background: 'var(--glass-surface)', padding: '20px', borderRadius: '16px', border: '1px solid var(--glass-border)', boxShadow: '0 4px 10px rgba(0,0,0,0.02)' }}>
                        <div style={{ padding: '12px', background: 'rgba(15, 118, 110, 0.1)', color: '#0f766e', borderRadius: '12px', marginRight: '20px', fontSize: '18px', fontWeight: '900', minWidth: '24px', textAlign: 'center' }}>
                          {i + 1}
                        </div>
                        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1.5fr 1fr 1.5fr', alignItems: 'center', gap: '16px' }}>
                          <div>
                            <h4 style={{ margin: 0, fontSize: '18px', fontWeight: '900', color: 'var(--text-main)' }}>{p.subject}</h4>
                            <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <Clock size={14} /> {formatTime(p.startTime)} - {formatTime(p.endTime)}
                            </p>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(5, 150, 105, 0.1)', color: '#059669', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                              {(p.teacherName || 'T').charAt(0)}
                            </div>
                            <span style={{ fontWeight: '700', fontSize: '14px', color: 'var(--text-main)' }}>{p.teacherName}</span>
                          </div>
                          <div style={{ textAlign: 'right', display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '8px' }}>
                            {p.room && (
                              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '6px 12px', background: 'rgba(255,255,255,0.05)', borderRadius: '8px', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-dim)', border: '1px solid var(--glass-border)' }}>
                                <MapPin size={12} /> {p.room}
                              </span>
                            )}
                            <button
                              onClick={() => {
                                setEditPeriodIndex(i);
                                setShowAddPeriodModal(true);
                              }}
                              className="action-btn-mini btn-blue"
                              style={{ padding: '8px', borderRadius: '8px' }}
                              title="Edit Period"
                            >
                              <Edit2 size={16} strokeWidth={2.5} />
                            </button>
                            <button
                              onClick={async () => {
                                if (!window.confirm('Are you sure you want to remove this period?')) return;
                                try {
                                  const existingSchedule = currentTimetable || {};
                                  const daySchedule = [...(existingSchedule[timetableDay] || [])];
                                  daySchedule.splice(i, 1);

                                  await setDoc(doc(db, 'timetable', activeClassId), {
                                    [timetableDay]: daySchedule,
                                    updatedAt: serverTimestamp()
                                  }, { merge: true });
                                } catch (err) {
                                  alert('Error deleting period: ' + err.message);
                                }
                              }}
                              className="action-btn-mini btn-red"
                              style={{ padding: '8px', borderRadius: '8px' }}
                              title="Delete Period"
                            >
                              <Trash size={16} strokeWidth={2.5} />
                            </button>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Add/Edit Period Modal */}
            {showAddPeriodModal && (
              <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(4px)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '24px' }}>
                <div className="glass-card" style={{ width: '90%', maxWidth: '1000px', padding: '40px', background: 'var(--card-bg)', borderRadius: '24px', boxShadow: '0 24px 50px rgba(0,0,0,0.1)' }}>
                  <h3 style={{ marginTop: 0, marginBottom: '32px', fontSize: '24px', fontWeight: '900', color: 'var(--text-main)', borderBottom: '1px solid var(--glass-border)', paddingBottom: '16px' }}>
                    {editPeriodIndex !== null ? 'Edit Period Details' : `Schedule New Period for ${timetableDay}`}
                  </h3>

                  <form key={editPeriodIndex !== null ? editPeriodIndex : 'new'} onSubmit={async (e) => {
                    e.preventDefault();
                    const form = e.target;

                    const startTimeParts = form.startTime.value.split(':');
                    const endTimeParts = form.endTime.value.split(':');
                    const startMins = parseInt(startTimeParts[0]) * 60 + parseInt(startTimeParts[1]);
                    const endMins = parseInt(endTimeParts[0]) * 60 + parseInt(endTimeParts[1]);

                    if (endMins <= startMins) {
                      alert('End time must be strictly after the start time.');
                      return;
                    }

                    const teacherId = form.teacher.value;
                    const teacherName = allUsers.find(u => u.id === teacherId)?.name || 'Unknown';

                    const newPeriod = {
                      subject: form.subject.value,
                      teacherId: teacherId,
                      teacherName: teacherName,
                      startTime: startMins,
                      endTime: endMins,
                      room: form.room.value || null
                    };

                    try {
                      const existingSchedule = currentTimetable || {};
                      const daySchedule = [...(existingSchedule[timetableDay] || [])];

                      if (editPeriodIndex !== null) {
                        daySchedule[editPeriodIndex] = newPeriod;
                      } else {
                        daySchedule.push(newPeriod);
                      }

                      await setDoc(doc(db, 'timetable', activeClassId), {
                        [timetableDay]: daySchedule,
                        updatedAt: serverTimestamp()
                      }, { merge: true });

                      setShowAddPeriodModal(false);
                      setEditPeriodIndex(null);
                    } catch (err) {
                      alert('Error saving period: ' + err.message);
                    }
                  }} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>

                    {(() => {
                      const existingPeriod = editPeriodIndex !== null ? periods[editPeriodIndex] : null;

                      const formatTimeForInput = (mins) => {
                        if (mins === undefined) return "";
                        const h = Math.floor(mins / 60);
                        const m = mins % 60;
                        return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
                      };

                      return (
                        <>
                          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                            <div>
                              <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Academic Subject</label>
                              <select name="subject" required defaultValue={existingPeriod?.subject || ''} style={{ width: '100%', boxSizing: 'border-box', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', fontSize: '15px' }}>
                                <option value="" disabled>Select Subject</option>
                                {['Mathematics', 'Science', 'English', 'Hindi', 'Social Studies', 'Computer Science', 'Physics', 'Chemistry', 'Biology', 'History', 'Geography', 'Economics'].map(s => <option key={s} value={s}>{s}</option>)}
                              </select>
                            </div>

                            <div>
                              <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Assigned Faculty</label>
                              <select name="teacher" required defaultValue={existingPeriod?.teacherId || ''} style={{ width: '100%', boxSizing: 'border-box', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', fontSize: '15px' }}>
                                <option value="" disabled>Select Teacher</option>
                                {allUsers.filter(u => u.role === 'teacher').map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
                              </select>
                            </div>
                          </div>

                          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '20px' }}>
                            <div>
                              <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Start Time</label>
                              <input type="time" name="startTime" required defaultValue={existingPeriod ? formatTimeForInput(existingPeriod.startTime) : "09:00"} style={{ width: '100%', boxSizing: 'border-box', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', fontSize: '15px' }} />
                            </div>
                            <div>
                              <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>End Time</label>
                              <input type="time" name="endTime" required defaultValue={existingPeriod ? formatTimeForInput(existingPeriod.endTime) : "10:00"} style={{ width: '100%', boxSizing: 'border-box', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', fontSize: '15px' }} />
                            </div>
                            <div>
                              <label style={{ display: 'block', marginBottom: '8px', color: 'var(--text-dim)', fontWeight: 'bold', fontSize: '13px', textTransform: 'uppercase' }}>Room (Optional)</label>
                              <input type="text" name="room" defaultValue={existingPeriod?.room || ''} placeholder="e.g., Lab 2, Room 101" style={{ width: '100%', boxSizing: 'border-box', padding: '16px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', outline: 'none', fontSize: '15px' }} />
                            </div>
                          </div>

                          <div style={{ display: 'flex', gap: '16px', marginTop: '24px' }}>
                            <button type="button" onClick={() => { setShowAddPeriodModal(false); setEditPeriodIndex(null); }} style={{ flex: 1, padding: '16px', background: 'var(--glass-surface)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', borderRadius: '12px', fontWeight: 'bold', cursor: 'pointer', fontSize: '15px' }}>Cancel Action</button>
                            <button type="submit" style={{ flex: 2, padding: '16px', background: 'linear-gradient(135deg, #0f766e, #14b8a6)', color: 'white', border: 'none', borderRadius: '12px', fontWeight: '900', cursor: 'pointer', fontSize: '15px', boxShadow: '0 8px 20px rgba(15, 118, 110, 0.3)' }}>{editPeriodIndex !== null ? 'Update Period Details' : 'Confirm & Save Period'}</button>
                          </div>
                        </>
                      );
                    })()}
                  </form>
                </div>
              </div>
            )}
          </div>
        );
      }

      case 'risk_monitor':
        return (
          <RiskMonitorHub
            predictions={predictions}
            allUsers={allUsers}
          />
        );

      case 'intelligence':
        return (
          <IntelligenceHub
            predictions={predictions}
            allUsers={allUsers}
            stats={stats}
            attendanceArchive={attendanceArchive}
            brainDnaData={brainDnaData}
            isAnalyzing={isAnalyzing}
            setIsAnalyzing={setIsAnalyzing}
            aiInsights={aiInsights}
            setAiInsights={setAiInsights}
            showIntelligenceResults={showIntelligenceResults}
            setShowIntelligenceResults={setShowIntelligenceResults}
            analyzePerformance={analyzePerformance}
          />
        );

      case 'health': {
        const usersCount = allUsers.length;
        const usersProgress = Math.min((usersCount / 100), 1) * 100;

        const aiCount = predictions.length;
        const aiProgress = Math.min((aiCount / 100), 1) * 100;

        const networkCount = attendanceArchive.length;
        const networkProgress = Math.min((networkCount / 100), 1) * 100;

        return (
          <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
            <div style={{
              background: 'linear-gradient(135deg, #0F172A, #1E293B)',
              padding: '40px 32px',
              borderBottom: '1px solid var(--glass-border)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: '16px'
            }}>
              <div>
                <h2 style={{ margin: '0 0 8px 0', color: 'white', fontSize: '32px', fontWeight: '900' }}>System Health Diagnostics</h2>
                <p style={{ margin: 0, color: 'rgba(255,255,255,0.7)', fontSize: '13px' }}>Real-time core performance and security tracking.</p>
              </div>
            </div>

            <div style={{ padding: '32px', background: 'var(--card-bg)' }}>
              {/* CORE SECURE Card */}
              <div style={{ display: 'flex', alignItems: 'center', background: 'linear-gradient(135deg, #0F172A, #1E293B)', padding: '24px', borderRadius: '24px', boxShadow: '0 10px 30px rgba(59, 130, 246, 0.15)', marginBottom: '32px' }}>
                <div style={{ padding: '16px', background: 'rgba(52, 211, 153, 0.1)', borderRadius: '50%', marginRight: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <ShieldCheck size={32} color="#34d399" />
                </div>
                <div style={{ flex: 1 }}>
                  <h4 style={{ margin: 0, fontSize: '20px', fontWeight: '900', color: 'white', letterSpacing: '1px' }}>CORE SECURE</h4>
                  <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: 'rgba(255,255,255,0.7)' }}>All systems operating at 100% efficiency</p>
                </div>
              </div>

              <h4 style={{ margin: '0 0 16px 0', fontSize: '12px', fontWeight: '900', letterSpacing: '1.5px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>
                Telemetry Real-Time
              </h4>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '20px', marginBottom: '40px' }}>
                <div style={{ background: 'var(--input-bg)', padding: '20px', borderRadius: '16px', border: '1px solid var(--glass-border)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '12px' }}>
                    <Users color="#3b82f6" size={20} />
                    <span style={{ fontWeight: '800', fontSize: '15px', color: 'var(--text-main)', flex: 1 }}>Firestore Pulse</span>
                    <span style={{ fontWeight: '900', fontSize: '15px', color: '#3b82f6' }}>{Math.max(usersProgress, 10).toFixed(0)}%</span>
                  </div>
                  <div style={{ height: '8px', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '8px', overflow: 'hidden' }}>
                    <div style={{ width: `${Math.max(usersProgress, 10)}%`, height: '100%', background: '#3b82f6', borderRadius: '8px', transition: 'width 1s ease-out' }}></div>
                  </div>
                  <p style={{ margin: '8px 0 0 0', fontSize: '12px', color: 'var(--text-dim)' }}>Real-time database synchronization status</p>
                </div>

                <div style={{ background: 'var(--input-bg)', padding: '20px', borderRadius: '16px', border: '1px solid var(--glass-border)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '12px' }}>
                    <Brain color="#c084fc" size={20} />
                    <span style={{ fontWeight: '800', fontSize: '15px', color: 'var(--text-main)', flex: 1 }}>AI Inference Load</span>
                    <span style={{ fontWeight: '900', fontSize: '15px', color: '#c084fc' }}>{Math.max(aiProgress, 10).toFixed(0)}%</span>
                  </div>
                  <div style={{ height: '8px', background: 'rgba(192, 132, 252, 0.1)', borderRadius: '8px', overflow: 'hidden' }}>
                    <div style={{ width: `${Math.max(aiProgress, 10)}%`, height: '100%', background: '#c084fc', borderRadius: '8px', transition: 'width 1s ease-out' }}></div>
                  </div>
                  <p style={{ margin: '8px 0 0 0', fontSize: '12px', color: 'var(--text-dim)' }}>Volume of predictive analysis threads</p>
                </div>

                <div style={{ background: 'var(--input-bg)', padding: '20px', borderRadius: '16px', border: '1px solid var(--glass-border)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '12px' }}>
                    <Cpu color="#2dd4bf" size={20} />
                    <span style={{ fontWeight: '800', fontSize: '15px', color: 'var(--text-main)', flex: 1 }}>Network Latency</span>
                    <span style={{ fontWeight: '900', fontSize: '15px', color: '#2dd4bf' }}>{Math.max(networkProgress, 10).toFixed(0)}%</span>
                  </div>
                  <div style={{ height: '8px', background: 'rgba(45, 212, 191, 0.1)', borderRadius: '8px', overflow: 'hidden' }}>
                    <div style={{ width: `${Math.max(networkProgress, 10)}%`, height: '100%', background: '#2dd4bf', borderRadius: '8px', transition: 'width 1s ease-out' }}></div>
                  </div>
                  <p style={{ margin: '8px 0 0 0', fontSize: '12px', color: 'var(--text-dim)' }}>Average response time for global packets</p>
                </div>
              </div>

              <h4 style={{ margin: '0 0 16px 0', fontSize: '12px', fontWeight: '900', letterSpacing: '1.5px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>
                Live System Activity (Synced)
              </h4>

              <div style={{ background: 'var(--glass-surface)', borderRadius: '16px', border: '1px solid var(--glass-border)', overflow: 'hidden' }}>
                {recentAlerts.length > 0 ? recentAlerts.map((log, index) => (
                  <div key={log.id || index} style={{ padding: '16px 20px', borderBottom: index < recentAlerts.length - 1 ? '1px solid var(--glass-border)' : 'none', display: 'flex', alignItems: 'center', gap: '16px' }}>
                    {log.type === 'security' || log.level === 'critical' ? <ShieldCheck size={20} color="#34d399" /> : <Settings size={20} color="var(--text-dim)" />}
                    <div style={{ flex: 1 }}>
                      <h5 style={{ margin: 0, fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>
                        {log.action || log.message || 'System Event Recorded'}
                      </h5>
                      <p style={{ margin: '4px 0 0 0', fontSize: '12px', color: 'var(--text-dim)' }}>
                        {log.timestamp?.toDate ? log.timestamp.toDate().toLocaleString() : 'Just now'} • {log.user || 'System'}
                      </p>
                    </div>
                  </div>
                )) : (
                  <div style={{ padding: '32px 20px', textAlign: 'center', color: 'var(--text-dim)', fontSize: '13px' }}>
                    No recent activity logs found in database.
                  </div>
                )}
              </div>

            </div>
          </div>
        );
      }

      case 'settings':
        return (
          <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
            <div style={{
              background: 'linear-gradient(135deg, #0F172A, #1E293B)',
              padding: '32px',
              borderBottom: '1px solid var(--glass-border)'
            }}>
              <h2 style={{ margin: '0', color: 'white', fontSize: '24px', fontWeight: '900' }}>System Configuration</h2>
            </div>

            <div style={{ padding: '32px', background: 'var(--card-bg)' }}>
              {role === 'admin' ? (
                <>
                  {/* AI & ANALYTICS ENGINE */}
                  <h4 style={{ margin: '0 0 16px 0', fontSize: '11px', fontWeight: '900', letterSpacing: '1.5px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>
                    AI & Analytics Engine
                  </h4>
                  <div style={{ background: 'var(--glass-surface)', padding: '24px', borderRadius: '16px', border: '1px solid var(--glass-border)', marginBottom: '32px' }}>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
                      <div style={{ padding: '10px', background: 'rgba(168, 85, 247, 0.1)', borderRadius: '50%', color: '#a855f7' }}>
                        <Brain size={20} />
                      </div>
                      <div style={{ flex: 1 }}>
                        <h5 style={{ margin: 0, fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>Core AI Model</h5>
                        <select
                          value={aiModel}
                          onChange={(e) => setAiModel(e.target.value)}
                          style={{
                            marginTop: '8px', width: '100%', padding: '8px 0', background: 'transparent',
                            border: 'none', borderBottom: '1px solid var(--glass-border)',
                            color: 'var(--text-main)', fontSize: '13px', outline: 'none'
                          }}
                        >
                          <option value="Gemini-1.5-Pro" style={{ background: 'var(--bg-gradient-start)' }}>Gemini-1.5-Pro</option>
                          <option value="Gemini-1.5-Flash" style={{ background: 'var(--bg-gradient-start)' }}>Gemini-1.5-Flash</option>
                          <option value="EduTrack-Custom-v2" style={{ background: 'var(--bg-gradient-start)' }}>EduTrack-Custom-v2</option>
                        </select>
                      </div>
                    </div>

                    <div style={{ borderTop: '1px solid var(--glass-border)', paddingTop: '24px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                        <span style={{ fontWeight: '700', fontSize: '14px', color: 'var(--text-main)' }}>Risk Sensitivity</span>
                        <span style={{ fontWeight: '900', color: '#3b82f6' }}>{attendanceThreshold.toFixed(0)}% Threshold</span>
                      </div>
                      <input
                        type="range"
                        min="50" max="90"
                        value={attendanceThreshold}
                        onChange={(e) => setAttendanceThreshold(parseFloat(e.target.value))}
                        style={{ width: '100%', accentColor: '#3b82f6' }}
                      />
                      <p style={{ margin: '8px 0 0 0', fontSize: '11px', color: 'var(--text-dim)' }}>Students below this attendance will be flagged as High Risk.</p>
                    </div>
                  </div>

                  {/* NOTIFICATION NODES */}
                  <h4 style={{ margin: '0 0 16px 0', fontSize: '11px', fontWeight: '900', letterSpacing: '1.5px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>
                    Notification Nodes
                  </h4>
                  <div style={{ background: 'var(--glass-surface)', borderRadius: '16px', border: '1px solid var(--glass-border)', marginBottom: '32px', overflow: 'hidden' }}>

                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 24px', borderBottom: '1px solid var(--glass-border)' }}>
                      <div style={{ flex: 1 }}>
                        <h5 style={{ margin: 0, fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>Auto-Notify Parents</h5>
                        <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'var(--text-dim)' }}>Send instant alerts for attendance/grade dips</p>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                        <div style={{ padding: '8px', background: 'rgba(249, 115, 22, 0.1)', borderRadius: '50%', color: '#f97316' }}>
                          <Bell size={18} />
                        </div>
                        <div
                          onClick={() => setAutoNotifyParents(!autoNotifyParents)}
                          style={{ cursor: 'pointer', color: autoNotifyParents ? '#3b82f6' : 'var(--text-dim)' }}
                        >
                          <ToggleRight size={32} fill={autoNotifyParents ? '#3b82f6' : 'transparent'} stroke={autoNotifyParents ? 'white' : 'currentColor'} />
                        </div>
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '20px 24px', cursor: 'pointer', transition: 'background 0.2s' }} className="hover-bg-glass">
                      <div style={{ padding: '8px', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '50%', color: '#3b82f6' }}>
                        <Globe size={18} />
                      </div>
                      <div style={{ flex: 1 }}>
                        <h5 style={{ margin: 0, fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>Global Announcement Rules</h5>
                        <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'var(--text-dim)' }}>Define who can send bulk messages</p>
                      </div>
                      <ChevronRight size={20} color="var(--text-dim)" />
                    </div>
                  </div>

                  {/* SECURITY & ACCESS */}
                  <h4 style={{ margin: '0 0 16px 0', fontSize: '11px', fontWeight: '900', letterSpacing: '1.5px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>
                    Security & Access
                  </h4>
                  <div style={{ background: 'var(--glass-surface)', borderRadius: '16px', border: '1px solid var(--glass-border)', marginBottom: '32px', overflow: 'hidden' }}>

                    <div
                      onClick={() => handleTabChange('manage_users')}
                      style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '20px 24px', borderBottom: '1px solid var(--glass-border)', cursor: 'pointer', transition: 'background 0.2s' }}
                      className="hover-bg-glass"
                    >
                      <div style={{ padding: '8px', background: 'rgba(239, 68, 68, 0.1)', borderRadius: '50%', color: '#ef4444' }}>
                        <ShieldCheck size={18} />
                      </div>
                      <div style={{ flex: 1 }}>
                        <h5 style={{ margin: 0, fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>Permissions Matrix</h5>
                        <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'var(--text-dim)' }}>Configure role-based access control</p>
                      </div>
                      <ChevronRight size={20} color="var(--text-dim)" />
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '20px 24px', cursor: 'pointer', transition: 'background 0.2s' }} className="hover-bg-glass">
                      <div style={{ padding: '8px', background: 'rgba(20, 184, 166, 0.1)', borderRadius: '50%', color: '#14b8a6' }}>
                        <Database size={18} />
                      </div>
                      <div style={{ flex: 1 }}>
                        <h5 style={{ margin: 0, fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>Database Backup Control</h5>
                        <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'var(--text-dim)' }}>Schedule automated system backups</p>
                      </div>
                      <ChevronRight size={20} color="var(--text-dim)" />
                    </div>
                  </div>
                </>
              ) : null}

              {/* LOCAL UI SETTINGS */}
              <h4 style={{ margin: '0 0 16px 0', fontSize: '11px', fontWeight: '900', letterSpacing: '1.5px', color: 'var(--text-dim)', textTransform: 'uppercase' }}>
                Local Visuals
              </h4>
              <div style={{ background: 'var(--glass-surface)', borderRadius: '16px', border: '1px solid var(--glass-border)', marginBottom: '40px', overflow: 'hidden' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 24px' }}>
                  <div style={{ flex: 1 }}>
                    <h5 style={{ margin: 0, fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>Visual Theme</h5>
                    <p style={{ margin: '4px 0 0 0', fontSize: '11px', color: 'var(--text-dim)' }}>Switch between Light and Dark mode for this browser</p>
                  </div>
                  <button
                    onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
                    style={{ background: theme === 'dark' ? '#3b82f6' : '#8b5cf6', padding: '8px 16px', fontSize: '12px', fontWeight: 'bold' }}
                  >
                    {theme === 'dark' ? 'Enable Light Mode' : 'Enable Dark Mode'}
                  </button>
                </div>
              </div>

              <button
                onClick={handleSaveConfig}
                style={{ width: '100%', background: '#0F172A', color: 'white', padding: '16px', borderRadius: '16px', fontSize: '16px', fontWeight: '900', letterSpacing: '0.5px', cursor: 'pointer' }}
              >
                Save & Sync Configuration
              </button>
            </div>
          </div>
        );

      case 'doubts':
        return (
          <DoubtHub
            doubts={doubts}
            backendOnline={backendOnline}
            aiDoubtLoading={aiDoubtLoading}
            setAiDoubtLoading={setAiDoubtLoading}
            generalChat={generalChat}
            db={db}
            fullUserData={fullUserData}
          />
        );

      case 'new_quiz':
      case 'quizzes':
        return (
<<<<<<< HEAD
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
            <div className="glass-card" style={{ padding: '24px' }}>
              <h3>Create New Quiz</h3>
              <form onSubmit={async (e) => {
                e.preventDefault();
                const formData = new FormData(e.target);
                await addDoc(collection(db, 'quizzes'), {
                  title: formData.get('title'),
                  subject: formData.get('subject'),
                  questions_count: parseInt(formData.get('count')),
                  duration: parseInt(formData.get('duration')),
                  class_id: formData.get('class'),
                  teacher_id: user.uid,
                  created_at: serverTimestamp()
                });
                alert('Quiz Published to Mobile App!');
                e.target.reset();
              }} style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginTop: '16px' }}>
                <input name="title" placeholder="Quiz Title" required style={{ padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)' }} />
                <input name="subject" placeholder="Subject" required style={{ padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)' }} />
                <div style={{ display: 'flex', gap: '12px' }}>
                  <input name="count" type="number" placeholder="No. of Questions" required style={{ flex: 1, padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)' }} />
                  <input name="duration" type="number" placeholder="Duration (mins)" required style={{ flex: 1, padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)' }} />
                </div>
                <select name="class" required style={{ padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)' }}>
                  {classes.map(c => <option key={c.id} value={c.id}>{c.standard} - {c.section}</option>)}
                </select>
                <button type="submit" style={{ background: '#f59e0b' }}>Publish Quiz</button>
              </form>
            </div>
            <div className="glass-card" style={{ padding: '24px' }}>
              <h3>Active Quizzes</h3>
              <div style={{ marginTop: '16px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {quizzes.map(q => (
                  <div key={q.id} style={{ padding: '16px', borderRadius: '12px', background: 'rgba(255,255,255,0.03)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <p style={{ fontWeight: '600' }}>{q.title}</p>
                      <p style={{ fontSize: '12px', color: 'var(--text-dim)' }}>{q.subject} | {q.questions_count} Qs | {q.duration} mins</p>
                    </div>
                    <button
                      onClick={() => deleteDoc(doc(db, 'quizzes', q.id))}
                      style={{ padding: '8px', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', border: 'none' }}
                    >
                      <Trash size={16} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        );

      case 'manage_assignments':
        return (
          <div className="glass-card" style={{ padding: '24px' }}>
            <h2>All Assignments</h2>
            <div style={{ marginTop: '24px', display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px' }}>
              {assignments.map(a => (
                <div key={a.id} className="glass-card" style={{ padding: '20px', background: 'rgba(255,255,255,0.02)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div>
                      <h4 style={{ margin: 0 }}>{a.title}</h4>
                      <p style={{ fontSize: '12px', color: 'var(--text-dim)', marginTop: '4px' }}>{a.subject} | Class {a.class_id}</p>
                    </div>
                    <button onClick={() => deleteDoc(doc(db, 'assignments', a.id))} style={{ background: 'transparent', color: '#ef4444' }}>
                      <Trash size={18} />
                    </button>
                  </div>
                  <div style={{ marginTop: '16px', display: 'flex', justifyContent: 'space-between', fontSize: '12px' }}>
                    <span style={{ color: '#f59e0b' }}>Due: {a.due_date}</span>
                    <span style={{ color: 'var(--text-dim)' }}>Created: {a.created_at?.toDate().toLocaleDateString()}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
=======
          <QuizHub
            classes={visibleClasses}
            quizzes={quizzes}
            user={user}
            db={db}
            quizDraftQuestions={quizDraftQuestions}
            setQuizDraftQuestions={setQuizDraftQuestions}
            isGeneratingQuiz={isGeneratingQuiz}
            setIsGeneratingQuiz={setIsGeneratingQuiz}
            backendOnline={backendOnline}
            generateQuiz={generateQuiz}
            setActiveTab={setActiveTab}
          />
>>>>>>> 82a22ca (Professionalize Bulk Grading Hub with Auto-Sync and fix System Crash hook violation)
        );

      case 'leave_requests':
        return (
          <div className="glass-card" style={{ padding: '24px' }}>
            <h2 style={{ marginBottom: '24px' }}>Leave Approvals</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {leaves.map(l => (
                <div key={l.id} className="glass-card" style={{ padding: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <p style={{ fontWeight: '700', fontSize: '16px' }}>{l.studentName}</p>
                    <p style={{ fontSize: '14px', color: 'var(--text-main)', marginTop: '4px' }}>{l.reason}</p>
                    <p style={{ fontSize: '12px', color: 'var(--text-dim)', marginTop: '8px' }}>{l.startDate} to {l.endDate}</p>
                  </div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    {l.status === 'pending' ? (
                      <>
                        <button
                          onClick={() => updateDoc(doc(db, 'leave_requests', l.id), { status: 'approved' })}
                          style={{ background: '#10b981' }}
                        >
                          Approve
                        </button>
                        <button
                          onClick={() => updateDoc(doc(db, 'leave_requests', l.id), { status: 'rejected' })}
                          style={{ background: '#ef4444' }}
                        >
                          Reject
                        </button>
                      </>
                    ) : (
                      <span style={{ fontWeight: 'bold', color: l.status === 'approved' ? '#10b981' : '#ef4444', textTransform: 'uppercase', fontSize: '12px' }}>
                        {l.status}
                      </span>
                    )}
                  </div>
                </div>
              ))}
              {leaves.length === 0 && <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-dim)' }}>No leave requests found.</div>}
            </div>
          </div>
        );
      case 'classroom':
        return (
          <div className="glass-card" style={{ padding: '32px' }}>
            <h2 style={{ marginBottom: '24px' }}>Classroom Management</h2>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
              {[
                { id: 'attendance', label: 'Mark Attendance', icon: <CheckCircle size={32} />, color: '#10b981' },
                { id: 'attendance_archive', label: 'Attendance Archive', icon: <Clock size={32} />, color: '#0F172A' },
                { id: 'manage_assignments', label: 'Assignments Hub', icon: <BookOpen size={32} />, color: '#6366f1' },
                { id: 'quizzes', label: 'Quiz Hub', icon: <TrendingUp size={32} />, color: '#f59e0b' },
                { id: 'bulk_grading', label: 'Bulk Grading', icon: <TrendingUp size={32} />, color: '#ec4899' },
              ].map(mod => (
                <div key={mod.id} className="nav-item" onClick={() => handleTabChange(mod.id)} style={{ flexDirection: 'column', gap: '16px', padding: '32px 20px', background: 'var(--glass-surface)', border: '1px solid var(--glass-border)', height: 'auto', alignItems: 'center', textAlign: 'center' }}>
                  <div style={{ color: mod.color }}>{mod.icon}</div>
                  <span style={{ fontSize: '16px', fontWeight: '700' }}>{mod.label}</span>
                </div>
              ))}
            </div>
          </div>
        );

      case 'ailabs':
        return (
          <div className="glass-card" style={{ padding: '32px' }}>
            <h2 style={{ marginBottom: '24px' }}>AI Labs & Insights</h2>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
              {[
                { id: 'lesson_plans', label: 'AI Lesson Plan', icon: <Cpu size={32} />, color: '#1d4ed8' },
                { id: 'upload_notes', label: 'Upload Notes', icon: <FileText size={32} />, color: '#059669' },
                { id: 'intelligence', label: 'Smart Analysis', icon: <BarChart3 size={32} />, color: '#8b5cf6' },
                { id: 'master_timetable', label: 'My Timetable', icon: <Grid size={32} />, color: '#eab308' },
              ].map(mod => (
                <div key={mod.id} className="nav-item" onClick={() => handleTabChange(mod.id)} style={{ flexDirection: 'column', gap: '16px', padding: '32px 20px', background: 'var(--glass-surface)', border: '1px solid var(--glass-border)', height: 'auto', alignItems: 'center', textAlign: 'center' }}>
                  <div style={{ color: mod.color }}>{mod.icon}</div>
                  <span style={{ fontSize: '16px', fontWeight: '700' }}>{mod.label}</span>
                </div>
              ))}
            </div>
          </div>
        );

      case 'connect':
        return (
          <div className="glass-card" style={{ padding: '32px' }}>
            <h2 style={{ marginBottom: '24px' }}>Connect & Support</h2>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
              {[
                { id: 'doubts', label: 'Student Doubts', icon: <HelpCircle size={32} />, color: '#7c3aed' },
                { id: 'leave_requests', label: 'Leave Approvals', icon: <Calendar size={32} />, color: '#0d9488' },
              ].map(mod => (
                <div key={mod.id} className="nav-item" onClick={() => handleTabChange(mod.id)} style={{ flexDirection: 'column', gap: '16px', padding: '32px 20px', background: 'var(--glass-surface)', border: '1px solid var(--glass-border)', height: 'auto', alignItems: 'center', textAlign: 'center' }}>
                  <div style={{ color: mod.color }}>{mod.icon}</div>
                  <span style={{ fontSize: '16px', fontWeight: '700' }}>{mod.label}</span>
                </div>
              ))}
            </div>
          </div>
        );

      case 'bulk_grading':
        return (
          <BulkGradingHub
            classes={visibleClasses}
            students={students}
            assignments={assignments}
            submissions={submissions}
            selectedClass={selectedClass}
            setSelectedClass={setSelectedClass}
            db={db}
            user={user}
            fullUserData={fullUserData}
          />
        );

      case 'lesson_plans':
        return (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
            <div className="glass-card" style={{ padding: '24px' }}>
              <h3>AI Lesson Planner</h3>
              <p style={{ fontSize: '13px', color: 'var(--text-dim)', marginBottom: '20px' }}>Generate smart lesson plans synced to your mobile app.</p>
              <form id="lesson-plan-form" onSubmit={async (e) => {
                e.preventDefault();
                const formData = new FormData(e.target);
                const title = formData.get('title');
                const subject = formData.get('subject');
                const objectives = formData.get('objectives');
                const classId = formData.get('class');

                // Save to Firestore
                await addDoc(collection(db, 'lesson_plans'), {
                  title, subject, objectives,
                  teacherId: user.uid,
                  classId,
                  aiGenerated: generatedPlan ? true : false,
                  aiPlan: generatedPlan || null,
                  createdAt: serverTimestamp()
                });
                alert('Lesson Plan Saved & Synced!');
                setGeneratedPlan('');
                e.target.reset();
              }} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <input name="title" placeholder="Topic Title" required style={{ padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)' }} />
                <input name="subject" placeholder="Subject" required style={{ padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)' }} />
                <textarea name="objectives" placeholder="Learning Objectives (One per line)" rows="3" required style={{ padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)', resize: 'none' }} />
                <select name="class" required style={{ padding: '12px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'white', border: '1px solid var(--glass-border)' }}>
                  {classes.map(c => <option key={c.id} value={c.id}>{c.standard} - {c.section}</option>)}
                </select>
                <div style={{ display: 'flex', gap: '10px' }}>
                  {backendOnline && (
                    <button
                      type="button"
                      disabled={aiPlanLoading}
                      onClick={async () => {
                        const form = document.getElementById('lesson-plan-form');
                        const fd = new FormData(form);
                        const subject = fd.get('subject');
                        const title = fd.get('title');
                        if (!subject || !title) { alert('Enter Subject and Topic first.'); return; }
                        setAiPlanLoading(true);
                        try {
                          const result = await generateLessonPlan({ subject, topic: title, duration: '45 minutes', grade: 'Grade 9' });
                          setGeneratedPlan(result.plan || '');
                        } catch (e) { alert('AI generation failed: ' + e.message); }
                        finally { setAiPlanLoading(false); }
                      }}
                      style={{ flex: 1, padding: '12px', background: 'linear-gradient(135deg, #7c3aed, #6366f1)', color: 'white', border: 'none', borderRadius: '8px', fontWeight: '700', cursor: aiPlanLoading ? 'wait' : 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}
                    >
                      {aiPlanLoading ? <><div style={{ width: '14px', height: '14px', border: '2px solid rgba(255,255,255,0.4)', borderTopColor: 'white', borderRadius: '50%', animation: 'spin 1s linear infinite' }}></div> Generating...</> : <><Zap size={14} /> AI Generate</>}
                    </button>
                  )}
                  <button type="submit" style={{ flex: 1, background: '#1d4ed8', padding: '12px', borderRadius: '8px', fontWeight: '700', color: 'white', border: 'none', cursor: 'pointer' }}>
                    Save & Sync
                  </button>
                </div>
              </form>

              {/* AI Generated Plan Preview */}
              {generatedPlan && (
                <div style={{ marginTop: '20px', padding: '20px', background: 'rgba(99,102,241,0.05)', borderRadius: '12px', border: '1px solid rgba(99,102,241,0.2)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                    <span style={{ fontSize: '12px', fontWeight: '900', color: '#6366f1', textTransform: 'uppercase', letterSpacing: '1px' }}>AI Generated Preview</span>
                    <button onClick={() => setGeneratedPlan('')} style={{ background: 'none', border: 'none', color: 'var(--text-dim)', cursor: 'pointer', fontSize: '12px' }}>Clear</button>
                  </div>
                  <pre style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word', fontSize: '12px', color: 'var(--text-main)', lineHeight: '1.7', maxHeight: '300px', overflowY: 'auto' }}>
                    {generatedPlan}
                  </pre>
                </div>
              )}
            </div>
            <div className="glass-card" style={{ padding: '24px' }}>
              <h3>My Lesson Plans</h3>
              <div style={{ marginTop: '16px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {lessonPlans.map(lp => (
                  <div key={lp.id} style={{ padding: '16px', borderRadius: '12px', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--glass-border)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <div style={{ fontWeight: '700' }}>{String(lp.title || 'Untitled Plan')}</div>
                      {lp.aiGenerated && <span style={{ fontSize: '10px', color: '#6366f1', background: 'rgba(99,102,241,0.1)', padding: '2px 8px', borderRadius: '10px', fontWeight: '700', flexShrink: 0 }}>AI</span>}
                    </div>
                    <div style={{ fontSize: '12px', color: 'var(--text-dim)' }}>{String(lp.subject || 'General')} | Hub {String(lp.classId || 'Global')}</div>
                    <div style={{ marginTop: '12px', fontSize: '13px', color: 'var(--text-main)' }}>
                      {(lp.objectives || '').split('\n').map((o, i) => <div key={i}>- {String(o)}</div>)}
                    </div>
                    {lp.aiPlan && (
                      <details style={{ marginTop: '12px' }}>
                        <summary style={{ cursor: 'pointer', fontSize: '12px', color: '#6366f1', fontWeight: '700' }}>View AI Plan</summary>
                        <pre style={{ whiteSpace: 'pre-wrap', fontSize: '11px', color: 'var(--text-dim)', marginTop: '8px', lineHeight: '1.6' }}>{lp.aiPlan}</pre>
                      </details>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        );

      case 'assignments':
      case 'create_assignment':
      case 'manage_assignments':
        return (
          <AssignmentsHub
            user={user}
            assignments={assignments}
            submissions={submissions}
            students={students}
            classes={visibleClasses}
            db={db}
            fullUserData={fullUserData}
            assignmentFile={assignmentFile}
            isUploadingAssignment={isUploadingAssignment}
            handleAssignmentFileChange={handleAssignmentFileChange}
            assignmentFileUrl={assignmentFileUrl}
            setAssignmentFileUrl={setAssignmentFileUrl}
            setAssignmentFile={setAssignmentFile}
            mode={activeTab === 'create_assignment' ? 'create' : (activeTab === 'manage_assignments' ? 'manage' : null)}
            setActiveTab={setActiveTab}
          />
        );


      case 'upload_notes':
        return (
          <div className="glass-card" style={{ padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h2>Upload Class Notes</h2>
              <button onClick={() => alert('File upload simulated. In a real environment, this would use Firebase Storage.')}>+ Select Files</button>
            </div>
            <div className="glass-card" style={{ padding: '40px', textAlign: 'center', border: '2px dashed var(--glass-border)', background: 'transparent' }}>
              <FileText size={48} color="var(--text-dim)" style={{ marginBottom: '16px' }} />
              <p style={{ color: 'var(--text-dim)' }}>Drag and drop PDF or Word documents here</p>
              <p style={{ fontSize: '12px', color: 'var(--text-dim)', marginTop: '8px' }}>Max size: 10MB</p>
            </div>

            <div style={{ marginTop: '32px' }}>
              <h3>Previously Uploaded</h3>
              <div style={{ marginTop: '16px', display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: '16px' }}>
                {(notes || []).filter(n => n.teacherId === user.uid).map((file, i) => (
                  <div key={file.id || i} className="glass-card" style={{ padding: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <FileText size={24} color="#059669" />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '14px', fontWeight: '600', margin: 0 }}>{String(file.title || 'Note')}</div>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)', margin: '4px 0 0 0' }}>{file.createdAt && typeof file.createdAt.toDate === 'function' ? file.createdAt.toDate().toLocaleDateString() : 'Just now'}</div>
                    </div>
                    <Trash size={16} color="#ef4444" style={{ cursor: 'pointer' }} onClick={() => deleteDoc(doc(db, 'notes', file.id))} />
                  </div>
                ))}
              </div>
            </div>
          </div>
        );

      case 'announcements':
        return <Announcements role={role} user={user} classes={visibleClasses} fullUserData={fullUserData} />;

      case 'messages':
        return <Messages role={role} user={user} classes={visibleClasses} allUsers={allUsers} fullUserData={fullUserData} />;

      case 'quiz_results':
        return <QuizResults role={role} user={user} quizzes={quizzes} allUsers={allUsers} />;

      case 'student_analytics':
        return <StudentAnalytics role={role} allUsers={allUsers} classes={visibleClasses} quizResults={quizResults} quizzes={quizzes} />;

      case 'school_analytics':
        return <SchoolAnalytics students={students} allUsers={allUsers} classes={visibleClasses} attendanceArchive={attendanceArchive} assignments={assignments} quizzes={quizzes} />;

      case 'profile': {
        const isAdmin = role === 'admin';
        const profileColor = role === 'admin' ? '#6366f1' : (role === 'teacher' ? '#10b981' : '#ec4899');

        return (
          <div style={{ maxWidth: '850px', margin: '0 auto', paddingBottom: '60px' }}>
            {/* Minimalist Profile Header */}
            <div className="glass-card" style={{ padding: '32px', marginBottom: '24px', position: 'relative', overflow: 'hidden' }}>
              <div style={{ position: 'absolute', top: 0, right: 0, width: '200px', height: '100%', background: `linear-gradient(to left, ${profileColor}15, transparent)`, pointerEvents: 'none' }}></div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '24px', position: 'relative', zIndex: 1 }}>
                <div style={{ position: 'relative' }}>
                  <div style={{
                    width: '100px', height: '100px', borderRadius: '28px',
                    background: 'white', padding: '4px', boxShadow: '0 10px 25px rgba(0,0,0,0.1)'
                  }}>
                    <div style={{
                      width: '100%', height: '100%', borderRadius: '24px',
                      justifyContent: 'center', fontSize: '40px', fontWeight: '900', color: profileColor,
                      overflow: 'hidden', position: 'relative'
                    }}>
                      {syncingImage && (
                        <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10 }}>
                          <motion.div animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1 }}>
                            <Zap size={24} color="white" />
                          </motion.div>
                        </div>
                      )}
                      {(fullUserData?.avatar_url || fullUserData?.photoURL || fullUserData?.profileImage || fullUserData?.avatar || fullUserData?.imageUrl || fullUserData?.image || fullUserData?.profile_image || fullUserData?.avatarUrl || fullUserData?.profilePic || fullUserData?.profile_pic) ? (
                        <img
                          src={fullUserData.avatar_url || fullUserData.photoURL || fullUserData.profileImage || fullUserData.avatar || fullUserData.imageUrl || fullUserData.image || fullUserData.profile_image || fullUserData.avatarUrl || fullUserData.profilePic || fullUserData.profile_pic}
                          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                          alt="Profile"
                        />
                      ) : (
                        user.email?.charAt(0).toUpperCase()
                      )}
                    </div>
                  </div>
                  <label style={{
                    position: 'absolute', bottom: '-5px', right: '-5px',
                    background: '#10b981', padding: '8px', borderRadius: '12px',
                    cursor: 'pointer', border: '3px solid white', color: 'white',
                    boxShadow: '0 5px 15px rgba(0,0,0,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center'
                  }}>
                    <Camera size={14} />
                    <input type="file" hidden accept="image/*" onChange={async (e) => {
                      const file = e.target.files[0];
                      if (!file) return;
                      try {
                        setSyncingImage(true);
                        const storageRef = ref(storage, `profiles/${user.uid}`);
                        await uploadBytes(storageRef, file);
                        const url = await getDownloadURL(storageRef);

                        const updates = {
                          avatar_url: url, // Primary Mobile Sync Key
                          photoURL: url,
                          image: url,
                          profile_image: url,
                          avatar: url,
                          photo_url: url,
                          profilePic: url,
                          profile_pic: url,
                          imageUrl: url
                        };

                        await updateDoc(doc(db, 'users', user.uid), updates);
                        setFullUserData(prev => ({ ...prev, ...updates }));
                        alert('Master Identity Synchronized.');
                      } catch (err) { alert('Sync Failed: ' + err.message); }
                      finally { setSyncingImage(false); }
                    }} />
                  </label>
                </div>
                <div>
                  <h2 style={{ margin: '0 0 4px 0', fontSize: '24px', fontWeight: '900', color: 'var(--text-main)', letterSpacing: '-0.5px' }}>
                    {fullUserData?.name || 'Academic Member'}
                  </h2>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <span style={{ padding: '4px 10px', background: `${profileColor}20`, color: profileColor, borderRadius: '8px', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                      {role} Access
                    </span>
                    <span style={{ color: 'var(--text-dim)', fontSize: '13px', fontWeight: '600' }}>{user.email}</span>
                  </div>
                </div>
              </div>

              {/* Internal Tabs */}
              <div style={{ display: 'flex', gap: '32px', marginTop: '32px', borderTop: '1px solid var(--glass-border)', paddingTop: '20px' }}>
                {[
                  { id: 'identity', label: 'Identity & Info', icon: <UserCircle size={16} /> },
                  { id: 'security', label: 'Hub Pass', icon: <ShieldCheck size={16} /> },
                  { id: 'stats', label: 'Platform Usage', icon: <TrendingUp size={16} /> }
                ].map(tab => (
                  <button
                    key={tab.id}
                    onClick={() => setProfileTab(tab.id)}
                    style={{
                      background: 'none', border: 'none', padding: '0 0 12px 0',
                      color: profileTab === tab.id ? profileColor : 'var(--text-dim)',
                      fontSize: '13px', fontWeight: '700', cursor: 'pointer',
                      display: 'flex', alignItems: 'center', gap: '8px',
                      borderBottom: `2px solid ${profileTab === tab.id ? profileColor : 'transparent'}`,
                      transition: 'all 0.2s'
                    }}
                  >
                    {tab.icon} {tab.label}
                  </button>
                ))}
              </div>
            </div>

            {profileTab === 'identity' && (
              <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="glass-card" style={{ padding: '32px', borderRadius: '24px' }}>
                <form onSubmit={async (e) => {
                  e.preventDefault();
                  const formData = new FormData(e.target);
                  try {
                    await updateDoc(doc(db, 'users', user.uid), {
                      name: formData.get('name'),
                      phone: formData.get('phone'),
                      location: formData.get('location'),
                      bio: formData.get('bio'),
                      fatherName: formData.get('fatherName')
                    });
                    alert('Institutional Records Synchronized.');
                  } catch (err) { alert('Push Error: ' + err.message); }
                }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>Full Name</label>
                      <input name="name" defaultValue={fullUserData?.name} className="glass-input" style={{ width: '100%', padding: '14px' }} />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>Institutional Email (Read-only)</label>
                      <input value={user.email} className="glass-input" style={{ width: '100%', padding: '14px', opacity: 0.6 }} readOnly />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>Contact Number</label>
                      <input name="phone" defaultValue={fullUserData?.phone} className="glass-input" style={{ width: '100%', padding: '14px' }} placeholder="+91 XXXX XXXX" />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>Guardian / Father's Name</label>
                      <input name="fatherName" defaultValue={fullUserData?.fatherName} className="glass-input" style={{ width: '100%', padding: '14px' }} placeholder="Father's Name" />
                    </div>
                  </div>

                  <div style={{ marginBottom: '20px' }}>
                    <label style={{ display: 'block', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>Operational Location / Address</label>
                    <input name="location" defaultValue={fullUserData?.location} className="glass-input" style={{ width: '100%', padding: '14px' }} placeholder="City, State, Country" />
                  </div>

                  <div style={{ marginBottom: '24px' }}>
                    <label style={{ display: 'block', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>Biographical Ledger / Bio</label>
                    <textarea name="bio" defaultValue={fullUserData?.bio} className="glass-input" style={{ width: '100%', height: '80px', padding: '14px', resize: 'none' }} placeholder="Academic summary..." />
                  </div>

                  <button type="submit" className="primary-btn" style={{ width: '100%', padding: '18px', borderRadius: '18px', fontWeight: '900', background: profileColor, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px' }}>
                    <CheckCircle size={20} /> Synchronize All Hub Records
                  </button>
                </form>
              </motion.div>
            )}

            {profileTab === 'security' && (
              <motion.div initial={{ opacity: 0, scale: 0.98 }} animate={{ opacity: 1, scale: 1 }} style={{ display: 'flex', justifyContent: 'center' }}>
                <div className="glass-card" style={{
                  width: '100%', maxWidth: '400px', padding: '32px',
                  background: 'linear-gradient(135deg, #0F172A, #1E293B)', color: 'white', border: 'none',
                  borderRadius: '32px', boxShadow: '0 25px 50px rgba(0,0,0,0.3)', position: 'relative'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '40px' }}>
                    <div style={{ fontSize: '18px', fontWeight: '900' }}>EduTrack <span style={{ color: '#10b981' }}>Pass</span></div>
                    <ShieldCheck size={20} color="#10b981" />
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '32px' }}>
                    <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', overflow: 'hidden' }}>
                      {(fullUserData?.avatar_url || fullUserData?.photoURL || fullUserData?.profileImage || fullUserData?.avatar || fullUserData?.imageUrl || fullUserData?.image || fullUserData?.profile_image || fullUserData?.avatarUrl || fullUserData?.profilePic || fullUserData?.profile_pic) ? (
                        <img src={fullUserData.avatar_url || fullUserData.photoURL || fullUserData.profileImage || fullUserData.avatar || fullUserData.imageUrl || fullUserData.image || fullUserData.profile_image || fullUserData.avatarUrl || fullUserData.profilePic || fullUserData.profile_pic} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="" />
                      ) : (
                        <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '20px', fontWeight: '900' }}>{user.email?.charAt(0).toUpperCase()}</div>
                      )}
                    </div>
                    <div>
                      <div style={{ fontSize: '16px', fontWeight: '800' }}>{fullUserData?.name}</div>
                      <div style={{ fontSize: '10px', color: '#10b981', fontWeight: '800', textTransform: 'uppercase' }}>{role} MEMBER</div>
                    </div>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                    <div>
                      <div style={{ fontSize: '8px', color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', marginBottom: '4px' }}>IDENTIFIER</div>
                      <div style={{ fontSize: '13px', fontWeight: '900', fontFamily: 'monospace' }}>{fullUserData?.roll_no || fullUserData?.studentId || fullUserData?.facultyId || 'TBD'}</div>
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '8px', color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase', marginBottom: '4px' }}>ACADEMIC HUB</label>
                      <div style={{ fontSize: '13px', fontWeight: '900' }}>{fullUserData?.class_id || fullUserData?.school_id || 'GLOBAL'}</div>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {profileTab === 'stats' && (
              <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="glass-card" style={{ padding: '32px', borderRadius: '24px' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px', marginBottom: '32px' }}>
                  {[
                    { label: 'Cloud Sync', value: '99.9%', color: '#6366f1' },
                    { label: 'Hub Fidelity', value: 'High', color: '#10b981' },
                    { label: 'Data Points', value: '2.4k', color: '#ec4899' }
                  ].map(s => (
                    <div key={s.label} style={{ padding: '20px', background: 'var(--glass-surface)', borderRadius: '20px', textAlign: 'center', border: '1px solid var(--glass-border)' }}>
                      <div style={{ fontSize: '20px', fontWeight: '900', color: s.color }}>{s.value}</div>
                      <div style={{ fontSize: '10px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginTop: '4px' }}>{s.label}</div>
                    </div>
                  ))}
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <div style={{ padding: '16px', borderRadius: '16px', background: 'var(--glass-surface)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div style={{ padding: '8px', background: 'rgba(16, 185, 129, 0.1)', borderRadius: '10px', color: '#10b981' }}><ShieldCheck size={16} /></div>
                      <span style={{ fontSize: '13px', fontWeight: '700' }}>Automatic Backups</span>
                    </div>
                    <span style={{ fontSize: '11px', fontWeight: '800', color: '#10b981' }}>ENABLED</span>
                  </div>
                </div>
              </motion.div>
            )}
          </div>
        );
      }

      default:
        return <div className="glass-card" style={{ padding: '40px', textAlign: 'center' }}>Module Coming Soon</div>;
    }
  };

  const isTabActive = (tabId) => {
    // 1. Direct Match (Highest Priority)
    if (activeTab === tabId) return true;

    // 2. Sub-modules categorization
    const classroomFeatures = ['attendance', 'attendance_archive', 'manage_assignments', 'quizzes', 'bulk_grading', 'new_quiz', 'create_assignment', 'classroom'];
    const managementFeatures = ['history', 'manage_users', 'manage_classes', 'attendance_archive', 'intelligence', 'teacher_tracking', 'global_alerts', 'institution_stats', 'master_timetable', 'risk_monitor', 'manage_assignments'];

    // 3. Parental & Mapping logic
    if (tabId === 'classroom' && classroomFeatures.includes(activeTab)) return true;
    if (tabId === 'management' && managementFeatures.includes(activeTab)) return true;

    // AI Labs Mapping
    if (tabId === 'ailabs' && activeTab === 'intelligence') return true;

    return false;
  };

  return (
    <div className="app-container">
      <aside className={`sidebar ${sidebarCollapsed ? 'collapsed' : ''}`} style={{
        backdropFilter: 'blur(20px)',
      }}>
        <div style={{ padding: '0 10px 28px', display: 'flex', alignItems: 'center', gap: '12px' }}>
          <img
            src={logo}
            style={{ width: '44px', height: '44px', objectFit: 'contain', flexShrink: 0, cursor: 'pointer', transition: 'transform 0.2s ease' }}
            alt="Logo"
            title={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
            onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.1)'}
            onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
          />
          <div className="sidebar-brand-text">
            <h1 style={{ fontSize: '18px', fontWeight: '800', margin: 0, color: 'var(--text-main)', letterSpacing: '-0.5px', fontFamily: 'Outfit, sans-serif', whiteSpace: 'nowrap' }}>EduTrack<span style={{ color: 'var(--primary)' }}>.ai</span></h1>
            <div style={{ fontSize: '9px', color: '#10b981', fontWeight: '700', letterSpacing: '1.5px', textTransform: 'uppercase', marginTop: '2px', whiteSpace: 'nowrap' }}> System Active</div>
          </div>
        </div>

        <div className="nav-section-label" style={{ marginTop: '4px' }}>MAIN</div>
        <nav style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '2px' }}>
          <motion.div
            whileHover={{ x: sidebarCollapsed ? 0 : 3 }}
            className={`nav-item ${isTabActive('dashboard') ? 'active' : ''}`}
            onClick={() => handleTabChange('dashboard')}
            data-tooltip="Dashboard"
          >
            <LayoutDashboard size={18} /> <span className="nav-item-text">Dashboard</span>
          </motion.div>

          {role === 'teacher' && (
            <>
              <div className="nav-section-label" style={{ marginTop: '12px' }}>ACADEMIC</div>
              {[
                { id: 'classroom', label: 'Classroom', icon: <GraduationCap size={18} /> },
                { id: 'ailabs', label: 'AI Labs', icon: <Brain size={18} /> },
                { id: 'quiz_results', label: 'Quiz Results', icon: <CheckCircle size={18} /> },
                { id: 'student_analytics', label: 'Student Analytics', icon: <BarChart3 size={18} /> },
              ].map(item => (
                <motion.div
                  key={item.id}
                  whileHover={{ x: sidebarCollapsed ? 0 : 3 }}
                  className={`nav-item ${isTabActive(item.id) ? 'active' : ''}`}
                  onClick={() => handleTabChange(item.id)}
                  data-tooltip={item.label}
                >
                  {item.icon} <span className="nav-item-text">{item.label}</span>
                </motion.div>
              ))}

              <div className="nav-section-label" style={{ marginTop: '12px' }}>COMMUNICATION</div>
              {[
                { id: 'connect', label: 'Connect', icon: <MessageSquare size={18} /> },
                { id: 'announcements', label: 'Academic Bulletins', icon: <Megaphone size={18} /> },
                { id: 'messages', label: 'Messages', icon: <MessageSquare size={18} /> },
              ].map(item => (
                <motion.div
                  key={item.id}
                  whileHover={{ x: sidebarCollapsed ? 0 : 3 }}
                  className={`nav-item ${isTabActive(item.id) ? 'active' : ''}`}
                  onClick={() => handleTabChange(item.id)}
                  data-tooltip={item.label}
                >
                  {item.icon} <span className="nav-item-text">{item.label}</span>
                </motion.div>
              ))}
            </>
          )}

          {role === 'admin' && (
            <>
              <div className="nav-section-label" style={{ marginTop: '12px' }}>ADMINISTRATION</div>
              {[
                { id: 'management', label: 'Control Center', icon: <Cpu size={18} /> },
                { id: 'school_analytics', label: 'School Analytics', icon: <BarChart3 size={18} /> },
                { id: 'announcements', label: 'Academic Bulletins', icon: <Megaphone size={18} /> },
                { id: 'messages', label: 'Messages', icon: <MessageSquare size={18} /> },
                { id: 'student_analytics', label: 'Student Analytics', icon: <Brain size={18} /> },
                { id: 'quiz_results', label: 'Quiz Results', icon: <CheckCircle size={18} /> },
              ].map(item => (
                <motion.div
                  key={item.id}
                  whileHover={{ x: sidebarCollapsed ? 0 : 3 }}
                  className={`nav-item ${isTabActive(item.id) ? 'active' : ''}`}
                  onClick={() => handleTabChange(item.id)}
                  data-tooltip={item.label}
                >
                  {item.icon} <span className="nav-item-text">{item.label}</span>
                </motion.div>
              ))}
            </>
          )}
        </nav>

        <div ref={profileMenuRef} style={{ marginTop: 'auto', borderTop: '1px solid var(--glass-border)', paddingTop: '16px', position: 'relative' }}>

          <div
            onClick={() => setShowProfileMenu(!showProfileMenu)}
            style={{
              padding: sidebarCollapsed ? '8px' : '12px',
              borderRadius: '16px',
              transition: 'all 0.3s ease',
              cursor: 'pointer',
              background: showProfileMenu ? 'var(--glass-surface)' : 'transparent'
            }}
            className="hover-bg-glass"
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', justifyContent: sidebarCollapsed ? 'center' : 'flex-start' }}>
              <div style={{
                width: sidebarCollapsed ? '36px' : '40px', height: sidebarCollapsed ? '36px' : '40px', borderRadius: '50%',
                background: role === 'admin' ? 'var(--primary)' : 'var(--secondary)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: '16px', fontWeight: '900', color: 'white',
                boxShadow: '0 4px 10px rgba(0,0,0,0.2)',
                overflow: 'hidden', flexShrink: 0,
                transition: 'all 0.3s ease'
              }}>
                {(fullUserData?.avatar_url || fullUserData?.photoURL || fullUserData?.profileImage || fullUserData?.avatar || fullUserData?.imageUrl || fullUserData?.image || fullUserData?.profile_image || fullUserData?.avatarUrl || fullUserData?.profilePic || fullUserData?.profile_pic) ? (
                  <img
                    src={fullUserData.avatar_url || fullUserData.photoURL || fullUserData.profileImage || fullUserData.avatar || fullUserData.imageUrl || fullUserData.image || fullUserData.profile_image || fullUserData.avatarUrl || fullUserData.profilePic || fullUserData.profile_pic}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    alt="Avatar"
                  />
                ) : (
                  user.email?.charAt(0).toUpperCase()
                )}
              </div>
              <div className="profile-info" style={{ flex: 1, overflow: 'hidden', transition: 'all 0.2s ease' }}>
                <p style={{ margin: 0, fontSize: '14px', fontWeight: '700', color: 'var(--text-main)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {fullUserData?.name || 'User'}
                </p>
                <p style={{ margin: 0, fontSize: '10px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase' }}>{role} Account</p>
              </div>
              <ChevronUp className="profile-chevron" size={16} color="var(--text-dim)" style={{ transform: showProfileMenu ? 'rotate(180deg)' : 'none', transition: 'transform 0.3s' }} />
            </div>
          </div>
        </div>
      </aside>

      {/* Profile Popup - rendered OUTSIDE sidebar to avoid overflow clipping */}
      {showProfileMenu && (
        <motion.div
          ref={profilePopupRef}
          initial={{ opacity: 0, y: 10, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.15, ease: 'easeOut' }}
          style={{
            position: 'fixed',
            bottom: '80px',
            left: sidebarCollapsed ? '8px' : '8px',
            width: sidebarCollapsed ? '240px' : '244px',
            background: 'var(--card-bg)',
            backdropFilter: 'blur(20px)',
            borderRadius: '14px',
            border: '1px solid var(--glass-border)',
            padding: '0',
            boxShadow: '0 12px 40px rgba(0,0,0,0.4)',
            zIndex: 1001,
            overflow: 'hidden'
          }}
        >
          {/* User Info Header */}
          <div style={{ padding: '14px 16px', borderBottom: '1px solid var(--glass-border)', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{
              width: '36px', height: '36px', borderRadius: '10px',
              background: role === 'admin' ? 'var(--primary)' : 'var(--secondary)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: '14px', fontWeight: '900', color: 'white',
              overflow: 'hidden', flexShrink: 0
            }}>
              {(fullUserData?.avatar_url || fullUserData?.photoURL || fullUserData?.profileImage || fullUserData?.avatar || fullUserData?.imageUrl || fullUserData?.image || fullUserData?.profile_image || fullUserData?.avatarUrl || fullUserData?.profilePic || fullUserData?.profile_pic) ? (
                <img src={fullUserData.avatar_url || fullUserData.photoURL || fullUserData.profileImage || fullUserData.avatar || fullUserData.imageUrl || fullUserData.image || fullUserData.profile_image || fullUserData.avatarUrl || fullUserData.profilePic || fullUserData.profile_pic} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="" />
              ) : (
                user.email?.charAt(0).toUpperCase()
              )}
            </div>
            <div style={{ overflow: 'hidden' }}>
              <p style={{ margin: 0, fontSize: '13px', fontWeight: '700', color: 'var(--text-main)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{fullUserData?.name || 'User'}</p>
              <p style={{ margin: 0, fontSize: '11px', color: 'var(--text-dim)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{user.email}</p>
            </div>
          </div>

          {/* Menu Items */}
          <div style={{ padding: '6px' }}>
            <motion.div
              whileHover={{ background: 'var(--glass-surface-hover)' }}
              onClick={(e) => {
                e.stopPropagation();
                handleTabChange('profile');
                setShowProfileMenu(false);
              }}
              style={{
                display: 'flex', alignItems: 'center', gap: '12px',
                padding: '10px 12px', borderRadius: '10px',
                cursor: 'pointer', transition: 'background 0.15s ease'
              }}
            >
              <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <UserCircle size={16} />
              </div>
              <div>
                <p style={{ margin: 0, fontSize: '13px', fontWeight: '600', color: 'var(--text-main)' }}>My Profile</p>
                <p style={{ margin: 0, fontSize: '10px', color: 'var(--text-dim)' }}>Edit personal info & photo</p>
              </div>
            </motion.div>

            <motion.div
              whileHover={{ background: 'var(--glass-surface-hover)' }}
              onClick={(e) => {
                e.stopPropagation();
                handleTabChange('settings');
                setShowProfileMenu(false);
              }}
              style={{
                display: 'flex', alignItems: 'center', gap: '12px',
                padding: '10px 12px', borderRadius: '10px',
                cursor: 'pointer', transition: 'background 0.15s ease'
              }}
            >
              <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Settings size={16} />
              </div>
              <div>
                <p style={{ margin: 0, fontSize: '13px', fontWeight: '600', color: 'var(--text-main)' }}>Settings</p>
                <p style={{ margin: 0, fontSize: '10px', color: 'var(--text-dim)' }}>Theme, AI config & alerts</p>
              </div>
            </motion.div>

            {role === 'admin' && (
              <motion.div
                whileHover={{ background: 'var(--glass-surface-hover)' }}
                onClick={(e) => {
                  e.stopPropagation();
                  handleTabChange('health');
                  setShowProfileMenu(false);
                }}
                style={{
                  display: 'flex', alignItems: 'center', gap: '12px',
                  padding: '10px 12px', borderRadius: '10px',
                  cursor: 'pointer', transition: 'background 0.15s ease'
                }}
              >
                <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <HeartPulse size={16} />
                </div>
                <div>
                  <p style={{ margin: 0, fontSize: '13px', fontWeight: '600', color: 'var(--text-main)' }}>System Health</p>
                  <p style={{ margin: 0, fontSize: '10px', color: 'var(--text-dim)' }}>View diagnostics & logs</p>
                </div>
              </motion.div>
            )}
          </div>

          {/* Logout Divider */}
          <div style={{ borderTop: '1px solid var(--glass-border)', padding: '6px' }}>
            <motion.div
              whileHover={{ background: 'rgba(239, 68, 68, 0.08)' }}
              onClick={(e) => {
                e.stopPropagation();
                handleLogout();
              }}
              style={{
                display: 'flex', alignItems: 'center', gap: '12px',
                padding: '10px 12px', borderRadius: '10px',
                cursor: 'pointer', transition: 'background 0.15s ease'
              }}
            >
              <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(239, 68, 68, 0.1)', color: '#f43f5e', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <LogOut size={16} />
              </div>
              <div>
                <p style={{ margin: 0, fontSize: '13px', fontWeight: '600', color: '#f43f5e' }}>Logout</p>
                <p style={{ margin: 0, fontSize: '10px', color: 'var(--text-dim)' }}>Sign out of this session</p>
              </div>
            </motion.div>
          </div>
        </motion.div>
      )}

      <main className={`main-content ${sidebarCollapsed ? 'shifted' : ''}`}>
        {/* AI Backend Status Badge */}
        <div style={{
          position: 'fixed', top: '16px', right: '20px', zIndex: 200,
          display: 'flex', alignItems: 'center', gap: '6px',
          padding: '6px 12px', borderRadius: '20px',
          background: backendOnline ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)',
          border: `1px solid ${backendOnline ? 'rgba(16,185,129,0.3)' : 'rgba(239,68,68,0.3)'}`,
          backdropFilter: 'blur(10px)',
          fontSize: '11px', fontWeight: '800', letterSpacing: '0.5px',
          color: backendOnline ? '#10b981' : '#ef4444',
          cursor: 'default',
          transition: 'all 0.3s ease'
        }}>
          <span style={{
            width: '7px', height: '7px', borderRadius: '50%',
            background: backendOnline ? '#10b981' : '#ef4444',
            boxShadow: backendOnline ? '0 0 6px #10b981' : 'none',
            animation: backendOnline ? 'pulse 2s infinite' : 'none'
          }}></span>
          {backendOnline ? 'Groq AI Online' : 'AI Backend Offline'}
        </div>

        {backendError && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            style={{
              background: 'rgba(239, 68, 68, 0.1)',
              border: '1px solid #ef4444',
              borderRadius: '16px',
              padding: '16px 24px',
              margin: '20px',
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              color: '#ef4444',
              boxShadow: '0 8px 32px rgba(239, 68, 68, 0.1)',
              backdropFilter: 'blur(10px)'
            }}
          >
            <ShieldAlert size={24} />
            <div style={{ flex: 1 }}>
              <h4 style={{ margin: 0, fontSize: '15px', fontWeight: '900' }}>Critical Infrastructure Issue</h4>
              <p style={{ margin: '2px 0 0 0', fontSize: '13px', opacity: 0.8 }}>{backendError}</p>
            </div>
            <button
              onClick={() => window.location.reload()}
              style={{ background: '#ef4444', color: 'white', border: 'none', padding: '10px 20px', borderRadius: '10px', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer' }}
            >
              Retry Sync
            </button>
          </motion.div>
        )}

        {renderContent()}

        {/* User Edit Modal */}
        {showEditUserModal && editingUser && (
          <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(15, 23, 42, 0.4)', backdropFilter: 'blur(10px)', zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
            <motion.div initial={{ opacity: 0, scale: 0.95, y: 10 }} animate={{ opacity: 1, scale: 1, y: 0 }} style={{ width: '100%', maxWidth: '500px', background: '#ffffff', borderRadius: '32px', overflow: 'hidden', boxShadow: '0 30px 60px -12px rgba(0, 0, 0, 0.25)', border: '1px solid #e2e8f0' }}>
              {/* Header */}
              <div style={{ background: 'linear-gradient(135deg, #ecfdf5, #d1fae5)', padding: '24px 32px', borderBottom: '1px solid #d1fae5' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div style={{ width: '44px', height: '44px', borderRadius: '14px', background: '#ffffff', color: '#059669', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(5, 150, 105, 0.1)' }}>
                      <UserCircle size={26} />
                    </div>
                    <div>
                      <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '800', color: '#064e3b', letterSpacing: '-0.5px' }}>Member Profile</h3>
                      <p style={{ margin: 0, fontSize: '11px', color: '#059669', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Identity & Security</p>
                    </div>
                  </div>
                  <button onClick={() => setShowEditUserModal(false)} style={{ background: 'transparent', border: 'none', color: '#059669', padding: '8px', borderRadius: '12px', cursor: 'pointer', opacity: 0.6, transition: 'opacity 0.2s' }} onMouseEnter={(e) => e.currentTarget.style.opacity = '1'} onMouseLeave={(e) => e.currentTarget.style.opacity = '0.6'}>
                    <TrendingUp size={20} style={{ transform: 'rotate(45deg)' }} />
                  </button>
                </div>
              </div>

              <form onSubmit={async (e) => {
                e.preventDefault();
                const formData = new FormData(e.target);
                try {
                  const role = formData.get('role') || editingUser.role;
                  const idValue = formData.get('idValue');

                  const updateData = {
                    name: formData.get('name'),
                    email: formData.get('email'),
                    role: role,
                    classId: formData.get('classId') || null,
                    phone: formData.get('phone') || null,
                    linkedStudentRollNo: formData.get('linkedStudentRollNo') || null,
                    linkedStudentClass: formData.get('linkedStudentClass') || null
                  };

                  // Assign ID to correct field based on role
                  if (role === 'student') updateData.studentId = idValue;
                  else if (role === 'teacher') {
                    updateData.facultyId = idValue;
                    updateData.specialization = teacherSpecs; // Use state
                    updateData.academicUnits = teacherClasses; // Use state
                  }

                  await updateDoc(doc(db, 'users', editingUser.id), updateData);
                  setShowEditUserModal(false);
                  setEditingUser(null);
                  alert('Profile updated and synchronized.');
                } catch (err) { alert('Update Error: ' + err.message); }
              }} style={{ padding: '32px', display: 'flex', flexDirection: 'column', gap: '20px' }}>

                <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '10px' }}>
                  <div style={{ position: 'relative' }}>
                    <div style={{ width: '80px', height: '80px', borderRadius: '20px', background: '#f8fafc', border: '1px solid #e2e8f0', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {(editingUser.avatar_url || editingUser.photoURL || editingUser.profileImage || editingUser.avatar || editingUser.imageUrl || editingUser.image || editingUser.profile_image || editingUser.avatarUrl || editingUser.profilePic || editingUser.profile_pic) ? (
                        <img src={editingUser.avatar_url || editingUser.photoURL || editingUser.profileImage || editingUser.avatar || editingUser.imageUrl || editingUser.image || editingUser.profile_image || editingUser.avatarUrl || editingUser.profilePic || editingUser.profile_pic} style={{ width: '100%', height: '100%', objectFit: 'cover' }} alt="" />
                      ) : (
                        <UserCircle size={40} color="#cbd5e1" />
                      )}
                    </div>
                    <label style={{ position: 'absolute', bottom: '-8px', right: '-8px', background: '#059669', color: 'white', padding: '6px', borderRadius: '10px', cursor: 'pointer', border: '2px solid white', boxShadow: '0 4px 10px rgba(0,0,0,0.1)' }}>
                      <Camera size={14} />
                      <input type="file" hidden accept="image/*" onChange={async (e) => {
                        const file = e.target.files[0];
                        if (!file) return;
                        try {
                          setSyncingImage(true);
                          const storageRef = ref(storage, `profiles/${editingUser.id}`);
                          await uploadBytes(storageRef, file);
                          const url = await getDownloadURL(storageRef);

                          const updates = {
                            avatar_url: url,
                            photoURL: url,
                            image: url,
                            profile_image: url,
                            avatar: url,
                            imageUrl: url,
                            profilePic: url,
                            profile_pic: url
                          };

                          await updateDoc(doc(db, 'users', editingUser.id), updates);
                          setEditingUser(prev => ({ ...prev, ...updates }));
                          alert('Profile photo updated and synced to mobile app.');
                        } catch (err) { alert('Upload Failed: ' + err.message); }
                        finally { setSyncingImage(false); }
                      }} />
                    </label>
                  </div>
                  <div style={{ flex: 1 }}>
                    <h4 style={{ margin: 0, fontSize: '15px', fontWeight: '800', color: '#1e293b' }}>Profile Identity</h4>
                    <p style={{ margin: '4px 0 0 0', fontSize: '12px', color: '#64748b' }}>Upload a photo to update it across all linked mobile devices.</p>
                    {syncingImage && <div style={{ marginTop: '8px', fontSize: '11px', color: '#059669', fontWeight: '700' }}>Synchronizing Identity Hub...</div>}
                  </div>
                </div>

                <div style={{ display: 'grid', gap: '16px' }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '16px' }}>
                    <div>
                      <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Full Name</label>
                      <input name="name" defaultValue={editingUser.name} required style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', borderRadius: '12px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontSize: '14px' }} />
                    </div>
                    <div>
                      <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>{editingUser.role === 'student' ? 'Roll No' : (editingUser.role === 'teacher' ? 'Faculty ID' : 'ID')}</label>
                      <input name="idValue" defaultValue={editingUser.studentId || editingUser.rollNo || editingUser.roll_no || editingUser.facultyId || ''} style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', borderRadius: '12px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontSize: '14px' }} />
                    </div>
                  </div>

                  <div>
                    <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Email Address</label>
                    <input name="email" type="email" defaultValue={editingUser.email} required style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', borderRadius: '12px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontSize: '14px' }} />
                  </div>

                  {editingUser.role === 'teacher' && (
                    <>
                      <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                        <label style={{ display: 'block', marginBottom: '12px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Subject Specialization</label>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                          {['Physics', 'Chemistry', 'Mathematics', 'Biology', 'English', 'Hindi', 'Computer Science', 'Art'].map(subject => {
                            const isSelected = teacherSpecs.includes(subject);
                            return (
                              <button key={subject} type="button" onClick={() => isSelected ? setTeacherSpecs(p => p.filter(s => s !== subject)) : setTeacherSpecs(p => [...p, subject])}
                                style={{ padding: '6px 12px', borderRadius: '8px', fontSize: '12px', fontWeight: '600', transition: 'all 0.2s', background: isSelected ? '#10b981' : '#ffffff', color: isSelected ? 'white' : '#64748b', border: isSelected ? '1px solid #10b981' : '1px solid #e2e8f0', cursor: 'pointer' }}>
                                {subject}
                              </button>
                            );
                          })}
                        </div>
                      </div>

                      <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                        <label style={{ display: 'block', marginBottom: '12px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Assigned Classes</label>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                          {classes.map(c => {
                            const isSelected = teacherClasses.includes(c.id);
                            return (
                              <button key={c.id} type="button" onClick={() => isSelected ? setTeacherClasses(p => p.filter(id => id !== c.id)) : setTeacherClasses(p => [...p, c.id])}
                                style={{ padding: '6px 12px', borderRadius: '8px', fontSize: '12px', fontWeight: '600', transition: 'all 0.2s', background: isSelected ? '#3b82f6' : '#ffffff', color: isSelected ? 'white' : '#64748b', border: isSelected ? '1px solid #3b82f6' : '1px solid #e2e8f0', cursor: 'pointer' }}>
                                {c.displayName}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    </>
                  )}

                  {editingUser.role === 'parent' && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                        <div>
                          <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Child's Roll No</label>
                          <input
                            name="linkedStudentRollNo"
                            value={tempParentChildRoll}
                            onChange={(e) => setTempParentChildRoll(e.target.value)}
                            placeholder="Roll No"
                            style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', borderRadius: '12px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontSize: '14px' }}
                          />
                        </div>
                        <div>
                          <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Child's Class</label>
                          <select name="linkedStudentClass" defaultValue={editingUser.linkedStudentClass || ''} style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', borderRadius: '12px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontSize: '13px', fontWeight: '600' }}>
                            <option value="">Select Class</option>
                            {classes.map(c => <option key={c.id} value={c.displayName || c.id}>{c.displayName}</option>)}
                          </select>
                        </div>
                      </div>

                      {/* Real-time Student Matching */}
                      {tempParentChildRoll && (
                        <div style={{ padding: '12px', background: '#f0f9ff', borderRadius: '12px', border: '1px solid #bae6fd', display: 'flex', alignItems: 'center', gap: '12px' }}>
                          {(() => {
                            const matchedStudent = allUsers.find(u =>
                              u.role === 'student' &&
                              (String(u.rollNo) == String(tempParentChildRoll) ||
                                String(u.roll_no) == String(tempParentChildRoll) ||
                                String(u.studentId) == String(tempParentChildRoll))
                            );
                            if (matchedStudent) {
                              return (
                                <>
                                  <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#3b82f6', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 'bold' }}>
                                    {matchedStudent.name?.charAt(0)}
                                  </div>
                                  <div>
                                    <div style={{ fontSize: '13px', fontWeight: '700', color: '#0369a1' }}>{matchedStudent.name}</div>
                                    <div style={{ fontSize: '11px', color: '#0ea5e9', fontWeight: '600' }}>Student Found in Hub: {matchedStudent.classId || matchedStudent.className || 'General'}</div>
                                  </div>
                                </>
                              );
                            } else {
                              return <div style={{ fontSize: '12px', color: '#ef4444', fontWeight: '600' }}>No student found with this Roll Number</div>;
                            }
                          })()}
                        </div>
                      )}
                    </div>
                  )}

                  <div style={{ display: 'grid', gridTemplateColumns: (editingUser.role === 'student' || editingUser.role === 'teacher' || editingUser.role === 'parent') ? '1fr' : '1fr 1fr', gap: '16px' }}>
                    {(editingUser.role !== 'student' && editingUser.role !== 'teacher' && editingUser.role !== 'parent') && (
                      <div>
                        <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>System Role</label>
                        <select name="role" defaultValue={editingUser.role} style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', borderRadius: '12px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontSize: '13px', fontWeight: '600' }}>
                          <option value="student">Student</option>
                          <option value="teacher">Teacher</option>
                          <option value="parent">Parent</option>
                          <option value="admin">Administrator</option>
                        </select>
                      </div>
                    )}
                    {(editingUser.role !== 'teacher' && editingUser.role !== 'parent') && (
                      <div>
                        <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Assigned Hub</label>
                        <select name="classId" defaultValue={editingUser.classId || editingUser.class_id || editingUser.className || ''} style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', borderRadius: '12px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontSize: '13px', fontWeight: '600' }}>
                          <option value="">None</option>
                          {classes.map(c => <option key={c.id} value={c.id}>{c.displayName}</option>)}
                        </select>
                      </div>
                    )}
                  </div>

                  <div>
                    <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Contact Number</label>
                    <input name="phone" defaultValue={editingUser.phone || ''} style={{ width: '100%', boxSizing: 'border-box', padding: '12px 14px', borderRadius: '12px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontSize: '14px' }} />
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '12px', marginTop: '10px' }}>
                  <button type="button" onClick={() => setShowEditUserModal(false)} style={{ flex: 1, padding: '14px', borderRadius: '12px', background: '#f1f5f9', color: '#475569', border: 'none', fontWeight: '800', cursor: 'pointer', fontSize: '13px' }}>Cancel</button>
                  <button type="submit" style={{ flex: 2, padding: '14px', borderRadius: '12px', background: '#10b981', color: 'white', border: 'none', fontWeight: '900', cursor: 'pointer', fontSize: '13px', boxShadow: '0 10px 20px rgba(16, 185, 129, 0.2)' }}>Update Profile</button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </main>

      {/* Edit Hub Modal */}
      {showEditHubModal && editingHub && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(10px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10000, padding: '20px' }}>
          <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} style={{ width: '100%', maxWidth: '450px', background: 'white', borderRadius: '24px', overflow: 'hidden', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' }}>
            <div style={{ padding: '24px', background: '#3b82f6', color: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h3 style={{ margin: 0, fontSize: '20px', fontWeight: '900' }}>Modify Academic Hub</h3>
                <p style={{ margin: '4px 0 0 0', fontSize: '11px', opacity: 0.8, fontWeight: '700', textTransform: 'uppercase' }}>Hub ID: {editingHub.id}</p>
              </div>
              <button onClick={() => setShowEditHubModal(false)} style={{ background: 'rgba(255,255,255,0.2)', border: 'none', color: 'white', padding: '8px', borderRadius: '12px', cursor: 'pointer' }}>
                <XCircle size={20} />
              </button>
            </div>

            <form onSubmit={async (e) => {
              e.preventDefault();
              const formData = new FormData(e.target);
              const standard = formData.get('standard');
              const section = formData.get('section');
              const displayName = section ? `${standard} - ${section}` : standard;

              try {
                await updateDoc(doc(db, 'classes', editingHub.id), {
                  standard,
                  section: section || null,
                  displayName
                });
                setShowEditHubModal(false);
                setEditingHub(null);
                alert('Academic Hub Synchronized.');
              } catch (err) { alert('Sync Error: ' + err.message); }
            }} style={{ padding: '32px', display: 'flex', flexDirection: 'column', gap: '24px' }}>

              <div>
                <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Academic Standard</label>
                <select name="standard" defaultValue={editingHub.standard} required style={{ width: '100%', boxSizing: 'border-box', padding: '14px', borderRadius: '14px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontWeight: '600' }}>
                  {['Pre-Primary', 'KG', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th', '11th', '12th'].map(s => (
                    <option key={s} value={s}>{s}</option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontWeight: '700', fontSize: '11px', textTransform: 'uppercase' }}>Section Identifier</label>
                <input name="section" defaultValue={editingHub.section || ''} placeholder="e.g. A, B, Alpha" style={{ width: '100%', boxSizing: 'border-box', padding: '14px', borderRadius: '14px', background: '#f8fafc', color: '#1e293b', border: '1px solid #e2e8f0', outline: 'none', fontWeight: '600' }} />
              </div>

              <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                <button type="button" onClick={() => setShowEditHubModal(false)} style={{ flex: 1, padding: '16px', borderRadius: '14px', background: '#f1f5f9', color: '#475569', border: 'none', fontWeight: '800', cursor: 'pointer', fontSize: '14px' }}>Discard</button>
                <button type="submit" style={{ flex: 2, padding: '16px', borderRadius: '14px', background: '#3b82f6', color: 'white', border: 'none', fontWeight: '900', cursor: 'pointer', fontSize: '14px', boxShadow: '0 10px 20px rgba(59, 130, 246, 0.2)' }}>Save Changes</button>
              </div>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}

export default function AppWithErrorBoundary() {
  return (
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  );
}
