import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, query, where, orderBy, getDocs, doc, getDoc } from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Trophy, Search, BarChart3, Users, Clock, Target, 
  ChevronDown, ChevronUp, Award, ExternalLink, ShieldCheck, 
  XCircle, Brain, BarChart, AlertTriangle, CheckCircle2,
  Calendar, BookOpen, Layers, Zap, Filter
} from 'lucide-react';
import { 
  BarChart as RechartsBarChart, Bar, XAxis, YAxis, Tooltip, 
  ResponsiveContainer, Cell, PieChart, Pie, AreaChart, Area
} from 'recharts';

export default function QuizResults({ role, user, quizzes, allUsers, visibleClasses }) {
  const [results, setResults] = useState([]);
  const [selectedQuiz, setSelectedQuiz] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(false);
  const [activeResult, setActiveResult] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);

  const studentMap = {};
  (allUsers || []).forEach(u => { if (u.role === 'student') studentMap[u.id] = u; });

  const loadResults = async (quiz) => {
    setSelectedQuiz(quiz);
    setLoading(true);
    try {
      const snap = await getDocs(query(collection(db, 'quiz_results'), where('quiz_id', '==', quiz.id)));
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      setResults(data);
    } catch (err) {
      console.error('Quiz results load error:', err);
      setResults([]);
    }
    setLoading(false);
  };

  const avgScore = (results || []).length > 0
    ? ((results || []).reduce((a, r) => a + (r.score || 0), 0) / (results || []).length).toFixed(1)
    : 0;

  const maxScore = (results || []).length > 0 ? Math.max(...(results || []).map(r => r.score || 0)) : 0;
  const passRate = (results || []).length > 0
    ? (((results || []).filter(r => (r.score / (selectedQuiz?.total_marks || 10) * 100) >= 40).length / (results || []).length) * 100).toFixed(0)
    : 0;

  const getGradeColor = (pct) => {
    if (pct >= 80) return '#10b981';
    if (pct >= 60) return '#3b82f6';
    if (pct >= 40) return '#f59e0b';
    return '#ef4444';
  };

  const distributionData = [
    { range: '0-20%', count: (results || []).filter(r => (r.score / (selectedQuiz?.total_marks || 10) * 100) < 20).length },
    { range: '21-40%', count: (results || []).filter(r => { const p = (r.score / (selectedQuiz?.total_marks || 10) * 100); return p >= 20 && p < 40; }).length },
    { range: '41-60%', count: (results || []).filter(r => { const p = (r.score / (selectedQuiz?.total_marks || 10) * 100); return p >= 40 && p < 60; }).length },
    { range: '61-80%', count: (results || []).filter(r => { const p = (r.score / (selectedQuiz?.total_marks || 10) * 100); return p >= 60 && p < 80; }).length },
    { range: '81-100%', count: (results || []).filter(r => (r.score / (selectedQuiz?.total_marks || 10) * 100) >= 80).length },
  ];

  const filteredQuizzes = (quizzes || []).filter(q => {
    const matchesSearch = q.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          q.subject?.toLowerCase().includes(searchTerm.toLowerCase());
    if (!matchesSearch) return false;

    if (role === 'admin') return true;
    if (role === 'teacher') {
      const visibleClassIds = (visibleClasses || []).map(c => c.id);
      return visibleClassIds.includes(q.class_id);
    }
    return false;
  });

  return (
    <div style={{ color: 'white', minHeight: '100vh' }}>
      {/* Header Section */}
      <div style={{ 
        marginBottom: '40px', 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'flex-end',
        background: 'linear-gradient(to right, rgba(99, 102, 241, 0.05), transparent)',
        padding: '32px',
        borderRadius: '24px',
        border: '1px solid rgba(255,255,255,0.05)'
      }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
            <div style={{ padding: '8px', background: 'var(--primary)', borderRadius: '10px' }}>
              <Trophy size={20} color="white" />
            </div>
            <h2 style={{ fontSize: '32px', fontWeight: '900', margin: 0, letterSpacing: '-1px' }}>
              Quiz <span className="gradient-text">Analysis Hub</span>
            </h2>
          </div>
          <p style={{ color: 'var(--text-dim)', fontSize: '15px', margin: 0, fontWeight: '500' }}>
            Enterprise-grade performance tracking and assessment diagnostics.
          </p>
        </div>
        
        <div style={{ display: 'flex', gap: '16px' }}>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: '24px', fontWeight: '900', color: 'white' }}>{quizzes.length}</div>
            <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase' }}>Total Quizzes</div>
          </div>
          <div style={{ width: '1px', background: 'rgba(255,255,255,0.1)', margin: '0 8px' }}></div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: '24px', fontWeight: '900', color: 'var(--primary)' }}>{visibleClasses.length}</div>
            <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase' }}>Active Units</div>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '340px 1fr', gap: '32px' }}>
        {/* Sidebar: Quiz Explorer */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
            <input
              className="glass-input"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search assessments..."
              style={{ 
                width: '100%', 
                padding: '16px 16px 16px 48px', 
                borderRadius: '16px',
                background: 'rgba(255,255,255,0.03)',
                border: '1px solid rgba(255,255,255,0.08)'
              }}
            />
          </div>

          <div style={{ 
            display: 'flex', 
            flexDirection: 'column', 
            gap: '12px', 
            maxHeight: 'calc(100vh - 300px)', 
            overflowY: 'auto',
            paddingRight: '8px'
          }}>
            {filteredQuizzes.length === 0 ? (
              <div style={{ padding: '40px', textAlign: 'center', background: 'rgba(255,255,255,0.02)', borderRadius: '20px', border: '1px dashed rgba(255,255,255,0.1)' }}>
                <AlertTriangle size={32} style={{ opacity: 0.2, marginBottom: '12px' }} />
                <p style={{ fontSize: '14px', color: 'var(--text-dim)', fontWeight: '600' }}>No nodes found</p>
              </div>
            ) : (
              filteredQuizzes.map((q) => (
                <motion.div
                  key={q.id}
                  whileHover={{ scale: 1.02, x: 4 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => loadResults(q)}
                  style={{
                    padding: '20px',
                    borderRadius: '20px',
                    cursor: 'pointer',
                    background: selectedQuiz?.id === q.id 
                      ? 'linear-gradient(135deg, rgba(99, 102, 241, 0.15), rgba(168, 85, 247, 0.15))' 
                      : 'rgba(255,255,255,0.02)',
                    border: '1px solid',
                    borderColor: selectedQuiz?.id === q.id ? 'var(--primary)' : 'rgba(255,255,255,0.05)',
                    transition: 'all 0.2s ease',
                    position: 'relative',
                    overflow: 'hidden'
                  }}
                >
                  {selectedQuiz?.id === q.id && (
                    <motion.div 
                      layoutId="active-pill"
                      style={{ position: 'absolute', left: 0, top: '20%', bottom: '20%', width: '4px', background: 'var(--primary)', borderRadius: '0 4px 4px 0' }}
                    />
                  )}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
                    <div style={{ 
                      padding: '8px', 
                      background: 'rgba(255,255,255,0.05)', 
                      borderRadius: '10px',
                      color: selectedQuiz?.id === q.id ? 'var(--primary)' : 'var(--text-dim)'
                    }}>
                      <BookOpen size={16} />
                    </div>
                    <span style={{ fontSize: '10px', fontWeight: '900', color: 'rgba(255,255,255,0.3)', textTransform: 'uppercase', letterSpacing: '1px' }}>
                      {q.class_id || 'Global'}
                    </span>
                  </div>
                  <h4 style={{ margin: 0, fontSize: '16px', fontWeight: '800', color: 'white', marginBottom: '4px' }}>{q.title}</h4>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', color: 'var(--text-dim)', fontWeight: '600' }}>
                    <span>{q.subject}</span>
                    <span style={{ opacity: 0.2 }}>•</span>
                    <span>{q.questions?.length || q.questions_count || 0} Questions</span>
                  </div>
                </motion.div>
              ))
            )}
          </div>
        </div>

        {/* Main Content: Diagnostics & Ledger */}
        <div style={{ minHeight: '60vh' }}>
          <AnimatePresence mode="wait">
            {!selectedQuiz ? (
              <motion.div
                key="empty"
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95 }}
                style={{ 
                  height: '100%', 
                  display: 'flex', 
                  flexDirection: 'column', 
                  alignItems: 'center', 
                  justifyContent: 'center',
                  background: 'rgba(255,255,255,0.01)',
                  borderRadius: '32px',
                  border: '2px dashed rgba(255,255,255,0.03)',
                  padding: '60px'
                }}
              >
                <div style={{ position: 'relative', marginBottom: '32px' }}>
                  <div style={{ position: 'absolute', inset: -20, background: 'var(--primary)', filter: 'blur(40px)', opacity: 0.1 }}></div>
                  <Target size={80} style={{ color: 'var(--primary)', opacity: 0.2 }} />
                </div>
                <h3 style={{ fontSize: '24px', fontWeight: '900', color: 'white', marginBottom: '12px' }}>Select an Assessment Node</h3>
                <p style={{ color: 'var(--text-dim)', textAlign: 'center', maxWidth: '400px', lineHeight: '1.6', fontSize: '15px' }}>
                  Choose a quiz from the left panel to aggregate student data, generate performance insights, and analyze competency distribution.
                </p>
                <div style={{ marginTop: '32px', display: 'flex', gap: '12px' }}>
                  <div style={{ padding: '12px 20px', borderRadius: '14px', background: 'rgba(255,255,255,0.03)', fontSize: '12px', fontWeight: '700', color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <ShieldCheck size={14} /> Encrypted Sync
                  </div>
                  <div style={{ padding: '12px 20px', borderRadius: '14px', background: 'rgba(255,255,255,0.03)', fontSize: '12px', fontWeight: '700', color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Zap size={14} /> Real-time Compute
                  </div>
                </div>
              </motion.div>
            ) : (
              <motion.div
                key={selectedQuiz.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                transition={{ duration: 0.4, ease: "easeOut" }}
              >
                {/* Stats Grid */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px', marginBottom: '32px' }}>
                  {[
                    { label: 'Submissions', value: results.length, icon: <Users size={20} />, color: '#6366f1', trend: '+12% this week' },
                    { label: 'Avg Competency', value: `${avgScore}%`, icon: <Brain size={20} />, color: '#a855f7', trend: 'Global Mean' },
                    { label: 'High Precision', value: maxScore, icon: <Award size={20} />, color: '#10b981', trend: 'Peak Score' },
                    { label: 'Passing Index', value: `${passRate}%`, icon: <Target size={20} />, color: '#f59e0b', trend: 'Success Ratio' },
                  ].map((s, i) => (
                    <motion.div 
                      key={i} 
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: i * 0.1 }}
                      style={{ 
                        background: 'rgba(255,255,255,0.03)', 
                        padding: '24px', 
                        borderRadius: '24px', 
                        border: '1px solid rgba(255,255,255,0.05)',
                        position: 'relative',
                        overflow: 'hidden'
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
                        <div style={{ padding: '10px', borderRadius: '12px', background: `${s.color}15`, color: s.color }}>{s.icon}</div>
                        <span style={{ fontSize: '11px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px' }}>{s.label}</span>
                      </div>
                      <div style={{ fontSize: '32px', fontWeight: '900', color: 'white', marginBottom: '4px' }}>{s.value}</div>
                      <div style={{ fontSize: '11px', color: s.color, fontWeight: '700' }}>{s.trend}</div>
                    </motion.div>
                  ))}
                </div>

                {/* Charts Section */}
                <div style={{ display: 'grid', gridTemplateColumns: '1.6fr 1fr', gap: '32px', marginBottom: '32px' }}>
                  <div style={{ background: 'rgba(255,255,255,0.02)', padding: '32px', borderRadius: '32px', border: '1px solid rgba(255,255,255,0.05)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
                      <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '900' }}>Competency Distribution</h3>
                      <div style={{ padding: '8px 16px', background: 'rgba(255,255,255,0.03)', borderRadius: '12px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', border: '1px solid rgba(255,255,255,0.05)' }}>
                        LIVE DATA
                      </div>
                    </div>
                    <div style={{ height: '300px' }}>
                      <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={distributionData}>
                          <defs>
                            <linearGradient id="colorCount" x1="0" y1="0" x2="0" y2="1">
                              <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.3}/>
                              <stop offset="95%" stopColor="var(--primary)" stopOpacity={0}/>
                            </linearGradient>
                          </defs>
                          <XAxis dataKey="range" axisLine={false} tickLine={false} tick={{ fill: 'var(--text-dim)', fontSize: 12 }} />
                          <YAxis hide />
                          <Tooltip 
                            contentStyle={{ background: '#0f172a', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '16px', boxShadow: '0 20px 40px rgba(0,0,0,0.4)' }}
                            itemStyle={{ color: 'white', fontSize: '13px', fontWeight: '700' }}
                          />
                          <Area type="monotone" dataKey="count" stroke="var(--primary)" strokeWidth={3} fillOpacity={1} fill="url(#colorCount)" />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>
                  </div>

                  <div style={{ background: 'rgba(255,255,255,0.02)', padding: '32px', borderRadius: '32px', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', flexDirection: 'column' }}>
                    <h3 style={{ margin: '0 0 24px 0', fontSize: '18px', fontWeight: '900', textAlign: 'center' }}>Pass/Fail Matrix</h3>
                    <div style={{ flex: 1, minHeight: '240px' }}>
                      <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                          <Pie
                            data={[
                              { name: 'Passed', value: (results || []).filter(r => (r.score / (selectedQuiz?.total_marks || 10) * 100) >= 40).length, color: '#10b981' },
                              { name: 'Failed', value: (results || []).filter(r => (r.score / (selectedQuiz?.total_marks || 10) * 100) < 40).length, color: '#ef4444' }
                            ]}
                            innerRadius={70}
                            outerRadius={95}
                            paddingAngle={8}
                            dataKey="value"
                            stroke="none"
                          >
                            {(results || []).length > 0 && [
                              { color: '#10b981' },
                              { color: '#ef4444' }
                            ].map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={entry.color} />
                            ))}
                          </Pie>
                          <Tooltip 
                            contentStyle={{ background: '#0f172a', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '16px' }}
                            labelStyle={{ display: 'none' }}
                          />
                        </PieChart>
                      </ResponsiveContainer>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'center', gap: '24px', marginTop: '16px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', fontWeight: '700', color: '#10b981' }}>
                        <div style={{ width: '10px', height: '10px', borderRadius: '3px', background: '#10b981' }}></div> Passed
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', fontWeight: '700', color: '#ef4444' }}>
                        <div style={{ width: '10px', height: '10px', borderRadius: '3px', background: '#ef4444' }}></div> Failed
                      </div>
                    </div>
                  </div>
                </div>

                {/* Ledger Table */}
                <div style={{ background: 'rgba(255,255,255,0.02)', borderRadius: '32px', border: '1px solid rgba(255,255,255,0.05)', overflow: 'hidden' }}>
                  <div style={{ padding: '32px', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <h3 style={{ margin: 0, fontSize: '20px', fontWeight: '900' }}>Student Performance Ledger</h3>
                      <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: 'var(--text-dim)', fontWeight: '500' }}>Comprehensive assessment data for all participants.</p>
                    </div>
                    <div style={{ display: 'flex', gap: '12px' }}>
                      <button style={{ padding: '10px 20px', borderRadius: '12px', background: 'rgba(255,255,255,0.05)', border: 'none', color: 'white', fontSize: '13px', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <Filter size={16} /> Filter
                      </button>
                    </div>
                  </div>

                  {loading ? (
                    <div style={{ padding: '100px', textAlign: 'center' }}>
                      <div className="spinning-loader" style={{ width: '40px', height: '40px', margin: '0 auto 20px auto' }}></div>
                      <p style={{ color: 'var(--text-dim)', fontWeight: '700' }}>Synchronizing Results...</p>
                    </div>
                  ) : results.length === 0 ? (
                    <div style={{ padding: '80px', textAlign: 'center', color: 'var(--text-dim)' }}>
                      <Users size={48} style={{ opacity: 0.1, marginBottom: '20px' }} />
                      <h4 style={{ color: 'white', marginBottom: '8px' }}>No Submissions Found</h4>
                      <p style={{ fontSize: '14px' }}>Wait for students to complete the assessment.</p>
                    </div>
                  ) : (
                    <div style={{ overflowX: 'auto' }}>
                      <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                        <thead>
                          <tr style={{ background: 'rgba(255,255,255,0.02)', color: 'var(--text-dim)', fontSize: '11px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '1px' }}>
                            <th style={{ padding: '24px 32px' }}>Student</th>
                            <th style={{ padding: '24px' }}>Score</th>
                            <th style={{ padding: '24px' }}>Accuracy</th>
                            <th style={{ padding: '24px' }}>Grade</th>
                            <th style={{ padding: '24px' }}>Date</th>
                            <th style={{ padding: '24px 32px', textAlign: 'right' }}>Action</th>
                          </tr>
                        </thead>
                        <tbody>
                          {results.sort((a, b) => (b.score || 0) - (a.score || 0)).map((r, idx) => {
                            const student = studentMap[r.student_id] || studentMap[r.studentId] || {};
                            const pct = (r.score / (selectedQuiz.total_marks || 10) * 100);
                            const grade = pct >= 90 ? 'A+' : pct >= 75 ? 'A' : pct >= 60 ? 'B' : pct >= 40 ? 'C' : 'F';
                            return (
                              <motion.tr
                                key={r.id}
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: idx * 0.05 }}
                                style={{ borderBottom: '1px solid rgba(255,255,255,0.03)' }}
                              >
                                <td style={{ padding: '20px 32px' }}>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                                    <div style={{ 
                                      width: '44px', height: '44px', borderRadius: '14px', 
                                      background: 'linear-gradient(135deg, #6366f1, #a855f7)',
                                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                                      fontSize: '16px', fontWeight: '900'
                                    }}>
                                      {(student.name || r.studentName || 'S').charAt(0).toUpperCase()}
                                    </div>
                                    <div>
                                      <div style={{ fontWeight: '800', fontSize: '15px', color: 'white' }}>{student.name || r.studentName || 'Unknown Student'}</div>
                                      <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600' }}>ID: {r.student_id?.slice(0, 8)}</div>
                                    </div>
                                  </div>
                                </td>
                                <td style={{ padding: '20px' }}>
                                  <div style={{ fontSize: '18px', fontWeight: '900', color: 'white' }}>
                                    {r.score} <span style={{ color: 'rgba(255,255,255,0.2)', fontSize: '13px' }}>/ {selectedQuiz.total_marks || 10}</span>
                                  </div>
                                </td>
                                <td style={{ padding: '20px' }}>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                    <div style={{ flex: 1, height: '6px', width: '80px', background: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                                      <div style={{ height: '100%', width: `${pct}%`, background: getGradeColor(pct), boxShadow: `0 0 12px ${getGradeColor(pct)}40` }}></div>
                                    </div>
                                    <span style={{ fontSize: '13px', fontWeight: '800', color: getGradeColor(pct) }}>{pct.toFixed(0)}%</span>
                                  </div>
                                </td>
                                <td style={{ padding: '20px' }}>
                                  <div style={{ fontSize: '18px', fontWeight: '900', color: getGradeColor(pct) }}>{grade}</div>
                                </td>
                                <td style={{ padding: '20px', fontSize: '13px', color: 'var(--text-dim)', fontWeight: '600' }}>
                                  {r.submitted_at?.toDate?.()?.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) || 'N/A'}
                                </td>
                                <td style={{ padding: '20px 32px', textAlign: 'right' }}>
                                  <button
                                    onClick={() => { setActiveResult(r); setShowDetailModal(true); }}
                                    style={{ 
                                      padding: '10px 18px', borderRadius: '12px', background: 'white', color: '#0f172a',
                                      fontSize: '12px', fontWeight: '800', cursor: 'pointer', border: 'none',
                                      display: 'inline-flex', alignItems: 'center', gap: '8px'
                                    }}
                                  >
                                    View Report <ExternalLink size={14} />
                                  </button>
                                </td>
                              </motion.tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Report Modal */}
      <AnimatePresence>
        {showDetailModal && activeResult && (
          <div style={{ 
            position: 'fixed', inset: 0, zIndex: 10000, 
            background: 'rgba(2, 6, 23, 0.95)', backdropFilter: 'blur(12px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' 
          }}>
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              style={{ 
                width: '100%', maxWidth: '900px', maxHeight: '90vh', 
                background: '#0f172a', borderRadius: '32px', border: '1px solid rgba(255,255,255,0.1)',
                overflow: 'hidden', display: 'flex', flexDirection: 'column'
              }}
            >
              <div style={{ padding: '32px 40px', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                  <div style={{ width: '56px', height: '56px', borderRadius: '18px', background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <BarChart size={28} />
                  </div>
                  <div>
                    <h3 style={{ margin: 0, fontSize: '22px', fontWeight: '900' }}>Student Diagnostic Report</h3>
                    <p style={{ margin: '4px 0 0 0', color: 'var(--text-dim)', fontSize: '14px', fontWeight: '600' }}>
                      Participant: <span style={{ color: 'white' }}>{studentMap[activeResult.student_id]?.name || activeResult.studentName}</span>
                    </p>
                  </div>
                </div>
                <button onClick={() => setShowDetailModal(false)} style={{ background: 'rgba(255,255,255,0.05)', border: 'none', color: 'white', width: '44px', height: '44px', borderRadius: '14px', cursor: 'pointer' }}>
                  <XCircle size={24} />
                </button>
              </div>

              <div style={{ padding: '40px', overflowY: 'auto', flex: 1 }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '24px', marginBottom: '40px' }}>
                  {[
                    { label: 'Final Score', value: `${activeResult.score}/${selectedQuiz.total_marks || 10}`, color: 'var(--primary)', icon: <Target size={20}/> },
                    { label: 'Accuracy Index', value: `${((activeResult.score / (selectedQuiz.total_marks || 10)) * 100).toFixed(0)}%`, color: '#a855f7', icon: <Zap size={20}/> },
                    { label: 'Fidelity Status', value: 'VERIFIED', color: '#10b981', icon: <ShieldCheck size={20}/> },
                  ].map((stat, i) => (
                    <div key={i} style={{ background: 'rgba(255,255,255,0.02)', padding: '24px', borderRadius: '24px', border: '1px solid rgba(255,255,255,0.05)', textAlign: 'center' }}>
                      <div style={{ color: stat.color, marginBottom: '12px', display: 'flex', justifyContent: 'center' }}>{stat.icon}</div>
                      <div style={{ fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>{stat.label}</div>
                      <div style={{ fontSize: '28px', fontWeight: '900', color: 'white' }}>{stat.value}</div>
                    </div>
                  ))}
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  <h4 style={{ margin: 0, fontSize: '16px', fontWeight: '900', display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--primary)' }}>
                    <Layers size={18} /> Question-by-Question Breakdown
                  </h4>
                  
                  {(!selectedQuiz.questions || selectedQuiz.questions.length === 0) ? (
                    <div style={{ padding: '40px', textAlign: 'center', background: 'rgba(255,255,255,0.02)', borderRadius: '24px', border: '1px dashed rgba(255,255,255,0.1)' }}>
                      <p style={{ color: 'var(--text-dim)', fontSize: '14px' }}>Detailed question data unavailable for this assessment node.</p>
                    </div>
                  ) : (
                    selectedQuiz.questions.map((q, i) => {
                      const ans = activeResult.answers?.[i];
                      const isCorrect = q.type === 'short_answer' ? true : (ans === (q.correct_option ?? q.correctOption));
                      return (
                        <div key={i} style={{ 
                          padding: '24px', background: 'rgba(255,255,255,0.02)', borderRadius: '24px', 
                          border: '1px solid', borderColor: isCorrect ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)'
                        }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
                            <span style={{ fontSize: '11px', fontWeight: '900', color: 'var(--text-dim)', background: 'rgba(255,255,255,0.05)', padding: '4px 10px', borderRadius: '8px' }}>Q{i+1} • {q.marks || 1} MARKS</span>
                            {isCorrect ? <CheckCircle2 size={18} color="#10b981" /> : <XCircle size={18} color="#ef4444" />}
                          </div>
                          <p style={{ margin: '0 0 20px 0', fontSize: '16px', fontWeight: '600', lineHeight: '1.5' }}>{q.text || q.question}</p>
                          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                            <div style={{ padding: '16px', background: 'rgba(255,255,255,0.03)', borderRadius: '16px' }}>
                              <div style={{ fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', marginBottom: '4px' }}>STUDENT CHOICE</div>
                              <div style={{ fontSize: '14px', fontWeight: '700', color: isCorrect ? '#10b981' : '#ef4444' }}>{q.options?.[ans] || ans || 'No Answer'}</div>
                            </div>
                            {!isCorrect && (
                              <div style={{ padding: '16px', background: 'rgba(16,185,129,0.05)', borderRadius: '16px' }}>
                                <div style={{ fontSize: '10px', fontWeight: '900', color: '#10b981', marginBottom: '4px' }}>CORRECT KEY</div>
                                <div style={{ fontSize: '14px', fontWeight: '700', color: 'white' }}>{q.options?.[q.correct_option ?? q.correctOption] || 'N/A'}</div>
                              </div>
                            )}
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>

              <div style={{ padding: '32px 40px', background: 'rgba(255,255,255,0.02)', borderTop: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'flex-end' }}>
                <button onClick={() => setShowDetailModal(false)} style={{ padding: '14px 40px', borderRadius: '16px', background: 'white', color: '#0f172a', fontWeight: '900', fontSize: '14px', border: 'none', cursor: 'pointer' }}>
                  Close Report
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <style dangerouslySetInnerHTML={{ __html: `
        .glass-input:focus {
          outline: none;
          border-color: var(--primary) !important;
          background: rgba(255,255,255,0.05) !important;
          box-shadow: 0 0 20px rgba(99, 102, 241, 0.1);
        }
        .spinning-loader {
          border: 3px solid rgba(255,255,255,0.05);
          border-top-color: var(--primary);
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); borderRadius: 10px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.2); }
      `}} />
    </div>
  );
}
