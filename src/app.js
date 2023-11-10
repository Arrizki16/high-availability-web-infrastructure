require('dotenv').config({path:'./.env'});
const express = require('express');
const mysql = require('mysql');
const app = express();
const port = 3333;
const multer = require('multer');


app.use(express.json());
// for parsing multipart/form-data
app.use(express.static('public'));
// const upload = multer({
//   limits: {
//     fileSize: 10 * 1024 * 1024, // limit file size to 5MB
//   },
// });
// app.use(upload.array()); 
    
var AWS = require('aws-sdk');

AWS.config.update({
  maxRetries: 3,
  httpOptions: {timeout: 30000, connectTimeout: 5000},
  region: 'ap-southeast-1', //Region
  accessKeyId: process.env.ACCESS_KEY, // Access key ID
  secretAccesskey: process.env.SECRET_ACCESS_KEY // Secret access key
})
      
const s3 = new AWS.S3();

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

app.post('/api/user', (req, res) => {
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

app.get('/api/user/:id', (req, res) => {
  const id = req.params.id

  db.query(
    'SELECT username FROM users WHERE id = ?',
    [id],
    (err, results) => {
      if (err) {
        throw err;
      }

      if (results.length === 0) {
        return res.status(401).json({ message: 'User not found.' });
      }

      const user = results[0];

      return res.status(200).json({ message: `User found. Username: ${user.username}` });
    }
  );
});

// app.post('/api/upload', (req, res) => {
//   const blobData = req.body.data;
//   db.query(
//     'INSERT INTO images (data) VALUES (?)',
//     [blobData],
//     (err, results) => {
//       if (err) {
//         return res.status(400).json({ message: err});
//       }
//       return res.status(400).json({ message: `${results} :: ${blobData}`});
//     }
//   );
//   return res.status(200).json({ message: `File uploaded successfully.`});
// });

// app.get('/api/image/:id', (req, res) => {
//   db.query(
//     'SELECT data FROM images WHERE id = ? ',
//     [req.params.id],
//     (err, results) => {
//       if (err) {
//         throw err;
//       }
//       res.send(results[0]);
//     }
//   )
// });

app.post('/api/image', 
  multer({
    limits: {
      fileSize: 10 * 1024 * 1024, // limit file size to 5MB
    },})
  .single('image'), 
  (req, res) => {
  const params = {
    Bucket: process.env.AWS_BUCKET_NAME,
    Key: req.file.originalname,
    Body: req.file.buffer,
  };

  s3.upload(params, (err, data) => {
    if (err) {
      console.error(err);
      return res.status(500).send('Error uploading file');
    }

    db.query(
      'INSERT INTO images (path) VALUES (?)',
      [req.file.originalname],
      (err, results) => {
        if (err) {
          throw err;
        }
      }
    );

    res.status(201).send('File uploaded successfully');
  });
})

app.get('/api/:id/images', (req, res) => {
  db.query(
    'SELECT path FROM images WHERE id = ?',
    [req.params.id],
    (err, results) => {
      if (err) {
        throw err;
      }

      if (results.length === 0) {
        return res.status(401).json({ message: 'Image not found.' });
      }

      const image = results[0].path;
      var bucket = process.env.AWS_BUCKET_NAME;
      const data = s3.getObject({ bucket, image})
      console.log(data)
      if (data.Body) {
        return res.status(200).send(data.Body.toString("utf-8"))
      } 
      else { 
        return res.status(401).json({ message: 'Image not found.' })
      }
    }
  );
})

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
});

app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});