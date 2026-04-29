import React, { useState } from 'react';
import { auth, db } from './firebase';
import { signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import logo from './assets/Edu_track-logo.png';

function Login({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Fetch role from Firestore
      const userDoc = await getDoc(doc(db, 'users', user.uid));
      if (userDoc.exists()) {
        const userData = userDoc.data();
        const role = userData.role || 'student';
        
        if (role !== 'admin' && role !== 'teacher') {
          await signOut(auth);
          setError('Access Denied: Web Dashboard is restricted to Admin & Faculty. Please use the Mobile App.');
          return;
        }

        onLogin(user, role);
      } else {
        setError('User record not found in database.');
      }
    } catch (err) {
      console.error(err);
      setError('Invalid email or password. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="glass-card login-card">
        <img src={logo} alt="Logo" style={{ width: '180px', marginBottom: '24px' }} />
        <h1 className="gradient-text" style={{ fontSize: '32px', marginBottom: '8px' }}>EduTrack AI</h1>
        <p style={{ color: 'var(--text-dim)', marginBottom: '32px' }}>Login to your dashboard</p>

        {error && <div className="error-badge">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="login-input-group">
            <label>Email Address</label>
            <input 
              type="email" 
              placeholder="name@school.com" 
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div className="login-input-group">
            <label>Password</label>
            <input 
              type="password" 
              placeholder="••••••••" 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <button 
            type="submit" 
            style={{ width: '100%', padding: '16px', fontSize: '16px', marginTop: '16px' }}
            disabled={loading}
          >
            {loading ? 'Authenticating...' : 'Sign In'}
          </button>
        </form>

        <p style={{ marginTop: '24px', fontSize: '14px', color: 'var(--text-dim)' }}>
          Don't have an account? Contact your administrator.
        </p>
      </div>
    </div>
  );
}

export default Login;
