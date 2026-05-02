import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, getDocs, query, where } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { BarChart3, Users, GraduationCap, TrendingUp, Award, BookOpen, Calendar, Target } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line, CartesianGrid, AreaChart, Area } from 'recharts';

export default function SchoolAnalytics({ students, allUsers, classes, attendanceArchive, assignments, quizzes }) {
  const teachers = (allUsers || []).filter(u => u.role === 'teacher');
  const parents = (allUsers || []).filter(u => u.role === 'parent');

  // Enrollment by class
  const enrollmentData = (classes || []).map((c, index) => {
    const className = c.standard ? (c.section ? `${c.standard} - ${c.section}` : c.standard) : (c.name || c.className || c.grade || c.title || c.subject || `Class ${index + 1}`);
    return {
      name: className,
      students: (students || []).filter(s => s.classId === c.id || s.class_id === c.id).length
    };
  }).filter(d => d.students > 0);

  // Attendance trend (Aggregated by date)
  const groupedAttendance = (attendanceArchive || []).reduce((acc, curr) => {
    const date = curr.date_string || (curr.date?.toDate ? curr.date.toDate().toLocaleDateString() : 'Unknown');
    if (!acc[date]) acc[date] = { name: date, present: 0, total: 0 };
    acc[date].total++;
    if (curr.status === 'present') acc[date].present++;
    return acc;
  }, {});

  const attendanceTrend = Object.values(groupedAttendance).map(d => ({
    name: d.name,
    rate: Math.round((d.present / d.total) * 100)
  })).slice(-7);


  // Performance distribution
  const perfDist = [
    { name: 'Excellent (90%+)', value: (students || []).filter(s => (s.mastery || 0) >= 90).length, color: '#10b981' },
    { name: 'Good (75-89%)', value: (students || []).filter(s => (s.mastery || 0) >= 75 && (s.mastery || 0) < 90).length, color: '#3b82f6' },
    { name: 'Average (60-74%)', value: (students || []).filter(s => (s.mastery || 0) >= 60 && (s.mastery || 0) < 75).length, color: '#f59e0b' },
    { name: 'Needs Help (<60%)', value: (students || []).filter(s => (s.mastery || 0) < 60).length, color: '#ef4444' },
  ].filter(d => d.value > 0);

  // Teacher stats
  const teacherStats = (teachers || []).map(t => {
    const teacherClasses = (classes || []).filter(c => c.teacherId === t.id || c.teacher_id === t.id);
    const teacherClassIds = teacherClasses.map(c => c.id);
    const teacherStudents = (students || []).filter(s => teacherClassIds.includes(s.classId) || teacherClassIds.includes(s.class_id));

    return {
      name: t.name || 'Teacher',
      classes: teacherClasses.length,
      students: teacherStudents.length,
      email: t.email
    };
  });

  const stats = [
    { label: 'Total Students', value: (students || []).length, icon: <Users size={20} />, color: '#3b82f6' },
    { label: 'Total Teachers', value: (teachers || []).length, icon: <GraduationCap size={20} />, color: '#8b5cf6' },
    { label: 'Total Parents', value: (parents || []).length, icon: <Users size={20} />, color: '#10b981' },
    { label: 'Total Classes', value: (classes || []).length, icon: <BookOpen size={20} />, color: '#f59e0b' },
    { label: 'Assignments', value: (assignments || []).length, icon: <Target size={20} />, color: '#ec4899' },
    { label: 'Quizzes', value: (quizzes || []).length, icon: <Award size={20} />, color: '#06b6d4' },
  ];

  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: '28px' }}>
        <h2 style={{ fontSize: '28px', margin: 0 }}>
          <span className="gradient-text">School Analytics</span>
        </h2>
        <p style={{ color: 'var(--text-dim)', fontSize: '14px', marginTop: '4px' }}>
          Comprehensive school performance overview
        </p>
      </div>

      {/* Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: '12px', marginBottom: '24px' }}>
        {stats.map((s, i) => (
          <motion.div key={i} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className="glass-card stat-item-compact" style={{ background: 'var(--glass-surface)', border: '1px solid var(--glass-border)' }}>
            <div style={{ padding: '8px', borderRadius: '8px', background: `${s.color}15`, color: s.color, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              {React.cloneElement(s.icon, { size: 16 })}
            </div>
            <div>
              <div style={{ fontSize: '18px', fontWeight: '800', letterSpacing: '-0.5px', color: 'var(--text-main)' }}>{s.value}</div>
              <div style={{ fontSize: '9px', color: 'var(--text-dim)', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{s.label}</div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Charts Row */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '24px' }}>
        {/* Enrollment by Class */}
        <div className="glass-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '16px', marginBottom: '16px' }}>Enrollment by Class</h3>
          {enrollmentData.length > 0 ? (
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={enrollmentData}>
                <defs>
                  <linearGradient id="colorEnroll" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#3b82f6" stopOpacity={1} />
                    <stop offset="100%" stopColor="#60a5fa" stopOpacity={0.6} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="name" tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '700' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '700' }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '12px', color: 'var(--text-main)' }}
                  itemStyle={{ color: '#3b82f6', fontWeight: '900' }}
                  labelStyle={{ color: 'var(--text-main)', fontWeight: '800' }}
                  cursor={{ fill: 'rgba(255,255,255,0.05)' }}
                />
                <Bar dataKey="students" fill="url(#colorEnroll)" radius={[8, 8, 0, 0]} barSize={45} animationDuration={1500} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div style={{ height: '250px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-dim)' }}>No enrollment data</div>
          )}
        </div>

        {/* Performance Distribution */}
        <div className="glass-card" style={{ padding: '20px' }}>
          <h3 style={{ fontSize: '16px', marginBottom: '16px' }}>Performance Distribution</h3>
          {perfDist.length > 0 ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
              <ResponsiveContainer width="50%" height={220}>
                <PieChart>
                  <Pie data={perfDist} dataKey="value" cx="50%" cy="50%" outerRadius={80} innerRadius={40}>
                    {perfDist.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                  </Pie>
                  <Tooltip contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '10px', fontSize: '12px' }} />
                </PieChart>
              </ResponsiveContainer>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {perfDist.map((d, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <div style={{ width: '10px', height: '10px', borderRadius: '3px', background: d.color }} />
                    <span style={{ fontSize: '12px', color: 'var(--text-dim)' }}>{d.name}: <strong style={{ color: 'var(--text-main)' }}>{d.value}</strong></span>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div style={{ height: '220px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-dim)' }}>No performance data</div>
          )}
        </div>
      </div>

      {/* Real-time Attendance Velocity (Synced) */}
      <div className="glass-card" style={{ padding: '20px', marginBottom: '24px' }}>
        <h3 style={{ fontSize: '16px', marginBottom: '16px' }}>Attendance Velocity (Live Sync)</h3>
        {attendanceTrend.length > 0 ? (
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={attendanceTrend}>
              <defs>
                <linearGradient id="colorAttTrend" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.6} />
                  <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
              <XAxis dataKey="name" tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '700' }} axisLine={false} tickLine={false} />
              <YAxis domain={[0, 100]} tick={{ fill: 'var(--text-dim)', fontSize: 11, fontWeight: '700' }} axisLine={false} tickLine={false} width={30} />
              <Tooltip
                contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '12px', color: 'var(--text-main)', backdropFilter: 'blur(10px)' }}
                itemStyle={{ color: '#8b5cf6', fontWeight: '900' }}
                labelStyle={{ color: 'var(--text-main)', fontWeight: '800' }}
              />
              <Area type="monotone" dataKey="rate" stroke="#8b5cf6" fillOpacity={1} fill="url(#colorAttTrend)" strokeWidth={3} animationDuration={1500} />
            </AreaChart>
          </ResponsiveContainer>
        ) : (
          <div style={{ height: '250px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-dim)' }}>
            No synced attendance data found in the app database.
          </div>
        )}
      </div>

      {/* Teacher Performance Table */}
      <div className="glass-card" style={{ overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--glass-border)' }}>
          <h3 style={{ margin: 0, fontSize: '16px' }}>Teacher Performance Overview</h3>
        </div>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--glass-border)' }}>
              <th style={{ textAlign: 'left', padding: '14px 20px' }}>Teacher</th>
              <th style={{ textAlign: 'center', padding: '14px' }}>Classes</th>
              <th style={{ textAlign: 'center', padding: '14px' }}>Students</th>
              <th style={{ textAlign: 'center', padding: '14px' }}>Email</th>
            </tr>
          </thead>
          <tbody>
            {teacherStats.map((t, idx) => {
              return (
                <tr key={idx} style={{ borderBottom: '1px solid var(--glass-border)' }}>
                  <td style={{ padding: '12px 20px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <div style={{ width: '34px', height: '34px', borderRadius: '50%', background: '#8b5cf620', color: '#8b5cf6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800', fontSize: '13px' }}>
                        {(t.name || 'T').charAt(0).toUpperCase()}
                      </div>
                      <span style={{ fontWeight: '600' }}>{t.name || 'Teacher'}</span>
                    </div>
                  </td>
                  <td style={{ textAlign: 'center', fontWeight: '700' }}>{t.classes}</td>
                  <td style={{ textAlign: 'center', fontWeight: '700' }}>{t.students}</td>
                  <td style={{ textAlign: 'center', fontSize: '13px', color: 'var(--text-dim)' }}>{t.email || '-'}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
