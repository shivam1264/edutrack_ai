import React, { useState, useEffect } from 'react';
import {
  Cpu, Zap, Save, Trash2, BookOpen, Layers, Clock, Target, ListChecks, FileText, ChevronRight, Share2, Download, CheckCircle, AlertCircle, Search, Plus, ExternalLink, GraduationCap, Book, Timer, Folder
} from 'lucide-react';
import {
  collection, addDoc, query, where, onSnapshot, serverTimestamp, deleteDoc, doc, updateDoc, orderBy
} from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';
import { generateLessonPlan } from '../services/api';

const LessonPlanner = ({ user, db, classes, backendOnline }) => {
  const [plans, setPlans] = useState([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  
  // Form State matching mobile app
  const [formData, setFormData] = useState({
    subject: 'Mathematics',
    grade: '8th standard',
    topic: '',
    duration: '45 minutes',
    classId: ''
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
      
      // Save automatically after generation to match "Generate Lesson Plan" intent
      await addDoc(collection(db, 'lesson_plans'), {
        ...formData,
        title: formData.topic,
        activities: planContent,
        teacherId: user.uid,
        createdAt: serverTimestamp(),
        aiGenerated: true
      });
      
      alert('Lesson Plan Generated & Synced! Check "Saved Plans" below.');
      setFormData(prev => ({ ...prev, topic: '' }));
    } catch (err) {
      console.error(err);
      alert('AI Generation failed. Please try again.');
    } finally {
      setIsGenerating(false);
    }
  };

  const [selectedPlan, setSelectedPlan] = useState(null);

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', paddingBottom: '60px', fontFamily: "'Outfit', sans-serif" }}>
      
      {/* Plan Details Modal */}
      <AnimatePresence>
        {selectedPlan && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(8px)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}
            onClick={() => setSelectedPlan(null)}
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              className="glass-card"
              style={{ width: '100%', maxWidth: '700px', maxHeight: '85vh', background: 'white', borderRadius: '32px', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}
              onClick={e => e.stopPropagation()}
            >
              <div style={{ background: 'linear-gradient(135deg, #1d4ed8, #3b82f6)', padding: '32px', color: 'white' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h2 style={{ margin: 0, fontSize: '24px', fontWeight: '800' }}>{selectedPlan.title || selectedPlan.topic}</h2>
                    <p style={{ margin: '8px 0 0 0', opacity: 0.8, fontWeight: '600' }}>{selectedPlan.subject} • {selectedPlan.grade} • {selectedPlan.duration}</p>
                  </div>
                  <button onClick={() => setSelectedPlan(null)} style={{ background: 'rgba(255,255,255,0.2)', border: 'none', color: 'white', padding: '8px', borderRadius: '12px', cursor: 'pointer' }}>
                    <Plus size={20} style={{ transform: 'rotate(45deg)' }} />
                  </button>
                </div>
              </div>
              <div style={{ padding: '32px', overflowY: 'auto', flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px', color: '#1d4ed8' }}>
                  <Zap size={18} fill="#1d4ed8" />
                  <span style={{ fontWeight: '800', textTransform: 'uppercase', fontSize: '12px', letterSpacing: '1px' }}>AI Generated Strategy</span>
                </div>
                <div style={{ whiteSpace: 'pre-wrap', lineHeight: '1.8', color: '#334155', fontSize: '15px' }}>
                  {selectedPlan.activities}
                </div>
              </div>
              <div style={{ padding: '20px 32px', borderTop: '1px solid #f1f5f9', display: 'flex', gap: '12px' }}>
                <button style={{ flex: 1, padding: '14px', borderRadius: '16px', background: '#f1f5f9', color: '#475569', border: 'none', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                  <Download size={18} /> Export PDF
                </button>
                <button style={{ flex: 1, padding: '14px', borderRadius: '16px', background: '#1d4ed8', color: 'white', border: 'none', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                  <Share2 size={18} /> Share Plan
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Mobile-Style Header */}
      <div style={{ 
        background: 'linear-gradient(180deg, #1d4ed8 0%, #3b82f6 100%)', 
        padding: '60px 32px 40px 32px', 
        borderRadius: '0 0 40px 40px',
        margin: '-32px -32px 32px -32px',
        color: 'white',
        boxShadow: '0 10px 30px rgba(29, 78, 216, 0.2)'
      }}>
        <h1 style={{ fontSize: '32px', fontWeight: '800', margin: '0 0 8px 0' }}>AI Lesson Planner</h1>
        <p style={{ fontSize: '15px', opacity: 0.9, fontWeight: '500' }}>Active Class: Professional Lesson Planner</p>
      </div>

      {/* Generation Card */}
      <div className="glass-card" style={{ 
        padding: '32px', 
        borderRadius: '32px', 
        background: 'white', 
        boxShadow: '0 20px 40px rgba(0,0,0,0.05)',
        border: '1px solid #f1f5f9',
        marginBottom: '40px'
      }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '24px' }}>
          <div>
            <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-dim)', marginBottom: '8px', marginLeft: '12px', fontWeight: '600' }}>Subject</label>
            <div style={{ position: 'relative' }}>
              <select 
                value={formData.subject}
                onChange={e => setFormData({...formData, subject: e.target.value})}
                style={{ width: '100%', padding: '16px 20px', borderRadius: '20px', border: '2px solid #f1f5f9', background: 'white', color: 'var(--text-main)', fontSize: '15px', fontWeight: '700', appearance: 'none', outline: 'none' }}
              >
                <option>Mathematics</option>
                <option>Science</option>
                <option>English</option>
                <option>History</option>
              </select>
              <ChevronRight size={18} style={{ position: 'absolute', right: '16px', top: '50%', transform: 'translateY(-50%) rotate(90deg)', color: 'var(--text-dim)' }} />
            </div>
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-dim)', marginBottom: '8px', marginLeft: '12px', fontWeight: '600' }}>Grade</label>
            <div style={{ position: 'relative' }}>
              <select 
                value={formData.grade}
                onChange={e => setFormData({...formData, grade: e.target.value})}
                style={{ width: '100%', padding: '16px 20px', borderRadius: '20px', border: '2px solid #f1f5f9', background: 'white', color: 'var(--text-main)', fontSize: '15px', fontWeight: '700', appearance: 'none', outline: 'none' }}
              >
                <option>8th standard</option>
                <option>9th standard</option>
                <option>10th standard</option>
              </select>
              <ChevronRight size={18} style={{ position: 'absolute', right: '16px', top: '50%', transform: 'translateY(-50%) rotate(90deg)', color: 'var(--text-dim)' }} />
            </div>
          </div>
        </div>

        <div style={{ position: 'relative', marginBottom: '24px' }}>
          <div style={{ position: 'absolute', left: '20px', top: '50%', transform: 'translateY(-50%)', background: '#f1f5f9', padding: '8px', borderRadius: '8px' }}>
            <Book size={20} color="#475569" />
          </div>
          <input 
            placeholder="Topic / Chapter"
            value={formData.topic}
            onChange={e => setFormData({...formData, topic: e.target.value})}
            style={{ width: '100%', padding: '24px 20px 24px 64px', borderRadius: '24px', border: '2px solid #f1f5f9', background: 'white', color: 'var(--text-main)', fontSize: '18px', fontWeight: '700', outline: 'none', boxSizing: 'border-box' }}
          />
        </div>

        <div style={{ marginBottom: '32px' }}>
          <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-dim)', marginBottom: '8px', marginLeft: '12px', fontWeight: '600' }}>Class Duration</label>
          <div style={{ position: 'relative' }}>
            <div style={{ position: 'absolute', left: '20px', top: '50%', transform: 'translateY(-50%)' }}>
              <Timer size={22} color="#1d4ed8" />
            </div>
            <select 
              value={formData.duration}
              onChange={e => setFormData({...formData, duration: e.target.value})}
              style={{ width: '100%', padding: '18px 20px 18px 56px', borderRadius: '20px', border: '2px solid #f1f5f9', background: 'white', color: 'var(--text-main)', fontSize: '16px', fontWeight: '700', appearance: 'none', outline: 'none' }}
            >
              <option>45 minutes</option>
              <option>60 minutes</option>
              <option>90 minutes</option>
            </select>
            <ChevronRight size={18} style={{ position: 'absolute', right: '16px', top: '50%', transform: 'translateY(-50%) rotate(90deg)', color: 'var(--text-dim)' }} />
          </div>
        </div>

        <button 
          onClick={handleGenerateAI}
          disabled={isGenerating}
          style={{ 
            width: '100%', padding: '20px', borderRadius: '24px', 
            background: 'linear-gradient(90deg, #1d4ed8, #2563eb)', 
            color: 'white', border: 'none', fontWeight: '800', fontSize: '16px', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '12px',
            boxShadow: '0 10px 25px rgba(29, 78, 216, 0.3)',
            transition: 'transform 0.2s',
            opacity: isGenerating ? 0.8 : 1
          }}
        >
          {isGenerating ? <RefreshCw className="spinning" size={20} /> : <Zap size={20} fill="white" />}
          {isGenerating ? 'Generating Strategy...' : 'Generate Lesson Plan'}
        </button>
      </div>

      {/* Saved Plans Section */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '20px' }}>
        <Folder size={24} color="#f59e0b" fill="#f59e0b" />
        <h3 style={{ margin: 0, fontSize: '22px', fontWeight: '800', color: 'var(--text-main)' }}>Saved Plans</h3>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {plans.map(p => (
          <div key={p.id} onClick={() => setSelectedPlan(p)} className="glass-card" style={{ 
            padding: '24px', borderRadius: '24px', background: 'white', 
            border: '1px solid #f1f5f9', display: 'flex', alignItems: 'center', gap: '20px',
            boxShadow: '0 4px 15px rgba(0,0,0,0.02)', cursor: 'pointer'
          }}>
            <div style={{ padding: '16px', borderRadius: '16px', background: '#eff6ff', color: '#3b82f6' }}>
              <FileText size={28} fill="rgba(59, 130, 246, 0.1)" />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: '18px', fontWeight: '800', color: 'var(--text-main)', marginBottom: '4px' }}>{p.title || p.topic}</div>
              <div style={{ fontSize: '14px', color: 'var(--text-dim)', fontWeight: '600' }}>
                {p.subject} • {p.grade}
              </div>
            </div>
            <button style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', padding: '8px' }}>
              <ExternalLink size={24} />
            </button>
            <button 
              onClick={(e) => { e.stopPropagation(); deleteDoc(doc(db, 'lesson_plans', p.id)); }}
              style={{ background: 'none', border: 'none', color: '#fee2e2', cursor: 'pointer', padding: '8px' }}
            >
              <Trash2 size={20} color="#ef4444" />
            </button>
          </div>
        ))}


        {plans.length === 0 && (
          <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-dim)', background: '#f8fafc', borderRadius: '24px', border: '2px dashed #e2e8f0' }}>
            No saved plans yet. Generate your first AI strategy above.
          </div>
        )}
      </div>

      <style>{`
        .spinning { animation: spin 1s linear infinite; }
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        .gradient-text { background: linear-gradient(90deg, #1d4ed8, #3b82f6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
      `}</style>
    </div>
  );
};

export default LessonPlanner;
