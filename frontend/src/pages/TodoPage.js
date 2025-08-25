import React, { useEffect, useState } from 'react';
import axios from 'axios';

export default function TodoPage() {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');

  const fetchTasks = async () => {
    const res = await axios.get('/api/tasks');
    setTasks(res.data);
  };

  useEffect(() => { fetchTasks(); }, []);

  const addTask = async (e) => {
    e.preventDefault();
    if (!title) return;
    await axios.post('/api/tasks', { title, description });
    setTitle(''); setDescription('');
    fetchTasks();
  };

  const markComplete = async (id, completed) => {
    await axios.put(`/api/tasks/${id}`, { completed });
    fetchTasks();
  };

  const deleteTask = async (id) => {
    await axios.delete(`/api/tasks/${id}`);
    fetchTasks();
  };

  return (
    <div style={{ maxWidth: 500, margin: '2rem auto', fontFamily: 'sans-serif' }}>
      <h2>To-Do List</h2>
      <form onSubmit={addTask} style={{ marginBottom: 20 }}>
        <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Title" required style={{ width: '100%', marginBottom: 8 }} />
        <textarea value={description} onChange={e => setDescription(e.target.value)} placeholder="Description" style={{ width: '100%', marginBottom: 8 }} />
        <button type="submit">Add Task</button>
      </form>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {tasks.map(task => (
          <li key={task.id} style={{ marginBottom: 12, background: '#f9f9f9', padding: 10, borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <input type="checkbox" checked={task.completed} onChange={() => markComplete(task.id, !task.completed)} />
              <span style={{ textDecoration: task.completed ? 'line-through' : 'none', marginLeft: 8 }}>{task.title}</span>
              <div style={{ fontSize: 12, color: '#666' }}>{task.description}</div>
            </div>
            <button onClick={() => deleteTask(task.id)} style={{ color: 'red', border: 'none', background: 'none', cursor: 'pointer' }}>Delete</button>
          </li>
        ))}
      </ul>
    </div>
  );
}

