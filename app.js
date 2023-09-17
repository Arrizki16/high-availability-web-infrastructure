const express = require('express');
const mysql = require('mysql');
const app = express();
const port = 1234;

app.use(express.json());

const db = mysql.createConnection({
  host: 'soon',
  user: 'soon',
  password: 'soon',
  database: 'soon',
});

db.connect((err) => {
  if (err) {
    throw err;
  }
  console.log('Connected to MySQL database');
});

app.post('/api/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }

  db.query(
    'SELECT * FROM users WHERE email = ?',
    [email],
    (err, results) => {
      if (err) {
        throw err;
      }

      if (results.length === 0) {
        return res.status(401).json({ message: 'Incorrect email.' });
      }

      const user = results[0];

      if (password === user.password) {
        return res.status(200).json({ message: `Login successful. Welcome, ${user.username}!` });
      } else {
        return res.status(401).json({ message: 'Incorrect password.' });
      }
    }
  );
});

app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});