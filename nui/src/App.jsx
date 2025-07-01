// src/App.jsx

import React, { useEffect, useState } from 'react';
import './App.css'; // Assure-toi d'importer ton CSS ici
import BankUI from './components/BankUI'; // Ton composant qui contient le .screen_container

function App() {
  const [isNuiVisible, setIsNuiVisible] = useState(false); // Initialisation à false
  const [bankData, setBankData] = useState({});

  useEffect(() => {
    const handleMessage = (event) => {
      const data = event.data;
      if (data.type === 'openBank') {
        setIsNuiVisible(true);
        setBankData(data);
      } else if (data.type === 'closeBank') {
        setIsNuiVisible(false);
        setBankData({});
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  return (
    // Ce div représente ta NUI visible.
    // Il sera le seul élément enfant de #root (qui est transparent et plein écran).
    // Sa visibilité est contrôlée ici.
    <div className="nui-wrapper" >
      
      
      <BankUI
        locationType={bankData.locationType}
        playerMoney={bankData.playerMoney}
        bankBalance={bankData.bankBalance}
        config={bankData.config}
        onClose={() => sendMessageToLua('close', {})}
        onDeposit={(amount) => sendMessageToLua('deposit', { amount: amount })}
        />
     
    </div>
  );
}

// ... ta fonction sendMessageToLua ...

export default App;