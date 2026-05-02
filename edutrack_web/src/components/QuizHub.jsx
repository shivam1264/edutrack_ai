import React, { useState, useEffect } from 'react';
import {
  Trash,
  Settings,
  Calendar,
  Zap,
  PlusCircle,
  Users,
  Search,
  Activity,
  ArrowRight,
  Sparkles,
  Copy,
  Edit2,
  Bell,
  Rocket,
  Timer,
  LayoutGrid,
  FileQuestion,
  History,
  CheckSquare,
  ArrowLeft,
  ChevronRight,
  FileText,
  TrendingUp,
  BookOpen,
  ClipboardList,
  ChevronDown,
  ChevronUp,
  Info,
  CheckCircle2
} from 'lucide-react';
import { doc, addDoc, collection, serverTimestamp, deleteDoc, Timestamp, updateDoc, onSnapshot, query, where, orderBy } from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';

const QuizHub = ({
  classes,
  quizzes,
  user,
  db,
  quizDraftQuestions,
  setQuizDraftQuestions,
  isGeneratingQuiz,
  setIsGeneratingQuiz,
  backendOnline,
  generateQuiz,
  setActiveTab
}) => {
  // Use a fallback for quizzes to prevent map errors if prop is missing
  const allQuizzes = quizzes || [];
  
  // Filter quizzes for the current teacher
  const teacherQuizzes = allQuizzes.filter(q => q.teacher_id === user?.uid);

  const [startTime, setStartTime] = useState(new Date(Date.now() + 3600000).toISOString().slice(0, 16));
  const [endTime, setEndTime] = useState(new Date(Date.now() + 86400000).toISOString().slice(0, 16));
  const [activeView, setActiveView] = useState('manage');
  const [registryTab, setRegistryTab] = useState('Active');
  const [editingQuizId, setEditingQuizId] = useState(null);
  const [currentStep, setCurrentStep] = useState(1); // 1: Setup, 2: Questions
  const [expandedQuestion, setExpandedQuestion] = useState(null);
  const [quizTitle, setQuizTitle] = useState('');
  const [quizSubject, setQuizSubject] = useState('Mathematics');
  const [quizClass, setQuizClass] = useState('');
  const [quizDuration, setQuizDuration] = useState(30);
  const [showAiModal, setShowAiModal] = useState(false);
  const [aiTopic, setAiTopic] = useState('');
  const [aiDifficulty, setAiDifficulty] = useState('Medium');
  const [aiCount, setAiCount] = useState(5);
  const [aiType, setAiType] = useState('MCQ');

  const safetyClasses = [
    { id: 'c1', displayName: 'Class 9 - Section A' },
    { id: 'c2', displayName: 'Class 10 - Section B' },
    { id: 'c3', displayName: 'Class 11 - Science' },
    { id: 'c4', displayName: 'Class 12 - Commerce' }
  ];

  const activeClasses = (classes && classes.length > 0) ? classes : safetyClasses;



  const getStatus = (q) => {
    const now = new Date();
    const start = q.start_time?.toDate?.() || now;
    const end = q.end_time?.toDate?.() || now;
    if (now >= start && now <= end) return 'Active';
    if (now < start) return 'Upcoming';
    return 'Expired';
  };

  const handleAddQuestion = (type = 'mcq') => {
    const newQ = {
      text: '',
      type: type,
      options: type === 'mcq' ? ['', '', '', ''] : [],
      correct_option: 0,
      marks: 1
    };
    setQuizDraftQuestions([...quizDraftQuestions, newQ]);
    setExpandedQuestion(quizDraftQuestions.length);
  };

  const handleEditQuiz = (q) => {
    setEditingQuizId(q.id);
    setQuizDraftQuestions(q.questions || []);
    setQuizTitle(q.title || '');
    setQuizSubject(q.subject || 'Mathematics');
    setQuizClass(q.class_id || '');
    setQuizDuration(q.duration_mins || 30);
    setStartTime(q.start_time?.toDate?.().toISOString().slice(0, 16) || startTime);
    setEndTime(q.end_time?.toDate?.().toISOString().slice(0, 16) || endTime);
    setActiveView('create');
    setCurrentStep(1);
  };

  return (
    <div className="quiz-hub-friendly" style={{ minHeight: '100vh', padding: '20px', color: '#1e293b', background: '#f8fafc' }}>
      
      {/* Vibrant Colorful Header Section - Reduced Height */}
      <div style={{ 
        background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 50%, #ec4899 100%)', 
        margin: '-20px -20px 30px -20px', 
        padding: '30px 40px', 
        position: 'relative', 
        overflow: 'hidden',
        boxShadow: '0 10px 20px rgba(168, 85, 247, 0.1)'
      }}>
        {/* Abstract Background Element */}
        <Sparkles size={160} style={{ position: 'absolute', top: '-20px', right: '-20px', color: 'white', opacity: 0.1, transform: 'rotate(15deg)' }} />
        
        <div style={{ position: 'relative', zIndex: 1, maxWidth: '1000px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
              {activeView === 'create' && (
                <button 
                  onClick={() => {
                    if (currentStep === 2) setCurrentStep(1);
                    else setActiveView('manage');
                  }}
                  style={{ background: 'rgba(255,255,255,0.2)', border: 'none', padding: '8px', borderRadius: '10px', color: 'white', cursor: 'pointer', display: 'flex', alignItems: 'center', backdropFilter: 'blur(10px)' }}
                >
                  <ArrowLeft size={18} />
                </button>
              )}
              <div style={{ background: 'rgba(255,255,255,0.2)', padding: '4px 12px', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.3)', backdropFilter: 'blur(10px)' }}>
                <span style={{ fontSize: '10px', fontWeight: '900', color: 'white', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  {activeView === 'create' ? 'Academic Creation Node' : 'Management Registry'}
                </span>
              </div>
            </div>
            <h1 style={{ fontSize: '32px', fontWeight: '900', color: 'white', margin: 0, letterSpacing: '-1px' }}>
              {activeView === 'create' ? 'Quiz Creator' : 'Quiz Dashboard'}
            </h1>
          </div>

          {activeView === 'manage' && (
            <button 
              onClick={() => { setActiveView('create'); setCurrentStep(1); setEditingQuizId(null); setQuizDraftQuestions([]); }}
              style={{ background: 'white', color: '#a855f7', border: 'none', padding: '12px 24px', borderRadius: '12px', fontWeight: '900', fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', boxShadow: '0 8px 20px rgba(0,0,0,0.1)' }}
            >
              <PlusCircle size={20} /> New Quiz
            </button>
          )}
        </div>
      </div>

      <AnimatePresence mode="wait">
        {activeView === 'create' ? (
          <motion.div 
            key="create-stepper"
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.98 }}
            style={{ maxWidth: '800px', margin: '0 auto' }}
          >
            {/* Step Progress Bar */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '20px', marginBottom: '40px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: currentStep >= 1 ? '#3b82f6' : '#e2e8f0', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800', fontSize: '14px' }}>1</div>
                <span style={{ fontWeight: '700', color: currentStep >= 1 ? '#0f172a' : '#94a3b8' }}>Basic Setup</span>
              </div>
              <div style={{ width: '60px', height: '2px', background: currentStep >= 2 ? '#3b82f6' : '#e2e8f0' }}></div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: currentStep >= 2 ? '#3b82f6' : '#e2e8f0', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800', fontSize: '14px' }}>2</div>
                <span style={{ fontWeight: '700', color: currentStep >= 2 ? '#0f172a' : '#94a3b8' }}>Question Bank</span>
              </div>
            </div>

            <div className="glass-card" style={{ padding: '40px', background: 'white', borderRadius: '24px', boxShadow: '0 10px 30px rgba(0,0,0,0.05)', border: '1px solid #f1f5f9' }}>
              {currentStep === 1 ? (
                <form onSubmit={(e) => { e.preventDefault(); setCurrentStep(2); }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
                    <div>
                      <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>What's the title of this quiz?</label>
                      <input 
                        name="title" 
                        required 
                        value={quizTitle}
                        onChange={(e) => setQuizTitle(e.target.value)}
                        placeholder="e.g. Mid-term Algebra Challenge" 
                        style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '16px', outline: 'none' }} 
                      />
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                      <div>
                        <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Subject</label>
                        <select 
                          name="subject" 
                          required 
                          value={quizSubject}
                          onChange={(e) => setQuizSubject(e.target.value)}
                          style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '15px', outline: 'none' }}
                        >
                          {['Mathematics', 'Science', 'English', 'History', 'Geography'].map(s => <option key={s} value={s}>{s}</option>)}
                        </select>
                      </div>
                      <div>
                        <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Duration (Minutes)</label>
                        <select 
                          name="duration" 
                          required 
                          value={quizDuration}
                          onChange={(e) => setQuizDuration(parseInt(e.target.value))}
                          style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '15px', outline: 'none' }}
                        >
                          {[15, 30, 45, 60, 90].map(m => <option key={m} value={m}>{m} Mins</option>)}
                        </select>
                      </div>
                    </div>

                    <div>
                      <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Target Class</label>
                      <select 
                        name="class" 
                        required 
                        value={quizClass}
                        onChange={(e) => setQuizClass(e.target.value)}
                        style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '15px', outline: 'none' }}
                      >
                        <option value="">Select Class</option>
                        {activeClasses.map(c => <option key={c.id} value={c.id}>{c.displayName || `${c.standard}-${c.section}`}</option>)}
                      </select>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                      <div>
                        <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Start Schedule</label>
                        <input 
                          type="datetime-local" 
                          value={startTime} 
                          onChange={(e) => setStartTime(e.target.value)} 
                          required 
                          style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '14px', fontWeight: '600', outline: 'none' }} 
                        />
                      </div>
                      <div>
                        <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Expiry Time</label>
                        <input 
                          type="datetime-local" 
                          value={endTime} 
                          onChange={(e) => setEndTime(e.target.value)} 
                          required 
                          style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '14px', fontWeight: '600', outline: 'none' }} 
                        />
                      </div>
                    </div>

                    <div style={{ display: 'flex', gap: '12px', marginTop: '20px' }}>
                      <button type="button" onClick={() => setActiveView('manage')} style={{ flex: 1, padding: '16px', borderRadius: '12px', background: '#f1f5f9', color: '#475569', fontWeight: '700', border: 'none', cursor: 'pointer' }}>Cancel</button>
                      <button type="submit" style={{ flex: 2, padding: '16px', borderRadius: '12px', background: '#3b82f6', color: 'white', fontWeight: '700', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                        Next: Add Questions <ArrowRight size={20} />
                      </button>
                    </div>
                  </div>
                </form>
              ) : (
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
                    <h3 style={{ fontSize: '20px', fontWeight: '800', margin: 0 }}>Add Your Questions</h3>
                    <button 
                      type="button"
                      onClick={async () => {
                        console.log("Generating with AI topic:", quizTitle);
                        try {
                          const result = await generateAI(`Create 5 quiz questions for: ${quizTitle}`, "Output only JSON array of objects with fields: text, options (array), correctOption (number), marks, type ('mcq' or 'short_answer')");
                          console.log("AI Response received:", result);
                          const parsed = JSON.parse(result);
                          setQuizDraftQuestions(parsed);
                        } catch (e) {
                          console.error("AI Generation process failed in UI:", e);
                        }
                      }}
                      style={{ background: '#f0f9ff', color: '#0369a1', border: '1px solid #bae6fd', padding: '10px 20px', borderRadius: '12px', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' }}
                    >
                      <Sparkles size={18} /> Auto-Generate with AI
                    </button>
                  </div>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '32px' }}>
                    {quizDraftQuestions.map((q, i) => (
                      <div key={i} style={{ border: '1px solid #e2e8f0', borderRadius: '16px', overflow: 'hidden', background: '#f8fafc' }}>
                        <div 
                          onClick={() => setExpandedQuestion(expandedQuestion === i ? null : i)}
                          style={{ padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', cursor: 'pointer', background: 'white' }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                            <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: '#3b82f6', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: '800' }}>{i + 1}</div>
                            <span style={{ fontWeight: '600', color: '#1e293b' }}>{q.text ? q.text.slice(0, 40) + '...' : 'New Question'}</span>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                            <Trash size={18} color="#ef4444" style={{ cursor: 'pointer' }} onClick={(e) => { e.stopPropagation(); setQuizDraftQuestions(quizDraftQuestions.filter((_, idx) => idx !== i)); }} />
                            {expandedQuestion === i ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
                          </div>
                        </div>
                        {expandedQuestion === i && (
                          <div style={{ padding: '20px', borderTop: '1px solid #f1f5f9' }}>
                            <textarea 
                              placeholder="Type your question here..."
                              value={q.text}
                              onChange={(e) => {
                                const updated = [...quizDraftQuestions];
                                updated[i].text = e.target.value;
                                setQuizDraftQuestions(updated);
                              }}
                              style={{ width: '100%', padding: '12px', borderRadius: '8px', border: '1px solid #e2e8f0', minHeight: '80px', marginBottom: '16px', fontSize: '14px', outline: 'none' }}
                            />
                            {q.type === 'mcq' && (
                              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                                {q.options.map((opt, oIdx) => (
                                  <div key={oIdx} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    <input 
                                      type="radio" 
                                      name={`correct-${i}`} 
                                      checked={q.correct_option === oIdx} 
                                      onChange={() => {
                                        const updated = [...quizDraftQuestions];
                                        updated[i].correct_option = oIdx;
                                        setQuizDraftQuestions(updated);
                                      }}
                                    />
                                    <input 
                                      placeholder={`Option ${oIdx + 1}`}
                                      value={opt}
                                      onChange={(e) => {
                                        const updated = [...quizDraftQuestions];
                                        updated[i].options[oIdx] = e.target.value;
                                        setQuizDraftQuestions(updated);
                                      }}
                                      style={{ flex: 1, padding: '10px', borderRadius: '6px', border: '1px solid #e2e8f0', fontSize: '13px' }}
                                    />
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    ))}

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                      <button onClick={() => handleAddQuestion('mcq')} style={{ padding: '16px', borderRadius: '12px', border: '2px dashed #3b82f6', background: 'transparent', color: '#3b82f6', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                        <PlusCircle size={20} /> Add Multiple Choice
                      </button>
                      <button onClick={() => handleAddQuestion('short_answer')} style={{ padding: '16px', borderRadius: '12px', border: '2px dashed #64748b', background: 'transparent', color: '#64748b', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                        <FileText size={20} /> Add Short Answer
                      </button>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '12px' }}>
                    <button onClick={() => setCurrentStep(1)} style={{ flex: 1, padding: '16px', borderRadius: '12px', background: '#f1f5f9', color: '#475569', fontWeight: '700', border: 'none', cursor: 'pointer' }}>Back</button>
                    <button 
                      onClick={async () => {
                        const data = {
                          title: quizTitle,
                          subject: quizSubject,
                          duration_mins: quizDuration,
                          class_id: quizClass,
                          teacher_id: user.uid,
                          questions: quizDraftQuestions,
                          questions_count: quizDraftQuestions.length,
                          updated_at: serverTimestamp(),
                          start_time: Timestamp.fromDate(new Date(startTime)),
                          end_time: Timestamp.fromDate(new Date(endTime)),
                        };
                        if (editingQuizId) await updateDoc(doc(db, 'quizzes', editingQuizId), data);
                        else { data.created_at = serverTimestamp(); await addDoc(collection(db, 'quizzes'), data); }
                        setQuizDraftQuestions([]);
                        setEditingQuizId(null);
                        setActiveView('manage');
                      }}
                      style={{ flex: 2, padding: '16px', borderRadius: '12px', background: '#059669', color: 'white', fontWeight: '800', border: 'none', cursor: 'pointer', boxShadow: '0 4px 12px rgba(5, 150, 105, 0.2)' }}
                    >
                      Publish Quiz Now 🚀
                    </button>
                  </div>
                </div>
              )}
            </div>
          </motion.div>
        ) : (
          <motion.div 
            key="manage-view"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 10 }}
            style={{ maxWidth: '1000px', margin: '0 auto' }}
          >
            <div style={{ display: 'flex', gap: '12px', marginBottom: '32px', background: 'white', padding: '6px', borderRadius: '14px', width: 'fit-content', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
              {['Active', 'Upcoming', 'Expired'].map(t => (
                <button 
                  key={t} 
                  onClick={() => setRegistryTab(t)} 
                  style={{ padding: '10px 24px', borderRadius: '10px', border: 'none', background: registryTab === t ? '#3b82f6' : 'transparent', color: registryTab === t ? 'white' : '#64748b', fontWeight: '700', cursor: 'pointer' }}
                >
                  {t}
                </button>
              ))}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px' }}>
              {teacherQuizzes.filter(q => getStatus(q) === registryTab).map(q => (
                <div key={q.id} className="glass-card" style={{ padding: '24px', background: 'white', borderRadius: '24px', border: '1px solid #f1f5f9', boxShadow: '0 4px 20px rgba(0,0,0,0.02)', position: 'relative' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
                    <div style={{ width: '48px', height: '48px', borderRadius: '14px', background: '#f0fdf4', color: '#16a34a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Zap size={24} />
                    </div>
                    <div style={{ padding: '4px 12px', borderRadius: '20px', background: '#dcfce7', color: '#166534', fontSize: '11px', fontWeight: '800' }}>LIVE</div>
                  </div>

                  <h3 style={{ margin: '0 0 4px 0', fontSize: '18px', fontWeight: '800', color: '#0f172a' }}>{q.title}</h3>
                  <p style={{ margin: 0, color: '#64748b', fontSize: '14px', fontWeight: '600' }}>{q.subject} • {q.questions_count} Qs</p>

                  <div style={{ height: '1px', background: '#f1f5f9', margin: '20px 0' }}></div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: '#64748b', fontWeight: '600' }}>
                      <Users size={16} /> 0 Subs
                    </div>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button onClick={() => handleEditQuiz(q)} style={{ background: '#f8fafc', border: '1px solid #e2e8f0', padding: '8px 12px', borderRadius: '10px', color: '#475569', fontSize: '12px', fontWeight: '700', cursor: 'pointer' }}>Edit</button>
                      <button onClick={() => setActiveTab('quiz_results')} style={{ background: '#f0fdf4', border: '1px solid #dcfce7', padding: '8px 12px', borderRadius: '10px', color: '#16a34a', fontSize: '12px', fontWeight: '700', cursor: 'pointer' }}>Results</button>
                      <button onClick={async () => { if (window.confirm('Delete this quiz?')) await deleteDoc(doc(db, 'quizzes', q.id)); }} style={{ background: 'transparent', border: 'none', padding: '8px', color: '#ef4444', cursor: 'pointer' }}><Trash size={18} /></button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {teacherQuizzes.filter(q => getStatus(q) === registryTab).length === 0 && (
              <div style={{ textAlign: 'center', padding: '60px 20px', background: 'white', borderRadius: '32px', border: '2px dashed #e2e8f0' }}>
                <ClipboardList size={40} color="#cbd5e1" style={{ marginBottom: '16px' }} />
                <h4 style={{ margin: 0, fontSize: '18px', fontWeight: '800', color: '#475569' }}>No {registryTab} Quizzes</h4>
                <p style={{ color: '#94a3b8', fontSize: '14px', marginTop: '4px' }}>Click "Create New Quiz" to start.</p>
              </div>
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* AI Magic Generator Modal */}
      <AnimatePresence>
        {showAiModal && (
          <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2000, padding: '20px' }}>
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              style={{ background: 'white', width: '100%', maxWidth: '420px', borderRadius: '40px', padding: '32px', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)', position: 'relative' }}
            >
              <div style={{ textAlign: 'center', marginBottom: '24px' }}>
                <div style={{ width: '64px', height: '64px', borderRadius: '20px', background: '#f5f3ff', color: '#8b5cf6', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px auto' }}>
                  <Sparkles size={32} />
                </div>
                <h2 style={{ fontSize: '24px', fontWeight: '900', color: '#1e293b', margin: 0 }}>AI Magic Generator</h2>
                <p style={{ color: '#94a3b8', fontSize: '14px', marginTop: '8px', fontWeight: '600' }}>Generate high-quality questions using EduTrack AI.</p>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                <div style={{ padding: '16px 20px', background: 'white', borderRadius: '20px', border: '2px solid #f1f5f9', display: 'flex', alignItems: 'center', gap: '16px' }}>
                  <BookOpen size={20} color="#8b5cf6" />
                  <input 
                    placeholder="Topic" 
                    value={aiTopic}
                    onChange={(e) => setAiTopic(e.target.value)}
                    style={{ flex: 1, border: 'none', background: 'transparent', fontSize: '16px', fontWeight: '700', color: '#1e293b', outline: 'none' }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div style={{ padding: '12px 16px', background: 'white', borderRadius: '20px', border: '2px solid #f1f5f9' }}>
                    <label style={{ fontSize: '11px', fontWeight: '700', color: '#94a3b8', display: 'block', marginBottom: '4px' }}>Difficulty</label>
                    <select 
                      value={aiDifficulty}
                      onChange={(e) => setAiDifficulty(e.target.value)}
                      style={{ width: '100%', border: 'none', background: 'transparent', fontSize: '14px', fontWeight: '700', color: '#1e293b', outline: 'none' }}
                    >
                      {['Easy', 'Medium', 'Hard'].map(d => <option key={d} value={d}>{d}</option>)}
                    </select>
                  </div>
                  <div style={{ padding: '12px 16px', background: 'white', borderRadius: '20px', border: '2px solid #f1f5f9' }}>
                    <label style={{ fontSize: '11px', fontWeight: '700', color: '#94a3b8', display: 'block', marginBottom: '4px' }}>Count</label>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontWeight: '900', color: '#1e293b' }}>#</span>
                      <input 
                        type="number" 
                        value={aiCount}
                        onChange={(e) => setAiCount(parseInt(e.target.value))}
                        style={{ width: '100%', border: 'none', background: 'transparent', fontSize: '16px', fontWeight: '700', color: '#1e293b', outline: 'none' }}
                      />
                    </div>
                  </div>
                </div>

                <div style={{ padding: '12px 16px', background: 'white', borderRadius: '20px', border: '2px solid #f1f5f9' }}>
                  <label style={{ fontSize: '11px', fontWeight: '700', color: '#94a3b8', display: 'block', marginBottom: '4px' }}>Question Type</label>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <LayoutGrid size={18} color="#94a3b8" />
                    <select 
                      value={aiType}
                      onChange={(e) => setAiType(e.target.value)}
                      style={{ width: '100%', border: 'none', background: 'transparent', fontSize: '14px', fontWeight: '700', color: '#1e293b', outline: 'none' }}
                    >
                      {['MCQ', 'True/False', 'Short Answer'].map(t => <option key={t} value={t}>{t}</option>)}
                    </select>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '16px', marginTop: '12px' }}>
                  <button 
                    onClick={() => setShowAiModal(false)}
                    style={{ flex: 1, padding: '16px', borderRadius: '16px', background: 'transparent', color: '#6366f1', border: 'none', fontWeight: '800', cursor: 'pointer' }}
                  >
                    Cancel
                  </button>
                  <button 
                    disabled={isGeneratingQuiz}
                    onClick={async () => {
                      setIsGeneratingQuiz(true);
                      try {
                        const res = await generateQuiz({ topic: aiTopic, subject: quizSubject, count: aiCount, difficulty: aiDifficulty, type: aiType });
                        if (Array.isArray(res)) {
                          const formatted = res.map(q => ({ text: q.text, type: aiType.toLowerCase().replace(' ', '_'), options: q.options || [], correct_option: q.correctOption || 0, marks: q.marks || 1 }));
                          setQuizDraftQuestions([...quizDraftQuestions, ...formatted]);
                          setShowAiModal(false);
                        }
                      } catch (e) { alert(e.message); } finally { setIsGeneratingQuiz(false); }
                    }}
                    style={{ flex: 2, padding: '16px', borderRadius: '16px', background: '#059669', color: 'white', border: 'none', fontWeight: '900', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px', boxShadow: '0 10px 20px rgba(5, 150, 105, 0.2)' }}
                  >
                    {isGeneratingQuiz ? <div className="spinning-loader" style={{ width: '18px', height: '18px' }}></div> : <>Generate <Sparkles size={18} /></>}
                  </button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default QuizHub;
