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
  const messagesEndRef = useRef(null);

  // Get all parents for teacher to chat with
  const parents = allUsers.filter(u => u.role === 'parent');
  const teachers = allUsers.filter(u => u.role === 'teacher');

  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'messages'), where('participants', 'array-contains', user.uid), orderBy('lastMessageAt', 'desc')),
      (snap) => {
        setConversations(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      },
      () => {
        // Fallback if no index: load all messages involving user
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

  const contactList = role === 'teacher' ? parents : [...teachers, ...parents];
  const filteredContacts = contactList.filter(u =>
    u.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    u.email?.toLowerCase().includes(searchTerm.toLowerCase())
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
        <div style={{ padding: '20px', borderBottom: '1px solid var(--glass-border)' }}>
          <h3 style={{ margin: '0 0 12px 0', fontSize: '20px' }}>
            <span className="gradient-text">Messages</span>
          </h3>
          <div style={{ position: 'relative' }}>
            <Search size={14} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-dim)' }} />
            <input
              className="glass-input"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search contacts..."
              style={{ width: '100%', paddingLeft: '34px', fontSize: '13px', padding: '10px 12px 10px 34px' }}
            />
          </div>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', padding: '8px' }}>
          {/* Active Conversations */}
          {conversations.length > 0 && (
            <>
              <p style={{ fontSize: '10px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px', padding: '8px 12px' }}>Recent Chats</p>
              {conversations.map(convo => (
                <motion.div
                  key={convo.id}
                  whileHover={{ background: 'var(--glass-surface-hover)' }}
                  onClick={() => setSelectedConvo(convo)}
                  style={{
                    padding: '12px', borderRadius: '12px', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', gap: '12px',
                    background: selectedConvo?.id === convo.id ? 'var(--glass-surface-hover)' : 'transparent'
                  }}
                >
                  <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'var(--secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: '800', fontSize: '14px', flexShrink: 0 }}>
                    {getOtherName(convo).charAt(0).toUpperCase()}
                  </div>
                  <div style={{ flex: 1, overflow: 'hidden' }}>
                    <p style={{ margin: 0, fontSize: '14px', fontWeight: '600', color: 'var(--text-main)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{getOtherName(convo)}</p>
                    <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-dim)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{convo.lastMessage || 'No messages yet'}</p>
                  </div>
                </motion.div>
              ))}
            </>
          )}

          {/* New Contact List */}
          <p style={{ fontSize: '10px', fontWeight: '800', color: 'var(--text-dim)', textTransform: 'uppercase', letterSpacing: '1px', padding: '12px 12px 6px' }}>
            {role === 'teacher' ? 'Parents' : 'All Contacts'}
          </p>
          {filteredContacts.map(u => (
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
                    maxWidth: '70%', padding: '12px 16px',
                    borderRadius: isMe ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                    background: isMe ? 'linear-gradient(135deg, var(--primary), var(--secondary))' : 'var(--glass-surface)',
                    color: isMe ? 'white' : 'var(--text-main)',
                    border: isMe ? 'none' : '1px solid var(--glass-border)'
                  }}>
                    <p style={{ margin: 0, fontSize: '14px', lineHeight: '1.5' }}>{msg.text}</p>
                    <p style={{ margin: '6px 0 0 0', fontSize: '10px', opacity: 0.7, textAlign: 'right' }}>
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
