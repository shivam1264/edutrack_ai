import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, query, where, getDocs, orderBy } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { Brain, BookOpen, MessageSquare, Search, Zap, Target, Users, ChevronRight, Activity } from 'lucide-react';

export default function StudentAnalytics({ role, allUsers, classes }) {
  const [activeTab, setActiveTab] = useState('brain_dna');
  const [brainDnaData, setBrainDnaData] = useState([]);
  const [studyTasks, setStudyTasks] = useState([]);
  const [homeworkChats, setHomeworkChats] = useState([]);
  const [homeworkUsage, setHomeworkUsage] = useState([]);
  const [knowledgeNodes, setKnowledgeNodes] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedStudent, setSelectedStudent] = useState(null);

  const students = allUsers.filter(u => u.role === 'student');
  const studentMap = {};
  students.forEach(s => { studentMap[s.id] = s; });

  useEffect(() => {
    const unsub1 = onSnapshot(collection(db, 'brain_dna'), (snap) => {
      setBrainDnaData(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    const unsub2 = onSnapshot(collection(db, 'study_tasks'), (snap) => {
      setStudyTasks(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    const unsub3 = onSnapshot(collection(db, 'homework_chats'), (snap) => {
      setHomeworkChats(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    const unsub4 = onSnapshot(collection(db, 'homework_usage'), (snap) => {
      setHomeworkUsage(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    const unsub5 = onSnapshot(collection(db, 'knowledge_nodes'), (snap) => {
      setKnowledgeNodes(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    return () => { unsub1(); unsub2(); unsub3(); unsub4(); unsub5(); };
  }, []);

  const tabs = [
    { id: 'brain_dna', label: 'Brain DNA', icon: <Brain size={16} />, color: '#8b5cf6', count: brainDnaData.length },
    { id: 'study_tasks', label: 'Study Tasks', icon: <Target size={16} />, color: '#3b82f6', count: studyTasks.length },
    { id: 'knowledge', label: 'Knowledge Map', icon: <Zap size={16} />, color: '#10b981', count: knowledgeNodes.length },
    { id: 'homework_ai', label: 'AI Homework Logs', icon: <MessageSquare size={16} />, color: '#f59e0b', count: homeworkChats.length },
  ];

  const filteredStudents = students.filter(s =>
    s.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    s.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: '24px' }}>
        <h2 style={{ fontSize: '28px', margin: 0 }}>
          <span className="gradient-text">Student Analytics</span>
        </h2>
        <p style={{ color: 'var(--text-dim)', fontSize: '14px', marginTop: '4px' }}>
          AI-powered learning insights and progress tracking
        </p>
      </div>

      {/* Tab Navigation */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px', flexWrap: 'wrap' }}>
        {tabs.map(tab => (
          <motion.button
            key={tab.id}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => setActiveTab(tab.id)}
            style={{
              display: 'flex', alignItems: 'center', gap: '8px',
              padding: '10px 18px', borderRadius: '12px',
              background: activeTab === tab.id ? `${tab.color}20` : 'var(--glass-surface)',
              color: activeTab === tab.id ? tab.color : 'var(--text-dim)',
              border: `1px solid ${activeTab === tab.id ? tab.color + '40' : 'var(--glass-border)'}`,
              fontSize: '13px', fontWeight: '600', cursor: 'pointer'
            }}
          >
            {tab.icon} {tab.label}
            <span style={{ padding: '2px 8px', borderRadius: '10px', background: `${tab.color}15`, fontSize: '11px', fontWeight: '700' }}>{tab.count}</span>
          </motion.button>
        ))}
      </div>

      {/* Search */}
      <div style={{ position: 'relative', marginBottom: '20px' }}>
        <Search size={14} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
        <input
          className="glass-input"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          placeholder="Search students..."
          style={{ width: '100%', paddingLeft: '40px' }}
        />
      </div>

      {/* Content based on active tab */}
      {activeTab === 'brain_dna' && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px', marginBottom: '20px' }}>
            {[
              { label: 'Profiles Generated', value: brainDnaData.length, color: '#8b5cf6' },
              { label: 'Visual Learners', value: brainDnaData.filter(b => b.learning_style === 'visual' || b.primaryStyle === 'visual').length, color: '#3b82f6' },
              { label: 'Active Learners', value: brainDnaData.filter(b => b.learning_style === 'kinesthetic' || b.primaryStyle === 'kinesthetic').length, color: '#10b981' },
            ].map((s, i) => (
              <div key={i} className="glass-card" style={{ padding: '16px 20px' }}>
                <div style={{ fontSize: '24px', fontWeight: '800', color: s.color }}>{s.value}</div>
                <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{s.label}</div>
              </div>
            ))}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '14px' }}>
            {brainDnaData.map((dna, idx) => {
              const student = studentMap[dna.student_id] || studentMap[dna.studentId] || {};
              if (searchTerm && !student.name?.toLowerCase().includes(searchTerm.toLowerCase())) return null;
              return (
                <motion.div key={dna.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: idx * 0.04 }} className="glass-card" style={{ padding: '20px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '14px' }}>
                    <div style={{ width: '38px', height: '38px', borderRadius: '50%', background: '#8b5cf620', color: '#8b5cf6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800', fontSize: '14px' }}>
                      {(student.name || 'S').charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <h4 style={{ margin: 0, fontSize: '14px', fontWeight: '700' }}>{student.name || 'Student'}</h4>
                      <p style={{ margin: 0, fontSize: '11px', color: 'var(--text-dim)' }}>{dna.learning_style || dna.primaryStyle || 'Analyzing...'}</p>
                    </div>
                  </div>
                  {(dna.strengths || dna.strong_subjects) && (
                    <div style={{ marginBottom: '10px' }}>
                      <p style={{ fontSize: '10px', fontWeight: '700', color: '#10b981', textTransform: 'uppercase', marginBottom: '4px' }}>Strengths</p>
                      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                        {(dna.strengths || dna.strong_subjects || []).map((s, i) => (
                          <span key={i} style={{ padding: '2px 8px', borderRadius: '6px', background: '#10b98115', color: '#10b981', fontSize: '11px', fontWeight: '600' }}>{s}</span>
                        ))}
                      </div>
                    </div>
                  )}
                  {(dna.weaknesses || dna.weak_subjects) && (
                    <div>
                      <p style={{ fontSize: '10px', fontWeight: '700', color: '#f59e0b', textTransform: 'uppercase', marginBottom: '4px' }}>Needs Improvement</p>
                      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                        {(dna.weaknesses || dna.weak_subjects || []).map((w, i) => (
                          <span key={i} style={{ padding: '2px 8px', borderRadius: '6px', background: '#f59e0b15', color: '#f59e0b', fontSize: '11px', fontWeight: '600' }}>{w}</span>
                        ))}
                      </div>
                    </div>
                  )}
                </motion.div>
              );
            })}
          </div>
        </div>
      )}

      {activeTab === 'study_tasks' && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px', marginBottom: '20px' }}>
            {[
              { label: 'Total Tasks', value: studyTasks.length, color: '#3b82f6' },
              { label: 'Completed', value: studyTasks.filter(t => t.status === 'completed' || t.completed).length, color: '#10b981' },
              { label: 'Pending', value: studyTasks.filter(t => t.status === 'pending' || !t.completed).length, color: '#f59e0b' },
            ].map((s, i) => (
              <div key={i} className="glass-card" style={{ padding: '16px 20px' }}>
                <div style={{ fontSize: '24px', fontWeight: '800', color: s.color }}>{s.value}</div>
                <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{s.label}</div>
              </div>
            ))}
          </div>

          <div className="glass-card" style={{ overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--glass-border)' }}>
                  <th style={{ textAlign: 'left', padding: '14px 20px' }}>Student</th>
                  <th style={{ textAlign: 'left', padding: '14px' }}>Task</th>
                  <th style={{ textAlign: 'center', padding: '14px' }}>Subject</th>
                  <th style={{ textAlign: 'center', padding: '14px' }}>Status</th>
                  <th style={{ textAlign: 'right', padding: '14px 20px' }}>Due</th>
                </tr>
              </thead>
              <tbody>
                {studyTasks.slice(0, 50).map(task => {
                  const student = studentMap[task.student_id] || studentMap[task.studentId] || {};
                  if (searchTerm && !student.name?.toLowerCase().includes(searchTerm.toLowerCase())) return null;
                  const isComplete = task.status === 'completed' || task.completed;
                  return (
                    <tr key={task.id} style={{ borderBottom: '1px solid var(--glass-border)' }}>
                      <td style={{ padding: '12px 20px', fontWeight: '600', fontSize: '14px' }}>{student.name || 'Student'}</td>
                      <td style={{ padding: '12px', fontSize: '13px' }}>{task.title || task.task || 'Untitled'}</td>
                      <td style={{ padding: '12px', textAlign: 'center', fontSize: '12px' }}>{task.subject || '-'}</td>
                      <td style={{ padding: '12px', textAlign: 'center' }}>
                        <span style={{
                          padding: '3px 10px', borderRadius: '6px', fontSize: '11px', fontWeight: '700',
                          background: isComplete ? '#10b98115' : '#f59e0b15',
                          color: isComplete ? '#10b981' : '#f59e0b'
                        }}>
                          {isComplete ? '✓ Done' : '⏳ Pending'}
                        </span>
                      </td>
                      <td style={{ padding: '12px 20px', textAlign: 'right', fontSize: '12px', color: 'var(--text-dim)' }}>
                        {task.dueDate?.toDate?.()?.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }) || task.due_date || '-'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {activeTab === 'knowledge' && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px', marginBottom: '20px' }}>
            {[
              { label: 'Total Nodes', value: knowledgeNodes.length, color: '#10b981' },
              { label: 'Mastered', value: knowledgeNodes.filter(n => (n.mastery || n.progress || 0) >= 80).length, color: '#3b82f6' },
              { label: 'In Progress', value: knowledgeNodes.filter(n => (n.mastery || n.progress || 0) < 80).length, color: '#f59e0b' },
            ].map((s, i) => (
              <div key={i} className="glass-card" style={{ padding: '16px 20px' }}>
                <div style={{ fontSize: '24px', fontWeight: '800', color: s.color }}>{s.value}</div>
                <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{s.label}</div>
              </div>
            ))}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '12px' }}>
            {knowledgeNodes.slice(0, 30).map((node, idx) => {
              const student = studentMap[node.student_id] || studentMap[node.studentId] || {};
              if (searchTerm && !student.name?.toLowerCase().includes(searchTerm.toLowerCase()) && !node.topic?.toLowerCase().includes(searchTerm.toLowerCase())) return null;
              const progress = node.mastery || node.progress || 0;
              return (
                <motion.div key={node.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: idx * 0.03 }} className="glass-card" style={{ padding: '16px 20px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                    <h4 style={{ margin: 0, fontSize: '14px', fontWeight: '700' }}>{node.topic || node.title || 'Topic'}</h4>
                    <span style={{ fontSize: '13px', fontWeight: '800', color: progress >= 80 ? '#10b981' : progress >= 50 ? '#f59e0b' : '#ef4444' }}>{progress}%</span>
                  </div>
                  <p style={{ fontSize: '12px', color: 'var(--text-dim)', margin: '0 0 8px' }}>{student.name || 'Student'} • {node.subject || 'General'}</p>
                  <div style={{ height: '6px', borderRadius: '3px', background: 'var(--glass-surface)', overflow: 'hidden' }}>
                    <div style={{ height: '100%', width: `${progress}%`, borderRadius: '3px', background: progress >= 80 ? '#10b981' : progress >= 50 ? '#f59e0b' : '#ef4444', transition: 'width 0.5s ease' }} />
                  </div>
                </motion.div>
              );
            })}
          </div>
        </div>
      )}

      {activeTab === 'homework_ai' && (
        <div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px', marginBottom: '20px' }}>
            {[
              { label: 'AI Conversations', value: homeworkChats.length, color: '#f59e0b' },
              { label: 'AI Usage Sessions', value: homeworkUsage.length, color: '#8b5cf6' },
              { label: 'Active Students', value: new Set([...homeworkChats.map(c => c.student_id || c.studentId), ...homeworkUsage.map(u => u.student_id || u.studentId)]).size, color: '#3b82f6' },
            ].map((s, i) => (
              <div key={i} className="glass-card" style={{ padding: '16px 20px' }}>
                <div style={{ fontSize: '24px', fontWeight: '800', color: s.color }}>{s.value}</div>
                <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{s.label}</div>
              </div>
            ))}
          </div>

          <div className="glass-card" style={{ overflow: 'hidden' }}>
            <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--glass-border)' }}>
              <h3 style={{ margin: 0, fontSize: '16px' }}>AI Homework Chat Logs</h3>
            </div>
            {homeworkChats.length === 0 ? (
              <div style={{ padding: '60px', textAlign: 'center', color: 'var(--text-dim)' }}>
                <MessageSquare size={32} style={{ opacity: 0.3, marginBottom: '8px' }} />
                <p style={{ fontWeight: '600' }}>No AI homework chats recorded yet</p>
              </div>
            ) : (
              <div style={{ maxHeight: '500px', overflowY: 'auto' }}>
                {homeworkChats.slice(0, 50).map((chat, idx) => {
                  const student = studentMap[chat.student_id] || studentMap[chat.studentId] || {};
                  if (searchTerm && !student.name?.toLowerCase().includes(searchTerm.toLowerCase())) return null;
                  return (
                    <div key={chat.id} style={{ padding: '14px 20px', borderBottom: '1px solid var(--glass-border)', display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: '#f59e0b15', color: '#f59e0b', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800', fontSize: '13px', flexShrink: 0 }}>
                        {(student.name || 'S').charAt(0).toUpperCase()}
                      </div>
                      <div style={{ flex: 1 }}>
                        <p style={{ margin: 0, fontSize: '14px', fontWeight: '600' }}>{student.name || 'Student'}</p>
                        <p style={{ margin: '2px 0 0', fontSize: '12px', color: 'var(--text-dim)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '400px' }}>
                          {chat.question || chat.message || chat.topic || 'Homework assistance'}
                        </p>
                      </div>
                      <span style={{ fontSize: '11px', color: 'var(--text-dim)', flexShrink: 0 }}>
                        {chat.timestamp?.toDate?.()?.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }) || 'Recent'}
                      </span>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
