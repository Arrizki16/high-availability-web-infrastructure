const express = require('express');
const app = express();
const port = 1234;

app.use(express.json());

app.get('/api/version', (req, res) => {
  const version = 'v16.14.2';
  res.send(`Node version: ${version}`);
});

app.listen(port, () => {
  console.log(`Server berjalan di http://localhost:${port}`);
});