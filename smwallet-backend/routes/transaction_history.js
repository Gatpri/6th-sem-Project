const express = require('express');
const router = express.Router();

module.exports = (pool) => {
  router.get('/:mobile', async (req, res) => {
    const mobile = req.params.mobile;

    try {
      console.log('📦 Fetching all transactions for:', mobile);

      // 1️⃣ Normal Send Money transactions
      const [normalTransactions] = await pool.query(`
        SELECT
          id,
          sender_mobile,
          receiver_mobile,
          amount,
          created_at,
          status
        FROM transactions
        WHERE (sender_mobile = ? OR receiver_mobile = ?)
          AND status IN ('normal')
        ORDER BY created_at DESC
      `, [mobile, mobile]);

      const normalMapped = normalTransactions.map(tx => {
        let description = '';
        if (tx.status === 'normal') {
          description = tx.sender_mobile === mobile
            ? `Sent RS ${tx.amount} to ${tx.receiver_mobile}`
            : `ReceivedRS ${tx.amount} from ${tx.sender_mobile}`;
        } else if (tx.status === 'returned') {
          description = tx.sender_mobile === mobile
            ? `Returned amount to ${tx.receiver_mobile}`
            : `Received returned amount from ${tx.sender_mobile}`;
        }

        return {
          id: tx.id,
          sender_mobile: tx.sender_mobile,
          receiver_mobile: tx.receiver_mobile,
          amount: tx.amount,
          hold_until: null,
          created_at: tx.created_at,
          status: tx.status,
          tx_type: 'normal',
          description
        };
      });

      // 2️⃣ Secure Transfer transactions
      const [secureTransactions] = await pool.query(`
        SELECT
          s.id,
          s.sender_mobile,
          s.receiver_mobile,
          s.amount,
          s.hold_until,
          s.created_at,
          s.status AS secure_status,
          t.status AS transaction_status
        FROM securedtransfer s
        LEFT JOIN transactions t
          ON t.sender_mobile = s.sender_mobile
          AND t.receiver_mobile = s.receiver_mobile
          AND t.amount = s.amount
          AND t.status = 'returned'
        WHERE s.sender_mobile = ? OR s.receiver_mobile = ?
        ORDER BY s.created_at DESC
      `, [mobile, mobile]);

      const secureMapped = secureTransactions.map(tx => {
        const finalStatus = tx.transaction_status === 'returned'
          ? 'returned'
          : tx.secure_status;

        const description =
          finalStatus === 'held'
            ? (tx.sender_mobile === mobile
                ? `Secure transfer to ${tx.receiver_mobile} (held)`
                : `Secure transfer from ${tx.sender_mobile} (held)`)
          : finalStatus === 'released'
            ? (tx.receiver_mobile === mobile
                ? `Secure amount released from ${tx.sender_mobile}`
                : `Released secure transfer to ${tx.receiver_mobile}`)
          : finalStatus === 'returned'
            ? (tx.sender_mobile === mobile
                ? `Returned amount from ${tx.receiver_mobile}`
                : `Returned to ${tx.sender_mobile}`)
          : '';

        return {
          id: tx.id,
          sender_mobile: tx.sender_mobile,
          receiver_mobile: tx.receiver_mobile,
          amount: tx.amount,
          hold_until: tx.hold_until,
          created_at: tx.created_at,
          status: finalStatus,
          tx_type: 'secure',
          description
        };
      });

      // 🔁 Combine and sort all transactions
      const allTransactions = [...normalMapped, ...secureMapped].sort(
        (a, b) => new Date(b.created_at) - new Date(a.created_at)
      );

      res.status(200).json(allTransactions);
    } catch (err) {
      console.error("⛔ Error fetching transaction history:", err.message);
      res.status(500).json({ error: "Failed to fetch transaction history." });
    }
  });

  return router;
};








/*
const express = require('express');
const router = express.Router();

module.exports = (pool) => {
  router.get('/:mobile', async (req, res) => {
    const mobile = req.params.mobile;

    try {
      console.log('📦 Fetching transactions (integrated) for:', mobile);

      const [transactions] = await pool.query(`
        SELECT
          s.id,
          s.sender_mobile,
          s.receiver_mobile,
          s.amount,
          s.hold_until,
          s.created_at,
          s.status AS secure_status,
          t.status AS transaction_status
        FROM securedtransfer s
        LEFT JOIN transactions t
          ON t.sender_mobile = s.sender_mobile
          AND t.receiver_mobile = s.receiver_mobile
          AND t.amount = s.amount
          AND t.status = 'returned'
        WHERE s.sender_mobile = ? OR s.receiver_mobile = ?
        ORDER BY s.created_at DESC
      `, [mobile, mobile]);

      const transactionsWithDesc = transactions.map(tx => {
        // Use 'returned' from transactions table if matched
        const finalStatus = tx.transaction_status === 'returned'
          ? 'returned'
          : tx.secure_status;

        const description =
          finalStatus === 'held'
            ? (tx.sender_mobile === mobile
                ? `Secure transfer to ${tx.receiver_mobile} (held)`
                : `Secure transfer from ${tx.sender_mobile} (held)`)
          : finalStatus === 'released'
            ? (tx.receiver_mobile === mobile
                ? `Secure amount released from ${tx.sender_mobile}`
                : `Released secure transfer to ${tx.receiver_mobile}`)
          : finalStatus === 'returned'
            ? (tx.sender_mobile === mobile
                ? `Returned amount from ${tx.receiver_mobile}`
                : `Returned to ${tx.sender_mobile}`)
          : '';

        return {
          id: tx.id,
          sender_mobile: tx.sender_mobile,
          receiver_mobile: tx.receiver_mobile,
          amount: tx.amount,
          hold_until: tx.hold_until,
          created_at: tx.created_at,
          status: finalStatus,
          tx_type: 'secure',
          description
        };
      });

      res.status(200).json(transactionsWithDesc);
    } catch (err) {
      console.error("⛔ Error fetching secure transfer history:", err.message);
      res.status(500).json({ error: "Failed to fetch transaction history." });
    }
  });

  return router;
};

*/



