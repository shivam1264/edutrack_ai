import React, { useState } from 'react';
import {
  Layers, Clock, ClipboardList, CheckCircle, BookOpen, Users, FileText, Trash, Zap, ArrowLeft, PlusCircle, Calendar, TrendingUp, ExternalLink, Eye, XCircle, RefreshCw, AlertCircle
} from 'lucide-react';
import {
  doc, updateDoc, addDoc, collection, serverTimestamp, deleteDoc
} from 'firebase/firestore';
import { Timestamp } from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';

const AssignmentsHub = ({
  user, assignments, submissions, students, classes, db, fullUserData,
  assignmentFile, isUploadingAssignment, handleAssignmentFileChange,
  assignmentFileUrl, setAssignmentFileUrl, setAssignmentFile,
  setActiveTab
}) => {
  const [activeView, setActiveView] = useState('manage'); // 'manage', 'create', 'review'
  const [currentStep, setCurrentStep] = useState(1);
  const [assignmentTab, setAssignmentTab] = useState('all');
  const [selectedAssignmentForGrading, setSelectedAssignmentForGrading] = useState(null);
  const [previewFile, setPreviewFile] = useState(null);

  const availableSubjects = fullUserData?.specialization || fullUserData?.subjects || ['Mathematics', 'Science', 'English', 'History', 'Geography', 'Physics', 'Chemistry', 'Biology', 'Computer Science'];
  const isAdmin = fullUserData?.role === 'admin';
  const myAssignments = (assignments || []).filter(a => isAdmin ? true : a.teacher_id === user?.uid);
  
  // Robust matching helper
  const findSubmission = (studentId, rollNo, assignmentId) => {
    return (submissions || []).find(sub => 
      sub.assignment_id === assignmentId && 
      (sub.student_id === studentId || sub.studentId === studentId || (rollNo && (sub.student_id === rollNo || sub.studentId === rollNo)))
    );
  };

  const assignmentStats = {
    total: myAssignments.length,
    pending: myAssignments.filter(a => (submissions || []).filter(s => s.assignment_id === a.id).length === 0).length,
    submitted: myAssignments.filter(a => {
      const subs = (submissions || []).filter(s => s.assignment_id === a.id);
      return subs.length > 0 && subs.some(s => String(s.status).toLowerCase() !== 'graded');
    }).length,
    graded: myAssignments.filter(a => {
      const subs = (submissions || []).filter(s => s.assignment_id === a.id);
      const targetClass = classes.find(c => c.id === a.class_id);
      const totalInClass = (students || []).filter(s =>
        (s.class_id === a.class_id) ||
        (s.classId === a.class_id) ||
        (targetClass && s.classId === targetClass.displayName)
      ).length;
      return subs.length > 0 && subs.every(s => String(s.status).toLowerCase() === 'graded') && subs.length === totalInClass;
    }).length
  };

  const handleBack = () => {
    if (activeView === 'create') {
      if (currentStep === 2) setCurrentStep(1);
      else setActiveView('manage');
    } else if (activeView === 'review') {
      setActiveView('manage');
      setSelectedAssignmentForGrading(null);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px', minHeight: '100vh', paddingBottom: '40px', fontFamily: "'Inter', sans-serif", color: 'var(--text-main)' }}>
      
      {/* Premium Header */}
      <div style={{ 
        background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)', 
        padding: '40px 32px', 
        borderRadius: '32px',
        position: 'relative',
        overflow: 'hidden',
        boxShadow: '0 20px 40px rgba(99, 102, 241, 0.2)'
      }}>
        <Layers size={160} style={{ position: 'absolute', top: '-20px', right: '-20px', color: 'white', opacity: 0.1, transform: 'rotate(15deg)' }} />
        
        <div style={{ position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
              {activeView !== 'manage' && (
                <button 
                  onClick={handleBack}
                  style={{ background: 'rgba(255,255,255,0.2)', border: 'none', padding: '8px', borderRadius: '10px', color: 'white', cursor: 'pointer', display: 'flex', alignItems: 'center', backdropFilter: 'blur(10px)' }}
                >
                  <ArrowLeft size={18} />
                </button>
              )}
              <div style={{ background: 'rgba(255,255,255,0.2)', padding: '4px 12px', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.3)', backdropFilter: 'blur(10px)' }}>
                <span style={{ fontSize: '10px', fontWeight: '900', color: 'white', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  {activeView === 'create' ? `Provisioning Phase ${currentStep}/2` : (activeView === 'review' ? 'Mission Intelligence' : 'Assignment Nexus')}
                </span>
              </div>
            </div>
            <h1 style={{ fontSize: '32px', fontWeight: '900', color: 'white', margin: 0, letterSpacing: '-1px' }}>
              {activeView === 'create' ? 'Mission Provisioner' : (activeView === 'review' ? 'Review Protocol' : 'Assignments Hub')}
            </h1>
          </div>

          {activeView === 'manage' && (
            <div style={{ display: 'flex', gap: '12px' }}>
              <button 
                onClick={() => window.location.reload()}
                style={{ background: 'rgba(255,255,255,0.15)', color: 'white', border: '1px solid rgba(255,255,255,0.2)', padding: '12px', borderRadius: '12px', cursor: 'pointer', display: 'flex', alignItems: 'center', backdropFilter: 'blur(10px)' }}
                title="Refresh Registry"
              >
                <RefreshCw size={20} />
              </button>
              <button 
                onClick={() => { setActiveView('create'); setCurrentStep(1); }}
                style={{ background: 'white', color: '#6366f1', border: 'none', padding: '12px 24px', borderRadius: '12px', fontWeight: '900', fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', boxShadow: '0 8px 20px rgba(0,0,0,0.1)' }}
              >
                <PlusCircle size={20} /> New Assignment
              </button>
            </div>
          )}
        </div>
      </div>

      <AnimatePresence mode="wait">
        {activeView === 'manage' && (
          <motion.div 
            key="manage"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}
          >
            {/* Stats Summary */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
              {[
                { label: 'Total Missions', value: assignmentStats.total, icon: <Layers size={20} />, color: '#6366f1' },
                { label: 'Pending Start', value: assignmentStats.pending, icon: <Clock size={20} />, color: '#f59e0b' },
                { label: 'Awaiting Review', value: assignmentStats.submitted, icon: <ClipboardList size={20} />, color: '#8b5cf6' },
                { label: 'Fully Graded', value: assignmentStats.graded, icon: <CheckCircle size={20} />, color: '#10b981' }
              ].map((s, i) => (
                <div key={i} className="glass-card" style={{ padding: '20px', display: 'flex', alignItems: 'center', gap: '16px', borderRadius: '24px', border: '1px solid var(--glass-border)', background: 'var(--card-bg)', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
                  <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: `${s.color}15`, color: s.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    {s.icon}
                  </div>
                  <div>
                    <div style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{s.label}</div>
                    <div style={{ fontSize: '20px', fontWeight: '900', color: 'var(--text-main)', marginTop: '2px' }}>{s.value}</div>
                  </div>
                </div>
              ))}
            </div>

            {/* Main Registry Table */}
            <div className="glass-card" style={{ background: 'var(--card-bg)', borderRadius: '32px', border: '1px solid var(--glass-border)', overflow: 'hidden', boxShadow: '0 4px 30px rgba(0,0,0,0.03)' }}>
              <div style={{ padding: '20px 32px', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', gap: '10px' }}>
                  {['all', 'pending', 'submitted', 'graded'].map(t => (
                    <button
                      key={t}
                      onClick={() => setAssignmentTab(t)}
                      style={{
                        padding: '8px 16px',
                        borderRadius: '10px',
                        border: 'none',
                        background: assignmentTab === t ? '#6366f1' : 'var(--glass-surface)',
                        color: assignmentTab === t ? 'white' : 'var(--text-dim)',
                        fontSize: '12px',
                        fontWeight: '800',
                        textTransform: 'capitalize',
                        cursor: 'pointer',
                        transition: 'all 0.2s'
                      }}
                    >
                      {t}
                    </button>
                  ))}
                </div>
              </div>

              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                  <thead>
                    <tr style={{ borderBottom: '1px solid var(--glass-border)', background: 'var(--glass-surface)' }}>
                      <th style={{ padding: '16px 32px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Mission Deployment</th>
                      <th style={{ padding: '16px 20px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Target Hub</th>
                      <th style={{ padding: '16px 20px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Telemetry</th>
                      <th style={{ padding: '16px 32px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', textAlign: 'right' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {myAssignments
                      .filter(a => {
                        if (assignmentTab === 'all') return true;
                        const subs = (submissions || []).filter(s => s.assignment_id === a.id);
                        const targetClass = classes.find(c => c.id === a.class_id);
                        const totalInClass = (students || []).filter(s =>
                          (s.class_id === a.class_id) || (s.classId === a.class_id) || (targetClass && s.classId === targetClass.displayName)
                        ).length;
                        if (assignmentTab === 'pending') return subs.length < totalInClass || subs.length === 0;
                        if (assignmentTab === 'submitted') return subs.length > 0 && subs.some(s => String(s.status).toLowerCase() !== 'graded');
                        if (assignmentTab === 'graded') return subs.length > 0 && subs.every(s => String(s.status).toLowerCase() === 'graded');
                        return true;
                      })
                      .map((a) => {
                        const subs = (submissions || []).filter(s => s.assignment_id === a.id);
                        const targetClass = classes.find(c => c.id === a.class_id);
                        const totalInClass = (students || []).filter(s =>
                          (s.class_id === a.class_id) || (s.classId === a.class_id) || (targetClass && s.classId === targetClass.displayName)
                        ).length;
                        const progress = totalInClass > 0 ? (subs.length / totalInClass) * 100 : 0;

                        return (
                          <tr key={a.id} style={{ borderBottom: '1px solid var(--glass-border)', transition: 'background 0.2s' }}>
                            <td style={{ padding: '20px 32px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                                <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: '#f5f3ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#7c3aed' }}>
                                  <BookOpen size={18} />
                                </div>
                                <div>
                                  <div style={{ fontWeight: '800', color: 'var(--text-main)', fontSize: '14px' }}>{a.title}</div>
                                  <div style={{ fontSize: '11px', color: 'var(--text-dim)', marginTop: '2px' }}>{a.subject}</div>
                                </div>
                              </div>
                            </td>
                            <td style={{ padding: '20px 20px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-main)', fontWeight: '700', fontSize: '13px' }}>
                                <Users size={14} /> {classes.find(c => c.id === a.class_id)?.displayName || 'Global'}
                              </div>
                            </td>
                            <td style={{ padding: '20px 20px' }}>
                              <div style={{ width: '120px' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', marginBottom: '6px', fontWeight: '800' }}>
                                  <span style={{ color: 'var(--text-dim)' }}>{subs.length}/{totalInClass}</span>
                                  <span style={{ color: '#6366f1' }}>{Math.round(progress)}%</span>
                                </div>
                                <div style={{ width: '100%', height: '4px', background: 'var(--glass-surface)', borderRadius: '2px', overflow: 'hidden' }}>
                                  <div style={{ width: `${progress}%`, height: '100%', background: '#6366f1', borderRadius: '2px' }}></div>
                                </div>
                              </div>
                            </td>
                            <td style={{ padding: '20px 32px', textAlign: 'right' }}>
                              <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end', alignItems: 'center' }}>
                                <button
                                  onClick={() => { setSelectedAssignmentForGrading(a); setActiveView('review'); }}
                                  style={{ padding: '8px 16px', borderRadius: '10px', background: '#6366f1', color: 'white', border: 'none', fontSize: '12px', fontWeight: '800', cursor: 'pointer', transition: 'all 0.2s' }}
                                >
                                  Review
                                </button>
                                <button
                                  onClick={async () => { if (window.confirm('Delete this mission?')) await deleteDoc(doc(db, 'assignments', a.id)); }}
                                  style={{ 
                                    width: '36px', height: '36px', borderRadius: '10px', 
                                    background: '#fee2e2', color: '#ef4444', 
                                    border: 'none', display: 'flex', alignItems: 'center', 
                                    justifyContent: 'center', cursor: 'pointer',
                                    transition: 'all 0.2s'
                                  }}
                                  title="Delete Assignment"
                                >
                                  <Trash size={16} strokeWidth={2.5} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                  </tbody>
                </table>
              </div>
            </div>
          </motion.div>
        )}

        {activeView === 'review' && selectedAssignmentForGrading && (
          <motion.div 
            key="review"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
          >
            <div className="glass-card" style={{ padding: '32px', background: 'var(--card-bg)', borderRadius: '32px', border: '1px solid var(--glass-border)', boxShadow: '0 4px 30px rgba(0,0,0,0.03)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
                <div>
                   <h3 style={{ margin: 0, fontSize: '20px', fontWeight: '900', color: 'var(--text-main)' }}>Member Roster & Grading</h3>
                   <p style={{ margin: '4px 0 0 0', fontSize: '12px', color: 'var(--text-dim)', fontWeight: '600' }}>Reviewing: {selectedAssignmentForGrading.title}</p>
                </div>
                <div style={{ fontSize: '14px', fontWeight: '700', color: 'var(--text-dim)', background: 'var(--glass-surface)', padding: '8px 16px', borderRadius: '12px', border: '1px solid var(--glass-border)' }}>
                  Submissions: {(submissions || []).filter(s => s.assignment_id === selectedAssignmentForGrading.id).length}
                </div>
              </div>
              
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ background: 'var(--glass-surface)' }}>
                      <th style={{ padding: '16px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Member</th>
                      <th style={{ padding: '16px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Submission Preview</th>
                      <th style={{ padding: '16px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Status</th>
                      <th style={{ padding: '16px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase' }}>Marks</th>
                      <th style={{ padding: '16px', fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', textAlign: 'right' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(students || []).filter(s => 
                      s.class_id === selectedAssignmentForGrading.class_id || 
                      s.classId === selectedAssignmentForGrading.class_id ||
                      (classes.find(c => c.id === selectedAssignmentForGrading.class_id)?.displayName === s.classId)
                    ).map(s => {
                      const sub = findSubmission(s.id, s.roll_no || s.rollNo || s.studentId, selectedAssignmentForGrading.id);
                      // Check all possible image fields
                      const imageUrl = sub?.file_url || sub?.fileUrl || sub?.image_url || sub?.imageUrl || sub?.submission_url;
                      
                      return (
                        <tr key={s.id} style={{ borderBottom: '1px solid var(--glass-border)', transition: 'background 0.2s' }}>
                          <td style={{ padding: '16px' }}>
                            <div style={{ fontWeight: '700', fontSize: '14px', color: 'var(--text-main)' }}>{s.name}</div>
                            <div style={{ fontSize: '11px', color: 'var(--text-dim)' }}>Roll: {s.roll_no || s.rollNo || '--'}</div>
                          </td>
                          <td style={{ padding: '16px' }}>
                            {imageUrl ? (
                              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <div 
                                  onClick={() => setPreviewFile(imageUrl)}
                                  style={{ width: '40px', height: '40px', borderRadius: '8px', overflow: 'hidden', cursor: 'pointer', border: '2px solid #6366f1', background: 'var(--glass-surface)' }}
                                >
                                  <img src={imageUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                </div>
                                <button 
                                  onClick={() => setPreviewFile(imageUrl)}
                                  style={{ 
                                    display: 'flex', alignItems: 'center', gap: '4px', 
                                    padding: '4px 10px', borderRadius: '8px', 
                                    background: '#f5f3ff', color: '#7c3aed', 
                                    border: 'none', fontSize: '10px', fontWeight: '800', 
                                    cursor: 'pointer' 
                                  }}
                                >
                                  <Eye size={12} /> View Full
                                </button>
                              </div>
                            ) : (
                              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-dim)' }}>
                                <AlertCircle size={14} />
                                <span style={{ fontSize: '11px', fontStyle: 'italic' }}>{sub ? 'No image attachment' : 'Not submitted yet'}</span>
                              </div>
                            )}
                          </td>
                          <td style={{ padding: '16px' }}>
                            <span style={{ 
                              padding: '4px 10px', borderRadius: '20px', fontSize: '10px', fontWeight: '900',
                              background: sub ? 'rgba(16, 185, 129, 0.1)' : 'rgba(245, 158, 11, 0.1)', 
                              color: sub ? '#10b981' : '#f59e0b' 
                            }}>
                              {sub ? (String(sub.status).toUpperCase() === 'GRADED' ? 'GRADED' : 'SUBMITTED') : 'PENDING'}
                            </span>
                          </td>
                          <td style={{ padding: '16px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                               <input id={`marks-${s.id}`} defaultValue={sub?.marks || ''} type="number" placeholder="0" style={{ width: '50px', padding: '6px', borderRadius: '8px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', textAlign: 'center', fontWeight: '700' }} />
                               <span style={{ fontSize: '10px', color: 'var(--text-dim)', fontWeight: '700' }}>/{selectedAssignmentForGrading.max_marks || 100}</span>
                            </div>
                          </td>
                          <td style={{ padding: '16px', textAlign: 'right' }}>
                            <button 
                              onClick={async (e) => {
                                const btn = e.currentTarget;
                                btn.disabled = true;
                                const originalText = btn.innerHTML;
                                btn.innerHTML = '...';
                                
                                const m = document.getElementById(`marks-${s.id}`).value;
                                try {
                                  if (sub) await updateDoc(doc(db, 'submissions', sub.id), { marks: parseFloat(m), status: 'graded', graded_at: serverTimestamp() });
                                  else await addDoc(collection(db, 'submissions'), { student_id: s.id, assignment_id: selectedAssignmentForGrading.id, marks: parseFloat(m), status: 'graded', created_at: serverTimestamp(), content: '[Manual Grading]' });
                                  alert('Grade Synced for ' + s.name);
                                } catch (err) { alert('Sync Failed: ' + err.message); }
                                finally {
                                  btn.disabled = false;
                                  btn.innerHTML = originalText;
                                }
                              }}
                              style={{ padding: '8px 16px', borderRadius: '10px', background: '#6366f1', color: 'white', border: 'none', fontSize: '11px', fontWeight: '900', cursor: 'pointer' }}
                            >
                              Sync Grade
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Photo Preview Modal */}
      <AnimatePresence>
        {previewFile && (
          <div 
            onClick={() => setPreviewFile(null)}
            style={{ position: 'fixed', inset: 0, zIndex: 10000, background: 'rgba(0,0,0,0.95)', backdropFilter: 'blur(15px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}
          >
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }} 
              animate={{ scale: 1, opacity: 1 }} 
              exit={{ scale: 0.9, opacity: 0 }} 
              onClick={(e) => e.stopPropagation()}
              style={{ position: 'relative', maxWidth: '100%', maxHeight: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center' }}
            >
              <button 
                onClick={() => setPreviewFile(null)} 
                style={{ position: 'absolute', top: '-50px', right: '0', background: 'white', border: 'none', color: 'black', cursor: 'pointer', padding: '8px', borderRadius: '50%', display: 'flex', boxShadow: '0 10px 20px rgba(0,0,0,0.3)' }}
              >
                <XCircle size={24} />
              </button>
              
              <div style={{ background: 'white', padding: '12px', borderRadius: '24px', boxShadow: '0 30px 60px rgba(0,0,0,0.5)', overflow: 'hidden' }}>
                <img src={previewFile} alt="Submission" style={{ maxWidth: '90vw', maxHeight: '80vh', display: 'block', borderRadius: '12px' }} />
                
                <div style={{ marginTop: '16px', display: 'flex', justifyContent: 'center', gap: '16px' }}>
                  <a 
                    href={previewFile} 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    style={{ background: '#6366f1', color: 'white', padding: '10px 20px', borderRadius: '12px', textDecoration: 'none', fontSize: '13px', fontWeight: '800', display: 'flex', alignItems: 'center', gap: '8px' }}
                  >
                    <ExternalLink size={16} /> Open Original
                  </a>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default AssignmentsHub;
