import React from 'react';
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import TodoPage from './pages/TodoPage';
import MonitorPage from './pages/MonitorPage';

function App() {
  return (
    <BrowserRouter>
      <div style={{ maxWidth: 960, margin: '2rem auto', fontFamily: 'sans-serif' }}>
        <nav style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
          <Link to="/">To-Do</Link>
          <Link to="/monitor">CI/CD Monitor</Link>
        </nav>
        <Routes>
          <Route path="/" element={<TodoPage />} />
          <Route path="/monitor" element={<MonitorPage />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}

export default App;
