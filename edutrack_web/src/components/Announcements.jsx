import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, addDoc, onSnapshot, query, orderBy, serverTimestamp, deleteDoc, doc } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { Bell, Send, Trash, Users, GraduationCap, Globe, Search, Filter, Megaphone, Info, Calendar, Bookmark } from 'lucide-react';

export default function Announcements({ role, user, classes, fullUserData }) {
  const [announcements, setAnnouncements] = useState([]);
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [target, setTarget] = useState('all');
  const [category, setCategory] = useState('General');
  const [selectedClassId, setSelectedClassId] = useState('');
  const [sending, setSending] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'announcements'), orderBy('timestamp', 'desc')),
      (snap) => setAnnouncements(snap.docs.map(d => ({ id: d.id, ...d.data() })))
    );
    return unsub;
  }, []);

  const sendAnnouncement = async (e) => {
    e.preventDefault();
    if (!title.trim() || !message.trim()) return alert('Please fill all fields');
    setSending(true);
    try {
      await addDoc(collection(db, 'announcements'), {
        title: title.trim(),
        message: message.trim(),
        target,
        category,
        ...(target === 'class' && { class_id: selectedClassId }),
        timestamp: serverTimestamp(),
        sender_id: user.uid,
        sender_name: fullUserData?.name || 'Academic Office',
        type: 'announcement'
      });
      // Also create notification for mobile app
      await addDoc(collection(db, 'notifications'), {
        title: `[${category}] ${title.trim()}`,
        message: message.trim(),
        type: 'announcement',
        category,
        target,
        ...(target === 'class' && { class_id: selectedClassId }),
        timestamp: serverTimestamp(),
        sender_id: user.uid,
      });
      setTitle(''); setMessage(''); setTarget('all'); setSelectedClassId(''); setCategory('General');
      setShowForm(false);
    } catch (err) {
      console.error(err);
      alert('Failed to broadcast bulletin');
    }
    setSending(false);
  };

  const deleteAnnouncement = async (id) => {
    if (!window.confirm('Archive this bulletin?')) return;
    await deleteDoc(doc(db, 'announcements', id));
  };

  const filtered = announcements.filter(a =>
    a.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    a.message?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    a.category?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getCategoryIcon = (cat) => {
    switch (cat) {
      case 'Event': return <Calendar size={14} />;
      case 'Academic': return <GraduationCap size={14} />;
      case 'Holiday': return <Bookmark size={14} />;
      default: return <Info size={14} />;
    }
  };

  const getCategoryColor = (cat) => {
    switch (cat) {
      case 'Event': return '#3b82f6';
      case 'Academic': return '#8b5cf6';
      case 'Holiday': return '#f59e0b';
      default: return '#10b981';
    }
  };

  const targetLabel = (t, classId) => {
    if (t === 'all') return 'Global';
    if (t === 'teachers') return 'Faculty';
    if (t === 'class') {
      const cls = classes.find(c => c.id === classId);
      return cls ? cls.displayName || cls.name || classId : classId;
    }
    return t;
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px' }}>
        <div>
          <h2 style={{ fontSize: '28px', margin: 0, fontWeight: '900' }}>
            <span className="gradient-text">Academic Bulletins</span>
          </h2>
          <p style={{ color: 'var(--text-dim)', fontSize: '14px', marginTop: '4px', fontWeight: '600' }}>
            Official institutional updates and news feed
          </p>
        </div>
        {role === 'admin' && (
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => setShowForm(!showForm)}
            style={{
              display: 'flex', alignItems: 'center', gap: '8px',
              padding: '12px 24px', borderRadius: '14px', fontSize: '14px',
              background: 'linear-gradient(135deg, var(--primary), var(--secondary))',
              color: 'white', border: 'none', fontWeight: '800',
              boxShadow: '0 10px 20px rgba(236, 72, 153, 0.2)',
              cursor: 'pointer'
            }}
          >
            <Megaphone size={16} /> {showForm ? 'Discard Draft' : 'Create New Bulletin'}
          </motion.button>
        )}
      </div>

      {/* Create Form */}
      {showForm && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-card"
          style={{ padding: '32px', marginBottom: '32px', border: '1px solid var(--glass-border)' }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
            <div style={{ padding: '8px', background: 'rgba(236, 72, 153, 0.1)', borderRadius: '10px', color: 'var(--primary)' }}>
              <Bookmark size={20} />
            </div>
            <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '800', color: 'var(--text-main)' }}>Compose New Bulletin</h3>
          </div>

          <form onSubmit={sendAnnouncement} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr', gap: '16px' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <label style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Bulletin Title</label>
                <input
                  className="glass-input"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g., Annual Sports Meet 2024"
                  required
                  style={{ padding: '14px', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)' }}
                />
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <label style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Category</label>
                <select
                  className="glass-input"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  style={{ padding: '14px', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', cursor: 'pointer' }}
                >
                  <option value="General" style={{ background: '#0f172a', color: 'white' }}>General</option>
                  <option value="Academic" style={{ background: '#0f172a', color: 'white' }}>Academic</option>
                  <option value="Event" style={{ background: '#0f172a', color: 'white' }}>Event</option>
                  <option value="Holiday" style={{ background: '#0f172a', color: 'white' }}>Holiday</option>
                </select>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <label style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Target Scope</label>
                <select
                  className="glass-input"
                  value={target}
                  onChange={(e) => setTarget(e.target.value)}
                  style={{ padding: '14px', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', cursor: 'pointer' }}
                >
                  <option value="all" style={{ background: '#0f172a', color: 'white' }}>Entire School</option>
                  <option value="teachers" style={{ background: '#0f172a', color: 'white' }}>Faculty Only</option>
                  <option value="class" style={{ background: '#0f172a', color: 'white' }}>Specific Hub</option>
                </select>
              </div>
            </div>

            {target === 'class' && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <label style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Select Target Hub</label>
                <select
                  className="glass-input"
                  value={selectedClassId}
                  onChange={(e) => setSelectedClassId(e.target.value)}
                  required
                  style={{ padding: '14px', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)' }}
                >
                  <option value="" style={{ background: '#0f172a', color: 'white' }}>Choose a Hub...</option>
                  {classes.map(c => (
                    <option key={c.id} value={c.id} style={{ background: '#0f172a', color: 'white' }}>{c.displayName || c.name || c.id}</option>
                  ))}
                </select>
              </motion.div>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <label style={{ fontSize: '11px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Detailed Content</label>
              <textarea
                className="glass-input"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Provide comprehensive details about this update..."
                rows={5}
                style={{ resize: 'none', padding: '16px', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)' }}
                required
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              <button
                type="button"
                onClick={() => setShowForm(false)}
                style={{
                  padding: '14px 28px', borderRadius: '12px', background: 'rgba(255,255,255,0.03)',
                  color: 'var(--text-dim)', border: '1px solid var(--glass-border)',
                  fontWeight: '700', cursor: 'pointer'
                }}
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={sending}
                style={{
                  padding: '14px 40px', borderRadius: '12px', fontSize: '15px', fontWeight: '800',
                  background: 'linear-gradient(135deg, var(--primary), var(--secondary))',
                  color: 'white', border: 'none', cursor: 'pointer',
                  boxShadow: '0 10px 20px rgba(236, 72, 153, 0.3)',
                  opacity: sending ? 0.6 : 1, display: 'flex', alignItems: 'center', gap: '10px'
                }}
              >
                <Send size={18} /> {sending ? 'Transmitting...' : 'Post Bulletin'}
              </button>
            </div>
          </form>
        </motion.div>
      )}

      {/* Filters & Search */}
      <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
        <div style={{ position: 'relative', flex: 1 }}>
          <Search size={18} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
          <input
            className="glass-input"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search bulletins by title, content or category..."
            style={{ width: '100%', padding: '14px 14px 14px 48px', fontSize: '14px', background: 'rgba(255,255,255,0.03)' }}
          />
        </div>
      </div>

      {/* Bulletins Feed */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {filtered.length === 0 ? (
          <div className="glass-card" style={{ padding: '80px', textAlign: 'center', color: 'var(--text-dim)' }}>
            <Megaphone size={48} style={{ opacity: 0.2, marginBottom: '16px', color: 'var(--primary)' }} />
            <p style={{ fontSize: '18px', fontWeight: '700', margin: '0 0 8px 0' }}>Feed is empty</p>
            <p style={{ fontSize: '14px' }}>Official bulletins will appear here once broadcasted.</p>
          </div>
        ) : (
          filtered.map((a, idx) => (
            <motion.div
              key={a.id}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: idx * 0.05 }}
              className="glass-card bulletin-card"
              style={{ padding: '24px', borderLeft: `4px solid ${getCategoryColor(a.category)}` }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '8px', marginBottom: '12px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '4px 10px', borderRadius: '8px', background: `${getCategoryColor(a.category)}15`, color: getCategoryColor(a.category), fontSize: '10px', fontWeight: '900', textTransform: 'uppercase' }}>
                      {getCategoryIcon(a.category)}
                      {a.category || 'General'}
                    </div>
                    <div style={{ padding: '4px 10px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', color: 'var(--text-dim)', fontSize: '10px', fontWeight: '900', textTransform: 'uppercase', border: '1px solid var(--glass-border)' }}>
                      {targetLabel(a.target, a.class_id)}
                    </div>
                  </div>

                  <h4 style={{ margin: '0 0 10px 0', fontSize: '18px', fontWeight: '800', color: 'var(--text-main)' }}>{a.title}</h4>
                  <p style={{ color: 'var(--text-main)', opacity: 0.8, fontSize: '14px', lineHeight: '1.7', margin: '0 0 16px 0' }}>{a.message}</p>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '16px', borderTop: '1px solid var(--glass-border)', paddingTop: '16px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <div style={{ width: '24px', height: '24px', borderRadius: '50%', background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: 'bold' }}>
                        {a.sender_name?.charAt(0) || 'A'}
                      </div>
                      <span style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-main)' }}>{a.sender_name || 'Academic Office'}</span>
                    </div>
                    <div style={{ fontSize: '12px', color: 'var(--text-dim)', fontWeight: '600' }}>
                      {a.timestamp?.toDate?.()?.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) || 'Just now'}
                    </div>
                  </div>
                </div>
                {role === 'admin' && (
                  <motion.button
                    whileHover={{ scale: 1.1, background: '#ef4444', color: 'white' }}
                    onClick={() => deleteAnnouncement(a.id)}
                    style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', padding: '10px', borderRadius: '12px', border: 'none', cursor: 'pointer', transition: 'all 0.2s' }}
                  >
                    <Trash size={16} />
                  </motion.button>
                )}
              </div>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
}
