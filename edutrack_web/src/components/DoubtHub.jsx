import React from 'react';
import {
  Zap,
  Trash
} from 'lucide-react';
import { doc, updateDoc, serverTimestamp } from 'firebase/firestore';

const DoubtHub = ({
  doubts,
  backendOnline,
  aiDoubtLoading,
  setAiDoubtLoading,
  generalChat,
  db,
  fullUserData
}) => {
  return (
    <div className="glass-card" style={{ padding: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <h2 style={{ fontSize: '24px', fontWeight: '800' }}>Student Doubt Queue</h2>
        <div style={{ padding: '8px 16px', background: 'rgba(124, 58, 237, 0.1)', borderRadius: '12px', color: '#7c3aed', fontSize: '14px', fontWeight: 'bold' }}>
          {doubts.filter(d => d.status === 'pending').length} Pending
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {doubts.map(d => (
          <div key={d.id} className="glass-card" style={{ padding: '20px', background: 'var(--glass-surface)', border: '1px solid var(--glass-border)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
              <span style={{ fontSize: '11px', fontWeight: '900', color: d.status === 'pending' ? '#f59e0b' : '#10b981', textTransform: 'uppercase' }}>
                {d.status === 'pending' ? 'Pending' : 'Answered'}
              </span>
              <span style={{ fontSize: '11px', color: 'var(--text-dim)' }}>
                Class {d.classId} | {d.subject}
              </span>
            </div>
            <p style={{ fontWeight: '600', fontSize: '15px', marginBottom: '16px' }}>{d.question}</p>

            {d.status === 'pending' ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <input
                    id={`ans-${d.id}`}
                    placeholder="Type your answer here..."
                    style={{ flex: 1, padding: '12px', borderRadius: '8px', background: 'var(--input-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)' }}
                  />
                </div>
                <div style={{ display: 'flex', gap: '8px' }}>
                  {backendOnline && (
                    <button
                      disabled={aiDoubtLoading[d.id]}
                      onClick={async () => {
                        setAiDoubtLoading(prev => ({ ...prev, [d.id]: true }));
                        try {
                          const result = await generalChat(d.question, 'teacher');
                          const inputEl = document.getElementById(`ans-${d.id}`);
                          if (inputEl) inputEl.value = result.answer || '';
                        } catch (e) { alert('AI error: ' + e.message); }
                        finally { setAiDoubtLoading(prev => ({ ...prev, [d.id]: false })); }
                      }}
                      style={{ flex: 1, padding: '10px', background: 'linear-gradient(135deg, #7c3aed, #6366f1)', color: 'white', border: 'none', borderRadius: '8px', fontWeight: '700', cursor: aiDoubtLoading[d.id] ? 'wait' : 'pointer', fontSize: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}
                    >
                      {aiDoubtLoading[d.id] ? <><div style={{ width: '12px', height: '12px', border: '2px solid rgba(255,255,255,0.4)', borderTopColor: 'white', borderRadius: '50%', animation: 'spin 1s linear infinite' }}></div> AI Thinking...</> : <><Zap size={12} /> AI Answer</>}
                    </button>
                  )}
                  <button
                    onClick={async () => {
                      const ans = document.getElementById(`ans-${d.id}`).value;
                      if (!ans) return;
                      await updateDoc(doc(db, 'doubts', d.id), {
                        answer: ans,
                        status: 'answered',
                        answeredBy: fullUserData?.name || 'Teacher',
                        answeredAt: serverTimestamp()
                      });
                      alert('Answer submitted!');
                    }}
                    style={{ flex: 1, padding: '10px', background: '#7c3aed', border: 'none', borderRadius: '8px', color: 'white', fontWeight: '700', cursor: 'pointer', fontSize: '12px' }}
                  >
                    Submit
                  </button>
                </div>
              </div>
            ) : (
              <div style={{ padding: '12px', background: 'rgba(16, 185, 129, 0.05)', borderRadius: '8px', border: '1px solid rgba(16, 185, 129, 0.1)' }}>
                <p style={{ fontSize: '13px', color: '#10b981', fontWeight: 'bold', marginBottom: '4px' }}>Teacher Answer:</p>
                <p style={{ fontSize: '14px', color: 'var(--text-main)' }}>{d.answer}</p>
              </div>
            )}
          </div>
        ))}
        {doubts.length === 0 && <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-dim)' }}>No doubts found in your assigned classes.</div>}
      </div>
    </div>
  );
};

export default DoubtHub;
