const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');

module.exports = (pool) => {
  const otpStore = new Map(); // In-memory OTP store

  // POST: Send OTP to email if mobile+email matches
  router.post('/forgot-password', async (req, res) => {
    const { mobile, email } = req.body;

    try {
      const [rows] = await pool.query(
        'SELECT * FROM users WHERE mobile = ? AND email = ?',
        [mobile, email]
      );

      if (rows.length === 0) {
        return res.status(404).json({ success: false, error: 'User not found with provided details.' });
      }

      const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
      otpStore.set(mobile, { otp, createdAt: Date.now() });

      // Send OTP via email
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: 'your_email@gmail.com', // replace
          pass: 'your_email_password',  // use App Password if 2FA
        },
      });

      const mailOptions = {
        from: 'your_email@gmail.com',
        to: email,
        subject: 'SM Wallet - OTP to reset your password',
        text: `Your OTP to reset password is: ${otp}`,
      };

      await transporter.sendMail(mailOptions);

      res.json({ success: true, message: 'OTP sent to your email.' });
    } catch (err) {
      console.error('OTP send error:', err);
      res.status(500).json({ success: false, error: 'Failed to send OTP' });
    }
  });

  // POST: Verify OTP and reset password
  router.post('/reset-password', async (req, res) => {
    const { mobile, otp, newPassword } = req.body;

    const entry = otpStore.get(mobile);
    if (!entry || entry.otp !== otp) {
      return res.status(400).json({ success: false, error: 'Invalid or expired OTP' });
    }

    // Optional: Expire OTP after 5 minutes
    const isExpired = Date.now() - entry.createdAt > 5 * 60 * 1000;
    if (isExpired) {
      otpStore.delete(mobile);
      return res.status(400).json({ success: false, error: 'OTP expired' });
    }

    try {
      const bcrypt = require('bcrypt');
      const hashedPassword = await bcrypt.hash(newPassword, 10);

      await pool.query('UPDATE users SET password = ? WHERE mobile = ?', [
        hashedPassword,
        mobile,
      ]);

      otpStore.delete(mobile);

      res.json({ success: true, message: 'Password reset successfully.' });
    } catch (err) {
      console.error('Password reset error:', err);
      res.status(500).json({ success: false, error: 'Failed to reset password' });
    }
  });

  return router;
};
