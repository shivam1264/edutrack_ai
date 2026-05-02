import React, { useState, useEffect } from 'react';
import {
  Cpu, Zap, Save, Trash2, BookOpen, Layers, Clock, Target, ListChecks, FileText, ChevronRight, Share2, Download, CheckCircle, AlertCircle, Search, Plus, ExternalLink, GraduationCap, Book, Timer, Folder, RefreshCw, X
} from 'lucide-react';
import {
  collection, addDoc, query, where, onSnapshot, serverTimestamp, deleteDoc, doc, updateDoc, orderBy
} from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';
import { generateLessonPlan } from '../services/api';

const LessonPlanner = ({ user, db, classes, backendOnline }) => {
  const [plans, setPlans] = useState([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  
  const [formData, setFormData] = useState({
    subject: 'Mathematics',
    grade: '8th standard',
    topic: '',
    duration: '45 minutes'
  });

  useEffect(() => {
    if (!user) return;
    const q = query(
      collection(db, 'lesson_plans'),
      where('teacherId', '==', user.uid),
      orderBy('createdAt', 'desc')
    );
    
    const unsubscribe = onSnapshot(q, (snap) => {
      setPlans(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
    
    return () => unsubscribe();
  }, [user, db]);

  const handleGenerateAI = async () => {
    if (!formData.topic) {
      alert('Please enter a Topic / Chapter first.');
      return;
    }
    
    setIsGenerating(true);
    try {
      const response = await generateLessonPlan({
        topic: formData.topic,
        subject: formData.subject,
        grade: formData.grade,
        duration: formData.duration
      });
      
      const planContent = response.answer || response.plan;
      
      await addDoc(collection(db, 'lesson_plans'), {
        ...formData,
        title: formData.topic,
        activities: planContent,
        teacherId: user.uid,
        createdAt: serverTimestamp(),
        aiGenerated: true
      });
      
      setFormData(prev => ({ ...prev, topic: '' }));
    } catch (err) {
      console.error(err);
      alert('AI Generation failed.');
    } finally {
      setIsGenerating(false);
    }
  };

  const filteredPlans = plans.filter(p => 
    (p.title || p.topic || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (p.subject || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '380px 1fr', gap: '24px', height: 'calc(100vh - 180px)', minHeight: '600px' }}>
      
      {/* Plan Details Modal */}
      <AnimatePresence>
        {selectedPlan && (
          <motion.div 
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            style={{ position: 'fixed', inset: 0, background: 'rgba(15, 23, 42, 0.8)', backdropFilter: 'blur(12px)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '24px' }}
            onClick={() => setSelectedPlan(null)}
          >
            <motion.div 
              initial={{ scale: 0.95, y: 20 }} animate={{ scale: 1, y: 0 }}
              className="glass-card"
              style={{ width: '100%', maxWidth: '800px', maxHeight: '90vh', background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '24px', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}
              onClick={e => e.stopPropagation()}
            >
              <div style={{ background: 'linear-gradient(135deg, #1d4ed8, #3b82f6)', padding: '24px 32px', color: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <h2 style={{ margin: 0, fontSize: '20px', fontWeight: '800' }}>{selectedPlan.title || selectedPlan.topic}</h2>
                  <p style={{ margin: '4px 0 0 0', opacity: 0.9, fontSize: '13px', fontWeight: '600' }}>{selectedPlan.subject} • {selectedPlan.grade} • {selectedPlan.duration}</p>
                </div>
                <button onClick={() => setSelectedPlan(null)} style={{ background: 'rgba(255,255,255,0.2)', border: 'none', color: 'white', padding: '8px', borderRadius: '10px', cursor: 'pointer' }}>
                  <X size={20} />
                </button>
              </div>
              <div style={{ padding: '32px', overflowY: 'auto', flex: 1, color: 'var(--text-main)', fontSize: '15px', lineHeight: '1.8' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '20px', color: '#3b82f6' }}>
                  <Zap size={16} fill="#3b82f6" />
                  <span style={{ fontWeight: '900', textTransform: 'uppercase', fontSize: '11px', letterSpacing: '1px' }}>AI-Powered Academic Strategy</span>
                </div>
                <div style={{ whiteSpace: 'pre-wrap' }}>{selectedPlan.activities}</div>
              </div>
              <div style={{ padding: '20px 32px', borderTop: '1px solid var(--glass-border)', display: 'flex', gap: '12px', background: 'rgba(255,255,255,0.02)' }}>
                <button style={{ flex: 1, padding: '12px', borderRadius: '12px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                  <Download size={18} /> Export PDF
                </button>
                <button style={{ flex: 1, padding: '12px', borderRadius: '12px', background: '#3b82f6', color: 'white', border: 'none', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                  <Share2 size={18} /> Share Plan
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Left Column: Compact Generator */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        <div className="glass-card" style={{ padding: '24px', background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '24px', boxShadow: '0 10px 30px rgba(0,0,0,0.05)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
            <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: 'linear-gradient(135deg, #1d4ed8, #3b82f6)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
              <Cpu size={22} />
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '900', color: 'var(--text-main)' }}>AI Generator</h3>
              <p style={{ margin: 0, fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600' }}>Instant Academic Planning</p>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '10px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px', marginLeft: '4px' }}>Subject</label>
                <select 
                  value={formData.subject} onChange={e => setFormData({...formData, subject: e.target.value})}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: '10px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '13px', fontWeight: '700', outline: 'none' }}
                >
                  <option>Mathematics</option><option>Science</option><option>English</option><option>History</option>
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '10px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px', marginLeft: '4px' }}>Grade</label>
                <select 
                  value={formData.grade} onChange={e => setFormData({...formData, grade: e.target.value})}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: '10px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '13px', fontWeight: '700', outline: 'none' }}
                >
                  <option>8th standard</option><option>9th standard</option><option>10th standard</option>
                </select>
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '10px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px', marginLeft: '4px' }}>Topic / Chapter</label>
              <div style={{ position: 'relative' }}>
                <Book size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
                <input 
                  placeholder="e.g. Quantum Physics" value={formData.topic} onChange={e => setFormData({...formData, topic: e.target.value})}
                  style={{ width: '100%', padding: '12px 12px 12px 36px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '14px', fontWeight: '700', outline: 'none', boxSizing: 'border-box' }}
                />
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '10px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px', marginLeft: '4px' }}>Duration</label>
              <select 
                value={formData.duration} onChange={e => setFormData({...formData, duration: e.target.value})}
                style={{ width: '100%', padding: '10px 12px', borderRadius: '10px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '13px', fontWeight: '700', outline: 'none' }}
              >
                <option>45 minutes</option><option>60 minutes</option><option>90 minutes</option>
              </select>
            </div>

            <button 
              onClick={handleGenerateAI} disabled={isGenerating}
              style={{ 
                marginTop: '12px', width: '100%', padding: '14px', borderRadius: '14px', 
                background: 'linear-gradient(135deg, #1d4ed8, #3b82f6)', color: 'white', border: 'none', 
                fontWeight: '800', fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px',
                boxShadow: '0 4px 15px rgba(29, 78, 216, 0.2)', opacity: isGenerating ? 0.8 : 1
              }}
            >
              {isGenerating ? <RefreshCw className="spinning" size={18} /> : <Zap size={18} fill="white" />}
              {isGenerating ? 'Generating...' : 'Generate Strategy'}
            </button>
          </div>
        </div>

        <div style={{ textAlign: 'center', padding: '20px', background: 'rgba(59, 130, 246, 0.05)', borderRadius: '20px', border: '1px dashed rgba(59, 130, 246, 0.2)' }}>
          <p style={{ margin: 0, fontSize: '12px', color: '#3b82f6', fontWeight: '700' }}>✨ AI generates learning flow, objectives, and lab activities automatically.</p>
        </div>
      </div>

      {/* Right Column: Sleek Registry */}
      <div className="glass-card" style={{ display: 'flex', flexDirection: 'column', background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '24px', overflow: 'hidden' }}>
        <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Folder size={20} color="#f59e0b" fill="#f59e0b" />
            <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '900', color: 'var(--text-main)' }}>Plan Registry</h3>
          </div>
          <div style={{ position: 'relative' }}>
            <Search size={14} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
            <input 
              placeholder="Search plans..." value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
              style={{ padding: '8px 12px 8px 36px', borderRadius: '10px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '12px', width: '200px' }}
            />
          </div>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '12px', alignContent: 'start' }}>
          {filteredPlans.map(p => (
            <motion.div 
              key={p.id} onClick={() => setSelectedPlan(p)}
              whileHover={{ y: -2 }}
              style={{ 
                padding: '16px', borderRadius: '16px', background: 'var(--glass-surface)', 
                border: '1px solid var(--glass-border)', display: 'flex', alignItems: 'center', gap: '16px',
                cursor: 'pointer', transition: 'all 0.2s'
              }}
            >
              <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <FileText size={22} fill="rgba(59, 130, 246, 0.1)" />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: '14px', fontWeight: '800', color: 'var(--text-main)', marginBottom: '2px' }}>{p.title || p.topic}</div>
                <div style={{ fontSize: '11px', color: 'var(--text-dim)', fontWeight: '600' }}>{p.subject} • {p.grade}</div>
              </div>
              <div style={{ display: 'flex', gap: '4px' }}>
                <button 
                  onClick={(e) => { e.stopPropagation(); deleteDoc(doc(db, 'lesson_plans', p.id)); }}
                  style={{ background: 'none', border: 'none', padding: '6px', borderRadius: '8px', color: 'rgba(239, 68, 68, 0.2)', cursor: 'pointer', transition: 'color 0.2s' }}
                  onMouseEnter={e => e.currentTarget.style.color = '#ef4444'}
                  onMouseLeave={e => e.currentTarget.style.color = 'rgba(239, 68, 68, 0.2)'}
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </motion.div>
          ))}
          {filteredPlans.length === 0 && (
            <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '60px 20px', color: 'var(--text-dim)' }}>
              <Search size={40} style={{ opacity: 0.1, marginBottom: '12px' }} />
              <p style={{ fontSize: '13px', fontWeight: '600' }}>No plans found in the registry.</p>
            </div>
          )}
        </div>
      </div>

      <style>{`
        .spinning { animation: spin 1s linear infinite; }
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
};

export default LessonPlanner;
