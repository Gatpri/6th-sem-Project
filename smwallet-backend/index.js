const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise'); // ✅ FIXED: using promise-based mysql

const app = express();
app.use(cors());
app.use(express.json());

// ✅ MySQL Pool Connection (Good)
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'smwallet',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});


// ✅ Available Balance and Held Balance in Homepage route
const userBalancesRoute = require('./routes/both_balance_in_homepage');
app.use('/', userBalancesRoute(pool));  // Passing pool into register route


// ✅ Register route
const registerRoute = require('./routes/register');
app.use('/', registerRoute(pool));



// ✅ Login route
const loginRoute = require('./routes/login');
app.use('/', loginRoute(pool));



 // ✅ Send Money route
 const sendmoneyRoute = require('./routes/send_money');
 app.use('/', sendmoneyRoute(pool));




 // ✅ Secure Transfer route
 const securedtransferRoute = require('./routes/secure_transfer');
 app.use('/', securedtransferRoute(pool));




 // ✅ Balance release route
 const releaseTransferRoute = require('./routes/balance_release');
 app.use('/', releaseTransferRoute(pool));




 // ✅ get first name route
 const getfirstnamehomepageRoute = require('./routes/get_firstname_homepage');
 app.use('/', getfirstnamehomepageRoute(pool));



// ✅ get TRANSACTION HISTORY route
 const transactionhistoryRoute = require('./routes/transaction_history');
 app.use('/transactions', transactionhistoryRoute(pool));


// ✅ get VENDOR RETURN route
const vendorReturnRoute = require('./routes/admin_return')(pool);
app.use('/', vendorReturnRoute);


// ✅ get admin assign route
const adminAssignRoute = require('./routes/admin_assign')(pool);
app.use('/', adminAssignRoute);


// ✅ get set transaction pin route
const setTransactionpinRoute = require('./routes/set_transaction_pin')(pool);
app.use('/', setTransactionpinRoute);

// ✅ get change transaction pin route
const changeTransactionpinRoute = require('./routes/change_transaction_pin')(pool);
app.use('/', changeTransactionpinRoute);

// ✅ get check transaction pin route
const checkTransactionpinRoute = require('./routes/check_transaction_pin')(pool);
app.use('/', checkTransactionpinRoute);


// ✅ get admin extend hold amount route
const extendHoldRoute = require('./routes/admin_extend_held')(pool);
app.use('/', extendHoldRoute);

// ✅ get forget password route
const forgotPasswordRoutes = require('./routes/forgot_password')(pool);
app.use('/', forgotPasswordRoutes);


// ✅ Start Server
const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
});





