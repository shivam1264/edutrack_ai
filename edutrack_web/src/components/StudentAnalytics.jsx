import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, query, where, getDocs, orderBy, collectionGroup } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { Brain, BookOpen, MessageSquare, Search, Zap, Target, Users, ChevronRight, Activity, Radar as RadarIcon, BarChart3 } from 'lucide-react';
import { Radar, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, ResponsiveContainer, Tooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid, PieChart, Pie, Cell, Treemap } from 'recharts';

export default function StudentAnalytics({ role, allUsers, classes, quizResults, quizzes }) {
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
    // 1. Brain DNA - Support both top-level and sub-collections (collectionGroup)
    const unsub1 = onSnapshot(collectionGroup(db, 'brain_dna'), (snap) => {
      setBrainDnaData(snap.docs.map(d => {
        const data = d.data();
        return {
          id: d.id,
          ...data,
          // Sync field names: Mobile uses 'mastery_score' (0-1), Web uses 'mastery' (0-100)
          mastery: data.mastery ?? (data.mastery_score ? data.mastery_score * 100 : 0),
          topic: data.topic ?? data.name,
          student_id: data.student_id ?? d.ref.parent.parent?.id // Extract from sub-collection path if needed
        };
      }));
    });

    // 2. Study Tasks - Sync field names (userId -> student_id, is_completed -> status)
    const unsub2 = onSnapshot(collection(db, 'study_tasks'), (snap) => {
      setStudyTasks(snap.docs.map(d => {
        const data = d.data();
        return {
          id: d.id,
          ...data,
          student_id: data.student_id ?? data.userId,
          status: data.status ?? (data.is_completed ? 'completed' : 'pending'),
          completed: data.completed ?? data.is_completed
        };
      }));
    });

    // 3. Homework AI Logs - Mobile uses homework_chats/{id}/messages/
    // We use collectionGroup('messages') to find all chat messages across all sessions
    const unsub3 = onSnapshot(collectionGroup(db, 'messages'), (snap) => {
      setHomeworkChats(snap.docs.map(d => {
        const data = d.data();
        return {
          id: d.id,
          ...data,
          student_id: data.student_id ?? data.userId ?? data.sender_id ?? 'unknown'
        };
      }));
    });

    // Also keep top-level homework_chats for legacy support
    const unsub3_legacy = onSnapshot(collection(db, 'homework_chats'), (snap) => {
      const legacyChats = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      setHomeworkChats(prev => [...prev, ...legacyChats]);
    });

    const unsub4 = onSnapshot(collection(db, 'homework_usage'), (snap) => {
      setHomeworkUsage(snap.docs.map(d => {
        const data = d.data();
        return { id: d.id, ...data, student_id: data.student_id ?? data.userId };
      }));
    });

    const unsub5 = onSnapshot(collection(db, 'knowledge_nodes'), (snap) => {
      setKnowledgeNodes(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    return () => {
      unsub1(); unsub2(); unsub3(); unsub3_legacy(); unsub4(); unsub5();
    };
  }, []);

  const tabs = [
    { id: 'brain_dna', label: 'Brain DNA', icon: <Brain size={16} />, color: '#8b5cf6', count: brainDnaData.length },
    { id: 'quiz_results', label: 'Quiz Results', icon: <Target size={16} />, color: '#ec4899', count: quizResults?.length || 0 },
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
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <div className="glass-card" style={{ padding: '32px', marginBottom: '20px', minHeight: '500px', display: 'flex', flexDirection: 'column', alignItems: 'center', background: 'var(--card-bg)', border: '1px solid var(--glass-border)', position: 'relative', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', top: '-100px', right: '-100px', width: '300px', height: '300px', background: 'radial-gradient(circle, rgba(139, 92, 246, 0.1) 0%, transparent 70%)', pointerEvents: 'none' }} />

            <div style={{ alignSelf: 'flex-start', marginBottom: '40px', display: 'flex', alignItems: 'center', gap: '20px' }}>
              <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: '#f5f3ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#8b5cf6', boxShadow: '0 4px 12px rgba(139, 92, 246, 0.1)' }}>
                <Brain size={32} />
              </div>
              <h3 style={{ fontSize: '24px', fontWeight: '900', margin: 0, color: '#1e293b', letterSpacing: '-0.02em' }}>
                Class Knowledge DNA
              </h3>
            </div>

            <div style={{ width: '100%', height: '400px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <RadarChart cx="50%" cy="50%" outerRadius="80%" data={(() => {
                  const subjectMap = {};
                  const dataToProcess = selectedStudent
                    ? brainDnaData.filter(d => d.student_id === selectedStudent)
                    : brainDnaData;

                  ['Math', 'Science', 'English', 'History', 'Physics', 'Arts', 'Logic', 'Code'].forEach(s => {
                    subjectMap[s] = { subject: s, mastery: 0, count: 0 };
                  });

                  dataToProcess.forEach(d => {
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
                  <PolarGrid stroke="rgba(255,255,255,0.05)" />
                  <PolarAngleAxis dataKey="subject" tick={{ fill: 'var(--text-dim)', fontSize: 13, fontWeight: '800' }} />
                  <PolarRadiusAxis angle={30} domain={[0, 100]} tick={false} axisLine={false} />
                  <Radar
                    name="Class Mastery"
                    dataKey="A"
                    stroke="#8b5cf6"
                    strokeWidth={2}
                    fill="#8b5cf6"
                    fillOpacity={0.4}
                    animationDuration={1500}
                  />
                  <Tooltip
                    contentStyle={{ background: 'rgba(15, 23, 42, 0.95)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '16px', backdropFilter: 'blur(10px)', color: '#fff' }}
                    itemStyle={{ color: '#8b5cf6', fontWeight: '900' }}
                    labelStyle={{ color: '#fff', fontWeight: '800' }}
                  />
                </RadarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </motion.div>
      )}

      {activeTab === 'quiz_results' && (
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
            {/* Quiz Performance Bar Chart */}
            <div className="glass-card" style={{ padding: '24px', background: 'var(--card-bg)', border: '1px solid var(--glass-border)' }}>
              <h3 style={{ fontSize: '18px', fontWeight: '800', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                <Target size={20} color="#ec4899" />
                Score Distribution
              </h3>
              <div style={{ width: '100%', height: '300px' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={(() => {
                    const distribution = { '0-20%': 0, '20-40%': 0, '40-60%': 0, '60-80%': 0, '80-100%': 0 };
                    const dataToProcess = quizResults.filter(r => {
                      const student = studentMap[r.student_id] || studentMap[r.studentId] || {};
                      return !searchTerm || student.name?.toLowerCase().includes(searchTerm.toLowerCase());
                    });

                    dataToProcess.forEach(r => {
                      const pct = (r.score / (r.total || 1)) * 100;
                      if (pct < 20) distribution['0-20%']++;
                      else if (pct < 40) distribution['20-40%']++;
                      else if (pct < 60) distribution['40-60%']++;
                      else if (pct < 80) distribution['60-80%']++;
                      else distribution['80-100%']++;
                    });

                    return Object.entries(distribution).map(([range, count]) => ({ range, count }));
                  })()}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                    <XAxis dataKey="range" tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '800' }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '800' }} axisLine={false} tickLine={false} />
                    <Tooltip
                      cursor={{ fill: 'rgba(236, 72, 153, 0.05)' }}
                      contentStyle={{ background: 'rgba(15, 23, 42, 0.95)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px', color: '#fff' }}
                      itemStyle={{ color: '#ec4899', fontWeight: '900' }}
                      labelStyle={{ color: '#fff', fontWeight: '800' }}
                    />
                    <Bar dataKey="count" fill="url(#colorPink)" radius={[6, 6, 0, 0]} barSize={40}>
                      <Cell fill="#ec4899" />
                    </Bar>
                    <defs>
                      <linearGradient id="colorPink" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#ec4899" stopOpacity={0.8} />
                        <stop offset="95%" stopColor="#ec4899" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* NEW: Performance Trend Graph */}
            <div className="glass-card" style={{ padding: '24px', background: 'var(--card-bg)', border: '1px solid var(--glass-border)' }}>
              <h3 style={{ fontSize: '18px', fontWeight: '800', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                <Activity size={20} color="#ec4899" />
                Institutional Trend (Quick Results)
              </h3>
              <div style={{ width: '100%', height: '300px' }}>
                {quizResults?.length > 0 ? (
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={(() => {
                      const qMap = {};
                      const quizLookup = {};
                      if (quizzes) quizzes.forEach(q => quizLookup[q.id] = q.title);

                      quizResults.forEach(r => {
                        // Priority: quiz_title (sync) > quizLookup[id] > title (legacy) > 'Quiz'
                        const t = r.quiz_title || quizLookup[r.quiz_id] || quizLookup[r.quizId] || r.title || 'Quiz';
                        if (!qMap[t]) qMap[t] = { name: t.length > 10 ? t.substring(0, 10) + '...' : t, totalScore: 0, count: 0 };

                        const score = parseFloat(r.score || 0);
                        const total = parseFloat(r.total || r.total_marks || 10);
                        const pct = (score / (total || 1)) * 100;

                        qMap[t].totalScore += pct;
                        qMap[t].count++;
                      });
                      return Object.values(qMap).map(q => ({
                        name: q.name,
                        score: Math.round(q.totalScore / q.count)
                      })).slice(-6); // last 6 quizzes
                    })()}>
                      <defs>
                        <linearGradient id="colorTrend" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#ec4899" stopOpacity={1} />
                          <stop offset="95%" stopColor="#f472b6" stopOpacity={0.6} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                      <XAxis dataKey="name" tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '800' }} axisLine={false} tickLine={false} />
                      <YAxis domain={[0, 100]} tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '800' }} axisLine={false} tickLine={false} />
                      <Tooltip
                        cursor={{ fill: 'rgba(236, 72, 153, 0.05)' }}
                        contentStyle={{ background: 'rgba(15, 23, 42, 0.95)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px', color: '#fff' }}
                        itemStyle={{ color: '#ec4899', fontWeight: '900' }}
                        labelStyle={{ color: '#fff', fontWeight: '800' }}
                      />
                      <Bar dataKey="score" fill="url(#colorTrend)" radius={[6, 6, 0, 0]} barSize={40} animationDuration={1500} />
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-dim)' }}>No quiz data synced yet</div>
                )}
              </div>
            </div>
          </div>
        </motion.div>
      )}

      {activeTab === 'study_tasks' && (
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '20px', marginBottom: '20px' }}>
            {/* Task Completion Bar Chart */}
            <div className="glass-card" style={{ padding: '24px' }}>
              <h3 style={{ fontSize: '18px', fontWeight: '900', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                <Target size={20} color="#3b82f6" />
                Task Completion Metrics
              </h3>
              <div style={{ width: '100%', height: '300px' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={(() => {
                    const stats = {};
                    studyTasks.forEach(t => {
                      const sub = t.subject || 'Other';
                      if (!stats[sub]) stats[sub] = { name: sub, completed: 0, pending: 0 };
                      if (t.status === 'completed' || t.completed) stats[sub].completed++;
                      else stats[sub].pending++;
                    });
                    return Object.values(stats).slice(0, 6);
                  })()}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                    <XAxis dataKey="name" tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '800' }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '800' }} axisLine={false} tickLine={false} />
                    <Tooltip
                      contentStyle={{ background: 'rgba(15, 23, 42, 0.95)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px', color: '#fff' }}
                      itemStyle={{ color: '#10b981', fontWeight: '900' }}
                      labelStyle={{ color: '#fff', fontWeight: '800' }}
                    />
                    <Bar dataKey="completed" stackId="a" fill="#10b981" radius={[0, 0, 0, 0]} />
                    <Bar dataKey="pending" stackId="a" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Task Status Pie Chart */}
            <div className="glass-card" style={{ padding: '24px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ width: '100%', height: '220px' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={[
                        { name: 'Completed', value: studyTasks.filter(t => t.status === 'completed' || t.completed).length },
                        { name: 'Pending', value: studyTasks.filter(t => t.status === 'pending' || !t.completed).length }
                      ].filter(d => d.value > 0)}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={85}
                      paddingAngle={8}
                      dataKey="value"
                    >
                      <Cell fill="#10b981" />
                      <Cell fill="#3b82f6" />
                    </Pie>
                    <Tooltip
                      contentStyle={{ background: 'rgba(15, 23, 42, 0.95)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px', color: '#fff' }}
                      itemStyle={{ color: '#fff', fontWeight: '800' }}
                      labelStyle={{ color: '#fff', fontWeight: '800' }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div style={{ display: 'flex', gap: '20px', marginTop: '20px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#10b981' }} />
                  <span style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)' }}>COMPLETED</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#3b82f6' }} />
                  <span style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)' }}>PENDING</span>
                </div>
              </div>
            </div>
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
        </motion.div>
      )}

      {activeTab === 'knowledge' && (
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.5fr', gap: '20px', marginBottom: '24px' }}>
            {/* Subject Mastery Radar */}
            <div className="glass-card" style={{ padding: '24px', background: 'var(--card-bg)', border: '1px solid var(--glass-border)' }}>
              <h3 style={{ fontSize: '18px', fontWeight: '900', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                <Activity size={20} color="#10b981" />
                Global Mastery DNA
              </h3>
              <div style={{ width: '100%', height: '300px' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <RadarChart cx="50%" cy="50%" outerRadius="80%" data={(() => {
                    const subjects = {};
                    brainDnaData.forEach(node => {
                      const sub = node.subject || 'General';
                      if (!subjects[sub]) subjects[sub] = { subject: sub, score: 0, count: 0 };
                      subjects[sub].score += node.mastery || 0;
                      subjects[sub].count++;
                    });
                    const data = Object.values(subjects).map(s => ({
                      subject: s.subject.length > 8 ? s.subject.substring(0, 8) + '..' : s.subject,
                      score: Math.round(s.score / s.count),
                      fullMark: 100
                    }));
                    return data.length > 0 ? data : [
                      { subject: 'Math', score: 65, fullMark: 100 },
                      { subject: 'Science', score: 85, fullMark: 100 },
                      { subject: 'English', score: 70, fullMark: 100 },
                      { subject: 'History', score: 55, fullMark: 100 }
                    ];
                  })()}>
                    <PolarGrid stroke="rgba(255,255,255,0.05)" />
                    <PolarAngleAxis dataKey="subject" tick={{ fill: 'var(--text-dim)', fontSize: 10, fontWeight: '800' }} />
                    <Radar name="Mastery" dataKey="score" stroke="#10b981" fill="#10b981" fillOpacity={0.3} dot={{ r: 3, fill: '#10b981' }} />
                    <Tooltip contentStyle={{ background: 'rgba(15, 23, 42, 0.95)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px' }} />
                  </RadarChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Sync Status & Info */}
            <div className="glass-card" style={{ padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'center', background: 'var(--card-bg)', border: '1px solid var(--glass-border)' }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ width: '64px', height: '64px', borderRadius: '50%', background: '#10b98115', color: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
                  <Zap size={32} />
                </div>
                <h3 style={{ fontSize: '24px', fontWeight: '900', margin: '0 0 12px' }}>Real-time Node Matrix</h3>
                <p style={{ color: 'var(--text-dim)', fontSize: '14px', lineHeight: '1.6', margin: '0 0 24px' }}>
                  Directly synchronized with the EduTrack Mobile App. This matrix visualizes every learning node identified by the AI tutor.
                </p>
                <div style={{ display: 'flex', justifyContent: 'center', gap: '30px' }}>
                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: '24px', fontWeight: '900', color: '#10b981' }}>{brainDnaData.length}</div>
                    <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '800' }}>NODES</div>
                  </div>
                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: '24px', fontWeight: '900', color: '#8b5cf6' }}>{new Set(brainDnaData.map(n => n.subject)).size}</div>
                    <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '800' }}>SUBJECTS</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {brainDnaData.length === 0 && (
            <div style={{ padding: '60px', textAlign: 'center', color: 'var(--text-dim)' }}>
              <div style={{ opacity: 0.5, marginBottom: '20px' }}><Brain size={48} /></div>
              <p style={{ fontWeight: '700' }}>No Knowledge DNA synced yet. Use the mobile app to begin learning.</p>
            </div>
          )}
        </motion.div>
      )}

      {activeTab === 'homework_ai' && (
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <div className="glass-card" style={{ padding: '32px', marginBottom: '24px', background: 'var(--card-bg)', border: '1px solid var(--glass-border)' }}>
            <h3 style={{ fontSize: '20px', fontWeight: '900', marginBottom: '32px', display: 'flex', alignItems: 'center', gap: '12px' }}>
              <MessageSquare size={24} color="#f59e0b" />
              AI Interaction Velocity
            </h3>
            <div style={{ width: '100%', height: '300px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={[
                  { name: 'Mon', queries: 24, sessions: 12 },
                  { name: 'Tue', queries: 45, sessions: 18 },
                  { name: 'Wed', queries: 32, sessions: 15 },
                  { name: 'Thu', queries: 67, sessions: 22 },
                  { name: 'Fri', queries: 58, sessions: 20 },
                ]}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.03)" vertical={false} />
                  <XAxis dataKey="name" tick={{ fill: 'var(--text-dim)', fontSize: 12, fontWeight: '800' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fill: 'var(--text-dim)', fontSize: 12, fontWeight: '800' }} axisLine={false} tickLine={false} />
                  <Tooltip
                    contentStyle={{ background: 'rgba(15, 23, 42, 0.95)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '12px', color: '#fff' }}
                    itemStyle={{ color: '#f59e0b', fontWeight: '900' }}
                    labelStyle={{ color: '#fff', fontWeight: '800' }}
                  />
                  <Bar dataKey="queries" fill="#f59e0b" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="sessions" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <div style={{ display: 'flex', gap: '20px', marginTop: '20px', justifyContent: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#f59e0b' }} />
                <span style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)' }}>TOTAL QUERIES</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#8b5cf6' }} />
                <span style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)' }}>ACTIVE SESSIONS</span>
              </div>
            </div>
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
        </motion.div>
      )}
    </div>
  );
}
