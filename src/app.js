require('dotenv').config({path:'./.env'});
const express = require('express');
const mysql = require('mysql');
const app = express();
const port = 3333;

app.use(express.json());

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT)
});

db.connect((err) => {
  if (err) {
    throw err;
  }
  console.log('Connected to MySQL database');
});

app.get('/api/version', (req, res) => {
    const version = 'v16.14.2';
    res.send(`Node version: ${version}`);
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

app.post('/api/register', (req, res) => {
  const {username, email, password} = req.body;

  if (!email || !password || !username) {
    return res.status(400).json({ message: 'All fields must be filled.' });
  }

  db.query(
    'SELECT * FROM users WHERE email = ? OR username = ?',
    [email, username],
    (err, results) => {
      if (err) {
        throw err;
      }

      if (results.length === 0) {
        db.query(
          'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
          [username, email, password],
          (err, results) => {
            if (err) {
              throw err;
            }
          }
        );
        return res.status(200).json({ message: `Account created.`});
      }

      if (results.length === 2) {
        if (username === results[0].username || username === results[1].username) {
          return res.status(401).json({ message: `Username ${username} already taken`});
        }
        if (email === results[0].email || email === results[1].email) {
          return res.status(401).json({ message: `Email ${email} has been used`});
        }
      }

      const user = results[0];

      if (username === user.username) {
        return res.status(401).json({ message: `Username ${username} already taken`});
      } else {
        return res.status(401).json({ message: `Email ${email} has been used`});
      }
    }
  );
})

app.post('/api/upload', (req, res) => {
  const blobData = req.body.data;
  db.query(
    'INSERT INTO images (data) VALUES (?)',
    [blobData],
    (err, results) => {
      if (err) {
        throw err;
      }
    }
  );
  return res.status(200).json({ message: `File uploaded successfully.`});
});

app.get('/api/image/:id', (req, res) => {
  db.query(
    'SELECT data FROM images WHERE id = ? ',
    [req.params.id],
    (err, results) => {
      if (err) {
        throw err;
      }
      res.send(`${results[0]}`);
    }
  )
});

app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});