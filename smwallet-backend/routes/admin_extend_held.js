const express = require('express');
const router = express.Router();
module.exports = (pool) => {


router.post('/admin-extend-hold', async (req, res) => {
  const { sender_mobile, receiver_mobile, amount, new_release_date } = req.body;

  if (!sender_mobile || !receiver_mobile || !amount || !new_release_date) {
    return res.status(400).json({ error: 'Missing required fields.' });
  }

  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    // Find the most recent matching held secure transfer
    const [rows] = await connection.query(
      `SELECT id FROM securedtransfer
       WHERE sender_mobile = ? AND receiver_mobile = ? AND amount = ? AND status = 'held'
       ORDER BY id DESC LIMIT 1`,
      [sender_mobile, receiver_mobile, amount]
    );

    if (rows.length === 0) {
      throw new Error("No held secure transfer found to extend.");
    }

    const transferId = rows[0].id;

    // Update the hold_until date
    await connection.query(
      `UPDATE securedtransfer
       SET hold_until = ?
       WHERE id = ?`,
      [new_release_date, transferId]
    );

    await connection.commit();
    res.status(200).json({ message: `Hold date extended to ${new_release_date}` });

  } catch (error) {
    await connection.rollback();
    console.error('Admin extend hold error:', error);
    res.status(500).json({ error: error.message || 'Failed to extend hold date' });
  } finally {
    connection.release();
  }
});

return router;
}