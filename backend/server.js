/**
 * Mada Explorer API
 * Minimal but real backend: JWT auth (access + refresh), Madagascar
 * national parks & endemic species endpoints, in-memory user store.
 *
 * Run: npm install && npm start   (default port 3000)
 */
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

const ACCESS_SECRET = process.env.ACCESS_SECRET || 'mada-explorer-access-secret-dev';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'mada-explorer-refresh-secret-dev';
const ACCESS_TTL = '15m';
const REFRESH_TTL = '7d';

// --- "Database" (in-memory, fine for a demo/learning backend) ---
const users = []; // { id, email, passwordHash, name }
let refreshTokens = new Set();

const parks = JSON.parse(fs.readFileSync(path.join(__dirname, 'data/parks.json'), 'utf-8'));
const species = JSON.parse(fs.readFileSync(path.join(__dirname, 'data/species.json'), 'utf-8'));

function makeTokens(user) {
  const payload = { sub: user.id, email: user.email, name: user.name };
  const accessToken = jwt.sign(payload, ACCESS_SECRET, { expiresIn: ACCESS_TTL });
  const refreshToken = jwt.sign(payload, REFRESH_SECRET, { expiresIn: REFRESH_TTL });
  refreshTokens.add(refreshToken);
  return { accessToken, refreshToken };
}

function authMiddleware(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Missing access token' });
  try {
    req.user = jwt.verify(token, ACCESS_SECRET);
    next();
  } catch (e) {
    return res.status(401).json({ message: 'Access token expired or invalid' });
  }
}

// --- Auth ---
app.post('/auth/register', async (req, res) => {
  const { email, password, name } = req.body || {};
  if (!email || !password || !name) {
    return res.status(400).json({ message: 'name, email and password are required' });
  }
  if (users.find((u) => u.email === email)) {
    return res.status(409).json({ message: 'Email already registered' });
  }
  const passwordHash = await bcrypt.hash(password, 10);
  const user = { id: String(users.length + 1), email, passwordHash, name };
  users.push(user);
  const tokens = makeTokens(user);
  return res.status(201).json({ user: { id: user.id, email, name }, ...tokens });
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  const user = users.find((u) => u.email === email);
  if (!user) return res.status(401).json({ message: 'Invalid credentials' });
  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) return res.status(401).json({ message: 'Invalid credentials' });
  const tokens = makeTokens(user);
  return res.json({ user: { id: user.id, email: user.email, name: user.name }, ...tokens });
});

app.post('/auth/refresh', (req, res) => {
  const { refreshToken } = req.body || {};
  if (!refreshToken || !refreshTokens.has(refreshToken)) {
    return res.status(401).json({ message: 'Invalid refresh token' });
  }
  try {
    const decoded = jwt.verify(refreshToken, REFRESH_SECRET);
    // rotate refresh token
    refreshTokens.delete(refreshToken);
    const user = users.find((u) => u.id === decoded.sub);
    if (!user) return res.status(401).json({ message: 'User no longer exists' });
    const tokens = makeTokens(user);
    return res.json(tokens);
  } catch (e) {
    refreshTokens.delete(refreshToken);
    return res.status(401).json({ message: 'Refresh token expired' });
  }
});

app.post('/auth/logout', (req, res) => {
  const { refreshToken } = req.body || {};
  if (refreshToken) refreshTokens.delete(refreshToken);
  return res.status(204).send();
});

app.get('/profile', authMiddleware, (req, res) => {
  const user = users.find((u) => u.id === req.user.sub);
  if (!user) return res.status(404).json({ message: 'User not found' });
  return res.json({ id: user.id, email: user.email, name: user.name });
});

// --- Parks & species (protected: demonstrates the auth interceptor) ---
app.get('/parks', authMiddleware, (req, res) => res.json(parks));

app.get('/parks/:id', authMiddleware, (req, res) => {
  const park = parks.find((p) => p.id === req.params.id);
  if (!park) return res.status(404).json({ message: 'Park not found' });
  return res.json(park);
});

app.get('/species', authMiddleware, (req, res) => res.json(species));

app.get('/species/:id', authMiddleware, (req, res) => {
  const item = species.find((s) => s.id === req.params.id);
  if (!item) return res.status(404).json({ message: 'Species not found' });
  return res.json(item);
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Mada Explorer API listening on port ${PORT}`));
