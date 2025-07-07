const express = require('express');
const router = express.Router();



module.exports = (pool) => {



router.get('/get-user', async (req, res) => {
  const mobile = req.query.mobile;
  if (!mobile) return res.status(400).json({ error: 'Mobile required' });

  const connection = await pool.getConnection();
  try {
    const [rows] = await connection.query(
      'SELECT firstName, lastName FROM users WHERE mobile = ?', [mobile]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const name = `${rows[0].firstName} ${rows[0].lastName}`;
    res.json({ name });
  } catch (err) {
    res.status(500).json({ error: 'DB error' });
  } finally {
    connection.release();
  }
});


return router;
};