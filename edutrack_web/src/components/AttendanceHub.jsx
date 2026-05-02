import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ChevronLeft,
  ChevronRight,
  Calendar,
  Clock,
  ArrowLeft,
  CheckCircle2,
  Users,
  CheckCircle,
  XCircle,
  TrendingUp,
  History
} from 'lucide-react';

const AttendanceHub = ({
  classes,
  students,
  selectedClass,
  attDate,
  attStatusMap,
  attLoading,
  attSaving,
  handleAttClassChange,
  handleAttDateChange,
  shiftAttDate,
  setStudentStatus,
  saveAllAttendance,
  setAttStatusMap,
  setActiveTab
}) => {
  const [currentStep, setCurrentStep] = useState(selectedClass ? 2 : 1); // 1: Class Selection, 2: Marking

  // Filter students: support both 'class_id' (mobile app) and 'classId' (web legacy)
  const classStudents = selectedClass
    ? students.filter(s => (s.class_id === selectedClass) || (s.classId === selectedClass))
    : [];

  const markedCount = Object.keys(attStatusMap).length;
  const presentCount = Object.values(attStatusMap).filter(v => v === 'present').length;
  const absentCount = Object.values(attStatusMap).filter(v => v === 'absent').length;
  const lateCount = Object.values(attStatusMap).filter(v => v === 'late').length;

  const handleBack = () => {
    if (currentStep === 2) setCurrentStep(1);
    else setActiveTab('dashboard');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px', minHeight: '100vh', paddingBottom: '40px' }}>
      
      {/* Premium Header */}
      <div style={{ 
        background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)', 
        padding: '40px 32px', 
        borderRadius: '32px',
        position: 'relative',
        overflow: 'hidden',
        boxShadow: '0 20px 40px rgba(16, 185, 129, 0.2)'
      }}>
        <CheckCircle2 size={160} style={{ position: 'absolute', top: '-20px', right: '-20px', color: 'white', opacity: 0.1, transform: 'rotate(15deg)' }} />
        
        <div style={{ position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
              <button 
                onClick={handleBack}
                style={{ background: 'rgba(255,255,255,0.2)', border: 'none', padding: '8px', borderRadius: '10px', color: 'white', cursor: 'pointer', display: 'flex', alignItems: 'center', backdropFilter: 'blur(10px)' }}
              >
                <ArrowLeft size={18} />
              </button>
              <div style={{ background: 'rgba(255,255,255,0.2)', padding: '4px 12px', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.3)', backdropFilter: 'blur(10px)' }}>
                <span style={{ fontSize: '10px', fontWeight: '900', color: 'white', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  {currentStep === 1 ? 'Session Configuration' : 'Live Presence Marking'}
                </span>
              </div>
            </div>
            <h1 style={{ fontSize: '32px', fontWeight: '900', color: 'white', margin: 0, letterSpacing: '-1px' }}>
              {currentStep === 1 ? 'Attendance Setup' : 'Mark Attendance'}
            </h1>
          </div>

          {currentStep === 2 && (
            <div style={{ textAlign: 'right', color: 'white' }}>
              <div style={{ fontSize: '24px', fontWeight: '900' }}>{markedCount} / {classStudents.length}</div>
              <div style={{ fontSize: '11px', fontWeight: '700', opacity: 0.8, textTransform: 'uppercase' }}>Synchronized</div>
            </div>
          )}
        </div>
      </div>

      <AnimatePresence mode="wait">
        {currentStep === 1 ? (
          <motion.div 
            key="step1"
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.98 }}
            style={{ maxWidth: '600px', margin: '0 auto', width: '100%' }}
          >
            <div className="glass-card" style={{ padding: '40px', background: 'white', borderRadius: '32px', border: '1px solid #f1f5f9', boxShadow: '0 20px 50px rgba(0,0,0,0.05)' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
                <div>
                  <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '12px', display: 'block' }}>Target Hub (Class)</label>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: '12px' }}>
                    {classes.map(c => (
                      <button
                        key={c.id}
                        onClick={() => { handleAttClassChange(c.id); setCurrentStep(2); }}
                        style={{
                          padding: '16px',
                          borderRadius: '16px',
                          border: `2px solid ${selectedClass === c.id ? '#10b981' : '#f1f5f9'}`,
                          background: selectedClass === c.id ? '#ecfdf5' : 'white',
                          color: selectedClass === c.id ? '#059669' : '#475569',
                          fontWeight: '800',
                          fontSize: '14px',
                          cursor: 'pointer',
                          transition: 'all 0.2s'
                        }}
                      >
                        {c.displayName || `${c.standard}-${c.section}`}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '12px', display: 'block' }}>Session Date</label>
                  <input 
                    type="date" 
                    value={attDate} 
                    onChange={(e) => handleAttDateChange(e.target.value)}
                    style={{ width: '100%', padding: '16px', borderRadius: '16px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '16px', fontWeight: '700' }}
                  />
                </div>
              </div>
            </div>
          </motion.div>
        ) : (
          <motion.div 
            key="step2"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}
          >
            {/* Stats Row */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '20px' }}>
              {[
                { label: 'Present', count: presentCount, color: '#10b981', icon: <CheckCircle size={20} /> },
                { label: 'Absent', count: absentCount, color: '#ef4444', icon: <XCircle size={20} /> },
                { label: 'Late', count: lateCount, color: '#f59e0b', icon: <Clock size={20} /> },
                { label: 'Pending', count: classStudents.length - markedCount, color: '#64748b', icon: <History size={20} /> }
              ].map(s => (
                <div key={s.label} className="glass-card" style={{ padding: '20px', display: 'flex', alignItems: 'center', gap: '12px', borderRadius: '20px', border: '1px solid #f1f5f9', background: 'white' }}>
                  <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: `${s.color}15`, color: s.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    {s.icon}
                  </div>
                  <div>
                    <div style={{ fontSize: '20px', fontWeight: '900', color: '#0f172a' }}>{s.count}</div>
                    <div style={{ fontSize: '10px', fontWeight: '800', color: '#64748b', textTransform: 'uppercase' }}>{s.label}</div>
                  </div>
                </div>
              ))}
            </div>

            {/* Attendance Roster */}
            <div className="glass-card" style={{ background: 'white', borderRadius: '32px', border: '1px solid #f1f5f9', overflow: 'hidden', boxShadow: '0 4px 30px rgba(0,0,0,0.03)' }}>
              <div style={{ padding: '24px 32px', borderBottom: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '800' }}>Student Presence Roster</h3>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button onClick={() => { const m = {}; classStudents.forEach(s => m[s.id] = 'present'); setAttStatusMap(m); }} style={{ padding: '8px 16px', borderRadius: '10px', background: '#ecfdf5', color: '#059669', border: 'none', fontSize: '12px', fontWeight: '800', cursor: 'pointer' }}>All Present</button>
                  <button onClick={() => { const m = {}; classStudents.forEach(s => m[s.id] = 'absent'); setAttStatusMap(m); }} style={{ padding: '8px 16px', borderRadius: '10px', background: '#fef2f2', color: '#ef4444', border: 'none', fontSize: '12px', fontWeight: '800', cursor: 'pointer' }}>All Absent</button>
                </div>
              </div>

              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ background: '#f8fafc' }}>
                      <th style={{ padding: '16px 32px', textAlign: 'left', fontSize: '12px', fontWeight: '800', color: '#475569' }}>Student Member</th>
                      <th style={{ padding: '16px', textAlign: 'center', fontSize: '12px', fontWeight: '800', color: '#475569' }}>Roll No</th>
                      <th style={{ padding: '16px 32px', textAlign: 'center', fontSize: '12px', fontWeight: '800', color: '#475569' }}>Status Selector</th>
                    </tr>
                  </thead>
                  <tbody>
                    {classStudents.map((s, idx) => {
                      const status = attStatusMap[s.id] || null;
                      return (
                        <tr key={s.id} style={{ borderBottom: '1px solid #f1f5f9', background: status === 'present' ? '#f0fdf4' : status === 'absent' ? '#fef2f2' : 'transparent' }}>
                          <td style={{ padding: '16px 32px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                              <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800' }}>
                                {(s.name || 'S').charAt(0)}
                              </div>
                              <div style={{ fontWeight: '700', fontSize: '15px' }}>{s.name}</div>
                            </div>
                          </td>
                          <td style={{ padding: '16px', textAlign: 'center', fontWeight: '700', color: '#64748b' }}>{s.roll_no || idx + 1}</td>
                          <td style={{ padding: '16px 32px' }}>
                            <div style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
                              {[
                                { k: 'present', l: 'P', c: '#10b981' },
                                { k: 'absent', l: 'A', c: '#ef4444' },
                                { k: 'late', l: 'L', c: '#f59e0b' }
                              ].map(btn => (
                                <button
                                  key={btn.k}
                                  onClick={() => setStudentStatus(s.id, btn.k)}
                                  style={{
                                    width: '36px', height: '36px', borderRadius: '10px',
                                    border: `2px solid ${status === btn.k ? btn.c : '#e2e8f0'}`,
                                    background: status === btn.k ? btn.c : 'white',
                                    color: status === btn.k ? 'white' : '#64748b',
                                    fontWeight: '900', cursor: 'pointer', transition: 'all 0.2s'
                                  }}
                                >
                                  {btn.l}
                                </button>
                              ))}
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>

              {/* Final Execution Button */}
              <div style={{ padding: '32px' }}>
                <button
                  disabled={attSaving}
                  onClick={() => saveAllAttendance(classStudents)}
                  style={{
                    width: '100%', padding: '20px',
                    background: attSaving ? '#64748b' : 'linear-gradient(135deg, #10b981, #059669)',
                    color: 'white', border: 'none', borderRadius: '16px',
                    fontSize: '16px', fontWeight: '900', cursor: 'pointer',
                    boxShadow: '0 10px 30px rgba(16, 185, 129, 0.2)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '12px'
                  }}
                >
                  {attSaving ? 'Synchronizing Telemetry...' : `Finalize & Sync Attendance (${markedCount} Members)`}
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default AttendanceHub;
