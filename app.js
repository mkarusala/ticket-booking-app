const express = require('express');
const app = express();
const PORT = 3000;

// Simple health check and confirmation message
app.get('/', (req, res) => {
  res.status(200).send({
    message: 'Ticket Booking Service is up and running!',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'production' // Set to production in the container
  });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
