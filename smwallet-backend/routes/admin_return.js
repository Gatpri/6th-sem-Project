module.exports = function (pool) {
  const express = require('express');
  const router = express.Router();

  // ✅ FIXED: Fetch only secure held transactions correctly
  router.post('/admin-return-list', async (req, res) => {
    const { sender_mobile, receiver_mobile } = req.body;

    try {
      const [result] = await pool.query(
        `SELECT t.id, t.amount, t.status
         FROM transactions t
         JOIN securedtransfer s ON s.sender_mobile = t.sender_mobile
           AND s.receiver_mobile = t.receiver_mobile
           AND s.amount = t.amount
           AND s.status = 'held'
         WHERE t.sender_mobile = ?
           AND t.receiver_mobile = ?
           AND t.status = 'held'`,
        [sender_mobile, receiver_mobile]
      );

      res.json({ transactions: result });
    } catch (error) {
      console.error('List error:', error);
      res.status(500).json({ error: 'Failed to fetch transactions' });
    }
  });

  // ✅ FIXED: Admin returns held transaction properly
  router.post('/admin-return-one', async (req, res) => {
    const { transferId } = req.body;

    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      const [transferResult] = await connection.query(
        'SELECT * FROM transactions WHERE id = ? AND status = "held"',
        [transferId]
      );

      if (transferResult.length === 0) {
        return res.status(404).json({ error: 'Transaction not found or not held' });
      }

      const transfer = transferResult[0];
      const { sender_mobile, receiver_mobile, amount } = transfer;

      // Deduct from receiver
      await connection.query(
        'UPDATE users SET held_balance = held_balance - ? WHERE mobile = ?',
        [amount, receiver_mobile]
      );

      // Refund sender
      await connection.query(
        'UPDATE users SET balance = balance + ? WHERE mobile = ?',
        [amount, sender_mobile]
      );

      // ✅ UPDATE transaction status
      await connection.query(
        'UPDATE transactions SET status = "returned" WHERE id = ?',
        [transferId]
      );

      // ✅ UPDATE securedtransfer status as well
      await connection.query(
        `UPDATE securedtransfer
         SET status = 'returned'
         WHERE sender_mobile = ? AND receiver_mobile = ? AND amount = ? AND status = 'held'
         ORDER BY id DESC LIMIT 1`,
        [sender_mobile, receiver_mobile, amount]
      );

      await connection.commit();
      res.json({ message: `Transaction ${transferId} returned successfully.` });
    } catch (error) {
      await connection.rollback();
      console.error('Return one error:', error);
      res.status(500).json({ error: 'Failed to return money' });
    } finally {
      connection.release();
    }
  });

  return router;
};



