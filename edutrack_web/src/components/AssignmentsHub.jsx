import React, { useState } from 'react';
import {
  Layers, Clock, ClipboardList, CheckCircle, BookOpen, Users, FileText, Trash, Zap, ArrowLeft, PlusCircle, Calendar, TrendingUp
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

  const availableSubjects = fullUserData?.specialization || fullUserData?.subjects || ['Mathematics', 'Science', 'English', 'History', 'Geography', 'Physics', 'Chemistry', 'Biology', 'Computer Science'];
  const isAdmin = fullUserData?.role === 'admin';
  const myAssignments = (assignments || []).filter(a => isAdmin ? true : a.teacher_id === user?.uid);
  
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
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px', minHeight: '100vh', paddingBottom: '40px' }}>
      
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
            <button 
              onClick={() => { setActiveView('create'); setCurrentStep(1); }}
              style={{ background: 'white', color: '#6366f1', border: 'none', padding: '12px 24px', borderRadius: '12px', fontWeight: '900', fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', boxShadow: '0 8px 20px rgba(0,0,0,0.1)' }}
            >
              <PlusCircle size={20} /> New Assignment
            </button>
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
                <div key={i} className="glass-card" style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '16px', borderRadius: '24px', border: '1px solid #f1f5f9', background: 'white', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
                  <div style={{ width: '48px', height: '48px', borderRadius: '14px', background: `${s.color}15`, color: s.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    {s.icon}
                  </div>
                  <div>
                    <div style={{ fontSize: '12px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{s.label}</div>
                    <div style={{ fontSize: '24px', fontWeight: '900', color: '#0f172a', marginTop: '2px' }}>{s.value}</div>
                  </div>
                </div>
              ))}
            </div>

            {/* Main Registry Table */}
            <div className="glass-card" style={{ background: 'white', borderRadius: '32px', border: '1px solid #f1f5f9', overflow: 'hidden', boxShadow: '0 4px 30px rgba(0,0,0,0.03)' }}>
              <div style={{ padding: '28px 32px', borderBottom: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', gap: '12px' }}>
                  {['all', 'pending', 'submitted', 'graded'].map(t => (
                    <button
                      key={t}
                      onClick={() => setAssignmentTab(t)}
                      style={{
                        padding: '10px 20px',
                        borderRadius: '12px',
                        border: 'none',
                        background: assignmentTab === t ? '#6366f1' : '#f8fafc',
                        color: assignmentTab === t ? 'white' : '#64748b',
                        fontSize: '13px',
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
                    <tr style={{ borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
                      <th style={{ padding: '16px 32px', fontSize: '12px', fontWeight: '800', color: '#475569', textTransform: 'uppercase' }}>Mission Deployment</th>
                      <th style={{ padding: '16px 20px', fontSize: '12px', fontWeight: '800', color: '#475569', textTransform: 'uppercase' }}>Target Hub</th>
                      <th style={{ padding: '16px 20px', fontSize: '12px', fontWeight: '800', color: '#475569', textTransform: 'uppercase' }}>Telemetry</th>
                      <th style={{ padding: '16px 32px', fontSize: '12px', fontWeight: '800', color: '#475569', textTransform: 'uppercase', textAlign: 'right' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {myAssignments
                      .filter(a => {
                        if (assignmentTab === 'all') return true;
                        const subs = submissions.filter(s => s.assignment_id === a.id);
                        const targetClass = classes.find(c => c.id === a.class_id);
                        const totalInClass = students.filter(s =>
                          (s.class_id === a.class_id) || (s.classId === a.class_id) || (targetClass && s.classId === targetClass.displayName)
                        ).length;
                        if (assignmentTab === 'pending') return subs.length < totalInClass || subs.length === 0;
                        if (assignmentTab === 'submitted') return subs.length > 0 && subs.some(s => String(s.status).toLowerCase() !== 'graded');
                        if (assignmentTab === 'graded') return subs.length > 0 && subs.every(s => String(s.status).toLowerCase() === 'graded');
                        return true;
                      })
                      .map((a) => {
                        const subs = submissions.filter(s => s.assignment_id === a.id);
                        const targetClass = classes.find(c => c.id === a.class_id);
                        const totalInClass = students.filter(s =>
                          (s.class_id === a.class_id) || (s.classId === a.class_id) || (targetClass && s.classId === targetClass.displayName)
                        ).length;
                        const gradedCount = subs.filter(s => String(s.status).toLowerCase() === 'graded').length;
                        const progress = totalInClass > 0 ? (subs.length / totalInClass) * 100 : 0;

                        return (
                          <tr key={a.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '24px 32px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                                <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#f5f3ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#7c3aed' }}>
                                  <BookOpen size={20} />
                                </div>
                                <div>
                                  <div style={{ fontWeight: '800', color: '#0f172a', fontSize: '15px' }}>{a.title}</div>
                                  <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>{a.subject}</div>
                                </div>
                              </div>
                            </td>
                            <td style={{ padding: '24px 20px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#334155', fontWeight: '700', fontSize: '14px' }}>
                                <Users size={16} /> {classes.find(c => c.id === a.class_id)?.displayName || 'Global'}
                              </div>
                            </td>
                            <td style={{ padding: '24px 20px' }}>
                              <div style={{ width: '140px' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', marginBottom: '8px', fontWeight: '800' }}>
                                  <span style={{ color: '#64748b' }}>{subs.length}/{totalInClass}</span>
                                  <span style={{ color: '#6366f1' }}>{Math.round(progress)}%</span>
                                </div>
                                <div style={{ width: '100%', height: '6px', background: '#f1f5f9', borderRadius: '3px', overflow: 'hidden' }}>
                                  <div style={{ width: `${progress}%`, height: '100%', background: '#6366f1', borderRadius: '3px' }}></div>
                                </div>
                              </div>
                            </td>
                            <td style={{ padding: '24px 32px', textAlign: 'right' }}>
                              <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
                                <button
                                  onClick={() => { setSelectedAssignmentForGrading(a); setActiveView('review'); }}
                                  style={{ padding: '8px 16px', borderRadius: '10px', background: '#f1f5f9', color: '#475569', border: 'none', fontSize: '12px', fontWeight: '800', cursor: 'pointer' }}
                                >
                                  Review
                                </button>
                                <button
                                  onClick={async () => { if (window.confirm('Delete this mission?')) await deleteDoc(doc(db, 'assignments', a.id)); }}
                                  style={{ width: '36px', height: '36px', borderRadius: '10px', background: '#fef2f2', color: '#ef4444', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}
                                >
                                  <Trash size={18} />
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

        {activeView === 'create' && (
          <motion.div 
            key="create"
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.98 }}
            style={{ maxWidth: '800px', margin: '0 auto' }}
          >
            {/* Step Progress Bar */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '20px', marginBottom: '40px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: currentStep >= 1 ? '#6366f1' : '#e2e8f0', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800', fontSize: '14px' }}>1</div>
                <span style={{ fontWeight: '700', color: currentStep >= 1 ? '#0f172a' : '#94a3b8' }}>Mission Data</span>
              </div>
              <div style={{ width: '60px', height: '2px', background: currentStep >= 2 ? '#6366f1' : '#e2e8f0' }}></div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: currentStep >= 2 ? '#6366f1' : '#e2e8f0', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: '800', fontSize: '14px' }}>2</div>
                <span style={{ fontWeight: '700', color: currentStep >= 2 ? '#0f172a' : '#94a3b8' }}>Intelligence Assets</span>
              </div>
            </div>

            <div className="glass-card" style={{ padding: '40px', background: 'white', borderRadius: '32px', border: '1px solid #f1f5f9', boxShadow: '0 20px 50px rgba(0,0,0,0.05)' }}>
              <form onSubmit={async (e) => {
                e.preventDefault();
                const formData = new FormData(e.target);
                if (currentStep === 1) {
                  setCurrentStep(2);
                  return;
                }
                
                try {
                  const dueDate = new Date(formData.get('due_date'));
                  await addDoc(collection(db, 'assignments'), {
                    title: String(formData.get('title') || 'Untitled'),
                    subject: String(formData.get('subject') || 'General'),
                    description: String(formData.get('description') || ''),
                    max_marks: parseFloat(formData.get('max_marks') || '0'),
                    due_date: Timestamp.fromDate(dueDate),
                    class_id: String(formData.get('class') || ''),
                    teacher_id: user.uid,
                    file_url: assignmentFileUrl || null,
                    created_at: serverTimestamp()
                  });
                  alert('Mission Deployed! 🚀');
                  setActiveView('manage');
                } catch (err) { alert('Deployment Error: ' + err.message); }
              }}>
                
                {currentStep === 1 && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
                    <div>
                      <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Mission Title</label>
                      <input name="title" required placeholder="e.g. Quantum Mechanics Assignment" style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '15px' }} />
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                      <div>
                        <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Subject</label>
                        <select name="subject" required style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '15px' }}>
                          {availableSubjects.map(s => <option key={s} value={s}>{s}</option>)}
                        </select>
                      </div>
                      <div>
                        <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Target Class</label>
                        <select name="class" required style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '15px' }}>
                          {classes.map(c => <option key={c.id} value={c.id}>{c.displayName || c.standard}</option>)}
                        </select>
                      </div>
                    </div>
                    <button type="submit" style={{ width: '100%', padding: '18px', background: '#6366f1', color: 'white', borderRadius: '16px', fontWeight: '900', border: 'none', cursor: 'pointer', fontSize: '16px' }}>
                      Continue to Assets
                    </button>
                  </div>
                )}

                {currentStep === 2 && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                      <div>
                        <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Max Marks</label>
                        <input name="max_marks" type="number" required placeholder="100" style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '15px' }} />
                      </div>
                      <div>
                        <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '8px', display: 'block' }}>Due Horizon</label>
                        <input name="due_date" type="datetime-local" required style={{ width: '100%', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', background: '#f8fafc', fontSize: '15px' }} />
                      </div>
                    </div>
                    <div>
                      <label style={{ fontSize: '14px', fontWeight: '700', color: '#475569', marginBottom: '12px', display: 'block' }}>Intelligence Assets (PDF/JPG)</label>
                      <div onClick={() => document.getElementById('assignment-file-input').click()} style={{ padding: '40px', borderRadius: '24px', border: '2px dashed #cbd5e1', textAlign: 'center', cursor: 'pointer', background: assignmentFile ? '#f5f3ff' : '#f8fafc', transition: 'all 0.2s' }}>
                        <input id="assignment-file-input" type="file" hidden onChange={handleAssignmentFileChange} />
                        <Zap size={32} color={assignmentFile ? '#7c3aed' : '#94a3b8'} style={{ marginBottom: '12px' }} />
                        <div style={{ fontWeight: '800', color: '#1e293b' }}>{assignmentFile ? assignmentFile.name : 'Upload Mission Dossier'}</div>
                        <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>Supported formats: PDF, PNG, JPG (Max 10MB)</div>
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: '16px' }}>
                      <button type="button" onClick={() => setCurrentStep(1)} style={{ flex: 1, padding: '18px', background: '#f1f5f9', color: '#475569', borderRadius: '16px', fontWeight: '900', border: 'none', cursor: 'pointer' }}>Back</button>
                      <button type="submit" style={{ flex: 2, padding: '18px', background: '#6366f1', color: 'white', borderRadius: '16px', fontWeight: '900', border: 'none', cursor: 'pointer' }}>Deploy Mission</button>
                    </div>
                  </div>
                )}
              </form>
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
            <div className="glass-card" style={{ padding: '32px', background: 'white', borderRadius: '32px', border: '1px solid #f1f5f9', boxShadow: '0 4px 30px rgba(0,0,0,0.03)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
                <h3 style={{ margin: 0, fontSize: '20px', fontWeight: '900' }}>Member Roster & Grading</h3>
                <div style={{ fontSize: '14px', fontWeight: '700', color: '#64748b' }}>
                  Submissions: {submissions.filter(s => s.assignment_id === selectedAssignmentForGrading.id).length}
                </div>
              </div>
              
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ background: '#f8fafc' }}>
                      <th style={{ padding: '16px', fontSize: '12px', fontWeight: '800', color: '#475569', textTransform: 'uppercase' }}>Member</th>
                      <th style={{ padding: '16px', fontSize: '12px', fontWeight: '800', color: '#475569', textTransform: 'uppercase' }}>Status</th>
                      <th style={{ padding: '16px', fontSize: '12px', fontWeight: '800', color: '#475569', textTransform: 'uppercase' }}>Marks</th>
                      <th style={{ padding: '16px', fontSize: '12px', fontWeight: '800', color: '#475569', textTransform: 'uppercase', textAlign: 'right' }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {students.filter(s => s.class_id === selectedAssignmentForGrading.class_id || s.classId === selectedAssignmentForGrading.class_id).map(s => {
                      const sub = submissions.find(sub => sub.student_id === s.id && sub.assignment_id === selectedAssignmentForGrading.id);
                      return (
                        <tr key={s.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                          <td style={{ padding: '16px' }}>
                            <div style={{ fontWeight: '700', fontSize: '14px' }}>{s.name}</div>
                            <div style={{ fontSize: '11px', color: '#64748b' }}>{s.roll_no || '--'}</div>
                          </td>
                          <td style={{ padding: '16px' }}>
                            <span style={{ fontSize: '11px', fontWeight: '800', color: sub ? '#10b981' : '#f59e0b' }}>
                              {sub ? 'SUBMITTED' : 'PENDING'}
                            </span>
                          </td>
                          <td style={{ padding: '16px' }}>
                            <input id={`marks-${s.id}`} defaultValue={sub?.marks || ''} type="number" placeholder="0" style={{ width: '60px', padding: '8px', borderRadius: '8px', border: '1px solid #e2e8f0', textAlign: 'center' }} />
                          </td>
                          <td style={{ padding: '16px', textAlign: 'right' }}>
                            <button 
                              onClick={async () => {
                                const m = document.getElementById(`marks-${s.id}`).value;
                                if (sub) await updateDoc(doc(db, 'submissions', sub.id), { marks: parseFloat(m), status: 'graded', graded_at: serverTimestamp() });
                                else await addDoc(collection(db, 'submissions'), { student_id: s.id, assignment_id: selectedAssignmentForGrading.id, marks: parseFloat(m), status: 'graded', created_at: serverTimestamp() });
                                alert('Grade Synced!');
                              }}
                              style={{ padding: '6px 12px', borderRadius: '8px', background: '#6366f1', color: 'white', border: 'none', fontSize: '11px', fontWeight: '800' }}
                            >
                              Sync
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
    </div>
  );
};

export default AssignmentsHub;
