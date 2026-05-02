import React, { useState, useEffect, useRef } from 'react';
import { db } from '../firebase';
import { collection, addDoc, onSnapshot, query, where, orderBy, serverTimestamp, doc, getDoc } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { MessageSquare, Send, Search, Users, ChevronLeft } from 'lucide-react';

export default function Messages({ role, user, classes, allUsers, fullUserData }) {
  const [conversations, setConversations] = useState([]);
  const [selectedConvo, setSelectedConvo] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [contactType, setContactType] = useState('parent'); // 'parent' or 'teacher'
  const messagesEndRef = useRef(null);

  // Get all parents for teacher to chat with
  const parents = (allUsers || []).filter(u => u.role === 'parent');
  const teachers = (allUsers || []).filter(u => u.role === 'teacher');

  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'messages'), where('participants', 'array-contains', user.uid)),
      (snap) => {
        const convos = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        // Client-side sort to avoid composite index requirement
        convos.sort((a, b) => {
          const tA = a.lastMessageAt?.toMillis ? a.lastMessageAt.toMillis() : 0;
          const tB = b.lastMessageAt?.toMillis ? b.lastMessageAt.toMillis() : 0;
          return tB - tA;
        });
        setConversations(convos);
      },
      (error) => {
        console.error("Messages query error:", error);
        setConversations([]);
      }
    );
    return unsub;
  }, [user.uid]);

  useEffect(() => {
    if (!selectedConvo) return;
    const unsub = onSnapshot(
      query(collection(db, 'messages', selectedConvo.id, 'chats'), orderBy('timestamp', 'asc')),
      (snap) => {
        setMessages(snap.docs.map(d => ({ id: d.id, ...d.data() })));
        setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
      }
    );
    return unsub;
  }, [selectedConvo]);

  const startConversation = async (otherUser) => {
    // Check if conversation already exists
    const existing = conversations.find(c => c.participants?.includes(otherUser.id));
    if (existing) {
      setSelectedConvo(existing);
      return;
    }
    // Create new conversation
    const docRef = await addDoc(collection(db, 'messages'), {
      participants: [user.uid, otherUser.id],
      participantNames: { [user.uid]: fullUserData?.name || 'Teacher', [otherUser.id]: otherUser.name || 'Parent' },
      lastMessage: '',
      lastMessageAt: serverTimestamp(),
      createdAt: serverTimestamp()
    });
    const newConvo = { id: docRef.id, participants: [user.uid, otherUser.id], participantNames: { [user.uid]: fullUserData?.name, [otherUser.id]: otherUser.name } };
    setSelectedConvo(newConvo);
  };

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedConvo) return;
    const msg = newMessage.trim();
    setNewMessage('');
    await addDoc(collection(db, 'messages', selectedConvo.id, 'chats'), {
      text: msg,
      senderId: user.uid,
      senderName: fullUserData?.name || 'User',
      timestamp: serverTimestamp()
    });
    // Update last message in conversation
    const { updateDoc: updateDocFn } = await import('firebase/firestore');
    await updateDocFn(doc(db, 'messages', selectedConvo.id), {
      lastMessage: msg,
      lastMessageAt: serverTimestamp()
    });
  };

  const getOtherName = (convo) => {
    if (!convo.participantNames) return 'Unknown';
    const otherId = convo.participants?.find(p => p !== user.uid);
    return convo.participantNames?.[otherId] || 'User';
  };

  const contactList = contactType === 'teacher' ? teachers : parents;
  const filteredContacts = contactList.filter(u =>
    (u.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    u.email?.toLowerCase().includes(searchTerm.toLowerCase())) &&
    u.id !== user.uid
  );

  return (
    <div style={{ display: 'flex', height: 'calc(100vh - 80px)', gap: '0', overflow: 'hidden' }}>
      {/* Sidebar - Conversations */}
      <div style={{
        width: selectedConvo ? '320px' : '100%',
        borderRight: '1px solid var(--glass-border)',
        display: 'flex', flexDirection: 'column',
        background: 'var(--glass-surface)',
        borderRadius: '16px 0 0 16px',
        overflow: 'hidden',
        transition: 'width 0.3s ease'
      }}>
        <div style={{ padding: '24px 20px', borderBottom: '1px solid var(--glass-border)', background: 'rgba(255,255,255,0.02)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3 style={{ margin: 0, fontSize: '22px', fontWeight: '900', letterSpacing: '-0.5px' }}>
              <span className="gradient-text">Messages</span>
            </h3>
            <div style={{ display: 'flex', gap: '4px', background: 'var(--glass-surface)', padding: '4px', borderRadius: '10px', border: '1px solid var(--glass-border)' }}>
              <button 
                onClick={() => setContactType('teacher')}
                style={{ 
                  padding: '6px 12px', borderRadius: '7px', fontSize: '11px', fontWeight: '800', border: 'none', cursor: 'pointer',
                  background: contactType === 'teacher' ? 'var(--primary)' : 'transparent',
                  color: contactType === 'teacher' ? 'white' : 'var(--text-dim)',
                  transition: 'all 0.2s ease'
                }}
              >TEACHERS</button>
              <button 
                onClick={() => setContactType('parent')}
                style={{ 
                  padding: '6px 12px', borderRadius: '7px', fontSize: '11px', fontWeight: '800', border: 'none', cursor: 'pointer',
                  background: contactType === 'parent' ? 'var(--primary)' : 'transparent',
                  color: contactType === 'parent' ? 'white' : 'var(--text-dim)',
                  transition: 'all 0.2s ease'
                }}
              >PARENTS</button>
            </div>
          </div>
          <div style={{ position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)', opacity: 0.5 }} />
            <input
              className="glass-input"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder={`Search ${contactType}s...`}
              style={{ width: '100%', paddingLeft: '40px', fontSize: '14px', height: '44px', background: 'var(--glass-surface)', border: '1px solid var(--glass-border)' }}
            />
          </div>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', padding: '8px' }}>
          {/* New Contact List */}
          <p style={{ fontSize: '10px', fontWeight: '900', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1.5px', padding: '20px 12px 8px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Users size={12} />
            Available {contactType}s
          </p>
          {(filteredContacts || []).map(u => (
            <motion.div
              key={u.id}
              whileHover={{ background: 'var(--glass-surface-hover)' }}
              onClick={() => startConversation(u)}
              style={{ padding: '10px 12px', borderRadius: '10px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px' }}
            >
              <div style={{ width: '34px', height: '34px', borderRadius: '50%', background: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: '800', fontSize: '12px', flexShrink: 0 }}>
                {u.name?.charAt(0).toUpperCase() || '?'}
              </div>
              <div>
                <p style={{ margin: 0, fontSize: '13px', fontWeight: '600', color: 'var(--text-main)' }}>{u.name || 'Unnamed'}</p>
                <p style={{ margin: 0, fontSize: '11px', color: 'var(--text-dim)' }}>{u.role} • {u.email}</p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Chat Area */}
      {selectedConvo && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: 'var(--card-bg)', borderRadius: '0 16px 16px 0' }}>
          {/* Chat Header */}
          <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--glass-border)', display: 'flex', alignItems: 'center', gap: '12px' }}>
            <motion.div whileHover={{ scale: 1.1 }} onClick={() => setSelectedConvo(null)} style={{ cursor: 'pointer', color: 'var(--text-dim)' }}>
              <ChevronLeft size={20} />
            </motion.div>
            <div style={{ width: '38px', height: '38px', borderRadius: '50%', background: 'var(--secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: '800' }}>
              {getOtherName(selectedConvo).charAt(0).toUpperCase()}
            </div>
            <div>
              <p style={{ margin: 0, fontSize: '15px', fontWeight: '700', color: 'var(--text-main)' }}>{getOtherName(selectedConvo)}</p>
              <p style={{ margin: 0, fontSize: '11px', color: '#10b981', fontWeight: '600' }}>Online</p>
            </div>
          </div>

          {/* Messages */}
          <div style={{ flex: 1, overflowY: 'auto', padding: '20px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {messages.length === 0 && (
              <div style={{ textAlign: 'center', color: 'var(--text-dim)', marginTop: '60px' }}>
                <MessageSquare size={40} style={{ opacity: 0.3, marginBottom: '12px' }} />
                <p style={{ fontSize: '14px', fontWeight: '600' }}>Start the conversation</p>
              </div>
            )}
            {messages.map(msg => {
              const isMe = msg.senderId === user.uid;
              return (
                <div key={msg.id} style={{ display: 'flex', justifyContent: isMe ? 'flex-end' : 'flex-start' }}>
                  <div style={{
                    maxWidth: '75%', padding: '12px 18px',
                    borderRadius: isMe ? '20px 20px 4px 20px' : '20px 20px 20px 4px',
                    background: isMe ? 'linear-gradient(135deg, #3b82f6, #2563eb)' : 'var(--glass-surface)',
                    color: isMe ? 'white' : 'var(--text-main)',
                    border: isMe ? 'none' : '1px solid var(--glass-border)',
                    boxShadow: isMe ? '0 4px 15px rgba(59, 130, 246, 0.2)' : '0 2px 10px rgba(0,0,0,0.05)',
                    position: 'relative'
                  }}>
                    <p style={{ margin: 0, fontSize: '14.5px', lineHeight: '1.6', fontWeight: '500' }}>{msg.text}</p>
                    <p style={{ margin: '6px 0 0 0', fontSize: '10px', opacity: 0.6, textAlign: 'right', fontWeight: '700' }}>
                      {msg.timestamp?.toDate?.()?.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }) || 'Now'}
                    </p>
                  </div>
                </div>
              );
            })}
            <div ref={messagesEndRef} />
          </div>

          {/* Input */}
          <form onSubmit={sendMessage} style={{ padding: '16px 20px', borderTop: '1px solid var(--glass-border)', display: 'flex', gap: '12px' }}>
            <input
              className="glass-input"
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              placeholder="Type a message..."
              style={{ flex: 1 }}
            />
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              type="submit"
              style={{ padding: '12px 20px', borderRadius: '12px', display: 'flex', alignItems: 'center', gap: '6px' }}
            >
              <Send size={16} />
            </motion.button>
          </form>
        </div>
      )}
    </div>
  );
}
