const { Storage } = require('@google-cloud/storage');
const Multer = require('multer');
const storage = new Storage();

const app = express();
const port = 3333;

// Configure Multer for Google Cloud Storage
const multer = Multer({
  storage: Multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // limit file size to 10MB
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

    stream.end(req.file.buffer);

    // Wait for the upload to finish
    await stream.promise();

    // Insert into the database
    db.query('INSERT INTO images (path) VALUES (?)', [req.file.originalname], (err, results) => {
      if (err) {
        console.error(err);
        return res.status(500).send('Error inserting into the database');
      }
    });

    res.status(201).send('File uploaded successfully');
  } catch (err) {
    console.error(err);
    res.status(500).send('Error uploading file');
  }
});
