// src/components/BankUI.jsx
import React from 'react';

function BankUI({ locationType, playerMoney, bankBalance, config, onClose, onDeposit }) {
  return (
    <div className="screen_container"> {/* C'est ton div avec la taille et la couleur de fond */}
      {/* <h1>{locationType === 'bank' ? config.BankTitle : config.AtmTitle}</h1>
      <p>Argent liquide : {playerMoney}</p>
      <p>Solde bancaire : {bankBalance}</p>
      <button onClick={() => onDeposit(100)}>Déposer 100$</button>
      <button onClick={onClose}>Fermer</button> */}
      {/* ... le reste de ton interface ... */}
    </div>
  );
}

export default BankUI;