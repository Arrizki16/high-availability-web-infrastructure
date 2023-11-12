require('dotenv').config({path:'./.env'});
const express = require('express');
// const multer = require('multer');
const { Storage } = require('@google-cloud/storage');
const mysql = require('mysql');
const Multer = require('multer');
const app = express();
const port = 3333;

app.use(express.json());
app.use(express.static('public'));

// const storage = multer.memoryStorage();
// // const upload = multer({ storage: storage });

// const storageGCS = new Storage({
//   projectId: 'rpl-project-404906',
//   keyFilename: 'csql-ce-cs.json',
// });


// const upload = multer({
//   limits: {
//     fileSize: 10 * 1024 * 1024, // limit file size to 10MB
//   },
// }).single('image');

// const bucket = storageGCS.bucket('rpl-cs-revision');


const db = mysql.createConnection({
  host: "34.143.140.100",
  user: "root",
  password: "password",
  database: "rpl",
  port: 3306
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


// app.post('/api/image',
//   multer({
//     limits: {
//       fileSize: 10 * 1024 * 1024, // limit file size to 5MB
//     },})
//   .single('image'), 
//   (req, res) => {
//     if (err) {
//       console.error(err);
//       return res.status(500).send('Error uploading file');
//     }

//     const params = {
//       metadata: {
//         contentType: req.file.mimetype,
//       },
//     };

//     const blob = bucket.file(req.file.originalname);
//     const blobStream = blob.createWriteStream(params);

//     blobStream.on('error', (err) => {
//       console.error(err);
//       return res.status(500).send('Error uploading file to GCS');
//     });

//     blobStream.on('finish', () => {
//       // File uploaded successfully to GCS
//       const publicUrl = `https://storage.googleapis.com/${bucket.name}/${blob.name}`;

//       // Store file path in MySQL database
//       db.query(
//         'INSERT INTO images (path) VALUES (?)',
//         [publicUrl],
//         (err, results) => {
//           if (err) {
//             throw err;
//           }

//           res.status(201).send('File uploaded successfully');
//         }
//       );
//     });

//     blobStream.end(req.file.buffer);
//   });
;

// app.post('/api/image', 
//   multer({
//     limits: {
//       fileSize: 10 * 1024 * 1024, // limit file size to 5MB
//     },})
//   .single('image'), 
//   (req, res) => {
//   const params = {
//     Bucket: process.env.AWS_BUCKET_NAME,
//     Key: req.file.originalname,
//     Body: req.file.buffer,
//   };

//   s3.upload(params, (err, data) => {
//     if (err) {
//       console.error(err);
//       return res.status(500).send('Error uploading file');
//     }

//     db.query(
//       'INSERT INTO images (path) VALUES (?)',
//       [req.file.originalname],
//       (err, results) => {
//         if (err) {
//           throw err;
//         }
//       }
//     );

//     res.status(201).send('File uploaded successfully');
//   });
// })

// app.get('/api/:id/images', (req, res) => {
//   db.query(
//     'SELECT path FROM images WHERE id = ?',
//     [req.params.id],
//     (err, results) => {
//       if (err) {
//         throw err;
//       }

//       if (results.length === 0) {
//         return res.status(401).json({ message: 'Image not found.' });
//       }

//       const image = results[0].path;
//       const getParams = {
//         Bucket: process.env.AWS_BUCKET_NAME,
//         Key: image
//       }
//       s3.getObject(getParams, function(err, data) {
//         if (err) {
//           return res.status(401).json({ message: 'Image not found.' })
//         } 
//         else { 
//           return res.status(200).send(data.Body)
//         }
//       })
//     }
//   );
// })

const storage = new Storage({ keyFilename: 'csql-ce-cs.json' });

const multer = Multer({
  storage: Multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
});

const bucketName = "rpl-cs-revision";

app.post('/api/image', multer.single('image'), async (req, res) => {
  try {
    const bucket = storage.bucket(bucketName);

    const file = bucket.file(req.file.originalname);
    const stream = file.createWriteStream({
      metadata: {
        contentType: req.file.mimetype,
      },
      resumable: false,
    });

    stream.on('error', (err) => {
      console.error(err);
      res.status(500).send('Error uploading file to Google Cloud Storage');
    });

    stream.on('finish', async () => {
      try {
        // Insert into the database
        await db.query('INSERT INTO images (path) VALUES (?)', [req.file.originalname]);

        res.status(201).send('File uploaded successfully');
      } catch (dbError) {
        console.error(dbError);
        res.status(500).send('Error inserting into the database');
      }
    });

    stream.end(req.file.buffer);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error uploading file');
  }
});

