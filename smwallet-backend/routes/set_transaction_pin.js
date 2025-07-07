const express = require('express');
const bcrypt = require('bcrypt');
const router = express.Router();

module.exports = (pool) => {
  router.post('/set-transaction-pin', async (req, res) => {
    const { mobile, pin } = req.body;

    if (!mobile || !pin) {
      return res.status(400).json({ message: 'Mobile and PIN are required.' });
    }

    try {
      const hashedPin = await bcrypt.hash(pin, 10);
      const connection = await pool.getConnection();

      await connection.query(
        'UPDATE users SET transaction_pin = ? WHERE mobile = ?',
        [hashedPin, mobile]
      );

      connection.release();
      res.json({ message: 'Transaction PIN saved securely.' });
    } catch (error) {
      console.error('Error setting transaction PIN:', error);
      res.status(500).json({ message: 'Internal server error.' });
    }
  });

  return router;
};
