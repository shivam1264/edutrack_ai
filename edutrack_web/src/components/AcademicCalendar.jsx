import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ChevronLeft, 
  ChevronRight, 
  Calendar as CalendarIcon,
  Clock,
  BookOpen,
  FileText,
  GraduationCap,
  Filter,
  RefreshCcw,
  CheckCircle2,
  AlertCircle,
  MoreVertical,
  Plus
} from 'lucide-react';

const AcademicCalendar = ({ 
  assignments = [], 
  quizzes = [], 
  notes = [], 
  lessonPlans = [],
  classes = [],
  role = 'teacher'
}) => {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedClass, setSelectedClass] = useState('all');

  // Helper to normalize Firestore timestamps or date strings
  const parseDate = (dateVal) => {
    if (!dateVal) return null;
    if (dateVal.toDate && typeof dateVal.toDate === 'function') return dateVal.toDate();
    if (dateVal.seconds) return new Date(dateVal.seconds * 1000);
    return new Date(dateVal);
  };

  // Helper to get local date string YYYY-MM-DD
  const getDateKey = (date) => {
    if (!date) return '';
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
  };

  // Aggregate all events
  const eventsByDate = useMemo(() => {
    const map = {};

    const addEvent = (date, event) => {
      const key = getDateKey(date);
      if (!key) return;
      if (!map[key]) map[key] = [];
      map[key].push(event);
    };

    // Filter by class if selected
    const filterByClass = (item) => {
      if (selectedClass === 'all') return true;
      return item.class_id === selectedClass || item.classId === selectedClass;
    };

    assignments.filter(filterByClass).forEach(a => {
      const date = parseDate(a.dueDate || a.due_date);
      if (date) addEvent(date, { ...a, type: 'assignment', color: '#ef4444' });
    });

    quizzes.filter(filterByClass).forEach(q => {
      const date = parseDate(q.startTime || q.start_time);
      if (date) addEvent(date, { ...q, type: 'quiz', color: '#3b82f6' });
    });

    notes.filter(filterByClass).forEach(n => {
      const date = parseDate(n.createdAt || n.created_at || n.timestamp);
      if (date) addEvent(date, { ...n, type: 'note', color: '#10b981' });
    });

    // lessonPlans prop needs to be added to component destructuring
    (lessonPlans || []).filter(filterByClass).forEach(lp => {
      const date = parseDate(lp.targetDate || lp.created_at || lp.timestamp);
      if (date) addEvent(date, { ...lp, type: 'lesson', color: '#6366f1' });
    });

    return map;
  }, [assignments, quizzes, notes, lessonPlans, selectedClass]);

  // Calendar logic
  const daysInMonth = (year, month) => new Date(year, month + 1, 0).getDate();
  const firstDayOfMonth = (year, month) => new Date(year, month, 1).getDay();

  const handlePrevMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1));
  };

  const handleNextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1));
  };

  const renderCalendar = () => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const totalDays = daysInMonth(year, month);
    const startDay = firstDayOfMonth(year, month);
    const days = [];

    // Padding for empty days at start (adjusting for Monday start if preferred, but usually Sunday start is easier for grid)
    for (let i = 0; i < startDay; i++) {
      days.push(<div key={`empty-${i}`} style={{ height: '100px', border: '1px solid #f1f5f9' }}></div>);
    }

    for (let d = 1; d <= totalDays; d++) {
      const date = new Date(year, month, d);
      const key = getDateKey(date);
      const dayEvents = eventsByDate[key] || [];
      const isToday = getDateKey(new Date()) === key;
      const isSelected = getDateKey(selectedDate) === key;

      days.push(
        <motion.div
          key={d}
          whileHover={{ backgroundColor: '#f8fafc' }}
          onClick={() => setSelectedDate(date)}
          style={{
            height: '100px',
            border: '1px solid #f1f5f9',
            padding: '8px',
            cursor: 'pointer',
            position: 'relative',
            backgroundColor: isSelected ? '#f1f5f9' : 'white',
            transition: 'all 0.2s'
          }}
        >
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '4px'
          }}>
            <span style={{
              fontSize: '14px',
              fontWeight: '700',
              color: isToday ? '#3b82f6' : '#475569',
              background: isToday ? '#dbeafe' : 'transparent',
              width: '24px',
              height: '24px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              borderRadius: '50%'
            }}>
              {d}
            </span>
            {dayEvents.length > 0 && (
              <div style={{
                fontSize: '10px',
                fontWeight: '800',
                color: '#64748b',
                background: '#f1f5f9',
                padding: '2px 6px',
                borderRadius: '10px'
              }}>
                {dayEvents.length}
              </div>
            )}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', overflow: 'hidden' }}>
            {dayEvents.slice(0, 3).map((e, idx) => (
              <div
                key={idx}
                style={{
                  fontSize: '9px',
                  fontWeight: '700',
                  padding: '2px 4px',
                  borderRadius: '4px',
                  background: `${e.color}15`,
                  color: e.color,
                  whiteSpace: 'nowrap',
                  textOverflow: 'ellipsis',
                  overflow: 'hidden',
                  borderLeft: `2px solid ${e.color}`
                }}
              >
                {e.title || 'Untitled'}
              </div>
            ))}
            {dayEvents.length > 3 && (
              <div style={{ fontSize: '8px', color: '#94a3b8', fontWeight: '700', textAlign: 'center' }}>
                +{dayEvents.length - 3} more
              </div>
            )}
          </div>
        </motion.div>
      );
    }

    return days;
  };

  const selectedDayEvents = eventsByDate[getDateKey(selectedDate)] || [];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', paddingBottom: '40px' }}>
      
      {/* Header with Stats & Filters */}
      <div style={{ 
        background: 'linear-gradient(135deg, #6366f1 0%, #4f46e5 100%)', 
        padding: '32px', 
        borderRadius: '24px',
        color: 'white',
        boxShadow: '0 10px 25px rgba(99, 102, 241, 0.2)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center'
      }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
            <div style={{ background: 'rgba(255,255,255,0.2)', padding: '6px', borderRadius: '10px' }}>
              <CalendarIcon size={20} />
            </div>
            <h1 style={{ fontSize: '28px', fontWeight: '900', margin: 0, letterSpacing: '-0.5px' }}>Academic Calendar</h1>
          </div>
          <p style={{ margin: 0, opacity: 0.8, fontWeight: '600', fontSize: '14px' }}>
            Real-time synchronization with Institutional Events, Hub Activities & Deadlines.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          <select
            value={selectedClass}
            onChange={(e) => setSelectedClass(e.target.value)}
            style={{
              padding: '12px 20px',
              borderRadius: '12px',
              background: 'rgba(255,255,255,0.15)',
              border: '1px solid rgba(255,255,255,0.3)',
              color: 'white',
              fontWeight: '700',
              fontSize: '14px',
              outline: 'none',
              backdropFilter: 'blur(10px)',
              cursor: 'pointer'
            }}
          >
            <option value="all" style={{ color: '#1e293b' }}>All Academic Hubs</option>
            {classes.map(cls => (
              <option key={cls.id} value={cls.id} style={{ color: '#1e293b' }}>
                {cls.displayName || `${cls.standard}-${cls.section}`}
              </option>
            ))}
          </select>
          <button style={{
            padding: '12px',
            borderRadius: '12px',
            background: 'rgba(255,255,255,0.15)',
            border: '1px solid rgba(255,255,255,0.3)',
            color: 'white',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            backdropFilter: 'blur(10px)'
          }}>
            <RefreshCcw size={18} />
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: '24px' }}>
        
        {/* Main Calendar Card */}
        <div className="glass-card" style={{ background: 'white', padding: '24px', borderRadius: '24px', boxShadow: '0 4px 20px rgba(0,0,0,0.05)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
            <h2 style={{ fontSize: '20px', fontWeight: '800', color: '#1e293b', margin: 0 }}>
              {currentDate.toLocaleString('default', { month: 'long', year: 'numeric' })}
            </h2>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button onClick={handlePrevMonth} className="btn-icon" style={{ padding: '8px', borderRadius: '10px', background: '#f8fafc', border: 'none', cursor: 'pointer' }}>
                <ChevronLeft size={20} />
              </button>
              <button onClick={() => setCurrentDate(new Date())} style={{ padding: '8px 16px', borderRadius: '10px', background: '#f1f5f9', border: 'none', cursor: 'pointer', fontSize: '13px', fontWeight: '800' }}>
                Today
              </button>
              <button onClick={handleNextMonth} className="btn-icon" style={{ padding: '8px', borderRadius: '10px', background: '#f8fafc', border: 'none', cursor: 'pointer' }}>
                <ChevronRight size={20} />
              </button>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: '0', border: '1px solid #f1f5f9', borderRadius: '16px', overflow: 'hidden' }}>
            {['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map(day => (
              <div key={day} style={{ 
                padding: '12px', 
                textAlign: 'center', 
                fontSize: '11px', 
                fontWeight: '900', 
                color: '#64748b', 
                background: '#f8fafc',
                borderBottom: '1px solid #f1f5f9'
              }}>
                {day}
              </div>
            ))}
            {renderCalendar()}
          </div>

          <div style={{ display: 'flex', gap: '20px', marginTop: '24px', padding: '16px', background: '#f8fafc', borderRadius: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#ef4444' }}></div>
              <span style={{ fontSize: '11px', fontWeight: '800', color: '#64748b' }}>Assignments</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#3b82f6' }}></div>
              <span style={{ fontSize: '11px', fontWeight: '800', color: '#64748b' }}>Quizzes</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#10b981' }}></div>
              <span style={{ fontSize: '11px', fontWeight: '800', color: '#64748b' }}>Study Notes</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#6366f1' }}></div>
              <span style={{ fontSize: '11px', fontWeight: '800', color: '#64748b' }}>Lesson Plans</span>
            </div>
          </div>
        </div>

        {/* Selected Day View */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          
          <div className="glass-card" style={{ background: 'white', padding: '24px', borderRadius: '24px', boxShadow: '0 4px 20px rgba(0,0,0,0.05)', flex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <div>
                <div style={{ fontSize: '12px', fontWeight: '900', color: '#3b82f6', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  {selectedDate.toLocaleDateString('default', { weekday: 'long' })}
                </div>
                <h3 style={{ margin: 0, fontSize: '20px', fontWeight: '800', color: '#1e293b' }}>
                  {selectedDate.toLocaleDateString('default', { day: 'numeric', month: 'short' })}
                </h3>
              </div>
              <button style={{ 
                width: '40px', 
                height: '40px', 
                borderRadius: '50%', 
                background: '#f1f5f9', 
                border: 'none', 
                color: '#3b82f6', 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                cursor: 'pointer'
              }}>
                <Plus size={20} />
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {selectedDayEvents.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '40px 20px', opacity: 0.5 }}>
                  <CalendarIcon size={40} style={{ marginBottom: '12px' }} />
                  <p style={{ margin: 0, fontSize: '14px', fontWeight: '700' }}>No Events Scheduled</p>
                  <p style={{ margin: '4px 0 0 0', fontSize: '12px' }}>Enjoy your free day!</p>
                </div>
              ) : (
                selectedDayEvents.map((e, idx) => (
                  <motion.div
                    key={idx}
                    initial={{ opacity: 0, x: 10 }}
                    animate={{ opacity: 1, x: 0 }}
                    style={{
                      padding: '16px',
                      borderRadius: '16px',
                      background: '#f8fafc',
                      border: '1px solid #f1f5f9',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '16px',
                      position: 'relative',
                      overflow: 'hidden'
                    }}
                  >
                    <div style={{ 
                      width: '4px', 
                      height: '100%', 
                      background: e.color, 
                      position: 'absolute', 
                      left: 0, 
                      top: 0 
                    }} />
                    
                    <div style={{ 
                      width: '40px', 
                      height: '40px', 
                      borderRadius: '12px', 
                      background: `${e.color}15`, 
                      color: e.color,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}>
                      {e.type === 'assignment' && <FileText size={20} />}
                      {e.type === 'quiz' && <BookOpen size={20} />}
                      {e.type === 'note' && <GraduationCap size={20} />}
                    </div>

                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '14px', fontWeight: '800', color: '#1e293b' }}>{e.title}</div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                        <span style={{ fontSize: '11px', fontWeight: '700', color: e.color, textTransform: 'uppercase' }}>
                          {e.type}
                        </span>
                        <span style={{ color: '#cbd5e1' }}>•</span>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '11px', color: '#64748b', fontWeight: '600' }}>
                          <Clock size={12} />
                          {e.startTime || e.dueTime || 'All Day'}
                        </div>
                      </div>
                    </div>

                    <button style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer' }}>
                      <MoreVertical size={16} />
                    </button>
                  </motion.div>
                ))
              )}
            </div>
          </div>

          {/* Quick Shortcuts */}
          <div className="glass-card" style={{ background: '#1e293b', padding: '24px', borderRadius: '24px', color: 'white' }}>
            <h4 style={{ margin: '0 0 16px 0', fontSize: '14px', fontWeight: '800' }}>Institution Legend</h4>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '13px', opacity: 0.7 }}>Academic Working Days</span>
                <span style={{ fontSize: '13px', fontWeight: '800' }}>22 Days</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '13px', opacity: 0.7 }}>Institutional Holidays</span>
                <span style={{ fontSize: '13px', fontWeight: '800', color: '#f87171' }}>08 Days</span>
              </div>
              <div style={{ height: '1px', background: 'rgba(255,255,255,0.1)', margin: '4px 0' }} />
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <AlertCircle size={16} style={{ color: '#fbbf24' }} />
                <span style={{ fontSize: '12px', fontWeight: '600', color: '#fbbf24' }}>Upcoming Parent-Teacher Meet (May 15)</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AcademicCalendar;
