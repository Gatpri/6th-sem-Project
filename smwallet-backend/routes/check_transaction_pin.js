
const express = require('express');
const router = express.Router();

module.exports = (pool) => {
  router.post('/check-transaction-pin', async (req, res) => {
    const { mobile } = req.body;
    try {
      const [rows] = await pool.query('SELECT transaction_pin FROM users WHERE mobile = ?', [mobile]);
      if (rows.length > 0 && rows[0].transaction_pin) {
        res.json({ hasPin: true });
      } else {
        res.json({ hasPin: false });
      }
    } catch (err) {
      console.error("Check PIN error:", err);
      res.status(500).json({ message: 'Server error' });
    }
  });

  return router;
};
