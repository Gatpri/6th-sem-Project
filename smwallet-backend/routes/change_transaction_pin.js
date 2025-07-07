const express = require('express');
const bcrypt = require('bcrypt');
const router = express.Router();

module.exports = (pool) => {
  router.post('/change-transaction-pin', async (req, res) => {
    const { mobile, currentPin, newPin } = req.body;

    if (!mobile || !currentPin || !newPin) {
      return res.status(400).json({ message: 'All fields are required.' });
    }

    try {
      const [rows] = await pool.query('SELECT transaction_pin FROM users WHERE mobile = ?', [mobile]);

      if (rows.length === 0 || !rows[0].transaction_pin) {
        return res.status(404).json({ message: 'User or PIN not found.' });
      }

      const pinMatch = await bcrypt.compare(currentPin, rows[0].transaction_pin);
      if (!pinMatch) {
        return res.status(400).json({ message: 'Current PIN is incorrect.' });
      }

      const hashedNewPin = await bcrypt.hash(newPin, 10);
      await pool.query('UPDATE users SET transaction_pin = ? WHERE mobile = ?', [hashedNewPin, mobile]);

      res.json({ message: 'Transaction PIN changed successfully.' });
    } catch (err) {
      console.error("Error changing PIN:", err);
      res.status(500).json({ message: 'Server error.' });
    }
  });

  return router;
};
