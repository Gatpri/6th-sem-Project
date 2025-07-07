module.exports = function (pool) {
  const express = require('express');
  const router = express.Router();

  // ✅ Assign admin role
  router.post('/assign-admin', async (req, res) => {
    const { requesterMobile, targetMobile } = req.body;

    try {
      const [adminCheck] = await pool.query(
        'SELECT role FROM users WHERE mobile = ?',
        [requesterMobile]
      );

      if (adminCheck.length === 0 || adminCheck[0].role !== 'admin') {
        return res.status(403).json({ message: 'Only admins can assign admin role' });
      }

      const [updateResult] = await pool.query(
        'UPDATE users SET role = "admin" WHERE mobile = ?',
        [targetMobile]
      );

      if (updateResult.affectedRows === 0) {
        return res.status(404).json({ message: 'Target user not found' });
      }

      res.status(200).json({ message: 'Admin role assigned successfully' });
    } catch (error) {
      console.error('Assign admin error:', error);
      res.status(500).json({ message: 'Internal server error' });
    }
  });

  // ✅ Remove admin role
  router.post('/remove-admin', async (req, res) => {
    const { requesterMobile, targetMobile } = req.body;
const SAUGAT_ADMIN = '9818091358';//PROTECTED ADMIN NUMBER
    try {
      const [adminCheck] = await pool.query(
        'SELECT role FROM users WHERE mobile = ?',
        [requesterMobile]
      );

      if (adminCheck.length === 0 || adminCheck[0].role !== 'admin') {
        return res.status(403).json({ message: 'Only admins can remove admin role' });
      }

      if (requesterMobile === targetMobile) {
        return res.status(400).json({ message: "You cannot remove your own admin rights." });
      }

        if (targetMobile === SAUGAT_ADMIN) {
            return res.status(403).json({ message: "You cannot remove this protected admin." });
          }

      const [updateResult] = await pool.query(
        'UPDATE users SET role = "user" WHERE mobile = ?',
        [targetMobile]
      );

      if (updateResult.affectedRows === 0) {
        return res.status(404).json({ message: 'Target user not found' });
      }

      res.status(200).json({ message: 'Admin role removed successfully' });
    } catch (error) {
      console.error('Remove admin error:', error);
      res.status(500).json({ message: 'Internal server error' });
    }
  });

  return router;
};
