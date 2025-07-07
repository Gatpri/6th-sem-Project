const express = require('express');
const router = express.Router();

module.exports = (pool) => {
  router.post('/login', async (req, res) => {
    const { mobile, password } = req.body;
    const connection = await pool.getConnection();

    try {
      // Check user with matching mobile and password
      const [rows] = await connection.query(
        'SELECT firstname, mobile, role FROM users WHERE mobile = ? AND password = ?',
        [mobile, password]
      );

      if (rows.length === 0) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const user = rows[0];
      res.status(200).json({
        message: 'Login successful',
        userName: user.firstname,
        userMobile: user.mobile,
        role: user.role,  // Return user role for access control
      });

    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ error: 'Server error' });
    } finally {
      connection.release();
    }
  });

  return router;
};







