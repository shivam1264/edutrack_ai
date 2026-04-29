import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, query, where, orderBy, getDocs, doc, getDoc } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { Trophy, Search, BarChart3, Users, Clock, Target, ChevronDown, ChevronUp } from 'lucide-react';

export default function QuizResults({ role, user, quizzes, allUsers }) {
  const [results, setResults] = useState([]);
  const [selectedQuiz, setSelectedQuiz] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(false);

  const studentMap = {};
  allUsers.forEach(u => { if (u.role === 'student') studentMap[u.id] = u; });

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

  const avgScore = results.length > 0
    ? (results.reduce((a, r) => a + (r.score || 0), 0) / results.length).toFixed(1)
    : 0;
  const maxScore = results.length > 0 ? Math.max(...results.map(r => r.score || 0)) : 0;
  const passRate = results.length > 0
    ? ((results.filter(r => (r.percentage || (r.score / (selectedQuiz?.totalMarks || 100) * 100)) >= 40).length / results.length) * 100).toFixed(0)
    : 0;

  const getGradeColor = (pct) => {
    if (pct >= 80) return '#10b981';
    if (pct >= 60) return '#3b82f6';
    if (pct >= 40) return '#f59e0b';
    return '#ef4444';
  };

  const filteredQuizzes = quizzes.filter(q =>
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
                        {q.subject || 'General'} • {q.totalMarks || 0} marks • {q.questions?.length || 0} Qs
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

        {/* Results Detail */}
        {selectedQuiz && (
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }}>
            {/* Stats Bar */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '20px' }}>
              {[
                { label: 'Attempts', value: results.length, icon: <Users size={16} />, color: '#3b82f6' },
                { label: 'Avg Score', value: avgScore, icon: <BarChart3 size={16} />, color: '#8b5cf6' },
                { label: 'Top Score', value: maxScore, icon: <Trophy size={16} />, color: '#10b981' },
                { label: 'Pass Rate', value: `${passRate}%`, icon: <Target size={16} />, color: '#f59e0b' },
              ].map((s, i) => (
                <div key={i} className="glass-card" style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{ padding: '8px', borderRadius: '8px', background: `${s.color}15`, color: s.color }}>{s.icon}</div>
                  <div>
                    <div style={{ fontSize: '20px', fontWeight: '800', letterSpacing: '-0.5px' }}>{s.value}</div>
                    <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '600', textTransform: 'uppercase' }}>{s.label}</div>
                  </div>
                </div>
              ))}
            </div>

            {/* Results Table */}
            <div className="glass-card" style={{ overflow: 'hidden' }}>
              <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h3 style={{ margin: 0, fontSize: '16px' }}>{selectedQuiz.title} — Student Results</h3>
                <span style={{ fontSize: '12px', color: 'var(--text-dim)' }}>{results.length} submissions</span>
              </div>

              {loading ? (
                <div style={{ padding: '60px', textAlign: 'center', color: 'var(--text-dim)' }}>Loading results...</div>
              ) : results.length === 0 ? (
                <div style={{ padding: '60px', textAlign: 'center', color: 'var(--text-dim)' }}>
                  <Trophy size={32} style={{ opacity: 0.3, marginBottom: '8px' }} />
                  <p style={{ fontWeight: '600' }}>No submissions yet</p>
                </div>
              ) : (
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ borderBottom: '1px solid var(--glass-border)' }}>
                      <th style={{ textAlign: 'left', padding: '12px 20px' }}>Student</th>
                      <th style={{ textAlign: 'center', padding: '12px' }}>Score</th>
                      <th style={{ textAlign: 'center', padding: '12px' }}>Percentage</th>
                      <th style={{ textAlign: 'center', padding: '12px' }}>Grade</th>
                      <th style={{ textAlign: 'right', padding: '12px 20px' }}>Submitted</th>
                    </tr>
                  </thead>
                  <tbody>
                    {results.sort((a, b) => (b.score || 0) - (a.score || 0)).map((r, idx) => {
                      const student = studentMap[r.student_id] || studentMap[r.studentId] || {};
                      const pct = r.percentage || (r.score / (selectedQuiz.totalMarks || 100) * 100);
                      const grade = pct >= 90 ? 'A+' : pct >= 75 ? 'A' : pct >= 60 ? 'B' : pct >= 40 ? 'C' : 'F';
                      return (
                        <tr key={r.id} style={{ borderBottom: '1px solid var(--glass-border)' }}>
                          <td style={{ padding: '12px 20px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                              <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: `${getGradeColor(pct)}15`, color: getGradeColor(pct), display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800', fontSize: '12px' }}>
                                {(student.name || r.studentName || 'S').charAt(0).toUpperCase()}
                              </div>
                              <span style={{ fontWeight: '600', fontSize: '14px' }}>{student.name || r.studentName || r.student_id?.slice(0, 8)}</span>
                            </div>
                          </td>
                          <td style={{ textAlign: 'center', fontWeight: '700', fontSize: '15px' }}>{r.score}/{selectedQuiz.totalMarks || 100}</td>
                          <td style={{ textAlign: 'center' }}>
                            <span style={{ padding: '4px 10px', borderRadius: '6px', background: `${getGradeColor(pct)}15`, color: getGradeColor(pct), fontWeight: '700', fontSize: '13px' }}>
                              {pct.toFixed(0)}%
                            </span>
                          </td>
                          <td style={{ textAlign: 'center', fontWeight: '800', color: getGradeColor(pct) }}>{grade}</td>
                          <td style={{ textAlign: 'right', padding: '12px 20px', fontSize: '12px', color: 'var(--text-dim)' }}>
                            {r.submittedAt?.toDate?.()?.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }) || r.submitted_at || 'N/A'}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              )}
            </div>
          </motion.div>
        )}
      </div>
    </div>
  );
}
