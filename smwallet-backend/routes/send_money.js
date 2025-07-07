const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');

module.exports = (pool) => {

  router.post('/send-money', async (req, res) => {
    const { senderMobile, receiverMobile, amount, transactionPin } = req.body;

    if (!transactionPin) {
      return res.status(400).json({ error: 'Transaction PIN is required.' });
    }

    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // 1. Fetch sender's hashed PIN
      const [pinRows] = await connection.query(
        'SELECT transaction_pin FROM users WHERE mobile = ?', [senderMobile]
      );
      if (pinRows.length === 0) {
        throw new Error("Sender not found");
      }

      const storedHash = pinRows[0].transaction_pin;
      if (!storedHash) {
        throw new Error("Transaction PIN not set for sender");
      }

      // 2. Verify PIN
      const pinMatch = await bcrypt.compare(transactionPin, storedHash);
      if (!pinMatch) {
        throw new Error("Invalid transaction PIN");
      }

      // 3. Validate amount
      const amountNum = parseFloat(amount);
      if (isNaN(amountNum) || amountNum <= 10) {
        throw new Error("Amount must be greater than 10");
      }

      // 4. Fetch sender balance
      const [senderRows] = await connection.query(
        'SELECT balance FROM users WHERE mobile = ?', [senderMobile]
      );



      const senderBalance = parseFloat(senderRows[0].balance);
      if (senderBalance < amountNum) {
        throw new Error("Insufficient funds");
      }

      // 5. Ensure receiver exists
      const [receiverRows] = await connection.query(
        'SELECT balance FROM users WHERE mobile = ?', [receiverMobile]
      );

      if (receiverRows.length === 0) {
        throw new Error("Receiver not found");
      }

      // 6. Update balances
      await connection.query(
        'UPDATE users SET balance = balance - ? WHERE mobile = ?', [amountNum, senderMobile]
      );

      await connection.query(
        'UPDATE users SET balance = balance + ? WHERE mobile = ?', [amountNum, receiverMobile]
      );

      // 7. Insert transaction record
      await connection.query(
        `INSERT INTO transactions
          (sender_mobile, receiver_mobile, amount, created_at, status)
         VALUES (?, ?, ?, NOW(), 'normal')`,
        [senderMobile, receiverMobile, amountNum]
      );

      await connection.commit();

      res.status(200).json({ message: "Transaction successful" });
    } catch (err) {
      await connection.rollback();
      res.status(400).json({ error: err.message });
    } finally {
      connection.release();
    }
  });

  return router;
};


