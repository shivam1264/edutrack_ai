import React, { useState, useMemo } from 'react';
import { 
  Calendar, 
  Trash, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  Filter, 
  Search, 
  User, 
  ArrowRight, 
  MoreVertical, 
  Wifi,
  FileText,
  AlertCircle
} from 'lucide-react';
import { doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';

const LeaveHub = ({ leaves, db, fullUserData, role, visibleClasses }) => {
  const [filter, setFilter] = useState('pending'); // 'all', 'pending', 'approved', 'rejected'
  const [searchQuery, setSearchQuery] = useState('');
  const [processingId, setProcessingId] = useState(null);

  // Filter leaves based on search, status, and teacher role (classes)
  const filteredLeaves = useMemo(() => {
    let result = (leaves || []).filter(l => {
      // 1. Role-based filtering for teachers
      if (role === 'teacher') {
        const isMyClass = visibleClasses.some(c => c.id === l.classId || c.displayName === l.classId || c.id === l.class_id);
        if (!isMyClass) return false;
      }
      return true;
    });

    // 2. Status Filtering
    if (filter !== 'all') {
      result = result.filter(l => l.status === filter);
    }

    // 3. Search Filtering
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      result = result.filter(l => 
        l.studentName?.toLowerCase().includes(q) || 
        l.reason?.toLowerCase().includes(q) ||
        l.subject?.toLowerCase().includes(q)
      );
    }

    return result.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0));
  }, [leaves, filter, searchQuery, role, visibleClasses]);

  const handleStatusUpdate = async (id, newStatus) => {
    setProcessingId(id);
    try {
      await updateDoc(doc(db, 'leave_requests', id), { 
        status: newStatus,
        processedBy: fullUserData?.name || 'Teacher',
        processedAt: new Date().toISOString()
      });
    } catch (e) {
      alert('Error updating leave status: ' + e.message);
    } finally {
      setProcessingId(null);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Delete this leave record?')) {
      try {
        await deleteDoc(doc(db, 'leave_requests', id));
      } catch (e) {
        alert('Error deleting leave: ' + e.message);
      }
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', minHeight: '80vh' }}>
      
      {/* Dynamic Header */}
      <div style={{ 
        background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', 
        padding: '32px', 
        borderRadius: '24px',
        color: 'white',
        position: 'relative',
        overflow: 'hidden',
        boxShadow: '0 20px 40px rgba(13, 148, 136, 0.2)'
      }}>
        <div style={{ position: 'relative', zIndex: 1 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '24px' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: 'rgba(255,255,255,0.2)', padding: '4px 12px', borderRadius: '20px', width: 'fit-content', marginBottom: '12px' }}>
                <div className="pulse-dot" style={{ width: '8px', height: '8px', background: '#4ade80', borderRadius: '50%' }}></div>
                <span style={{ fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', letterSpacing: '1px' }}>Live Sync Active</span>
              </div>
              <h1 style={{ fontSize: '32px', fontWeight: '900', margin: 0, letterSpacing: '-1px' }}>Leave Approvals</h1>
              <p style={{ margin: '4px 0 0 0', opacity: 0.8, fontWeight: '500' }}>Manage student absence requests in real-time.</p>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '32px', fontWeight: '900' }}>{leaves.filter(l => {
                if (role === 'teacher') {
                  return l.status === 'pending' && visibleClasses.some(c => c.id === l.classId || c.displayName === l.classId || c.id === l.class_id);
                }
                return l.status === 'pending';
              }).length}</div>
              <div style={{ fontSize: '10px', fontWeight: '800', opacity: 0.8, textTransform: 'uppercase' }}>Pending Requests</div>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
            <div style={{ position: 'relative', flex: 1 }}>
              <Search size={18} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#64748b', zIndex: 1 }} />
              <input 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by student or reason..."
                style={{ width: '100%', padding: '12px 12px 12px 48px', borderRadius: '14px', border: 'none', background: 'white', color: '#1e293b', outline: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
              />
            </div>
            <div style={{ display: 'flex', background: 'rgba(255,255,255,0.1)', padding: '4px', borderRadius: '14px', backdropFilter: 'blur(10px)' }}>
              {['all', 'pending', 'approved', 'rejected'].map(t => (
                <button
                  key={t}
                  onClick={() => setFilter(t)}
                  style={{
                    padding: '8px 16px',
                    borderRadius: '10px',
                    border: 'none',
                    background: filter === t ? 'white' : 'transparent',
                    color: filter === t ? '#0f766e' : 'white',
                    fontWeight: '800',
                    fontSize: '12px',
                    cursor: 'pointer',
                    textTransform: 'uppercase',
                    transition: 'all 0.2s ease'
                  }}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Requests Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '20px' }}>
        <AnimatePresence>
          {filteredLeaves.map((leave) => (
            <motion.div
              layout
              key={leave.id}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="glass-card"
              style={{ padding: '24px', position: 'relative', border: '1px solid var(--glass-border)', display: 'flex', flexDirection: 'column', gap: '16px' }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                  <div style={{ 
                    width: '48px', 
                    height: '48px', 
                    borderRadius: '14px', 
                    background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'white',
                    fontSize: '18px',
                    fontWeight: '900'
                  }}>
                    {leave.studentName?.charAt(0) || 'S'}
                  </div>
                  <div>
                    <h4 style={{ margin: 0, fontSize: '16px', fontWeight: '800' }}>{leave.studentName}</h4>
                    <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-dim)', fontWeight: '600' }}>{leave.className || 'Class TBD'} • {leave.rollNo || 'ID TBD'}</p>
                  </div>
                </div>
                <div style={{ 
                  padding: '4px 10px', 
                  borderRadius: '8px', 
                  fontSize: '10px', 
                  fontWeight: '900', 
                  textTransform: 'uppercase',
                  background: leave.status === 'pending' ? 'rgba(245, 158, 11, 0.1)' : (leave.status === 'approved' ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)'),
                  color: leave.status === 'pending' ? '#f59e0b' : (leave.status === 'approved' ? '#10b981' : '#ef4444')
                }}>
                  {leave.status}
                </div>
              </div>

              <div style={{ background: 'var(--glass-surface)', padding: '16px', borderRadius: '16px', border: '1px solid var(--glass-border)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                  <Calendar size={14} color="#0d9488" />
                  <span style={{ fontSize: '13px', fontWeight: '800', color: 'var(--text-main)' }}>{leave.startDate} to {leave.endDate}</span>
                </div>
                <p style={{ margin: 0, fontSize: '14px', color: 'var(--text-main)', opacity: 0.9, lineHeight: '1.5' }}>
                  <FileText size={14} style={{ display: 'inline', marginRight: '6px', opacity: 0.6 }} />
                  {leave.reason || "No reason provided."}
                </p>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 'auto' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-dim)', fontSize: '11px', fontWeight: '600' }}>
                  <Clock size={12} />
                  {leave.timestamp?.toDate ? leave.timestamp.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Just now'}
                </div>
                
                <div style={{ display: 'flex', gap: '8px' }}>
                  {leave.status === 'pending' ? (
                    <>
                      <button
                        disabled={processingId === leave.id}
                        onClick={() => handleStatusUpdate(leave.id, 'rejected')}
                        style={{ 
                          padding: '8px 16px', 
                          borderRadius: '10px', 
                          border: '1px solid #fee2e2', 
                          background: 'white', 
                          color: '#ef4444', 
                          fontSize: '12px', 
                          fontWeight: '800', 
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px'
                        }}
                      >
                        <XCircle size={14} /> Reject
                      </button>
                      <button
                        disabled={processingId === leave.id}
                        onClick={() => handleStatusUpdate(leave.id, 'approved')}
                        style={{ 
                          padding: '8px 16px', 
                          borderRadius: '10px', 
                          border: 'none', 
                          background: '#10b981', 
                          color: 'white', 
                          fontSize: '12px', 
                          fontWeight: '800', 
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px',
                          boxShadow: '0 4px 12px rgba(16, 185, 129, 0.2)'
                        }}
                      >
                        <CheckCircle2 size={14} /> Approve
                      </button>
                    </>
                  ) : (
                    <button
                      onClick={() => handleDelete(leave.id)}
                      style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', padding: '8px' }}
                    >
                      <Trash size={18} />
                    </button>
                  )}
                </div>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>

        {filteredLeaves.length === 0 && (
          <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '60px 20px' }}>
            <div style={{ width: '80px', height: '80px', background: 'var(--glass-surface)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
              <AlertCircle size={40} color="var(--text-dim)" />
            </div>
            <h3 style={{ margin: 0, color: 'var(--text-main)', fontSize: '20px', fontWeight: '800' }}>No Requests Found</h3>
            <p style={{ margin: '8px 0 0 0', color: 'var(--text-dim)', fontWeight: '500' }}>There are no {filter} leave requests matching your criteria.</p>
          </div>
        )}
      </div>

      <style>{`
        .pulse-dot {
          animation: pulse 2s infinite;
        }
        @keyframes pulse {
          0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(74, 222, 128, 0.7); }
          70% { transform: scale(1); box-shadow: 0 0 0 10px rgba(74, 222, 128, 0); }
          100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(74, 222, 128, 0); }
        }
      `}</style>
    </div>
  );
};

export default LeaveHub;
