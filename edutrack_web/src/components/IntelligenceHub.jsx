import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  Brain,
  Zap,
  Users,
  GraduationCap,
  ShieldAlert,
  ShieldCheck,
  History,
  TrendingUp,
  AlertTriangle
} from 'lucide-react';
import {
  PieChart, Pie, Cell,
  AreaChart, Area,
  XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid
} from 'recharts';

const IntelligenceHub = ({
  predictions,
  allUsers,
  stats,
  attendanceArchive,
  brainDnaData,
  isAnalyzing,
  setIsAnalyzing,
  aiInsights,
  setAiInsights,
  showIntelligenceResults,
  setShowIntelligenceResults,
  analyzePerformance
}) => {
  const teachers = allUsers.filter(u => u.role === 'teacher').length;

  let low = 0, med = 0, high = 0;
  predictions.forEach(p => {
    if (p.risk_level === 'low') low++;
    else if (p.risk_level === 'medium') med++;
    else if (p.risk_level === 'high') high++;
  });

  const totalPredictions = low + med + high;
  const riskData = totalPredictions > 0 ? [
    { name: 'Safe', value: low, color: '#10b981' },
    { name: 'Watch', value: med, color: '#f59e0b' },
    { name: 'Alert', value: high, color: '#ef4444' }
  ] : [];

  const attendanceStats = {
    'Mon': { present: 0, total: 0, color: '#10b981' },
    'Tue': { present: 0, total: 0, color: '#f59e0b' },
    'Wed': { present: 0, total: 0, color: '#3b82f6' },
    'Thu': { present: 0, total: 0, color: '#6366f1' },
    'Fri': { present: 0, total: 0, color: '#ec4899' }
  };

  attendanceArchive.forEach(record => {
    if (record.date && typeof record.date.toDate === 'function') {
      const dateObj = record.date.toDate();
      const dayMap = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const day = dayMap[dateObj.getDay()];

      if (attendanceStats[day]) {
        attendanceStats[day].total++;
        if (record.status === 'present') {
          attendanceStats[day].present++;
        }
      }
    }
  });

  const attendanceData = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map(day => {
    const dayStats = attendanceStats[day];
    const percentage = dayStats.total > 0 ? Math.round((dayStats.present / dayStats.total) * 100) : 0;
    return { day, attendance: percentage, color: dayStats.color };
  });

  const runAnalysis = async () => {
    setIsAnalyzing(true);
    setAiInsights(null);
    try {
      const avgAttendance = attendanceArchive.length > 0
        ? Math.round(attendanceArchive.filter(r => r.status === 'present').length / attendanceArchive.length * 100)
        : 75;
      const result = await analyzePerformance({
        task: 'analysis',
        total_students: stats.students,
        total_teachers: teachers,
        total_assignments: stats.assignments,
        attendance_pct: avgAttendance,
        high_risk_count: high,
        medium_risk_count: med,
      });
      setAiInsights(result);
    } catch (e) {
      console.warn('Analysis using standalone data');
    } finally {
      setIsAnalyzing(false);
      setShowIntelligenceResults(true);
    }
  };

  if (!showIntelligenceResults) {
    return (
      <div className="glass-card" style={{ padding: '0', overflow: 'hidden', border: 'none', background: 'var(--bg-gradient-start)' }}>
        <div style={{
          background: 'radial-gradient(circle at center, #1e1b4b 0%, #0f172a 100%)',
          padding: '100px 40px',
          textAlign: 'center',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '70vh',
          color: 'white',
          position: 'relative',
          overflow: 'hidden'
        }}>
          {/* Cyber grid background */}
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, opacity: 0.1, backgroundImage: 'linear-gradient(#3b82f6 1px, transparent 1px), linear-gradient(90deg, #3b82f6 1px, transparent 1px)', backgroundSize: '40px 40px' }}></div>

          <motion.div
            animate={{
              rotate: 360,
              scale: [1, 1.05, 1],
            }}
            transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
            style={{ position: 'absolute', width: '600px', height: '600px', borderRadius: '50%', border: '1px dashed rgba(59, 130, 246, 0.2)', pointerEvents: 'none' }}
          ></motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.5 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 1 }}
          >
            <div style={{ position: 'relative', marginBottom: '40px' }}>
              <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: '120px', height: '120px', background: 'rgba(99, 102, 241, 0.2)', borderRadius: '50%', filter: 'blur(30px)' }}></div>
              <Brain size={100} style={{ color: '#818cf8', filter: 'drop-shadow(0 0 15px rgba(129, 140, 248, 0.6))' }} />
            </div>
          </motion.div>

          <h2 style={{ fontSize: '42px', fontWeight: '900', letterSpacing: '-1px', marginBottom: '16px', background: 'linear-gradient(to bottom, #ffffff, #94a3b8)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>GLOBAL INTELLIGENCE PROTOCOL</h2>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '40px' }}>
            <div style={{ display: 'flex', gap: '4px' }}>
              {[1, 2, 3].map(i => <div key={i} style={{ width: '4px', height: '4px', background: '#3b82f6', borderRadius: '50%', animation: `pulse 1.5s infinite ${i * 0.2}s` }}></div>)}
            </div>
            <span style={{ fontSize: '13px', fontWeight: '800', color: '#60a5fa', textTransform: 'uppercase', letterSpacing: '2px' }}>Neural Sync Initialized</span>
          </div>

          <p style={{ color: 'rgba(255,255,255,0.6)', marginBottom: '48px', maxWidth: '600px', lineHeight: '1.8', fontSize: '15px', fontWeight: '500' }}>
            Aggregating real-time telemetry from all educational nodes. Initialize deep-learning sequence to map institutional success DNA and identify performance variances.
          </p>

          <button
            onClick={runAnalysis}
            disabled={isAnalyzing}
            className="hover-glow"
            style={{
              padding: '20px 48px',
              fontSize: '15px',
              fontWeight: '900',
              background: 'white',
              color: '#0f172a',
              border: 'none',
              cursor: 'pointer',
              borderRadius: '16px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              transition: 'all 0.3s',
              textTransform: 'uppercase',
              letterSpacing: '1px',
              boxShadow: '0 20px 40px rgba(0,0,0,0.3)'
            }}
          >
            {isAnalyzing ? 'Decoding Neural Map...' : 'Establish Connection'}
          </button>
        </div>
      </div>
    );
  }

  return (
    <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      {/* Professional Command Header */}
      <div className="glass-card" style={{ padding: '32px', background: 'var(--card-bg)', border: '1px solid var(--glass-border)', position: 'relative', overflow: 'hidden' }}>
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '2px', background: 'linear-gradient(90deg, transparent, #3b82f6, transparent)' }}></div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
              <div style={{ width: '8px', height: '8px', background: '#3b82f6', borderRadius: '50%', boxShadow: '0 0 10px #3b82f6' }}></div>
              <span style={{ fontSize: '11px', fontWeight: '900', color: '#3b82f6', textTransform: 'uppercase', letterSpacing: '2px' }}>System Live Telemetry</span>
            </div>
            <h1 style={{ margin: 0, fontSize: '32px', fontWeight: '900', color: 'var(--text-main)' }}>Intelligence Protocol</h1>
            <p style={{ margin: '8px 0 0 0', color: 'var(--text-dim)', fontSize: '14px' }}>Real-time institutional performance aggregation & risk mapping.</p>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ padding: '8px 16px', background: 'var(--glass-surface)', borderRadius: '12px', border: '1px solid var(--glass-border)', display: 'flex', alignItems: 'center', gap: '12px' }}>
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontSize: '9px', color: 'var(--text-dim)', fontWeight: '800' }}>AI ENGINE</div>
                <div style={{ fontSize: '12px', color: '#60a5fa', fontWeight: '900' }}>ACTIVE SYNC</div>
              </div>
              <History size={18} color="var(--text-dim)" />
            </div>
          </div>
        </div>
      </div>

      {/* Neural Metrics Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px' }}>
        {[
          { label: 'Academic Nodes', value: stats.students, icon: <Users size={24} />, color: '#3b82f6', trend: '+4% vs last week' },
          { label: 'Faculty Entities', value: teachers, icon: <GraduationCap size={24} />, color: '#8b5cf6', trend: 'Fully Sync' },
          { label: 'Risk Anomalies', value: high, icon: <ShieldAlert size={24} />, color: '#ef4444', trend: `${high} Students Flagged` },
          { label: 'Sync Fidelity', value: '99.8%', icon: <Zap size={24} />, color: '#10b981', trend: 'Sub-ms Latency' },
        ].map((m, i) => (
          <div key={i} className="glass-card stat-item-compact" style={{ border: '1px solid var(--glass-border)', background: 'var(--glass-surface)' }}>
            <div style={{ color: m.color, width: '36px', height: '36px', borderRadius: '10px', background: `${m.color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              {React.cloneElement(m.icon, { size: 18 })}
            </div>
            <div>
              <div style={{ fontSize: '18px', fontWeight: '900', color: 'var(--text-main)' }}>{m.value}</div>
              <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{m.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* AI Visualization Layer */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '32px' }}>
        {/* Left Panel: Charts */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div className="glass-card" style={{ padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '800' }}>Monthly Presence Matrix</h3>
              <button onClick={() => setShowIntelligenceResults(false)} style={{ background: 'transparent', border: 'none', color: '#3b82f6', fontSize: '12px', fontWeight: '800', cursor: 'pointer' }}>RE-SCAN SYSTEM</button>
            </div>
            <div style={{ height: '300px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={attendanceData}>
                  <defs>
                    <linearGradient id="colorAttend" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                  <XAxis dataKey="day" stroke="var(--text-dim)" axisLine={false} tickLine={false} />
                  <YAxis stroke="var(--text-dim)" axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '12px', color: 'var(--text-main)' }} />
                  <Area type="monotone" dataKey="attendance" stroke="#3b82f6" strokeWidth={3} fillOpacity={1} fill="url(#colorAttend)" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* AI INSIGHTS ENGINE */}
          {aiInsights && (
            <div style={{ background: 'linear-gradient(135deg, #1e1b4b, #312e81)', padding: '32px', borderRadius: '24px', border: '1px solid rgba(99, 102, 241, 0.3)', position: 'relative', overflow: 'hidden' }}>
              <div style={{ position: 'absolute', right: '-40px', bottom: '-40px', opacity: 0.1 }}>
                <Brain size={200} color="white" />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
                <Zap size={24} color="#818cf8" />
                <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '900', color: 'white' }}>Neural Narrative Insights</h3>
              </div>
              <p style={{ fontSize: '15px', color: 'rgba(255,255,255,0.8)', lineHeight: '1.8', marginBottom: '24px' }}>
                {aiInsights.summary}
              </p>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                <div style={{ background: 'rgba(255,255,255,0.05)', padding: '20px', borderRadius: '16px' }}>
                  <h4 style={{ fontSize: '11px', fontWeight: '900', color: '#60a5fa', textTransform: 'uppercase', marginBottom: '12px' }}>Strategic Recommendations</h4>
                  <ul style={{ padding: 0, margin: 0, listStyle: 'none' }}>
                    {(aiInsights.recommendations || []).slice(0, 3).map((r, i) => (
                      <li key={i} style={{ fontSize: '13px', color: 'rgba(255,255,255,0.7)', marginBottom: '8px', display: 'flex', gap: '8px' }}>
                        <span style={{ color: '#60a5fa' }}>▶</span> {typeof r === 'object' ? r.title : r}
                      </li>
                    ))}
                  </ul>
                </div>
                <div style={{ background: 'rgba(255,255,255,0.05)', padding: '20px', borderRadius: '16px' }}>
                  <h4 style={{ fontSize: '11px', fontWeight: '900', color: '#4ade80', textTransform: 'uppercase', marginBottom: '12px' }}>Risk Mitigation</h4>
                  <ul style={{ padding: 0, margin: 0, listStyle: 'none' }}>
                    {(aiInsights.insights || []).slice(0, 3).map((ins, i) => (
                      <li key={i} style={{ fontSize: '13px', color: 'rgba(255,255,255,0.7)', marginBottom: '8px', display: 'flex', gap: '8px' }}>
                        <span style={{ color: '#4ade80' }}>✓</span> {typeof ins === 'object' ? ins.title : ins}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Right Panel: Risk Map */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div className="glass-card" style={{ padding: '24px' }}>
            <h3 style={{ margin: '0 0 24px 0', fontSize: '16px', fontWeight: '800' }}>Neural Risk Distribution</h3>
            <div style={{ height: '240px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={riskData} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={60} outerRadius={80} paddingAngle={5}>
                    {riskData.map((entry, index) => <Cell key={`cell-${index}`} fill={entry.color} />)}
                  </Pie>
                  <Tooltip contentStyle={{ background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '12px', color: 'var(--text-main)' }} />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', gap: '16px', marginTop: '16px' }}>
              {riskData.map(d => (
                <div key={d.name} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <div style={{ width: '8px', height: '8px', background: d.color, borderRadius: '50%' }}></div>
                  <span style={{ fontSize: '11px', fontWeight: '700', color: 'var(--text-dim)' }}>{d.name}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="glass-card" style={{ padding: '24px' }}>
            <h3 style={{ margin: '0 0 20px 0', fontSize: '16px', fontWeight: '800' }}>Critical Priority Hubs</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {predictions.filter(p => p.risk_level === 'high').slice(0, 5).map(p => {
                const student = allUsers.find(u => u.id === p.student_id);
                return (
                  <div key={p.student_id} style={{ padding: '12px', background: 'rgba(239, 68, 68, 0.05)', border: '1px solid rgba(239, 68, 68, 0.1)', borderRadius: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ fontWeight: '700', fontSize: '13px' }}>{student?.name || 'Unknown Node'}</div>
                    <div style={{ fontSize: '11px', color: '#ef4444', fontWeight: '900' }}>{(p.performance_score * 100).toFixed(0)}%</div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

export default IntelligenceHub;
