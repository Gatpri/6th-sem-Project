const express = require('express');
const router = express.Router();



module.exports = (pool) => {

router.get('/user-balances/:mobile', async (req, res) => {
  const mobile = req.params.mobile;

    if (!mobile) {
      return res.status(400).json({ error: 'Mobile number is required' });
    }

    const connection = await pool.getConnection();

  try {
    // Get available balance
    const [userRows] = await connection.query(
      'SELECT balance, held_balance FROM users WHERE mobile = ?', [mobile]
    );
    if (userRows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    const availableBalance = parseFloat(userRows[0].balance);

    // Get total held amount (not yet released)
    const [heldRows] = await connection.query(
      'SELECT SUM(amount) AS heldAmount FROM securedtransfer WHERE receiver_mobile = ? AND status = "held"',
      [mobile]
    );
    const heldAmount = parseFloat(heldRows[0].heldAmount) || 0;

    res.status(200).json({
      availableBalance,
      heldAmount,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  } finally {
    connection.release();
  }
});



return router;
};
