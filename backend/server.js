const express = require('express');
const app = express();

app.get(['/', '/health'], (req, res) => {
  res.send('The backend is up');
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`backend listening on ${port}`));
