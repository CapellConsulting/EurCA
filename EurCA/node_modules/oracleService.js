const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
const port = 3000;

// Replace these variables with your actual API credentials
const bankApiUrl = 'https://bank-api.example.com/liquidity-check';
const apiKey = 'your-api-key';

app.use(bodyParser.json());

app.post('/liquidityCheck', async (req, res) => {
  const { walletAddress, bankAccount } = req.body;

  try {
    // Fetch data from the bank's API
    const response = await axios.post(bankApiUrl, {
      walletAddress,
      bankAccount,
    }, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
    });

    // Extract liquidity status from the bank's response
    const liquidityStatus = response.data.liquidityStatus;

    // Send the liquidity status back to the smart contract
    res.json({ liquidityStatus });
  } catch (error) {
    console.error('Error interacting with the bank API:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(port, () => {
  console.log(`Oracle service listening at http://localhost:${port}`);
});
