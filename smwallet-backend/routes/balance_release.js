const express = require('express');
const router = express.Router();
const cron = require('node-cron');

module.exports = (pool) => {

  // Manual release endpoint — sender releases hold, no balance change here
  router.post('/release-transfer', async (req, res) => {
    const { senderMobile, transferId } = req.body;

    const connection = await pool.getConnection();
    await connection.beginTransaction();

      try {
      console.log('Release-transfer called with:', { senderMobile, transferId });

        const [rows] = await connection.query(`
          SELECT * FROM securedtransfer WHERE id = ? AND sender_mobile = ? AND status = 'held'
        `, [transferId, senderMobile]);

        if (rows.length === 0) throw new Error("Only sender can release blocked amount");

        const transfer = rows[0];

        // ✅ Actually release funds
        await connection.query(`
          UPDATE users SET balance = balance + ?, held_balance = held_balance - ? WHERE mobile = ?
        `, [transfer.amount, transfer.amount, transfer.receiver_mobile]);

        // ✅ Update status
        await connection.query(`
          UPDATE securedtransfer SET status = 'released' WHERE id = ?
        `, [transferId]);

        await connection.commit();
        res.status(200).json({ message: "✅ Transfer released manually" });

      } catch (err) {
        await connection.rollback();
        res.status(400).json({ error: err.message });
      } finally {
        connection.release();
      }
    });


  // Auto-release cron job runs every 5 minutes and credits receiver balance
  cron.schedule('*/5 * * * *', async () => {
    const connection = await pool.getConnection();
    try {
      const [heldTransfers] = await connection.query(`
        SELECT id, receiver_mobile, amount
        FROM securedtransfer
        WHERE status = 'held' AND hold_until <= NOW()
      `);

      for (const transfer of heldTransfers) {
        await connection.beginTransaction();

        // Credit receiver balance here when hold expires
       await connection.query(
         `UPDATE users SET balance = balance + ?, held_balance = held_balance - ? WHERE mobile = ?`,
         [transfer.amount, transfer.amount, transfer.receiver_mobile]
       );

        // Mark transfer as released
        await connection.query(
          `UPDATE securedtransfer SET status = 'released' WHERE id = ?`,
          [transfer.id]
        );

        await connection.commit();
        console.log(`✅ Auto-released transfer ID ${transfer.id}`);
      }
    } catch (err) {
      console.error('⛔ Error in auto-release cron:', err.message);
      await connection.rollback();
    } finally {
      connection.release();
    }
  });

  return router;
};











