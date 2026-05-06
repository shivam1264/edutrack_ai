import React, { useState, useEffect } from 'react';
import {
  Cpu, Sparkles, BookOpen, Clock, ChevronDown, Save,
  ExternalLink, Trash, FileText, Layout, RotateCw, Folder, Zap, Timer, Book,
  CheckCircle, Eye
} from 'lucide-react';
import {
  collection, addDoc, query, where, orderBy, onSnapshot,
  serverTimestamp, deleteDoc, doc
} from 'firebase/firestore';
import { generateLessonPlan } from '../services/api';
import { motion, AnimatePresence } from 'framer-motion';

const LessonPlanner = ({ user, db, classes, allPlans = [] }) => {
  const [formData, setFormData] = useState({
    subject: 'Mathematics',
    classId: '',
    className: '',
    topic: '',
    duration: '45 minutes'
  });

  const [isGenerating, setIsGenerating] = useState(false);
  const [plans, setPlans] = useState([]);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [generatedPlanPreview, setGeneratedPlanPreview] = useState(null);

  const subjects = [
    'Mathematics', 'Science', 'Physics', 'Chemistry', 'Biology',
    'English', 'Hindi', 'History', 'Geography', 'Computer Science'
  ];

  const durations = ['30 minutes', '45 minutes', '60 minutes', '90 minutes'];

  // Filter plans from the global state passed by App.jsx
  // We check both teacherId and teacher_id for cross-platform compatibility
  const filteredPlans = (allPlans || []).filter(p =>
    p.teacherId === user.uid || p.teacher_id === user.uid
  ).sort((a, b) => {
    const timeA = (a.createdAt?.toMillis?.() || a.createdAt?.seconds * 1000 || a.created_at?.toMillis?.() || a.created_at?.seconds * 1000 || 0);
    const timeB = (b.createdAt?.toMillis?.() || b.createdAt?.seconds * 1000 || b.created_at?.toMillis?.() || b.created_at?.seconds * 1000 || 0);
    return timeB - timeA;
  });

  // Keep internal 'plans' state for manual overrides or local updates if needed,
  // but sync it with filteredPlans whenever they change.
  useEffect(() => {
    setPlans(filteredPlans);
  }, [allPlans, user.uid]);

  const renderPlanContent = (content) => {
    if (!content) return null;

    // Clean up redundant metadata lines from the raw content before processing
    const cleanedContent = content.split('\n').filter(line => {
      const l = line.toLowerCase().trim();
      // Remove metadata headers and any line that is just hashes/spaces
      return !(
        l.startsWith('topic:') || l.startsWith('# topic:') || l.startsWith('## topic:') || l.startsWith('### topic:') ||
        l.startsWith('subject:') || l.startsWith('# subject:') || l.startsWith('## subject:') || l.startsWith('### subject:') ||
        l.startsWith('grade:') || l.startsWith('# grade:') || l.startsWith('## grade:') || l.startsWith('### grade:') ||
        l.startsWith('lesson plan:') || l.startsWith('# lesson plan:') || l.startsWith('## lesson plan:') || l.startsWith('### lesson plan:') ||
        /^#+\s*$/.test(l) || l === ''
      );
    }).join('\n').trim();

    // Split by markdown headers
    const sections = cleanedContent.split(/(?=#{1,4} )/);

    return sections.map((section, index) => {
      const isHeader = section.trim().startsWith('#');
      let title = '';
      let body = section;

      if (isHeader) {
        const lines = section.split('\n');
        title = lines[0].replace(/#+/g, '').trim();
        body = lines.slice(1).join('\n').trim();
      }

      // Remove any remaining hashes from body text as well
      body = body.replace(/#+/g, '').trim();

      if (!title && !body) return null;

      const getSectionIcon = (t) => {
        const lowerT = t.toLowerCase();
        if (lowerT.includes('objective')) return '🎯';
        if (lowerT.includes('strategy') || lowerT.includes('structure') || lowerT.includes('breakdown') || lowerT.includes('methodology')) return '⏱️';
        if (lowerT.includes('activity') || lowerT.includes('interactive')) return '⚡';
        if (lowerT.includes('assessment') || lowerT.includes('test') || lowerT.includes('quiz')) return '✅';
        return '📖';
      };

      const icon = getSectionIcon(title || body.substring(0, 20));

      return (
        <div key={index} style={{ marginBottom: '24px' }}>
          {title && (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              color: '#1e293b',
              fontWeight: '800',
              fontSize: '16px',
              marginBottom: '12px'
            }}>
              <span style={{ fontSize: '20px' }}>{icon}</span> {title}
            </div>
          )}
          <div style={{
            fontSize: '15px',
            color: '#475569',
            lineHeight: '1.8',
            whiteSpace: 'pre-wrap',
            paddingLeft: title ? '32px' : '0'
          }}>
            {body}
          </div>
        </div>
      );
    });
  };

  const handleGenerateAI = async () => {
    if (!formData.classId) {
      alert('Please select a Target Class first.');
      return;
    }
    if (!formData.topic) {
      alert('Please enter a Topic / Chapter first.');
      return;
    }

    setIsGenerating(true);
    setGeneratedPlanPreview(null);

    try {
      const response = await generateLessonPlan({
        topic: formData.topic,
        subject: formData.subject,
        grade: formData.grade,
        duration: formData.duration
      });

      const planContent = response.answer || response.plan;

      const newPlan = {
        ...formData,
        title: formData.topic,
        activities: planContent,
        plan: planContent, // For mobile compatibility
        teacher_id: user.uid,
        teacherId: user.uid,
        created_at: serverTimestamp(),
        createdAt: serverTimestamp(),
        ai_generated: true,
        aiGenerated: true
      };

      await addDoc(collection(db, 'lesson_plans'), newPlan);
      setGeneratedPlanPreview({ ...newPlan, id: 'preview' });
      // Clear topic after successful generation
      setFormData(prev => ({ ...prev, topic: '' }));
    } catch (err) {
      console.error(err);
      // Demo Fallback for User if API Fails
      const fallbackPlan = {
        ...formData,
        title: formData.topic,
        activities: `### 🎯 Learning Objectives\n1. Define and explain the core concepts of ${formData.topic}.\n2. Apply practical formulas and theories in real-world scenarios.\n\n### 📖 Teaching Strategy\n- **Intro:** Real-world hook related to ${formData.subject}.\n- **Core:** Direct instruction with visual aids.\n- **Closure:** Concept mapping and summary.\n\n### ⚡ Interactive Activity\nGroup discussion and hands-on problem solving based on ${formData.className} standards.\n\n### ✅ Assessment Methods\nExit ticket and peer-review session.`,
        teacher_id: user.uid,
        created_at: serverTimestamp(),
        ai_generated: true
      };
      setGeneratedPlanPreview({ ...fallbackPlan, id: 'preview' });
      alert('AI Generation failed, showing a sample structure instead.');
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div style={{
      maxWidth: '1200px',
      margin: '0 auto',
      paddingBottom: '40px',
      fontFamily: "'Outfit', sans-serif"
    }}>

      {/* Vibrant Web-Style Header */}
      <div style={{
        background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 50%, #ec4899 100%)',
        padding: '32px 40px',
        borderRadius: '32px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '32px',
        boxShadow: '0 20px 40px rgba(99, 102, 241, 0.15)',
        position: 'relative',
        overflow: 'hidden'
      }}>
        {/* Decorative Background Accents */}
        <div style={{ position: 'absolute', top: '-20%', right: '-10%', width: '300px', height: '300px', background: 'rgba(255,255,255,0.1)', borderRadius: '50%', filter: 'blur(60px)' }}></div>
        <div style={{ position: 'absolute', bottom: '-50%', left: '-5%', width: '250px', height: '250px', background: 'rgba(255,255,255,0.1)', borderRadius: '50%', filter: 'blur(50px)' }}></div>

        <div style={{ display: 'flex', gap: '20px', alignItems: 'center', position: 'relative', zIndex: 1 }}>
          <div style={{
            width: '60px', height: '60px', background: 'rgba(255,255,255,0.2)',
            borderRadius: '18px', display: 'flex', alignItems: 'center', justifyContent: 'center',
            backdropFilter: 'blur(10px)', border: '1px solid rgba(255,255,255,0.3)'
          }}>
            <Sparkles size={30} color="white" />
          </div>
          <div>
            <h1 style={{ fontSize: '32px', fontWeight: '900', margin: 0, color: 'white', letterSpacing: '-1px' }}>
              AI Lesson <span style={{ color: '#fbbf24' }}>Planner</span>
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
              <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#4ade80', boxShadow: '0 0 15px #4ade80' }}></div>
              <p style={{ color: 'rgba(255,255,255,0.8)', fontSize: '14px', fontWeight: '700', margin: 0 }}>Institutional Intelligence • Active Engine</p>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '16px', alignItems: 'center', position: 'relative', zIndex: 1 }}>
          <div style={{ textAlign: 'right', marginRight: '16px' }}>
            <div style={{ fontSize: '12px', color: 'rgba(255,255,255,0.6)', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '1px' }}>Available Credits</div>
            <div style={{ fontSize: '18px', fontWeight: '900', color: 'white' }}>Unlimited Access</div>
          </div>
          <div style={{
            width: '52px', height: '52px', borderRadius: '16px', background: 'rgba(255,255,255,0.1)',
            border: '1px solid rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center',
            justifyContent: 'center', color: 'white', backdropFilter: 'blur(10px)'
          }}>
            <Cpu size={24} />
          </div>
        </div>
      </div>

      {/* Two-Column Dashboard Layout */}
      <div style={{ display: 'grid', gridTemplateColumns: '400px 1fr', gap: '32px', alignItems: 'start' }}>

        {/* Left Column: Generator Form */}
        <div style={{ position: 'sticky', top: '24px', display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <div style={{
            padding: '28px',
            background: '#ffffff',
            borderRadius: '28px',
            boxShadow: '0 10px 30px rgba(0,0,0,0.04)',
            border: '1px solid #f1f5f9'
          }}>
            <h3 style={{ margin: '0 0 20px 0', fontSize: '18px', fontWeight: '800', color: '#1e293b', display: 'flex', alignItems: 'center', gap: '10px' }}>
              <Zap size={20} color="#f59e0b" fill="#f59e0b" /> Strategy Generator
            </h3>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              <div>
                <label style={{ fontSize: '11px', color: '#64748b', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px', display: 'block', marginLeft: '4px' }}>Subject</label>
                <div style={{ position: 'relative' }}>
                  <select
                    value={formData.subject}
                    onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
                    style={{ width: '100%', padding: '14px 16px', borderRadius: '14px', border: '2px solid #f1f5f9', background: '#f8fafc', fontSize: '14px', appearance: 'none', cursor: 'pointer', outline: 'none', fontWeight: '700', color: '#1e293b' }}
                  >
                    {subjects.map(s => <option key={s} value={s}>{s}</option>)}
                  </select>
                  <ChevronDown size={16} style={{ position: 'absolute', right: '16px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8', pointerEvents: 'none' }} />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '11px', color: '#64748b', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px', display: 'block', marginLeft: '4px' }}>Target Hub (Class)</label>
                <div style={{ position: 'relative' }}>
                  <select
                    value={formData.classId}
                    onChange={(e) => {
                      const cls = classes.find(c => c.id === e.target.value);
                      setFormData({ ...formData, classId: e.target.value, className: cls?.displayName || cls?.standard || '' });
                    }}
                    style={{ width: '100%', padding: '14px 16px', borderRadius: '14px', border: '2px solid #f1f5f9', background: '#f8fafc', fontSize: '14px', appearance: 'none', cursor: 'pointer', outline: 'none', fontWeight: '700', color: '#1e293b' }}
                  >
                    <option value="">Select Hub...</option>
                    {classes.map(c => <option key={c.id} value={c.id}>{c.displayName || c.standard}</option>)}
                  </select>
                  <ChevronDown size={16} style={{ position: 'absolute', right: '16px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8', pointerEvents: 'none' }} />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '11px', color: '#64748b', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px', display: 'block', marginLeft: '4px' }}>Topic / Module Title</label>
                <div style={{ position: 'relative' }}>
                  <div style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', background: '#eff6ff', padding: '6px', borderRadius: '8px' }}>
                    <Book size={16} color="#2563eb" />
                  </div>
                  <input
                    placeholder="Enter topic..."
                    value={formData.topic}
                    onChange={(e) => setFormData({ ...formData, topic: e.target.value })}
                    style={{ width: '100%', padding: '14px 16px 14px 48px', borderRadius: '14px', border: '2px solid #f1f5f9', background: '#f8fafc', fontSize: '14px', outline: 'none', fontWeight: '700', boxSizing: 'border-box', color: '#1e293b' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '11px', color: '#64748b', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px', display: 'block', marginLeft: '4px' }}>Session Duration</label>
                <div style={{ position: 'relative' }}>
                  <div style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)' }}>
                    <Timer size={18} color="#2563eb" />
                  </div>
                  <select
                    value={formData.duration}
                    onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
                    style={{ width: '100%', padding: '14px 16px 14px 48px', borderRadius: '14px', border: '2px solid #f1f5f9', background: '#f8fafc', fontSize: '14px', appearance: 'none', cursor: 'pointer', outline: 'none', fontWeight: '700', color: '#1e293b' }}
                  >
                    {durations.map(d => <option key={d} value={d}>{d}</option>)}
                  </select>
                  <ChevronDown size={16} style={{ position: 'absolute', right: '16px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8', pointerEvents: 'none' }} />
                </div>
              </div>

              <button
                onClick={handleGenerateAI}
                disabled={isGenerating}
                style={{
                  width: '100%',
                  padding: '16px',
                  borderRadius: '16px',
                  border: 'none',
                  background: isGenerating ? '#cbd5e1' : 'linear-gradient(135deg, #1d4ed8, #3b82f6)',
                  color: '#fff',
                  fontSize: '15px',
                  fontWeight: '800',
                  cursor: isGenerating ? 'not-allowed' : 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '10px',
                  transition: 'all 0.2s',
                  boxShadow: isGenerating ? 'none' : '0 10px 20px rgba(37, 99, 235, 0.2)',
                  marginTop: '8px'
                }}
              >
                {isGenerating ? <RotateCw className="spinning" size={18} /> : <Sparkles size={18} />}
                {isGenerating ? 'Synthesizing...' : 'Generate Plan'}
              </button>
            </div>
          </div>

          <div style={{ padding: '20px', background: '#eff6ff', borderRadius: '20px', border: '1px solid #dbeafe' }}>
            <h4 style={{ margin: '0 0 8px 0', fontSize: '13px', fontWeight: '800', color: '#1e40af' }}>Pro Tip:</h4>
            <p style={{ margin: 0, fontSize: '12px', color: '#1e40af', opacity: 0.8, lineHeight: '1.5', fontWeight: '600' }}>
              Specific topics yield higher-fidelity strategies. Try "Newton's Laws of Motion" instead of just "Physics".
            </p>
          </div>
        </div>

        {/* Right Column: Previews and Saved Plans */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>

          {/* Active Generation Preview */}
          <AnimatePresence>
            {generatedPlanPreview && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                style={{
                  background: '#ffffff',
                  borderRadius: '32px',
                  border: '1px solid #e2e8f0',
                  boxShadow: '0 20px 50px rgba(0,0,0,0.03)',
                  overflow: 'hidden'
                }}
              >
                <div style={{ padding: '24px 32px', background: '#f8fafc', borderBottom: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '40px', height: '40px', background: '#10b981', borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
                      <CheckCircle size={20} />
                    </div>
                    <div>
                      <div style={{ fontSize: '18px', fontWeight: '900', color: '#1e293b' }}>Generation Success</div>
                      <div style={{ fontSize: '12px', color: '#64748b', fontWeight: '700' }}>Review your custom strategy below</div>
                    </div>
                  </div>
                  <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    style={{ background: '#ecfdf5', border: '1px solid #10b981', padding: '8px 16px', borderRadius: '10px', display: 'flex', alignItems: 'center', gap: '8px', color: '#059669', fontWeight: '800', fontSize: '12px', cursor: 'pointer' }}
                  >
                    <Save size={16} /> Export PDF
                  </motion.button>
                </div>

                <div style={{ padding: '32px', maxHeight: '600px', overflowY: 'auto' }}>
                  {renderPlanContent(generatedPlanPreview.activities || generatedPlanPreview.plan)}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Saved History Table View */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{ width: '32px', height: '32px', background: '#fff7ed', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#f59e0b' }}>
                  <Folder size={18} fill="#f59e0b" />
                </div>
                <h3 style={{ margin: 0, fontSize: '20px', fontWeight: '900', color: '#1e293b' }}>Institutional Archives</h3>
              </div>
              <div style={{ fontSize: '12px', color: '#94a3b8', fontWeight: '800', textTransform: 'uppercase' }}>{plans.length} Records Found</div>
            </div>

            <div style={{ background: '#fff', borderRadius: '24px', border: '1px solid #f1f5f9', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.01)' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                <thead>
                  <tr style={{ background: '#f8fafc', borderBottom: '1px solid #f1f5f9' }}>
                    <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Module / Topic</th>
                    <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Subject</th>
                    <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Hub (Class)</th>
                    <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Created At</th>
                    <th style={{ padding: '16px 24px', fontSize: '11px', fontWeight: '800', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px', textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {plans.map((p, idx) => (
                    <motion.tr
                      key={p.id}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      transition={{ delay: idx * 0.05 }}
                      onClick={() => setSelectedPlan(p)}
                      style={{ borderBottom: '1px solid #f8fafc', cursor: 'pointer', transition: 'background 0.2s' }}
                      className="table-row-hover"
                    >
                      <td style={{ padding: '16px 24px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                          <div style={{ width: '36px', height: '36px', background: '#f5f3ff', borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#7c3aed' }}>
                            <FileText size={18} />
                          </div>
                          <div style={{ fontWeight: '800', color: '#1e293b', fontSize: '14px' }}>{p.title || p.topic}</div>
                        </div>
                      </td>
                      <td style={{ padding: '16px 24px' }}>
                        <span style={{ fontSize: '12px', background: '#eff6ff', color: '#2563eb', padding: '4px 10px', borderRadius: '8px', fontWeight: '800' }}>{p.subject}</span>
                      </td>
                      <td style={{ padding: '16px 24px' }}>
                        <span style={{ fontSize: '12px', color: '#64748b', fontWeight: '700' }}>{p.grade || p.className}</span>
                      </td>
                      <td style={{ padding: '16px 24px' }}>
                        <div style={{ fontSize: '12px', color: '#94a3b8', fontWeight: '700' }}>
                          {p.createdAt?.toDate ? p.createdAt.toDate().toLocaleDateString() : 'Recent'}
                        </div>
                      </td>
                      <td style={{ padding: '16px 24px', textAlign: 'right' }}>
                        <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
                          <div
                            onClick={(e) => { e.stopPropagation(); setSelectedPlan(p); }}
                            style={{ width: '36px', height: '36px', borderRadius: '10px', background: '#eff6ff', color: '#2563eb', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}
                          >
                            <Eye size={18} style={{ display: 'block', minWidth: '18px', minHeight: '18px' }} />
                          </div>
                          <div
                            onClick={(e) => { e.stopPropagation(); deleteDoc(doc(db, 'lesson_plans', p.id)); }}
                            style={{ width: '36px', height: '36px', borderRadius: '10px', background: '#fff1f2', color: '#ef4444', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}
                          >
                            <Trash size={18} style={{ display: 'block', minWidth: '18px', minHeight: '18px' }} />
                          </div>
                        </div>
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
              {plans.length === 0 && (
                <div style={{ textAlign: 'center', padding: '60px', color: '#94a3b8', background: '#fff' }}>
                  <Folder size={48} color="#e2e8f0" style={{ marginBottom: '16px' }} />
                  <div style={{ fontWeight: '800', fontSize: '16px' }}>No Archived Strategies</div>
                  <div style={{ fontSize: '13px', fontWeight: '600' }}>Generate your first intelligence-driven plan on the left.</div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Plan Details Modal */}
      <AnimatePresence>
        {selectedPlan && (
          <div
            onClick={() => setSelectedPlan(null)}
            style={{ position: 'fixed', inset: 0, zIndex: 1000, background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '40px' }}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              style={{ width: '100%', maxWidth: '900px', maxHeight: '90vh', background: '#fff', borderRadius: '32px', overflow: 'hidden', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)', display: 'flex', flexDirection: 'column' }}
            >
              <div style={{ padding: '32px 40px', background: '#fff', borderBottom: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h3 style={{ margin: '0 0 8px 0', fontSize: '28px', fontWeight: '900', color: '#1e293b', letterSpacing: '-0.5px' }}>{selectedPlan.title || selectedPlan.topic}</h3>
                  <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                    <span style={{ fontSize: '13px', background: '#eff6ff', color: '#2563eb', padding: '4px 12px', borderRadius: '8px', fontWeight: '800' }}>{selectedPlan.subject}</span>
                    <span style={{ fontSize: '13px', background: '#f5f3ff', color: '#7c3aed', padding: '4px 12px', borderRadius: '8px', fontWeight: '800' }}>{selectedPlan.grade || selectedPlan.className}</span>
                    <span style={{ fontSize: '13px', color: '#94a3b8', fontWeight: '700' }}>{selectedPlan.duration || '45 mins'} Session</span>
                  </div>
                </div>
                <button onClick={() => setSelectedPlan(null)} style={{ padding: '10px', borderRadius: '12px', background: '#f8fafc', border: '1px solid #e2e8f0', cursor: 'pointer' }}>
                  <RotateCw size={20} color="#64748b" style={{ transform: 'rotate(45deg)' }} />
                </button>
              </div>

              <div style={{ padding: '40px', overflowY: 'auto', flex: 1, background: '#fafbfc' }}>
                <div style={{ background: 'white', padding: '40px', borderRadius: '24px', border: '1px solid #f1f5f9', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
                  {renderPlanContent(selectedPlan.activities || selectedPlan.plan)}
                </div>
              </div>

              <div style={{ padding: '24px 40px', borderTop: '1px solid #f1f5f9', display: 'flex', justifyContent: 'flex-end', gap: '16px', background: '#fff' }}>
                <button style={{ padding: '12px 24px', background: '#f1f5f9', color: '#1e293b', borderRadius: '12px', fontWeight: '800', border: 'none', cursor: 'pointer', fontSize: '14px' }}>Download Archive</button>
                <button style={{ padding: '12px 24px', background: '#2563eb', color: 'white', borderRadius: '12px', fontWeight: '800', border: 'none', cursor: 'pointer', fontSize: '14px', boxShadow: '0 4px 12px rgba(37, 99, 235, 0.2)' }}>Print Strategy</button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <style>{`
        .spinning { animation: spin 1s linear infinite; }
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        .table-row-hover:hover { background: #fafbfc !important; }
        ::-webkit-scrollbar { width: 8px; }
        ::-webkit-scrollbar-track { background: #f8fafc; }
        ::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 10px; }
        ::-webkit-scrollbar-thumb:hover { background: #cbd5e1; }
      `}</style>
    </div>
  );
};

export default LessonPlanner;
