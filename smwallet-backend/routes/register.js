const express = require('express');
const router = express.Router();



module.exports = (pool) => {

router.post('/register', async (req, res) => {
  const { firstName, lastName, mobile, email, password } = req.body;

  if (!firstName || !lastName || !mobile || !email || !password) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  const connection = await pool.getConnection();
  try {
    const [existingUsers] = await connection.query(
      'SELECT * FROM users WHERE mobile = ? OR email = ?',
      [mobile, email]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({ message: 'User with given mobile or email already exists' });
    }

    const sql = 'INSERT INTO users (firstName, lastName, mobile, email, password) VALUES (?, ?, ?, ?, ?)';
    await connection.query(sql, [firstName, lastName, mobile, email, password]);

    res.status(200).json({ message: 'User registered successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Database error' });
  } finally {
    connection.release();
  }
});


return router;
};