import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, query, where, orderBy, getDocs, doc, getDoc } from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';
import { Trophy, Search, BarChart3, Users, Clock, Target, ChevronDown, ChevronUp, Award, ExternalLink, ShieldCheck, XCircle, Brain, BarChart, AlertTriangle, CheckCircle2 } from 'lucide-react';
import { BarChart as RechartsBarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell, PieChart, Pie } from 'recharts';

export default function QuizResults({ role, user, quizzes, allUsers }) {
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

  const filteredQuizzes = (quizzes || []).filter(q =>
    q.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    q.subject?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: '24px' }}>
        <h2 style={{ fontSize: '28px', margin: 0 }}>
          <span className="gradient-text">Quiz Results</span>
        </h2>
        <p style={{ color: 'var(--text-dim)', fontSize: '14px', marginTop: '4px' }}>
          View detailed quiz performance and student scores
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: selectedQuiz ? '320px 1fr' : '1fr', gap: '20px' }}>
        {/* Quiz List */}
        <div>
          <div style={{ position: 'relative', marginBottom: '16px' }}>
            <Search size={14} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
            <input
              className="glass-input"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search quizzes..."
              style={{ width: '100%', paddingLeft: '34px' }}
            />
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', maxHeight: selectedQuiz ? '70vh' : 'auto', overflowY: 'auto' }}>
            {filteredQuizzes.length === 0 ? (
              <div className="glass-card" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-dim)' }}>
                <Trophy size={32} style={{ opacity: 0.3, marginBottom: '8px' }} />
                <p style={{ fontWeight: '600' }}>No quizzes found</p>
              </div>
            ) : (
              filteredQuizzes.map((q, idx) => (
                <motion.div
                  key={q.id}
                  whileHover={{ scale: 1.01 }}
                  onClick={() => loadResults(q)}
                  className="glass-card"
                  style={{
                    padding: '16px 20px', cursor: 'pointer',
                    borderColor: selectedQuiz?.id === q.id ? 'var(--primary)' : 'var(--glass-border)'
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <h4 style={{ margin: 0, fontSize: '15px', fontWeight: '700' }}>{q.title}</h4>
                      <p style={{ margin: '4px 0 0', fontSize: '12px', color: 'var(--text-dim)' }}>
                        {q.subject || 'General'} • {q.total_marks || 0} marks • {q.questions?.length || 0} Qs
                      </p>
                    </div>
                    <div style={{ padding: '6px 12px', borderRadius: '8px', background: 'var(--glass-surface)', fontSize: '11px', fontWeight: '700', color: 'var(--text-dim)' }}>
                      {q.class_id || 'All'}
                    </div>
                  </div>
                </motion.div>
              ))
            )}
          </div>
        </div>

        {/* Detailed Results Pane */}
        <AnimatePresence mode="wait">
          {!selectedQuiz ? (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="glass-card"
              style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', background: 'rgba(255,255,255,0.01)', borderStyle: 'dashed' }}
            >
              <Trophy size={60} style={{ opacity: 0.05, marginBottom: '24px', color: 'var(--primary)' }} />
              <h3 style={{ fontSize: '20px', fontWeight: '800', color: 'var(--text-dim)' }}>Select a quiz node to initialize analysis</h3>
              <p style={{ color: 'var(--text-dim)', fontSize: '14px', opacity: 0.6 }}>Data will be aggregated across all student submissions.</p>
            </motion.div>
          ) : (
            <motion.div
              key={selectedQuiz.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
            >
              {/* Score Stats Row */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '24px' }}>
                {[
                  { label: 'Submissions', value: results.length, icon: <Users size={20} />, color: '#3b82f6', desc: 'Total attempts' },
                  { label: 'Class Average', value: avgScore, icon: <BarChart3 size={20} />, color: '#8b5cf6', desc: 'Mean competency' },
                  { label: 'Highest Score', value: maxScore, icon: <Award size={20} />, color: '#10b981', desc: 'Peak performance' },
                  { label: 'Passing Index', value: `${passRate}%`, icon: <Target size={20} />, color: '#f59e0b', desc: 'Success ratio' },
                ].map((s, i) => (
                  <div key={i} className="glass-card" style={{ padding: '24px', position: 'relative', overflow: 'hidden' }}>
                    <div style={{ position: 'absolute', right: '-10px', top: '-10px', opacity: 0.05, color: s.color }}>
                      {React.cloneElement(s.icon, { size: 60 })}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
                      <div style={{ padding: '10px', borderRadius: '12px', background: `${s.color}15`, color: s.color }}>{s.icon}</div>
                      <span style={{ fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px' }}>{s.label}</span>
                    </div>
                    <div style={{ fontSize: '32px', fontWeight: '900', color: 'var(--text-main)', marginBottom: '4px' }}>{s.value}</div>
                    <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600' }}>{s.desc}</div>
                  </div>
                ))}
              </div>

              {/* Visualization Section */}
              <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', marginBottom: '24px' }}>
                <div className="glass-card" style={{ padding: '32px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
                    <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '800' }}>Competency Distribution</h3>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <div style={{ padding: '6px 12px', background: 'var(--glass-surface)', borderRadius: '8px', fontSize: '11px', fontWeight: '700', border: '1px solid var(--glass-border)', color: 'var(--text-dim)' }}>Live Aggregate</div>
                    </div>
                  </div>
                  <div style={{ height: '280px', width: '100%' }}>
                    <ResponsiveContainer width="100%" height="100%">
                      <RechartsBarChart data={distributionData}>
                        <XAxis dataKey="range" axisLine={false} tickLine={false} tick={{ fill: 'var(--text-dim)', fontSize: 12 }} />
                        <YAxis hide />
                        <Tooltip
                          cursor={{ fill: 'rgba(255,255,255,0.03)' }}
                          contentStyle={{ background: '#0f172a', border: '1px solid var(--glass-border)', borderRadius: '12px' }}
                          itemStyle={{ color: 'white', fontSize: '12px', fontWeight: '700' }}
                          labelStyle={{ color: 'rgba(255,255,255,0.6)', fontSize: '10px', marginBottom: '4px', fontWeight: '800' }}
                        />
                        <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                          {distributionData.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={index === 4 ? 'var(--primary)' : '#6366f1'} fillOpacity={0.8} />
                          ))}
                        </Bar>
                      </RechartsBarChart>
                    </ResponsiveContainer>
                  </div>
                </div>

                <div className="glass-card" style={{ padding: '32px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                  <h3 style={{ margin: '0 0 24px 0', fontSize: '18px', fontWeight: '800', textAlign: 'center' }}>Pass / Fail Logic</h3>
                  <div style={{ height: '200px' }}>
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
                        >
                          {(results || []).length > 0 && [
                            { color: '#10b981' },
                            { color: '#ef4444' }
                          ].map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry.color} />
                          ))}
                        </Pie>
                        <Tooltip 
                          contentStyle={{ background: '#0f172a', border: '1px solid var(--glass-border)', borderRadius: '12px' }}
                          itemStyle={{ color: 'white', fontSize: '12px', fontWeight: '700' }}
                          labelStyle={{ display: 'none' }}
                        />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'center', gap: '20px', marginTop: '20px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', fontWeight: '700', color: '#10b981' }}>
                      <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#10b981' }}></div> Passed
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', fontWeight: '700', color: '#ef4444' }}>
                      <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#ef4444' }}></div> Failed
                    </div>
                  </div>
                </div>
              </div>

              {/* Submissions Table */}
              <div className="glass-card" style={{ overflow: 'hidden' }}>
                <div style={{ padding: '24px 32px', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'rgba(255,255,255,0.01)' }}>
                  <div>
                    <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '800' }}>Assessment Node Ledger</h3>
                    <p style={{ margin: '4px 0 0 0', fontSize: '12px', color: 'var(--text-dim)', fontWeight: '600' }}>Individual student performance matrices</p>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    <span style={{ fontSize: '12px', fontWeight: '800', color: 'var(--text-dim)' }}>{results.length} ENTRIES FOUND</span>
                  </div>
                </div>

                {loading ? (
                  <div style={{ padding: '100px', textAlign: 'center' }}>
                    <div className="spinning-loader" style={{ width: '40px', height: '40px', margin: '0 auto 16px auto', border: '3px solid rgba(255,255,255,0.05)', borderTopColor: 'var(--primary)', borderRadius: '50%' }}></div>
                    <p style={{ color: 'var(--text-dim)', fontWeight: '700' }}>Synchronizing results...</p>
                  </div>
                ) : results.length === 0 ? (
                  <div style={{ padding: '100px', textAlign: 'center', color: 'var(--text-dim)' }}>
                    <Users size={60} style={{ opacity: 0.1, marginBottom: '24px' }} />
                    <h4 style={{ color: 'var(--text-main)', margin: '0 0 8px 0' }}>No Submissions Synchronized</h4>
                    <p style={{ maxWidth: '300px', margin: '0 auto', fontSize: '14px', lineHeight: '1.6' }}>Students have not yet committed any response nodes for this assessment.</p>
                  </div>
                ) : (
                  <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                      <thead>
                        <tr style={{ borderBottom: '1px solid var(--glass-border)', background: 'rgba(255,255,255,0.02)', color: 'var(--text-dim)', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '1.5px' }}>
                          <th style={{ padding: '24px 32px' }}>Student Identity</th>
                          <th style={{ padding: '24px' }}>Score Matrix</th>
                          <th style={{ padding: '24px' }}>Competency</th>
                          <th style={{ padding: '24px' }}>Grade</th>
                          <th style={{ padding: '24px' }}>Fidelity Date</th>
                          <th style={{ padding: '24px 32px', textAlign: 'right' }}>Diagnostics</th>
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
                              initial={{ opacity: 0 }}
                              animate={{ opacity: 1 }}
                              transition={{ delay: idx * 0.05 }}
                              style={{ borderBottom: '1px solid var(--glass-border)', background: 'transparent' }}
                            >
                              <td style={{ padding: '20px 32px' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                                  <div style={{ width: '40px', height: '40px', borderRadius: '14px', background: 'linear-gradient(135deg, #6366f1, #8b5cf6)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '900', fontSize: '14px', boxShadow: '0 8px 15px rgba(99,102,241,0.2)' }}>
                                    {(student.name || r.studentName || 'S').charAt(0).toUpperCase()}
                                  </div>
                                  <div>
                                    <div style={{ fontWeight: '800', fontSize: '15px', color: 'var(--text-main)' }}>{student.name || r.studentName || 'Unmapped Node'}</div>
                                    <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '700', textTransform: 'uppercase' }}>STUDENT ID: {r.student_id?.slice(0, 8) || 'N/A'}</div>
                                  </div>
                                </div>
                              </td>
                              <td style={{ padding: '20px' }}>
                                <div style={{ fontSize: '18px', fontWeight: '900', color: 'var(--text-main)' }}>{r.score} <span style={{ color: 'var(--text-dim)', fontSize: '13px', fontWeight: '500' }}>/ {selectedQuiz.total_marks || 10}</span></div>
                              </td>
                              <td style={{ padding: '20px' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                  <div style={{ flex: 1, height: '6px', width: '80px', background: 'rgba(255,255,255,0.05)', borderRadius: '3px', overflow: 'hidden' }}>
                                    <motion.div initial={{ width: 0 }} animate={{ width: `${pct}%` }} transition={{ duration: 1 }} style={{ height: '100%', background: getGradeColor(pct), boxShadow: `0 0 10px ${getGradeColor(pct)}40` }}></motion.div>
                                  </div>
                                  <span style={{ fontSize: '13px', fontWeight: '900', color: getGradeColor(pct) }}>{pct.toFixed(0)}%</span>
                                </div>
                              </td>
                              <td style={{ padding: '20px' }}>
                                <div style={{ fontSize: '18px', fontWeight: '900', color: getGradeColor(pct) }}>{grade}</div>
                              </td>
                              <td style={{ padding: '20px', fontSize: '13px', color: 'var(--text-dim)', fontWeight: '600' }}>
                                {r.submitted_at?.toDate?.()?.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) || r.submitted_at || 'N/A'}
                              </td>
                              <td style={{ padding: '20px 32px', textAlign: 'right' }}>
                                <button
                                  onClick={() => { setActiveResult(r); setShowDetailModal(true); }}
                                  style={{ padding: '10px 16px', borderRadius: '10px', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--glass-border)', color: 'var(--text-main)', fontSize: '12px', fontWeight: '700', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: '8px' }}
                                >
                                  Deep Dive <ExternalLink size={14} />
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

      {/* Analysis Modal */}
      <AnimatePresence>
        {showDetailModal && activeResult && (
          <div style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', background: 'rgba(15, 23, 42, 0.9)', backdropFilter: 'blur(20px)', zIndex: 10000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
            <motion.div
              initial={{ scale: 0.95, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.95, opacity: 0, y: 20 }}
              className="glass-card"
              style={{ width: '100%', maxWidth: '900px', maxHeight: '90vh', overflowY: 'auto', border: '1px solid var(--primary)', position: 'relative' }}
            >
              {/* Modal Header */}
              <div style={{ position: 'sticky', top: 0, background: 'rgba(15, 23, 42, 0.8)', backdropFilter: 'blur(10px)', padding: '32px 40px', borderBottom: '1px solid var(--glass-border)', zIndex: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                  <div style={{ width: '56px', height: '56px', borderRadius: '18px', background: 'linear-gradient(135deg, var(--primary), #8b5cf6)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 10px 25px rgba(236, 72, 153, 0.3)' }}>
                    <Target size={28} />
                  </div>
                  <div>
                    <h3 style={{ margin: 0, fontSize: '24px', fontWeight: '900', letterSpacing: '-0.5px' }}>Response Analytics</h3>
                    <p style={{ margin: '4px 0 0 0', color: 'var(--text-dim)', fontWeight: '600', fontSize: '14px' }}>
                      Diagnostic breakdown for <span style={{ color: 'var(--text-main)' }}>{studentMap[activeResult.student_id]?.name || activeResult.studentName || 'Student'}</span>
                    </p>
                  </div>
                </div>
                <button onClick={() => setShowDetailModal(false)} style={{ background: 'rgba(255,255,255,0.05)', border: 'none', color: 'var(--text-main)', cursor: 'pointer', width: '40px', height: '40px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}>
                  <XCircle size={24} />
                </button>
              </div>

              <div style={{ padding: '40px' }}>
                {/* Score Summary Cards */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '20px', marginBottom: '40px' }}>
                  {[
                    { label: 'Precision Score', value: `${activeResult.score} / ${selectedQuiz.total_marks || selectedQuiz.totalMarks || 10}`, icon: <Target size={20} />, color: 'var(--primary)' },
                    { label: 'Competency Index', value: `${((activeResult.score / (selectedQuiz.total_marks || selectedQuiz.totalMarks || 10)) * 100).toFixed(0)}%`, icon: <Brain size={20} />, color: '#8b5cf6' },
                    { label: 'Fidelity Status', value: 'VERIFIED', icon: <ShieldCheck size={20} />, color: '#10b981' },
                  ].map((s, i) => (
                    <div key={i} style={{ padding: '24px', background: 'rgba(255,255,255,0.02)', borderRadius: '24px', border: '1px solid var(--glass-border)', textAlign: 'center' }}>
                      <div style={{ color: s.color, marginBottom: '12px', display: 'flex', justifyContent: 'center' }}>{s.icon}</div>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px', fontWeight: '800', letterSpacing: '1px' }}>{s.label}</div>
                      <div style={{ fontSize: '28px', fontWeight: '900', color: 'var(--text-main)' }}>{s.value}</div>
                    </div>
                  ))}
                </div>

                {/* Detailed Question Review */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
                    <BarChart size={18} color="var(--primary)" />
                    <h4 style={{ margin: 0, fontSize: '16px', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '1px' }}>Fidelity Diagnostics (Per Question)</h4>
                  </div>

                  {(!selectedQuiz.questions || selectedQuiz.questions.length === 0) ? (
                    <div style={{ padding: '60px', textAlign: 'center', background: 'rgba(255,255,255,0.02)', borderRadius: '24px', border: '1px dashed var(--glass-border)' }}>
                      <AlertTriangle size={48} style={{ opacity: 0.2, marginBottom: '16px', color: '#f59e0b' }} />
                      <h5 style={{ margin: 0, fontSize: '18px', color: 'var(--text-main)' }}>Question Data Unavailable</h5>
                      <p style={{ margin: '8px 0 0 0', color: 'var(--text-dim)', fontSize: '14px' }}>This assessment was created with a legacy node that did not store question text.</p>
                    </div>
                  ) : (
                    selectedQuiz.questions.map((q, i) => {
                      const studentAnswer = activeResult.answers?.[i];
                      const isCorrect = q.type === 'short_answer' ? true : (studentAnswer === (q.correct_option ?? q.correctOption));

                      return (
                        <motion.div
                          key={i}
                          initial={{ opacity: 0, x: -10 }}
                          animate={{ opacity: 1, x: 0 }}
                          transition={{ delay: i * 0.1 }}
                          style={{ padding: '28px', background: 'rgba(255,255,255,0.02)', borderRadius: '24px', border: `1px solid ${isCorrect ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)'}`, position: 'relative', overflow: 'hidden' }}
                        >
                          {/* Background Glow */}
                          <div style={{ position: 'absolute', top: 0, right: 0, width: '100px', height: '100px', background: isCorrect ? 'radial-gradient(circle, rgba(16,185,129,0.05) 0%, transparent 70%)' : 'radial-gradient(circle, rgba(239,68,68,0.05) 0%, transparent 70%)', zIndex: 0 }}></div>

                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px', position: 'relative', zIndex: 1 }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                              <span style={{ fontSize: '12px', fontWeight: '900', color: 'var(--text-dim)', background: 'rgba(255,255,255,0.05)', padding: '4px 10px', borderRadius: '6px' }}>NODE #{i + 1}</span>
                              <span style={{ fontSize: '11px', fontWeight: '700', color: 'var(--primary)' }}>{q.marks || 1} MARKS</span>
                            </div>
                            {isCorrect ? (
                              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#10b981', fontSize: '12px', fontWeight: '900' }}>
                                <CheckCircle2 size={16} /> PRECISION MATCH
                              </div>
                            ) : (
                              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#ef4444', fontSize: '12px', fontWeight: '900' }}>
                                <XCircle size={16} /> FIDELITY LOSS
                              </div>
                            )}
                          </div>

                          <p style={{ margin: '0 0 24px 0', fontSize: '17px', fontWeight: '600', color: 'var(--text-main)', lineHeight: '1.6', position: 'relative', zIndex: 1 }}>{q.text || q.question}</p>

                          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', position: 'relative', zIndex: 1 }}>
                            <div style={{ padding: '16px', borderRadius: '16px', background: isCorrect ? 'rgba(16,185,129,0.05)' : 'rgba(239,68,68,0.05)', border: `1px solid ${isCorrect ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)'}` }}>
                              <div style={{ fontSize: '10px', fontWeight: '900', color: isCorrect ? '#10b981' : '#ef4444', marginBottom: '8px', textTransform: 'uppercase' }}>STUDENT RESPONSE</div>
                              <div style={{ fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>
                                {q.type === 'mcq' ? (q.options?.[studentAnswer] || 'UNANSWERED') : (studentAnswer || 'NO DATA')}
                              </div>
                            </div>

                            {!isCorrect && (
                              <div style={{ padding: '16px', borderRadius: '16px', background: 'rgba(16, 185, 129, 0.05)', border: '1px solid rgba(16, 185, 129, 0.1)' }}>
                                <div style={{ fontSize: '10px', fontWeight: '900', color: '#10b981', marginBottom: '8px', textTransform: 'uppercase' }}>EXPECTED MATCH</div>
                                <div style={{ fontSize: '14px', fontWeight: '700', color: 'var(--text-main)' }}>
                                  {q.options?.[q.correct_option ?? q.correctOption] || 'N/A'}
                                </div>
                              </div>
                            )}
                          </div>
                        </motion.div>
                      );
                    })
                  )}
                </div>
              </div>

              {/* Modal Footer */}
              <div style={{ padding: '32px 40px', borderTop: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'flex-end', background: 'rgba(15, 23, 42, 0.4)' }}>
                <button onClick={() => setShowDetailModal(false)} style={{ padding: '12px 32px', borderRadius: '12px', background: 'white', color: '#0f172a', fontWeight: '900', fontSize: '14px', border: 'none', cursor: 'pointer' }}>
                  Close Diagnostics
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </div>
    </div>
  );
}
