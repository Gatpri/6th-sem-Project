const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');

module.exports = (pool) => {

  router.post('/secure-transfer', async (req, res) => {
    const { senderMobile, receiverMobile, amount, releaseDate, transactionPin } = req.body;

    if (!transactionPin) {
      return res.status(400).json({ error: 'Transaction PIN is required.' });
    }

    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      const amountNum = parseFloat(amount);
      if (isNaN(amountNum) || amountNum < 10) {
        throw new Error("Amount must be at least 10");
      }

      // 1. Fetch sender's hashed PIN
      const [pinRows] = await connection.query(
        'SELECT transaction_pin FROM users WHERE mobile = ?', [senderMobile]
      );
      if (pinRows.length === 0) throw new Error("Sender not found");

      const storedHash = pinRows[0].transaction_pin;
      if (!storedHash) throw new Error("Transaction PIN not set");

      // 2. Verify transaction PIN
      const pinMatch = await bcrypt.compare(transactionPin, storedHash);
      if (!pinMatch) throw new Error("Invalid transaction PIN");

      // 3. Check sender balance
      const [senderRows] = await connection.query(
        'SELECT balance FROM users WHERE mobile = ?', [senderMobile]
      );
      if (senderRows.length === 0) throw new Error("Sender not found");
      if (parseFloat(senderRows[0].balance) < amountNum) throw new Error("Insufficient funds");

      // 4. Check if receiver exists
      const [receiverRows] = await connection.query(
        'SELECT mobile FROM users WHERE mobile = ?', [receiverMobile]
      );
      if (receiverRows.length === 0) throw new Error("Receiver not found");

      // 5. Deduct balance from sender
      await connection.query(
        'UPDATE users SET balance = balance - ? WHERE mobile = ?', [amountNum, senderMobile]
      );

      // 6. Add to receiver's held_balance
      await connection.query(
        'UPDATE users SET held_balance = held_balance + ? WHERE mobile = ?', [amountNum, receiverMobile]
      );

      // 7. Insert into securedtransfer table with 'held' status
      await connection.query(
        'INSERT INTO securedtransfer (sender_mobile, receiver_mobile, amount, status, hold_until) VALUES (?, ?, ?, ?, ?)',
        [senderMobile, receiverMobile, amountNum, 'held', releaseDate || null]
      );

      // 8. Log into transactions table
      await connection.query(
        'INSERT INTO transactions (sender_mobile, receiver_mobile, amount, status) VALUES (?, ?, ?, ?)',
        [senderMobile, receiverMobile, amountNum, 'held']
      );

      await connection.commit();

      res.status(200).json({
        message: "Secure transfer initiated and amount held successfully.",
      });

    } catch (err) {
      await connection.rollback();
      res.status(400).json({ error: err.message });
    } finally {
      connection.release();
    }
  });

  // ... your return-transfer route unchanged

  return router;
};










