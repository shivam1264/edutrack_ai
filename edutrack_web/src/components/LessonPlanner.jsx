import React, { useState, useEffect } from 'react';
import {
  Cpu, Zap, Save, RefreshCw, Trash2, BookOpen, Layers, Clock, Target, ListChecks, FileText, ChevronRight, Share2, Download, CheckCircle, AlertCircle, Search, Plus
} from 'lucide-react';
import {
  collection, addDoc, query, where, onSnapshot, serverTimestamp, deleteDoc, doc, updateDoc, orderBy
} from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';
import { generateLessonPlan } from '../services/api';

const LessonPlanner = ({ user, db, classes, backendOnline }) => {
  const [plans, setPlans] = useState([]);
  const [activePlan, setActivePlan] = useState(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  
  // Form State
  const [formData, setFormData] = useState({
    title: '',
    subject: '',
    grade: 'Grade 10',
    duration: '45 mins',
    classId: '',
    objectives: '',
    materials: '',
    activities: ''
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
    if (!formData.title || !formData.subject) {
      alert('Please enter a Topic and Subject first.');
      return;
    }
    
    setIsGenerating(true);
    try {
      const response = await generateLessonPlan({
        topic: formData.title,
        subject: formData.subject,
        grade: formData.grade,
        duration: formData.duration
      });
      
      // Parse the AI response (it's often markdown or text from generalChatClient)
      const planContent = response.answer || response.plan;
      setFormData(prev => ({
        ...prev,
        activities: planContent
      }));
      
    } catch (err) {
      console.error(err);
      alert('AI Generation failed. Using fallback simulation.');
      setFormData(prev => ({
        ...prev,
        activities: "1. Introduction (5 mins): Brief overview of " + formData.title + "\n2. Core Concepts (20 mins): Deep dive into key theories.\n3. Practical Exercise (15 mins): Interactive student participation.\n4. Conclusion (5 mins): Summary and Q&A."
      }));
    } finally {
      setIsGenerating(false);
    }
  };

  const handleSavePlan = async (e) => {
    e.preventDefault();
    if (!formData.title || !formData.classId) return;
    
    setIsSaving(true);
    try {
      const planData = {
        ...formData,
        teacherId: user.uid,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        syncStatus: 'synced'
      };
      
      if (activePlan?.id) {
        await updateDoc(doc(db, 'lesson_plans', activePlan.id), planData);
      } else {
        await addDoc(collection(db, 'lesson_plans'), planData);
      }
      
      setFormData({
        title: '', subject: '', grade: 'Grade 10', duration: '45 mins',
        classId: '', objectives: '', materials: '', activities: ''
      });
      setActivePlan(null);
      alert('Lesson Plan Synchronized to Mobile Cloud 🚀');
    } catch (err) {
      console.error(err);
    } finally {
      setIsSaving(false);
    }
  };

  const filteredPlans = plans.filter(p => 
    (p.title || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (p.subject || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '350px 1fr', gap: '24px', height: 'calc(100vh - 180px)', minHeight: '600px' }}>
      
      {/* Sidebar: Saved Plans */}
      <div className="glass-card" style={{ display: 'flex', flexDirection: 'column', background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '24px', overflow: 'hidden' }}>
        <div style={{ padding: '24px', borderBottom: '1px solid var(--glass-border)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <h3 style={{ margin: 0, fontSize: '18px', fontWeight: '900', color: 'var(--text-main)' }}>Registry</h3>
            <button 
              onClick={() => { setActivePlan(null); setFormData({ title: '', subject: '', grade: 'Grade 10', duration: '45 mins', classId: '', objectives: '', materials: '', activities: '' }); }}
              style={{ background: '#6366f1', color: 'white', border: 'none', padding: '6px 12px', borderRadius: '8px', fontSize: '12px', fontWeight: '800', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
            >
              <Plus size={14} /> New
            </button>
          </div>
          <div style={{ position: 'relative' }}>
            <Search size={14} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
            <input 
              type="text" 
              placeholder="Search plans..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{ width: '100%', padding: '10px 10px 10px 36px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '13px' }}
            />
          </div>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', padding: '12px' }}>
          {filteredPlans.map(p => (
            <motion.div 
              key={p.id}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => { setActivePlan(p); setFormData(p); }}
              style={{ 
                padding: '16px', borderRadius: '16px', marginBottom: '8px', cursor: 'pointer',
                background: activePlan?.id === p.id ? 'rgba(99, 102, 241, 0.1)' : 'transparent',
                border: activePlan?.id === p.id ? '1px solid #6366f1' : '1px solid transparent',
                transition: 'all 0.2s'
              }}
            >
              <div style={{ fontWeight: '700', color: 'var(--text-main)', fontSize: '14px', marginBottom: '4px' }}>{p.title}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '11px', color: 'var(--text-dim)' }}>
                <span style={{ color: '#6366f1', fontWeight: '800' }}>{p.subject}</span>
                <span>•</span>
                <span>{classes.find(c => c.id === p.classId)?.displayName || 'Class'}</span>
              </div>
            </motion.div>
          ))}
          {filteredPlans.length === 0 && (
            <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--text-dim)', fontSize: '13px' }}>
              No lesson plans found.
            </div>
          )}
        </div>
      </div>

      {/* Main Editor */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <form onSubmit={handleSavePlan} style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '20px' }}>
          
          <div className="glass-card" style={{ padding: '24px', background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Cpu size={20} />
                </div>
                <div>
                  <h2 style={{ margin: 0, fontSize: '20px', fontWeight: '900', color: 'var(--text-main)' }}>AI Strategy Designer</h2>
                  <div style={{ fontSize: '12px', color: 'var(--text-dim)', fontWeight: '600' }}>Drafting: {formData.title || 'New Concept'}</div>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '12px' }}>
                <button 
                  type="button"
                  onClick={handleGenerateAI}
                  disabled={isGenerating}
                  style={{ 
                    padding: '10px 20px', borderRadius: '12px', background: 'linear-gradient(135deg, #6366f1, #a855f7)', 
                    color: 'white', border: 'none', fontWeight: '800', fontSize: '13px', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', gap: '8px', boxShadow: '0 4px 15px rgba(99, 102, 241, 0.2)',
                    opacity: isGenerating ? 0.7 : 1
                  }}
                >
                  {isGenerating ? <RefreshCw size={16} className="spinning" /> : <Zap size={16} fill="white" />}
                  {isGenerating ? 'Analyzing...' : 'AI Generate'}
                </button>
                <button 
                  type="submit"
                  disabled={isSaving}
                  style={{ 
                    padding: '10px 20px', borderRadius: '12px', background: '#10b981', 
                    color: 'white', border: 'none', fontWeight: '800', fontSize: '13px', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', gap: '8px', boxShadow: '0 4px 15px rgba(16, 185, 129, 0.2)'
                  }}
                >
                  <Save size={16} /> {isSaving ? 'Syncing...' : (activePlan ? 'Update Sync' : 'Save & Sync')}
                </button>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '16px', marginBottom: '20px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px' }}>Topic / Chapter</label>
                <input 
                  required value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})}
                  placeholder="e.g. Newton's 3rd Law" 
                  style={{ width: '100%', padding: '12px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '14px' }} 
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px' }}>Subject</label>
                <input 
                  required value={formData.subject} onChange={e => setFormData({...formData, subject: e.target.value})}
                  placeholder="e.g. Physics" 
                  style={{ width: '100%', padding: '12px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '14px' }} 
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px' }}>Academic Hub</label>
                <select 
                  required value={formData.classId} onChange={e => setFormData({...formData, classId: e.target.value})}
                  style={{ width: '100%', padding: '12px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '14px' }}
                >
                  <option value="">Select Class</option>
                  {classes.map(c => <option key={c.id} value={c.id}>{c.displayName || c.standard}</option>)}
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '6px' }}>Duration</label>
                <input 
                  value={formData.duration} onChange={e => setFormData({...formData, duration: e.target.value})}
                  placeholder="e.g. 45 mins" 
                  style={{ width: '100%', padding: '12px', borderRadius: '12px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '14px' }} 
                />
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
              <div>
                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>
                  <Target size={12} /> Learning Objectives
                </label>
                <textarea 
                  value={formData.objectives} onChange={e => setFormData({...formData, objectives: e.target.value})}
                  placeholder="What should students master? (One per line)" 
                  rows="3" 
                  style={{ width: '100%', padding: '16px', borderRadius: '16px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '14px', resize: 'none' }} 
                />
              </div>
              <div>
                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '8px' }}>
                  <Layers size={12} /> Required Materials
                </label>
                <textarea 
                  value={formData.materials} onChange={e => setFormData({...formData, materials: e.target.value})}
                  placeholder="Textbooks, lab kits, digital tools..." 
                  rows="3" 
                  style={{ width: '100%', padding: '16px', borderRadius: '16px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '14px', resize: 'none' }} 
                />
              </div>
            </div>
          </div>

          <div className="glass-card" style={{ flex: 1, padding: '24px', background: 'var(--card-bg)', border: '1px solid var(--glass-border)', borderRadius: '24px', display: 'flex', flexDirection: 'column' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', marginBottom: '12px' }}>
              <ListChecks size={12} /> Detailed Lesson Activities & Flow
            </label>
            <textarea 
              value={formData.activities} onChange={e => setFormData({...formData, activities: e.target.value})}
              placeholder="Outline the minute-by-minute flow of your class..." 
              style={{ flex: 1, width: '100%', padding: '20px', borderRadius: '20px', border: '1px solid var(--glass-border)', background: 'var(--input-bg)', color: 'var(--text-main)', fontSize: '15px', lineHeight: '1.6', resize: 'none', fontFamily: 'inherit' }} 
            />
          </div>
        </form>
      </div>

      <style>{`
        .spinning { animation: spin 1s linear infinite; }
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
};

export default LessonPlanner;
