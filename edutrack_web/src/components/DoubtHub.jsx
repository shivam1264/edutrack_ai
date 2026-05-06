import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Zap,
  Trash,
  MessageSquare,
  Clock,
  CheckCircle2,
  Filter,
  Search,
  User,
  ArrowRight,
  MoreVertical,
  X,
  Send,
  Sparkles,
  Wifi
} from 'lucide-react';
import { doc, updateDoc, serverTimestamp, deleteDoc } from 'firebase/firestore';

const DoubtHub = ({
  doubts,
  backendOnline,
  aiDoubtLoading,
  setAiDoubtLoading,
  generalChat,
  db,
  fullUserData
}) => {
  const [filter, setFilter] = useState('pending'); // 'all', 'pending', 'answered'
  const [searchQuery, setSearchQuery] = useState('');

  const filteredDoubts = useMemo(() => {
    return (doubts || [])
      .filter(d => {
        if (filter === 'all') return true;
        return d.status === filter;
      })
      .filter(d => {
        const query = searchQuery.toLowerCase();
        return (
          (d.question || '').toLowerCase().includes(query) ||
          (d.subject || '').toLowerCase().includes(query) ||
          (d.studentName || '').toLowerCase().includes(query)
        );
      })
      .sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));
  }, [doubts, filter, searchQuery]);

  const handleSubmitAnswer = async (doubtId, answer) => {
    if (!answer) return;
    try {
      await updateDoc(doc(db, 'doubts', doubtId), {
        answer: answer,
        status: 'answered',
        answeredBy: fullUserData?.name || 'Teacher',
        answeredAt: serverTimestamp()
      });
      // Clear input
      const inputEl = document.getElementById(`ans-${doubtId}`);
      if (inputEl) inputEl.value = '';
    } catch (err) {
      alert('Error submitting answer: ' + err.message);
    }
  };

  const handleDeleteDoubt = async (doubtId) => {
    if (window.confirm('Are you sure you want to delete this doubt?')) {
      await deleteDoc(doc(db, 'doubts', doubtId));
    }
  };

  const handleAiSuggest = async (doubt) => {
    setAiDoubtLoading(prev => ({ ...prev, [doubt.id]: true }));
    try {
      const result = await generalChat(doubt.question, 'teacher');
      const inputEl = document.getElementById(`ans-${doubt.id}`);
      if (inputEl) inputEl.value = result.answer || '';
    } catch (e) {
      alert('AI error: ' + e.message);
    } finally {
      setAiDoubtLoading(prev => ({ ...prev, [doubt.id]: false }));
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', minHeight: '80vh' }}>
      
      {/* Dynamic Header */}
      <div style={{ 
        background: 'linear-gradient(135deg, #7c3aed 0%, #4f46e5 100%)', 
        padding: '32px', 
        borderRadius: '24px',
        color: 'white',
        position: 'relative',
        overflow: 'hidden',
        boxShadow: '0 20px 40px rgba(79, 70, 229, 0.2)'
      }}>
        <div style={{ position: 'relative', zIndex: 1 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '24px' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', background: 'rgba(255,255,255,0.2)', padding: '4px 10px', borderRadius: '20px', fontSize: '10px', fontWeight: '800', textTransform: 'uppercase' }}>
                  <Wifi size={10} className="pulse-animation" /> Live Sync Active
                </div>
              </div>
              <h1 style={{ margin: 0, fontSize: '28px', fontWeight: '900', letterSpacing: '-0.5px' }}>Doubt Response Queue</h1>
              <p style={{ margin: '4px 0 0 0', opacity: 0.8, fontSize: '14px' }}>Real-time communication with your students</p>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '32px', fontWeight: '900' }}>{doubts.filter(d => d.status === 'pending').length}</div>
              <div style={{ fontSize: '10px', fontWeight: '800', opacity: 0.8, textTransform: 'uppercase' }}>Pending Doubts</div>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
            <div style={{ position: 'relative', flex: 1 }}>
              <Search size={18} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#64748b', zIndex: 1 }} />
              <input 
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by student, subject or question..."
                style={{ width: '100%', padding: '12px 12px 12px 48px', borderRadius: '14px', border: '1px solid rgba(255,255,255,0.3)', background: 'white', color: '#1e293b', outline: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
              />
            </div>
            <div style={{ display: 'flex', background: 'rgba(255,255,255,0.1)', padding: '4px', borderRadius: '14px', backdropFilter: 'blur(10px)' }}>
              {['all', 'pending', 'answered'].map(t => (
                <button
                  key={t}
                  onClick={() => setFilter(t)}
                  style={{
                    padding: '8px 16px',
                    borderRadius: '10px',
                    border: 'none',
                    background: filter === t ? 'white' : 'transparent',
                    color: filter === t ? '#4f46e5' : 'white',
                    fontWeight: '800',
                    fontSize: '12px',
                    cursor: 'pointer',
                    textTransform: 'uppercase',
                    transition: 'all 0.2s'
                  }}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>
        </div>
        <Sparkles size={180} style={{ position: 'absolute', right: '-40px', bottom: '-40px', opacity: 0.1, transform: 'rotate(-15deg)' }} />
      </div>

      {/* Doubts Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(380px, 1fr))', gap: '20px' }}>
        <AnimatePresence>
          {filteredDoubts.map(d => (
            <motion.div
              key={d.id}
              layout
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="glass-card"
              style={{ 
                padding: '24px', 
                background: 'var(--card-bg)', 
                border: '1px solid var(--glass-border)',
                position: 'relative',
                display: 'flex',
                flexDirection: 'column',
                gap: '16px',
                transition: 'transform 0.2s, box-shadow 0.2s'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: 'var(--glass-surface)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4f46e5', fontWeight: '800' }}>
                    {d.studentName ? d.studentName[0].toUpperCase() : <User size={20} />}
                  </div>
                  <div>
                    <h4 style={{ margin: 0, fontSize: '15px', fontWeight: '800' }}>{d.studentName || 'Unknown Student'}</h4>
                    <p style={{ margin: 0, fontSize: '11px', color: 'var(--text-dim)' }}>
                      {d.classId} • {d.subject}
                    </p>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <div style={{ 
                    padding: '4px 10px', 
                    borderRadius: '20px', 
                    fontSize: '10px', 
                    fontWeight: '900', 
                    background: d.status === 'pending' ? 'rgba(245, 158, 11, 0.1)' : 'rgba(16, 185, 129, 0.1)',
                    color: d.status === 'pending' ? '#f59e0b' : '#10b981',
                    textTransform: 'uppercase'
                  }}>
                    {d.status}
                  </div>
                  <button 
                    onClick={() => handleDeleteDoubt(d.id)}
                    style={{ background: 'transparent', border: 'none', color: 'var(--text-dim)', cursor: 'pointer', padding: '4px' }}
                  >
                    <Trash size={14} />
                  </button>
                </div>
              </div>

              <div style={{ flex: 1 }}>
                <p style={{ margin: 0, fontSize: '16px', fontWeight: '600', lineHeight: '1.5', color: 'var(--text-main)' }}>
                  "{d.question}"
                </p>
                {d.createdAt && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '12px', fontSize: '10px', color: 'var(--text-dim)' }}>
                    <Clock size={10} /> {new Date(d.createdAt.seconds * 1000).toLocaleString()}
                  </div>
                )}
              </div>

              {d.status === 'pending' ? (
                <div style={{ marginTop: '8px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <div style={{ position: 'relative' }}>
                    <textarea
                      id={`ans-${d.id}`}
                      placeholder="Type your academic response..."
                      rows={3}
                      style={{ 
                        width: '100%', 
                        padding: '16px', 
                        borderRadius: '16px', 
                        background: 'var(--input-bg)', 
                        color: 'var(--text-main)', 
                        border: '1px solid var(--glass-border)',
                        fontSize: '14px',
                        outline: 'none',
                        resize: 'none'
                      }}
                    />
                    {backendOnline && (
                      <button
                        disabled={aiDoubtLoading[d.id]}
                        onClick={() => handleAiSuggest(d)}
                        style={{ 
                          position: 'absolute', 
                          right: '12px', 
                          bottom: '12px', 
                          background: 'rgba(124, 58, 237, 0.1)', 
                          color: '#7c3aed',
                          border: 'none',
                          padding: '6px 12px',
                          borderRadius: '8px',
                          fontSize: '11px',
                          fontWeight: '800',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px'
                        }}
                      >
                        {aiDoubtLoading[d.id] ? <div className="spinning-loader" style={{ width: '12px', height: '12px' }} /> : <><Sparkles size={12} /> AI Help</>}
                      </button>
                    )}
                  </div>
                  <button
                    onClick={() => handleSubmitAnswer(d.id, document.getElementById(`ans-${d.id}`).value)}
                    style={{ 
                      width: '100%', 
                      padding: '14px', 
                      background: 'linear-gradient(135deg, #7c3aed, #4f46e5)', 
                      color: 'white', 
                      border: 'none', 
                      borderRadius: '14px', 
                      fontWeight: '800', 
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '8px',
                      boxShadow: '0 10px 20px rgba(79, 70, 229, 0.2)'
                    }}
                  >
                    Send Response <Send size={16} />
                  </button>
                </div>
              ) : (
                <div style={{ 
                  background: 'rgba(16, 185, 129, 0.03)', 
                  padding: '16px', 
                  borderRadius: '16px', 
                  border: '1px dotted #10b981',
                  marginTop: '8px'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px' }}>
                    <CheckCircle2 size={12} color="#10b981" />
                    <span style={{ fontSize: '11px', fontWeight: '900', color: '#10b981', textTransform: 'uppercase' }}>Resolution Log</span>
                  </div>
                  <p style={{ margin: 0, fontSize: '14px', color: 'var(--text-main)', opacity: 0.9 }}>{d.answer}</p>
                  <div style={{ marginTop: '12px', fontSize: '10px', color: 'var(--text-dim)', textAlign: 'right' }}>
                    Answered by {d.answeredBy}
                  </div>
                </div>
              )}
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {filteredDoubts.length === 0 && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', opacity: 0.5, gap: '16px' }}>
          <MessageSquare size={64} strokeWidth={1} />
          <div style={{ textAlign: 'center' }}>
            <h3 style={{ margin: 0 }}>Queue is Empty</h3>
            <p style={{ margin: 0, fontSize: '14px' }}>All student doubts have been resolved!</p>
          </div>
        </div>
      )}

      <style>{`
        .pulse-animation {
          animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: .5; }
        }
        .spinning-loader {
          border: 2px solid rgba(124, 58, 237, 0.2);
          border-top-color: #7c3aed;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
};

export default DoubtHub;
