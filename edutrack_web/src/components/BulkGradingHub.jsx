import React, { useState, useEffect, useMemo } from 'react';
import {
  TrendingUp,
  Users,
  CheckCircle,
  Search,
  Zap,
  Filter,
  Save,
  AlertCircle,
  MoreVertical,
  ArrowRight,
  GraduationCap
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  collection,
  query,
  where,
  getDocs,
  updateDoc,
  addDoc,
  doc,
  serverTimestamp
} from 'firebase/firestore';

const BulkGradingHub = ({
  classes,
  students,
  assignments,
  submissions,
  selectedClass,
  setSelectedClass,
  db,
  user,
  fullUserData
}) => {
  const [activeAssignmentId, setActiveAssignmentId] = useState('');
  const [localGrades, setLocalGrades] = useState({}); // { [studentId]: grade }
  const [searchQuery, setSearchQuery] = useState('');
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncProgress, setSyncProgress] = useState(0);
  const [isAutoSync, setIsAutoSync] = useState(false);
  const [syncingRows, setSyncingRows] = useState({}); // { [studentId]: boolean }


  // Filter assignments based on selected class
  const filteredAssignments = useMemo(() => {
    if (!selectedClass) return assignments;
    return assignments.filter(a => a.class_id === selectedClass || a.classId === selectedClass);
  }, [assignments, selectedClass]);

  // Filter students based on selected class
  const filteredStudents = useMemo(() => {
    if (!selectedClass) return students;
    return students.filter(s => s.class_id === selectedClass || s.classId === selectedClass);
  }, [students, selectedClass]);

  // Final roster filtered by search
  const roster = useMemo(() => {
    return filteredStudents.filter(s =>
      (s.name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (s.roll_number || '').toLowerCase().includes(searchQuery.toLowerCase())
    );
  }, [filteredStudents, searchQuery]);

  // Stats
  const stats = useMemo(() => {
    const total = roster.length;
    const gradedLocally = Object.values(localGrades).filter(g => g !== '').length;

    // Check existing submissions for this assignment
    const existingSubmissions = submissions.filter(sub => sub.assignment_id === activeAssignmentId);
    const alreadyGraded = existingSubmissions.filter(sub => sub.marks !== undefined).length;

    const grades = Object.values(localGrades)
      .filter(g => g !== '')
      .map(g => parseFloat(g))
      .concat(existingSubmissions.map(sub => parseFloat(sub.marks || 0)));

    const avg = grades.length > 0 ? (grades.reduce((a, b) => a + b, 0) / grades.length).toFixed(1) : '0.0';

    return { total, graded: Math.max(gradedLocally, alreadyGraded), avg };
  }, [roster, localGrades, submissions, activeAssignmentId]);

  const deploySingleGrade = async (studentId, marks) => {
    if (!activeAssignmentId) return;
    setSyncingRows(prev => ({ ...prev, [studentId]: true }));
    try {
      const q = query(
        collection(db, 'submissions'),
        where('assignment_id', '==', activeAssignmentId),
        where('student_id', '==', studentId)
      );
      const snap = await getDocs(q);

      if (!snap.empty) {
        await updateDoc(doc(db, 'submissions', snap.docs[0].id), {
          marks: parseFloat(marks),
          status: 'graded',
          graded_at: serverTimestamp(),
          graded_by: fullUserData?.name || user?.email || 'Teacher'
        });
      } else {
        await addDoc(collection(db, 'submissions'), {
          assignment_id: activeAssignmentId,
          student_id: studentId,
          marks: parseFloat(marks),
          status: 'graded',
          submitted_at: serverTimestamp(),
          graded_at: serverTimestamp(),
          graded_by: fullUserData?.name || user?.email || 'Teacher',
          content: '[Manual Entry]'
        });
      }
      // Clear local grade once synced
      setLocalGrades(prev => {
        const next = { ...prev };
        delete next[studentId];
        return next;
      });
    } catch (err) {
      console.error(err);
    } finally {
      setSyncingRows(prev => ({ ...prev, [studentId]: false }));
    }
  };

  const handleGradeChange = (studentId, value) => {
    if (value === '' || (parseFloat(value) >= 0 && parseFloat(value) <= 100)) {
      setLocalGrades(prev => ({ ...prev, [studentId]: value }));
      if (isAutoSync && value !== '') {
        setTimeout(() => deploySingleGrade(studentId, value), 1000);
      }
    }
  };

  const fillAllGrades = (value) => {
    const newGrades = {};
    roster.forEach(s => {
      newGrades[s.id] = value;
    });
    setLocalGrades(newGrades);
  };

  const deployGrades = async () => {
    if (!activeAssignmentId) {
      alert('Please select an assignment first.');
      return;
    }

    const studentsToGrade = Object.entries(localGrades).filter(([_, val]) => val !== '');
    if (studentsToGrade.length === 0) {
      alert('No new grades to deploy.');
      return;
    }

    setIsSyncing(true);
    setSyncProgress(0);

    try {
      let count = 0;
      for (const [studentId, marks] of studentsToGrade) {
        const q = query(
          collection(db, 'submissions'),
          where('assignment_id', '==', activeAssignmentId),
          where('student_id', '==', studentId)
        );
        const snap = await getDocs(q);

        if (!snap.empty) {
          await updateDoc(doc(db, 'submissions', snap.docs[0].id), {
            marks: parseFloat(marks),
            status: 'graded',
            graded_at: serverTimestamp(),
            graded_by: fullUserData?.name || user?.email || 'Teacher'
          });
        } else {
          await addDoc(collection(db, 'submissions'), {
            assignment_id: activeAssignmentId,
            student_id: studentId,
            marks: parseFloat(marks),
            status: 'graded',
            submitted_at: serverTimestamp(),
            graded_at: serverTimestamp(),
            graded_by: fullUserData?.name || user?.email || 'Teacher',
            content: '[Manual Entry]'
          });
        }
        count++;
        setSyncProgress(Math.round((count / studentsToGrade.length) * 100));
      }

      alert(`Sync Complete: ${count} grades deployed to the cloud!`);
      setLocalGrades({});
    } catch (err) {
      console.error(err);
      alert('Deployment failed. Check console for details.');
    } finally {
      setIsSyncing(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 5 }}
      animate={{ opacity: 1, y: 0 }}
      style={{
        display: 'flex', flexDirection: 'column', gap: '16px',
        maxWidth: '1200px', margin: '0 auto', padding: '12px'
      }}
    >
      {/* Compact Header & Stats Section */}
      <div style={{
        padding: '24px 32px',
        background: '#ffffff',
        border: '1px solid #f1f5f9',
        boxShadow: '0 4px 20px rgba(0,0,0,0.02)',
        borderRadius: '20px',
        display: 'flex',
        flexDirection: 'column',
        gap: '24px'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', gap: '14px', alignItems: 'center' }}>
            <div style={{
              width: '44px', height: '44px', background: '#fff1f2',
              borderRadius: '12px', color: '#ec4899',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <TrendingUp size={20} />
            </div>
            <div>
              <h2 style={{ fontSize: '22px', fontWeight: '900', margin: 0, color: '#1e293b', letterSpacing: '-0.5px' }}>
                Bulk Grading <span style={{ color: '#ec4899' }}>Protocol</span>
              </h2>
              <p style={{ color: '#94a3b8', fontSize: '12px', fontWeight: '600', margin: 0 }}>Institutional Assessment Hub</p>
            </div>
          </div>

          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={deployGrades}
            disabled={isSyncing || Object.keys(localGrades).length === 0}
            style={{
              display: 'flex', alignItems: 'center', gap: '8px',
              padding: '12px 24px', borderRadius: '12px',
              background: 'linear-gradient(135deg, #ec4899, #be123c)',
              boxShadow: '0 4px 12px rgba(236, 72, 153, 0.2)',
              border: 'none', color: 'white', fontWeight: '800',
              cursor: 'pointer', opacity: (isSyncing || Object.keys(localGrades).length === 0) ? 0.6 : 1,
              fontSize: '13px'
            }}
          >
            {isSyncing ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div className="spinning-loader" style={{ width: '14px', height: '14px', border: '2px solid rgba(255,255,255,0.3)', borderTopColor: 'white', borderRadius: '50%', animation: 'spin 1s linear infinite' }}></div>
                <span>Syncing...</span>
              </div>
            ) : (
              <><Zap size={16} fill="white" /> <span>Deploy Grades</span></>
            )}
          </motion.button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 0.6fr 0.6fr', gap: '16px' }}>
          <div>
            <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.8px' }}>
              Academic Hub (Class)
            </label>
            <div style={{ position: 'relative' }}>
              <select
                value={selectedClass || ''}
                onChange={(e) => setSelectedClass(e.target.value)}
                style={{
                  width: '100%', padding: '12px 16px',
                  background: '#f8fafc',
                  border: '1px solid #e2e8f0',
                  borderRadius: '12px', color: '#1e293b', fontSize: '14px',
                  fontWeight: '700', outline: 'none', appearance: 'none',
                  cursor: 'pointer'
                }}
                className="custom-select-white"
              >
                <option value="">Select a Hub...</option>
                {classes.map(c => (
                  <option key={c.id} value={c.id}>
                    {c.standard ? (c.section ? `${c.standard} - ${c.section}` : c.standard) : (c.displayName || c.id)}
                  </option>
                ))}
              </select>
              <ArrowRight size={16} style={{ position: 'absolute', right: '14px', top: '50%', transform: 'translateY(-50%) rotate(90deg)', color: '#94a3b8', pointerEvents: 'none' }} />
            </div>
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '8px', color: '#64748b', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.8px' }}>
              Mission Objective
            </label>
            <div style={{ position: 'relative' }}>
              <select
                value={activeAssignmentId}
                onChange={(e) => setActiveAssignmentId(e.target.value)}
                style={{
                  width: '100%', padding: '12px 16px',
                  background: '#f8fafc',
                  border: '1px solid #e2e8f0',
                  borderRadius: '12px', color: '#1e293b', fontSize: '14px',
                  fontWeight: '700', outline: 'none', appearance: 'none',
                  cursor: 'pointer'
                }}
                className="custom-select-white"
              >
                <option value="">Choose an assignment...</option>
                {filteredAssignments.map(a => (
                  <option key={a.id} value={a.id}>{a.title} • {a.subject || 'General'}</option>
                ))}
              </select>
              <ArrowRight size={16} style={{ position: 'absolute', right: '14px', top: '50%', transform: 'translateY(-50%) rotate(90deg)', color: '#94a3b8', pointerEvents: 'none' }} />
            </div>
          </div>

          <div style={{ background: '#f8fafc', padding: '16px 20px', borderRadius: '16px', border: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: '10px', fontWeight: '900', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Completion</div>
              <div style={{ fontSize: '20px', fontWeight: '900', color: '#ec4899', marginTop: '2px' }}>{stats.graded} <span style={{ color: '#94a3b8', fontSize: '12px', fontWeight: '600' }}>/ {stats.total}</span></div>
            </div>
            <div style={{ width: '40px', height: '40px', borderRadius: '50%', border: '4px solid #e2e8f0', borderTopColor: '#ec4899', transform: `rotate(${(stats.graded / (stats.total || 1)) * 360}deg)`, transition: 'transform 1s cubic-bezier(0.4, 0, 0.2, 1)' }}></div>
          </div>

          <div style={{ background: '#f8fafc', padding: '16px 20px', borderRadius: '16px', border: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: '10px', fontWeight: '900', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Class Average</div>
              <div style={{ fontSize: '20px', fontWeight: '900', color: '#8b5cf6', marginTop: '2px' }}>{stats.avg}%</div>
            </div>
            <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: '#f5f3ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#8b5cf6' }}>
              <TrendingUp size={20} />
            </div>
          </div>

          <div 
            onClick={() => setIsAutoSync(!isAutoSync)}
            style={{ 
              background: isAutoSync ? '#ecfdf5' : '#f8fafc', 
              padding: '16px 20px', borderRadius: '16px', 
              border: `1px solid ${isAutoSync ? '#10b981' : '#e2e8f0'}`, 
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              cursor: 'pointer', transition: 'all 0.2s'
            }}
          >
            <div>
              <div style={{ fontSize: '10px', fontWeight: '900', color: isAutoSync ? '#059669' : '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Auto-Sync App</div>
              <div style={{ fontSize: '13px', fontWeight: '800', color: isAutoSync ? '#059669' : '#94a3b8', marginTop: '2px' }}>{isAutoSync ? 'ENABLED' : 'OFF'}</div>
            </div>
            <div style={{ 
              width: '36px', height: '18px', background: isAutoSync ? '#10b981' : '#cbd5e1', 
              borderRadius: '20px', position: 'relative', transition: 'all 0.2s' 
            }}>
              <div style={{ 
                width: '14px', height: '14px', background: 'white', borderRadius: '50%', 
                position: 'absolute', top: '2px', left: isAutoSync ? '20px' : '2px',
                transition: 'all 0.2s'
              }} />
            </div>
          </div>
        </div>
      </div>


      {/* High-Density Roster Section */}
      <div style={{
        background: '#ffffff',
        border: '1px solid #f1f5f9',
        boxShadow: '0 2px 10px rgba(0,0,0,0.01)',
        borderRadius: '20px',
        overflow: 'hidden'
      }}>
        <div style={{
          padding: '16px 24px',
          borderBottom: '1px solid #f1f5f9',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          background: '#ffffff'
        }}>
          <div style={{ position: 'relative', width: '320px' }}>
            <Search size={16} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
            <input
              type="text"
              placeholder="Search students..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: '100%', paddingLeft: '40px', height: '42px', fontSize: '13px',
                borderRadius: '10px', border: '1px solid #e2e8f0', outline: 'none',
                background: '#f8fafc', color: '#1e293b'
              }}
            />
          </div>

          <div style={{ display: 'flex', gap: '10px' }}>
            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => fillAllGrades('100')}
              style={{
                padding: '0 16px', borderRadius: '8px', fontSize: '12px', fontWeight: '800',
                height: '42px', background: '#eff6ff', color: '#2563eb', border: '1px solid #dbeafe',
                cursor: 'pointer'
              }}
            >
              Set All 100
            </motion.button>
            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => fillAllGrades('')}
              style={{
                padding: '0 16px', borderRadius: '8px', fontSize: '12px', fontWeight: '800',
                height: '42px', background: '#fff1f2', color: '#e11d48', border: '1px solid #ffe4e6',
                cursor: 'pointer'
              }}
            >
              Clear All
            </motion.button>
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ background: '#f8fafc', borderBottom: '1px solid #f1f5f9' }}>
                <th style={{ padding: '12px 24px', color: '#64748b', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.8px' }}>Student Member</th>
                <th style={{ padding: '12px 16px', color: '#64748b', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.8px' }}>Status</th>
                <th style={{ padding: '12px 16px', color: '#64748b', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.8px', textAlign: 'center' }}>Mark Adjustment</th>
                <th style={{ padding: '12px 24px', color: '#64748b', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '0.8px', textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              <AnimatePresence>
                {roster.map((student, index) => {
                  const submission = submissions.find(s => s.student_id === student.id && s.assignment_id === activeAssignmentId);
                  const isGraded = submission?.marks !== undefined || (localGrades[student.id] !== undefined && localGrades[student.id] !== '');
                  const currentMark = localGrades[student.id] !== undefined ? localGrades[student.id] : (submission?.marks || '');

                  return (
                    <motion.tr
                      key={student.id}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      style={{
                        borderBottom: '1px solid #f8fafc',
                        background: index % 2 === 1 ? '#fafbfc' : '#ffffff',
                        transition: 'background 0.2s'
                      }}
                      className="table-row-hover"
                    >
                      <td style={{ padding: '12px 24px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                          <div style={{
                            width: '36px', height: '36px', borderRadius: '10px',
                            background: index % 2 === 0 ? '#eff6ff' : '#f5f3ff',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            border: `1px solid ${index % 2 === 0 ? '#dbeafe' : '#ede9fe'}`,
                            fontSize: '14px', fontWeight: '900', color: index % 2 === 0 ? '#2563eb' : '#7c3aed'
                          }}>
                            {(student.name || 'S')[0]}
                          </div>
                          <div>
                            <div style={{ fontWeight: '700', color: '#1e293b', fontSize: '14px' }}>{student.name || 'Unknown'}</div>
                            <div style={{ fontSize: '11px', color: '#94a3b8' }}>{student.roll_no || student.id.slice(0, 6).toUpperCase()}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        <div style={{
                          display: 'inline-flex', alignItems: 'center', gap: '6px',
                          padding: '4px 10px', borderRadius: '8px', fontSize: '10px', fontWeight: '800',
                          textTransform: 'uppercase',
                          background: isGraded ? '#ecfdf5' : '#fff7ed',
                          color: isGraded ? '#059669' : '#d97706',
                          border: `1px solid ${isGraded ? '#d1fae5' : '#ffedd5'}`
                        }}>
                          {isGraded ? 'Graded' : 'Pending'}
                        </div>
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px' }}>
                          <input
                            type="number"
                            min="0" max="100" placeholder="--"
                            value={currentMark}
                            onChange={(e) => handleGradeChange(student.id, e.target.value)}
                            style={{
                              width: '64px', height: '36px', textAlign: 'center',
                              fontSize: '16px', fontWeight: '800',
                              background: '#ffffff', border: '1px solid #e2e8f0',
                              borderRadius: '8px', outline: 'none', color: '#1e293b'
                            }}
                            className="compact-grade-input"
                          />
                          <span style={{ fontSize: '12px', color: '#94a3b8', fontWeight: '700' }}>/100</span>
                        </div>
                      </td>
                      <td style={{ padding: '12px 24px', textAlign: 'right' }}>
                        <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                          <motion.button 
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                            onClick={() => deploySingleGrade(student.id, localGrades[student.id])}
                            disabled={syncingRows[student.id] || localGrades[student.id] === undefined || localGrades[student.id] === ''}
                            style={{ 
                              display: 'flex', alignItems: 'center', gap: '6px',
                              padding: '6px 14px', borderRadius: '8px', 
                              border: 'none', 
                              background: (localGrades[student.id] !== undefined && localGrades[student.id] !== '') ? '#ec4899' : '#f1f5f9', 
                              color: (localGrades[student.id] !== undefined && localGrades[student.id] !== '') ? 'white' : '#94a3b8',
                              cursor: (localGrades[student.id] !== undefined && localGrades[student.id] !== '') ? 'pointer' : 'not-allowed',
                              fontSize: '11px', fontWeight: '800',
                              boxShadow: (localGrades[student.id] !== undefined && localGrades[student.id] !== '') ? '0 4px 10px rgba(236, 72, 153, 0.2)' : 'none',
                              transition: 'all 0.2s'
                            }}
                          >
                            {syncingRows[student.id] ? (
                              <div style={{ width: '12px', height: '12px', border: '2px solid rgba(255,255,255,0.3)', borderTopColor: 'white', borderRadius: '50%', animation: 'spin 1s linear infinite' }} />
                            ) : (
                              <Zap size={12} fill={(localGrades[student.id] !== undefined && localGrades[student.id] !== '') ? 'white' : 'none'} />
                            )}
                            Sync
                          </motion.button>

                          <button 
                            onClick={() => {
                              setLocalGrades(prev => {
                                const next = { ...prev };
                                delete next[student.id];
                                return next;
                              });
                            }}
                            style={{ 
                              padding: '6px 10px', borderRadius: '8px', 
                              border: '1px solid #e2e8f0', background: 'white', color: '#64748b',
                              cursor: 'pointer', fontSize: '11px', fontWeight: '700',
                              display: 'flex', alignItems: 'center', gap: '4px'
                            }}
                          >
                            <MoreVertical size={16} /> Reset
                          </button>
                        </div>
                      </td>

                    </motion.tr>
                  );
                })}
              </AnimatePresence>
            </tbody>
          </table>
        </div>
      </div>

      <style>{`
        .compact-grade-input:focus {
          border-color: #ec4899 !important;
          box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.1);
        }
        .table-row-hover:hover {
          background: #f1f5f9 !important;
        }
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        select option {
          background: white !important;
          color: #1e293b !important;
          padding: 10px !important;
        }
      `}</style>
    </motion.div>
  );
};

export default BulkGradingHub;
