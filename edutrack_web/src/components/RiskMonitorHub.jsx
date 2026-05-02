import React from 'react';
import {
  ShieldAlert,
  ShieldCheck,
  AlertTriangle
} from 'lucide-react';

const RiskMonitorHub = ({ predictions, allUsers }) => {
  const riskStudents = predictions
    .filter(p => p.risk_level === 'high' || p.risk_level === 'medium')
    .sort((a, b) => {
      if (a.risk_level === 'high' && b.risk_level !== 'high') return -1;
      if (a.risk_level !== 'high' && b.risk_level === 'high') return 1;
      return (a.performance_score || 0) - (b.performance_score || 0); // lower score first means higher risk
    })
    .slice(0, 10);

  return (
    <div className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
      <div style={{
        background: 'linear-gradient(135deg, #0F172A, #334155)',
        padding: '40px 32px',
        borderBottom: '1px solid var(--glass-border)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: '16px'
      }}>
        <div>
          <h2 style={{ margin: '0 0 8px 0', color: 'white', fontSize: '26px', fontWeight: '900' }}>AI Risk Monitor</h2>
          <p style={{ margin: 0, color: 'rgba(255,255,255,0.7)', fontSize: '13px' }}>Identifying the Top 10 students requiring academic intervention.</p>
        </div>
        <div style={{ padding: '6px 14px', background: 'rgba(244, 63, 94, 0.1)', color: '#f43f5e', borderRadius: '20px', border: '1px solid rgba(244, 63, 94, 0.3)', fontSize: '11px', fontWeight: '900', letterSpacing: '1.2px' }}>
          PROACTIVE
        </div>
      </div>

      <div style={{ padding: '32px', background: 'var(--card-bg)' }}>
        {riskStudents.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '60px 20px', color: 'var(--text-dim)' }}>
            <ShieldCheck size={64} color="#10b981" style={{ opacity: 0.2, marginBottom: '16px' }} />
            <p style={{ fontWeight: '600', color: 'var(--text-main)', fontSize: '15px' }}>All students are currently within safe academic thresholds.</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {riskStudents.map((pred, i) => {
              const isHigh = pred.risk_level === 'high';
              const score = (pred.performance_score || 0) * 100;
              const student = allUsers.find(u => u.id === pred.student_id);
              const name = student?.name || 'Loading Student...';
              const classId = student?.class_id || 'Unknown Class';
              const iconColor = isHigh ? '#ef4444' : '#f59e0b';
              const iconBg = isHigh ? 'rgba(239, 68, 68, 0.1)' : 'rgba(245, 158, 11, 0.1)';

              return (
                <div key={pred.student_id || i} style={{ display: 'flex', alignItems: 'center', background: 'var(--glass-surface)', padding: '20px', borderRadius: '16px', border: '1px solid var(--glass-border)', boxShadow: '0 4px 10px rgba(0,0,0,0.02)', transition: 'transform 0.2s' }}>
                  <div style={{ padding: '12px', background: iconBg, color: iconColor, borderRadius: '50%', marginRight: '20px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    {isHigh ? <ShieldAlert size={24} /> : <AlertTriangle size={24} />}
                  </div>
                  <div style={{ flex: 1 }}>
                    <h4 style={{ margin: 0, fontSize: '18px', fontWeight: '900', color: 'var(--text-main)' }}>{name}</h4>
                    <div style={{ margin: '4px 0 0 0', fontSize: '13px', color: 'var(--text-dim)' }}>Hub: {String(classId || 'Global')}</div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '20px', fontWeight: '900', color: iconColor }}>
                      {score.toFixed(0)}%
                    </div>
                    <div style={{ fontSize: '11px', fontWeight: '900', color: iconColor, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                      {pred.risk_level} RISK
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default RiskMonitorHub;
