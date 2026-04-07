//WEBHOOK CHECK 2
const express = require('express');
const app = express();
app.use(express.json());

let tasks = [
  { id: 1, title: 'Learn Docker' },
  { id: 2, title: 'Learn Ansible' }
];

// GET all tasks
app.get('/tasks', (req, res) => {
  res.json(tasks);
});

// POST create task
app.post('/tasks', (req, res) => {
  const task = { id: tasks.length + 1, title: req.body.title };
  tasks.push(task);
  res.status(201).json(task);
});

// Health check — Jenkins will ping this
app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

app.listen(3000, () =>
  console.log('Task API running on port 3000')
);