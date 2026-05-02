import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, query, where, orderBy, getDocs, doc, getDoc } from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Trophy, Search, BarChart3, Users, Clock, Target, 
  ChevronDown, ChevronUp, Award, ExternalLink, ShieldCheck, 
  XCircle, Brain, BarChart, AlertTriangle, CheckCircle2,
  Calendar, BookOpen, Layers, Zap, Filter, Layout
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
    <div style={{ color: 'var(--text-main)', minHeight: '100vh', fontFamily: "'Inter', sans-serif" }}>
      {/* Header Section */}
      <div className="glass-card" style={{ 
        marginBottom: '32px', 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center',
        padding: '24px 32px',
        background: 'var(--glass-surface)',
        borderColor: 'var(--glass-border)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          <div style={{ 
            width: '56px', height: '56px', borderRadius: '16px', 
            background: 'linear-gradient(135deg, var(--primary), var(--secondary))',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 8px 20px var(--primary-glow)'
          }}>
            <Layout size={28} color="white" />
          </div>
          <div>
            <h2 style={{ fontSize: '26px', fontWeight: '900', margin: 0, color: 'var(--text-main)' }}>
              Assessment <span className="gradient-text">Diagnostics</span>
            </h2>
            <p style={{ color: 'var(--text-dim)', fontSize: '13px', margin: '2px 0 0', fontWeight: '600' }}>
              Deep fidelity analysis for all synced quiz modules.
            </p>
          </div>
        </div>
        
        <div style={{ display: 'flex', gap: '24px' }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '20px', fontWeight: '900', color: 'var(--text-main)' }}>{quizzes.length}</div>
            <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase' }}>Nodes</div>
          </div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: '20px', fontWeight: '900', color: 'var(--primary)' }}>{role === 'admin' ? 'All' : visibleClasses.length}</div>
            <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase' }}>{role === 'admin' ? 'Scope' : 'Units'}</div>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '360px 1fr', gap: '24px', alignItems: 'start' }}>
        {/* Sidebar: Quiz Explorer */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
            <input
              className="glass-input"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Filter assessments..."
              style={{ width: '100%', padding: '14px 16px 14px 48px', borderRadius: '14px' }}
            />
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', maxHeight: '70vh', overflowY: 'auto' }}>
            {filteredQuizzes.length === 0 ? (
              <div className="glass-card" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-dim)', background: 'var(--glass-surface)' }}>
                <Trophy size={32} style={{ opacity: 0.2, marginBottom: '12px' }} />
                <p style={{ fontSize: '13px', fontWeight: '700' }}>No modules found</p>
              </div>
            ) : (
              filteredQuizzes.map((q) => (
                <motion.div
                  key={q.id}
                  whileHover={{ x: 4 }}
                  onClick={() => loadResults(q)}
                  className="glass-card"
                  style={{
                    padding: '16px',
                    cursor: 'pointer',
                    background: selectedQuiz?.id === q.id ? 'var(--primary-glow)' : 'var(--glass-surface)',
                    borderColor: selectedQuiz?.id === q.id ? 'var(--primary)' : 'var(--glass-border)',
                    transition: 'all 0.2s ease',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '16px'
                  }}
                >
                  <div style={{ 
                    width: '40px', height: '40px', borderRadius: '12px', 
                    background: selectedQuiz?.id === q.id ? 'var(--primary)' : 'var(--glass-surface)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    color: selectedQuiz?.id === q.id ? 'white' : 'var(--text-dim)',
                    flexShrink: 0
                  }}>
                    <BookOpen size={20} />
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <h4 style={{ 
                      margin: 0, fontSize: '15px', fontWeight: '800', 
                      color: 'var(--text-main)', overflow: 'hidden', 
                      textOverflow: 'ellipsis', whiteSpace: 'nowrap' 
                    }}>
                      {q.title || q.quiz_title || 'Untitled Quiz'}
                    </h4>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600', marginTop: '2px' }}>
                      <span style={{ textTransform: 'uppercase' }}>{q.subject || 'Academic'}</span>
                      <span style={{ opacity: 0.3 }}>•</span>
                      <span>{q.questions_count || q.questions?.length || 0} Qs</span>
                    </div>
                  </div>
                  <div style={{ 
                    fontSize: '10px', fontWeight: '900', color: 'var(--primary)', 
                    padding: '4px 8px', background: 'var(--primary-glow)', 
                    borderRadius: '6px', textTransform: 'uppercase' 
                  }}>
                    {q.class_id || 'GRP'}
                  </div>
                </motion.div>
              ))
            )}
          </div>
        </div>

        {/* Main Analytics Area */}
        <div style={{ minHeight: '60vh' }}>
          <AnimatePresence mode="wait">
            {!selectedQuiz ? (
              <motion.div
                key="empty"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="glass-card"
                style={{ 
                  height: '100%', minHeight: '60vh', display: 'flex', flexDirection: 'column', 
                  alignItems: 'center', justifyContent: 'center', background: 'var(--glass-surface)',
                  borderStyle: 'dashed', padding: '40px' 
                }}
              >
                <Target size={64} style={{ color: 'var(--primary)', opacity: 0.1, marginBottom: '24px' }} />
                <h3 style={{ fontSize: '20px', fontWeight: '900', color: 'var(--text-main)', marginBottom: '8px' }}>Select Assessment Node</h3>
                <p style={{ color: 'var(--text-dim)', fontSize: '14px', textAlign: 'center', maxWidth: '320px' }}>
                  Pick a quiz module from the list to synchronize and analyze student response matrices.
                </p>
              </motion.div>
            ) : (
              <motion.div
                key={selectedQuiz.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
              >
                {/* Stats Grid */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '24px' }}>
                  {[
                    { label: 'Total Submissions', value: results.length, icon: <Users size={18} />, color: '#6366f1' },
                    { label: 'Class Competency', value: `${avgScore}%`, icon: <Brain size={18} />, color: '#a855f7' },
                    { label: 'High Fidelity', value: maxScore, icon: <Award size={18} />, color: '#10b981' },
                    { label: 'Passing Index', value: `${passRate}%`, icon: <Target size={18} />, color: '#f59e0b' },
                  ].map((s, i) => (
                    <div key={i} className="glass-card" style={{ padding: '20px', background: 'var(--glass-surface)' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
                        <div style={{ padding: '8px', borderRadius: '10px', background: `${s.color}20`, color: s.color }}>{s.icon}</div>
                        <span style={{ fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{s.label}</span>
                      </div>
                      <div style={{ fontSize: '26px', fontWeight: '900', color: 'var(--text-main)' }}>{s.value}</div>
                    </div>
                  ))}
                </div>

                {/* Charts Row */}
                <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '24px', marginBottom: '24px' }}>
                  <div className="glass-card" style={{ padding: '24px', background: 'var(--glass-surface)' }}>
                    <h4 style={{ margin: '0 0 20px 0', fontSize: '16px', fontWeight: '900' }}>Competency Distribution</h4>
                    <div style={{ height: '260px' }}>
                      <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={distributionData}>
                          <defs>
                            <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
                              <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.2}/>
                              <stop offset="95%" stopColor="var(--primary)" stopOpacity={0}/>
                            </linearGradient>
                          </defs>
                          <XAxis dataKey="range" axisLine={false} tickLine={false} tick={{ fill: 'var(--text-dim)', fontSize: 11 }} />
                          <YAxis hide />
                          <Tooltip contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '12px', color: 'var(--text-main)' }} />
                          <Area type="monotone" dataKey="count" stroke="var(--primary)" strokeWidth={2} fill="url(#areaGradient)" />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>
                  </div>

                  <div className="glass-card" style={{ padding: '24px', background: 'var(--glass-surface)', display: 'flex', flexDirection: 'column' }}>
                    <h4 style={{ margin: '0 0 20px 0', fontSize: '16px', fontWeight: '900', textAlign: 'center' }}>Pass / Fail Logic</h4>
                    <div style={{ flex: 1 }}>
                      <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                          <Pie
                            data={[
                              { name: 'Passed', value: (results || []).filter(r => (r.score / (selectedQuiz?.total_marks || 10) * 100) >= 40).length, color: '#10b981' },
                              { name: 'Failed', value: (results || []).filter(r => (r.score / (selectedQuiz?.total_marks || 10) * 100) < 40).length, color: '#ef4444' }
                            ]}
                            innerRadius={60}
                            outerRadius={80}
                            paddingAngle={5}
                            dataKey="value"
                            stroke="none"
                          >
                            {(results || []).length > 0 && [
                              { color: '#10b981' },
                              { color: '#ef4444' }
                            ].map((entry, index) => <Cell key={`cell-${index}`} fill={entry.color} />)}
                          </Pie>
                          <Tooltip contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '12px' }} />
                        </PieChart>
                      </ResponsiveContainer>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'center', gap: '20px', fontSize: '12px', fontWeight: '700' }}>
                      <span style={{ color: '#10b981' }}>Passed</span>
                      <span style={{ color: '#ef4444' }}>Failed</span>
                    </div>
                  </div>
                </div>

                {/* Ledger Table */}
                <div className="glass-card" style={{ overflow: 'hidden', background: 'var(--glass-surface)' }}>
                  <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h4 style={{ margin: 0, fontWeight: '900' }}>Assessment Node Ledger</h4>
                    <div style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)' }}>{results.length} RECORDS SYNCED</div>
                  </div>

                  {loading ? (
                    <div style={{ padding: '80px', textAlign: 'center' }}><div className="spinning-loader" style={{ margin: '0 auto' }}></div></div>
                  ) : results.length === 0 ? (
                    <div style={{ padding: '60px', textAlign: 'center', color: 'var(--text-dim)' }}>No submissions found for this module.</div>
                  ) : (
                    <div style={{ overflowX: 'auto' }}>
                      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                          <tr style={{ background: 'var(--glass-surface)', color: 'var(--text-dim)', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase' }}>
                            <th style={{ padding: '16px 24px' }}>Student Identity</th>
                            <th style={{ padding: '16px' }}>Score</th>
                            <th style={{ padding: '16px' }}>Fidelity</th>
                            <th style={{ padding: '16px' }}>Grade</th>
                            <th style={{ padding: '16px 24px', textAlign: 'right' }}>Diagnostic</th>
                          </tr>
                        </thead>
                        <tbody>
                          {results.sort((a, b) => (b.score || 0) - (a.score || 0)).map((r, idx) => {
                            const student = studentMap[r.student_id] || studentMap[r.studentId] || {};
                            const pct = (r.score / (selectedQuiz.total_marks || 10) * 100);
                            const grade = pct >= 90 ? 'A+' : pct >= 75 ? 'A' : pct >= 60 ? 'B' : pct >= 40 ? 'C' : 'F';
                            return (
                              <tr key={r.id} style={{ borderBottom: '1px solid var(--glass-border)' }}>
                                <td style={{ padding: '14px 24px' }}>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                    <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '900', fontSize: '13px' }}>
                                      {(student.name || r.studentName || 'S').charAt(0).toUpperCase()}
                                    </div>
                                    <div>
                                      <div style={{ fontWeight: '800', fontSize: '14px', color: 'var(--text-main)' }}>{student.name || r.studentName || 'Student Node'}</div>
                                      <div style={{ fontSize: '10px', color: 'var(--text-dim)' }}>{r.student_id?.slice(0, 10)}</div>
                                    </div>
                                  </div>
                                </td>
                                <td style={{ padding: '14px', fontWeight: '900', color: 'var(--text-main)' }}>{r.score} <span style={{ opacity: 0.2 }}>/ {selectedQuiz.total_marks || 10}</span></td>
                                <td style={{ padding: '14px' }}>
                                  <div style={{ width: '60px', height: '6px', background: 'var(--glass-surface)', borderRadius: '3px', overflow: 'hidden' }}>
                                    <div style={{ height: '100%', width: `${pct}%`, background: getGradeColor(pct) }}></div>
                                  </div>
                                </td>
                                <td style={{ padding: '14px', fontWeight: '900', color: getGradeColor(pct) }}>{grade}</td>
                                <td style={{ padding: '14px 24px', textAlign: 'right' }}>
                                  <button onClick={() => { setActiveResult(r); setShowDetailModal(true); }} style={{ padding: '8px 12px', borderRadius: '8px', background: 'var(--text-main)', color: 'var(--card-bg)', border: 'none', fontSize: '11px', fontWeight: '800', cursor: 'pointer' }}>REPORT</button>
                                </td>
                              </tr>
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

      {/* Detail Modal */}
      <AnimatePresence>
        {showDetailModal && activeResult && (
          <div style={{ position: 'fixed', inset: 0, zIndex: 10000, background: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(10px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
            <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.9, opacity: 0 }} className="glass-card" style={{ width: '100%', maxWidth: '800px', maxHeight: '85vh', background: 'var(--card-bg)', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
              <div style={{ padding: '24px 32px', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h3 style={{ margin: 0, fontWeight: '900' }}>Diagnostic Report: {studentMap[activeResult.student_id]?.name || activeResult.studentName}</h3>
                <XCircle onClick={() => setShowDetailModal(false)} size={24} style={{ cursor: 'pointer', color: 'var(--text-dim)' }} />
              </div>
              <div style={{ padding: '32px', overflowY: 'auto', flex: 1 }}>
                 {/* Question breakdown similar to before but more compact */}
                 <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px', marginBottom: '32px' }}>
                    <div style={{ textAlign: 'center', padding: '16px', background: 'var(--glass-surface)', borderRadius: '16px' }}>
                      <div style={{ fontSize: '10px', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '4px' }}>Final Score</div>
                      <div style={{ fontSize: '24px', fontWeight: '900', color: 'var(--primary)' }}>{activeResult.score}/{selectedQuiz.total_marks || 10}</div>
                    </div>
                    <div style={{ textAlign: 'center', padding: '16px', background: 'var(--glass-surface)', borderRadius: '16px' }}>
                      <div style={{ fontSize: '10px', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '4px' }}>Accuracy</div>
                      <div style={{ fontSize: '24px', fontWeight: '900', color: '#8b5cf6' }}>{((activeResult.score/(selectedQuiz.total_marks || 10))*100).toFixed(0)}%</div>
                    </div>
                    <div style={{ textAlign: 'center', padding: '16px', background: 'var(--glass-surface)', borderRadius: '16px' }}>
                      <div style={{ fontSize: '10px', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '4px' }}>Status</div>
                      <div style={{ fontSize: '24px', fontWeight: '900', color: '#10b981' }}>PASSED</div>
                    </div>
                 </div>

                 <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                   {selectedQuiz.questions?.map((q, i) => {
                     const isCorrect = activeResult.answers?.[i] === (q.correct_option ?? q.correctOption);
                     return (
                       <div key={i} style={{ padding: '16px', background: 'var(--glass-surface)', borderRadius: '16px', border: '1px solid var(--glass-border)' }}>
                         <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                           <span style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)' }}>QUESTION {i+1}</span>
                           {isCorrect ? <CheckCircle2 size={16} color="#10b981" /> : <XCircle size={16} color="#ef4444" />}
                         </div>
                         <p style={{ margin: '0 0 12px 0', fontSize: '14px', fontWeight: '600', color: 'var(--text-main)' }}>{q.text || q.question}</p>
                         <div style={{ fontSize: '12px', color: isCorrect ? '#10b981' : '#ef4444', fontWeight: '700' }}>
                           Student: {q.options?.[activeResult.answers?.[i]] || activeResult.answers?.[i] || 'N/A'}
                         </div>
                       </div>
                     );
                   })}
                 </div>
              </div>
              <div style={{ padding: '20px 32px', background: 'var(--glass-surface)', borderTop: '1px solid var(--glass-border)', textAlign: 'right' }}>
                <button onClick={() => setShowDetailModal(false)} style={{ padding: '10px 24px', borderRadius: '10px', background: 'white', color: '#0f172a', border: 'none', fontWeight: '900', cursor: 'pointer' }}>CLOSE</button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <style dangerouslySetInnerHTML={{ __html: `
        .spinning-loader {
          width: 32px; height: 32px; border: 3px solid var(--glass-border); border-top-color: var(--primary);
          border-radius: 50%; animation: spin 1s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-thumb { background: var(--glass-border); border-radius: 10px; }
      `}} />
    </div>
  );
}
