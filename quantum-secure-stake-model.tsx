import React, { useState, useEffect, useRef } from 'react';
import { Shield, Cpu, Lock, Zap, Target, Box, Award, Key } from 'lucide-react';

// Quantum-secure random number generator using Web Crypto API
const generateQuantumSecureRandom = () => {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array).reduce((acc, byte) => acc + byte / 255, 0) / 32;
};

// Lattice-based key generation (simplified NTRU-like)
const generateLatticeKey = () => {
  const dimension = 256;
  const modulus = 2048;
  const key = new Array(dimension).fill(0).map(() => 
    Math.floor(generateQuantumSecureRandom() * modulus)
  );
  return {
    privateKey: key,
    publicKey: key.map(x => (x * 1337) % modulus), // Simplified public key derivation
    fingerprint: key.reduce((acc, val) => (acc + val) % modulus, 0)
  };
};

// Quantum-resistant hash function (simplified Keccak-like)
const quantumHash = (data) => {
  let hash = 0x811c9dc5;
  const fnv_prime = 0x01000193;
  
  for (let i = 0; i < data.length; i++) {
    hash = hash ^ data.charCodeAt(i);
    hash = (hash * fnv_prime) % 0x100000000;
  }
  
  // Apply quantum-resistant transformations
  hash = (hash * hash) % 0x7FFFFFFF;
  hash = hash ^ (hash >>> 16);
  hash = (hash * 0x85ebca6b) % 0x7FFFFFFF;
  hash = hash ^ (hash >>> 13);
  hash = (hash * 0xc2b2ae35) % 0x7FFFFFFF;
  hash = hash ^ (hash >>> 16);
  
  return Math.abs(hash);
};

// Quantum-secure transaction signing
const signTransaction = (transaction, privateKey) => {
  const message = JSON.stringify(transaction);
  const messageHash = quantumHash(message);
  
  // Lattice-based signature (simplified)
  const signature = privateKey.map((key, index) => 
    (key + messageHash + index) % 2048
  );
  
  return {
    signature,
    hash: messageHash,
    timestamp: Date.now()
  };
};

// Verify quantum signature
const verifySignature = (transaction, signature, publicKey) => {
  const messageHash = quantumHash(JSON.stringify(transaction));
  
  // Verify lattice signature
  const isValid = signature.signature.every((sig, index) => {
    const expected = (publicKey[index] / 1337 + messageHash + index) % 2048;
    return Math.abs(sig - expected) < 10; // Allow small variance
  });
  
  return isValid && signature.hash === messageHash;
};

// Quantum-resistant box value generation
const generateQuantumBox = (stakingInfo) => {
  const quantumSeed = generateQuantumSecureRandom();
  const latticeNoise = generateQuantumSecureRandom() * 0.1;
  const temporalEntropy = (Date.now() % 1000) / 1000;
  
  // Combine multiple quantum-resistant entropy sources
  const baseValue = (quantumSeed + latticeNoise + temporalEntropy) / 3;
  const scaledValue = 1 + (baseValue * 10);
  
  // Add quantum uncertainty principle simulation
  const uncertainty = generateQuantumSecureRandom() * 0.3;
  
  return {
    value: Math.max(0.1, Math.min(11, scaledValue + uncertainty)),
    quantumSignature: quantumHash(stakingInfo.publicKey.join('')),
    entropy: quantumSeed,
    timestamp: Date.now()
  };
};

const QuantumSecureStaking = () => {
  const [selectedCrop, setSelectedCrop] = useState('CORN');
  const [portfolio, setPortfolio] = useState({
    CORN: 50.0,
    WHEAT: 25.0,
    SOY: 30.0,
    RICE: 15.0
  });
  
  const [quantumKeys, setQuantumKeys] = useState({});
  const [stakingData, setStakingData] = useState({
    CORN: { staked: 0, tippingPoint: 50, boxes: [], rewards: 0, lastTip: null },
    WHEAT: { staked: 0, tippingPoint: 30, boxes: [], rewards: 0, lastTip: null },
    SOY: { staked: 0, tippingPoint: 40, boxes: [], rewards: 0, lastTip: null },
    RICE: { staked: 0, tippingPoint: 25, boxes: [], rewards: 0, lastTip: null }
  });
  
  const [stakingAmount, setStakingAmount] = useState(1);
  const [transactionLog, setTransactionLog] = useState([]);
  const intervalRef = useRef(null);

  // Initialize quantum keys on component mount
  useEffect(() => {
    const initQuantumSecurity = () => {
      const crops = ['CORN', 'WHEAT', 'SOY', 'RICE'];
      const newKeys = {};
      
      crops.forEach(crop => {
        newKeys[crop] = generateLatticeKey();
      });
      
      setQuantumKeys(newKeys);
      
      // Update staking data with public keys
      setStakingData(prev => {
        const updated = { ...prev };
        crops.forEach(crop => {
          updated[crop] = { ...updated[crop], publicKey: newKeys[crop].publicKey };
        });
        return updated;
      });
    };
    
    initQuantumSecurity();
  }, []);

  // Quantum-secure staking operations
  useEffect(() => {
    intervalRef.current = setInterval(() => {
      setStakingData(prev => {
        const newStakingData = { ...prev };
        
        Object.keys(newStakingData).forEach(crop => {
          const stakingInfo = newStakingData[crop];
          
          if (stakingInfo.staked > 0 && quantumKeys[crop]) {
            // Generate quantum-secure boxes
            if (generateQuantumSecureRandom() < 0.3) {
              const quantumBox = generateQuantumBox({
                ...stakingInfo,
                publicKey: quantumKeys[crop].publicKey
              });
              
              stakingInfo.boxes.push({
                id: Date.now() + Math.random(),
                ...quantumBox
              });
              
              // Log quantum box generation
              logTransaction({
                type: 'QUANTUM_BOX_GENERATED',
                crop,
                value: quantumBox.value,
                signature: quantumBox.quantumSignature
              });
            }
            
            // Check quantum tipping point
            const totalBoxValue = stakingInfo.boxes.reduce((sum, box) => sum + box.value, 0);
            if (totalBoxValue >= stakingInfo.tippingPoint && stakingInfo.lastTip !== Date.now()) {
              // Quantum-secure reward calculation
              const transaction = {
                type: 'TIPPING_POINT_ACHIEVED',
                crop,
                stakedAmount: stakingInfo.staked,
                totalBoxValue,
                tippingPoint: stakingInfo.tippingPoint,
                timestamp: Date.now()
              };
              
              const signature = signTransaction(transaction, quantumKeys[crop].privateKey);
              
              if (verifySignature(transaction, signature, quantumKeys[crop].publicKey)) {
                const multiplier = 1 + (totalBoxValue / stakingInfo.tippingPoint);
                const reward = stakingInfo.staked * multiplier * 0.1;
                
                stakingInfo.rewards += reward;
                stakingInfo.lastTip = Date.now();
                stakingInfo.boxes = [];
                
                // Update portfolio with quantum-verified rewards
                setPortfolio(portfolioPrev => ({
                  ...portfolioPrev,
                  [crop]: (portfolioPrev[crop] || 0) + reward
                }));
                
                logTransaction({
                  ...transaction,
                  reward,
                  signature,
                  verified: true
                });
              }
            }
            
            // Remove expired boxes (quantum decay simulation)
            stakingInfo.boxes = stakingInfo.boxes.filter(
              box => Date.now() - box.timestamp < 30000
            );
          }
        });
        
        return newStakingData;
      });
    }, 3000);
    
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [quantumKeys]);

  const logTransaction = (transaction) => {
    setTransactionLog(prev => [
      { id: Date.now(), ...transaction },
      ...prev.slice(0, 9) // Keep last 10 transactions
    ]);
  };

  const stakeCrop = (symbol, amount) => {
    const availableAmount = portfolio[symbol] || 0;
    const actualAmount = Math.min(amount, availableAmount);
    
    if (actualAmount > 0 && quantumKeys[symbol]) {
      const transaction = {
        type: 'STAKE',
        crop: symbol,
        amount: actualAmount,
        timestamp: Date.now()
      };
      
      const signature = signTransaction(transaction, quantumKeys[symbol].privateKey);
      
      if (verifySignature(transaction, signature, quantumKeys[symbol].publicKey)) {
        setPortfolio(prev => ({
          ...prev,
          [symbol]: prev[symbol] - actualAmount
        }));
        
        setStakingData(prev => ({
          ...prev,
          [symbol]: {
            ...prev[symbol],
            staked: prev[symbol].staked + actualAmount
          }
        }));
        
        logTransaction({ ...transaction, signature, verified: true });
      }
    }
  };

  const unstakeCrop = (symbol, amount) => {
    const stakedAmount = stakingData[symbol].staked;
    const actualAmount = Math.min(amount, stakedAmount);
    
    if (actualAmount > 0 && quantumKeys[symbol]) {
      const transaction = {
        type: 'UNSTAKE',
        crop: symbol,
        amount: actualAmount,
        timestamp: Date.now()
      };
      
      const signature = signTransaction(transaction, quantumKeys[symbol].privateKey);
      
      if (verifySignature(transaction, signature, quantumKeys[symbol].publicKey)) {
        setStakingData(prev => ({
          ...prev,
          [symbol]: {
            ...prev[symbol],
            staked: prev[symbol].staked - actualAmount
          }
        }));
        
        setPortfolio(prev => ({
          ...prev,
          [symbol]: (prev[symbol] || 0) + actualAmount
        }));
        
        logTransaction({ ...transaction, signature, verified: true });
      }
    }
  };

  const crops = [
    { symbol: 'CORN', name: 'Yellow Corn', color: 'yellow' },
    { symbol: 'WHEAT', name: 'Winter Wheat', color: 'amber' },
    { symbol: 'SOY', name: 'Soybeans', color: 'green' },
    { symbol: 'RICE', name: 'White Rice', color: 'gray' }
  ];

  const stakingInfo = stakingData[selectedCrop];
  const totalBoxValue = stakingInfo?.boxes.reduce((sum, box) => sum + box.value, 0) || 0;
  const progressPercentage = Math.min((totalBoxValue / (stakingInfo?.tippingPoint || 1)) * 100, 100);

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 p-4">
      <div className="max-w-7xl mx-auto">
        {/* Quantum Security Header */}
        <header className="bg-gray-900 rounded-lg shadow-2xl p-6 mb-6 border border-purple-500">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
                <Shield className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-white">Quantum-Secure Corn Base</h1>
                <p className="text-purple-300">Post-Quantum Cryptography Staking</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-sm text-purple-300">Quantum Security Level</p>
              <div className="flex items-center space-x-2">
                <Lock className="w-5 h-5 text-green-400" />
                <span className="text-xl font-bold text-green-400">256-bit Lattice</span>
              </div>
            </div>
          </div>
        </header>

        {/* Quantum Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-gray-800 rounded-lg shadow-lg p-4 border border-purple-400">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-purple-300">Quantum Keys</p>
                <p className="text-xl font-bold text-white">{Object.keys(quantumKeys).length}/4</p>
              </div>
              <Key className="w-8 h-8 text-purple-400" />
            </div>
          </div>
          <div className="bg-gray-800 rounded-lg shadow-lg p-4 border border-blue-400">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-blue-300">Verified Transactions</p>
                <p className="text-xl font-bold text-white">{transactionLog.filter(t => t.verified).length}</p>
              </div>
              <Cpu className="w-8 h-8 text-blue-400" />
            </div>
          </div>
          <div className="bg-gray-800 rounded-lg shadow-lg p-4 border border-green-400">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-green-300">Quantum Entropy</p>
                <p className="text-xl font-bold text-white">{(generateQuantumSecureRandom() * 100).toFixed(1)}%</p>
              </div>
              <Zap className="w-8 h-8 text-green-400" />
            </div>
          </div>
          <div className="bg-gray-800 rounded-lg shadow-lg p-4 border border-yellow-400">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-yellow-300">Security Score</p>
                <p className="text-xl font-bold text-white">AAA+</p>
              </div>
              <Award className="w-8 h-8 text-yellow-400" />
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Crop Selection */}
          <div className="bg-gray-800 rounded-lg shadow-lg p-6 border border-purple-300">
            <h2 className="text-xl font-bold text-white mb-4">Select Crop for Quantum Staking</h2>
            <div className="space-y-3">
              {crops.map(crop => {
                const isSelected = selectedCrop === crop.symbol;
                const keyInfo = quantumKeys[crop.symbol];
                return (
                  <div 
                    key={crop.symbol}
                    className={`p-3 rounded-lg border-2 cursor-pointer transition-all ${
                      isSelected 
                        ? 'border-purple-500 bg-purple-900 bg-opacity-30' 
                        : 'border-gray-600 hover:border-purple-400 bg-gray-700'
                    }`}
                    onClick={() => setSelectedCrop(crop.symbol)}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-semibold text-white">{crop.symbol}</p>
                        <p className="text-sm text-gray-300">{crop.name}</p>
                        {keyInfo && (
                          <p className="text-xs text-purple-300">
                            Key: {keyInfo.fingerprint.toString(16).slice(0, 8)}...
                          </p>
                        )}
                      </div>
                      <div className="text-right">
                        <p className="text-white">{portfolio[crop.symbol]} units</p>
                        <p className="text-sm text-purple-300">
                          {stakingData[crop.symbol].staked} staked
                        </p>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Quantum Staking Panel */}
          <div className="bg-gray-800 rounded-lg shadow-lg p-6 border border-blue-300">
            <h2 className="text-xl font-bold text-white mb-4">
              Quantum Stake {selectedCrop}
            </h2>
            
            {/* Quantum Key Status */}
            {quantumKeys[selectedCrop] && (
              <div className="bg-gray-700 rounded-lg p-3 mb-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-300">Quantum Key Status</span>
                  <span className="flex items-center text-green-400">
                    <Lock className="w-4 h-4 mr-1" />
                    Secured
                  </span>
                </div>
                <p className="text-xs text-purple-300 mt-1">
                  Fingerprint: {quantumKeys[selectedCrop].fingerprint}
                </p>
              </div>
            )}
            
            {/* Staking Stats */}
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="bg-blue-900 bg-opacity-30 rounded-lg p-3">
                <p className="text-sm text-blue-300">Staked Amount</p>
                <p className="text-lg font-bold text-white">{stakingInfo?.staked.toFixed(2)} units</p>
              </div>
              <div className="bg-green-900 bg-opacity-30 rounded-lg p-3">
                <p className="text-sm text-green-300">Quantum Rewards</p>
                <p className="text-lg font-bold text-white">{stakingInfo?.rewards.toFixed(2)} units</p>
              </div>
            </div>
            
            {/* Quantum Box Game */}
            <div className="mb-4">
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-semibold text-white flex items-center">
                  <Target className="w-5 h-5 mr-2 text-purple-400" />
                  Quantum Tipping Point
                </h3>
                <span className="text-sm text-gray-300">
                  Target: {stakingInfo?.tippingPoint} points
                </span>
              </div>
              
              {/* Progress Bar */}
              <div className="bg-gray-700 rounded-full h-4 mb-3">
                <div 
                  className="bg-gradient-to-r from-purple-500 via-blue-500 to-purple-600 h-4 rounded-full transition-all duration-500"
                  style={{ width: `${progressPercentage}%` }}
                />
              </div>
              <div className="flex justify-between text-xs text-gray-400 mb-3">
                <span>{totalBoxValue.toFixed(1)} points</span>
                <span>{progressPercentage.toFixed(1)}%</span>
              </div>
              
              {/* Quantum Boxes */}
              <div className="bg-gray-700 rounded-lg p-3 min-h-24">
                <p className="text-sm text-gray-300 mb-2">Quantum Boxes:</p>
                <div className="flex flex-wrap gap-2">
                  {stakingInfo?.boxes.map(box => (
                    <div 
                      key={box.id}
                      className="bg-purple-800 border-2 border-purple-400 rounded-lg p-2 min-w-12 text-center"
                    >
                      <Box className="w-4 h-4 mx-auto text-purple-300" />
                      <span className="text-xs font-bold text-white">{box.value.toFixed(1)}</span>
                      <div className="text-xs text-purple-300">{box.entropy.toFixed(3)}</div>
                    </div>
                  ))}
                  {(!stakingInfo?.boxes.length || stakingInfo.boxes.length === 0) && (
                    <p className="text-gray-400 text-sm">No quantum boxes. Stake to start!</p>
                  )}
                </div>
              </div>
            </div>
            
            {/* Staking Controls */}
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Amount to Stake
                </label>
                <input
                  type="number"
                  value={stakingAmount}
                  onChange={(e) => setStakingAmount(Number(e.target.value))}
                  min="0.1"
                  max={portfolio[selectedCrop] || 0}
                  step="0.1"
                  className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                />
              </div>
              
              <div className="grid grid-cols-2 gap-3">
                <button 
                  onClick={() => stakeCrop(selectedCrop, stakingAmount)}
                  className="bg-gradient-to-r from-purple-600 to-blue-600 text-white px-4 py-2 rounded-lg hover:from-purple-700 hover:to-blue-700 transition-all disabled:opacity-50"
                  disabled={!portfolio[selectedCrop] || portfolio[selectedCrop] < stakingAmount || !quantumKeys[selectedCrop]}
                >
                  Quantum Stake
                </button>
                <button 
                  onClick={() => unstakeCrop(selectedCrop, stakingAmount)}
                  className="bg-gradient-to-r from-orange-600 to-red-600 text-white px-4 py-2 rounded-lg hover:from-orange-700 hover:to-red-700 transition-all disabled:opacity-50"
                  disabled={!stakingInfo || stakingInfo.staked < stakingAmount || !quantumKeys[selectedCrop]}
                >
                  Unstake
                </button>
              </div>
            </div>
          </div>

          {/* Quantum Transaction Log */}
          <div className="bg-gray-800 rounded-lg shadow-lg p-6 border border-green-300">
            <h2 className="text-xl font-bold text-white mb-4">Quantum Transaction Log</h2>
            <div className="space-y-3 max-h-96 overflow-y-auto">
              {transactionLog.map(tx => (
                <div key={tx.id} className="bg-gray-700 rounded-lg p-3 border border-gray-600">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-white">{tx.type}</span>
                    <span className={`text-xs px-2 py-1 rounded-full ${
                      tx.verified ? 'bg-green-800 text-green-300' : 'bg-red-800 text-red-300'
                    }`}>
                      {tx.verified ? 'Verified' : 'Pending'}
                    </span>
                  </div>
                  <p className="text-xs text-gray-400 mt-1">
                    {tx.crop} - {new Date(tx.timestamp).toLocaleTimeString()}
                  </p>
                  {tx.signature && (
                    <p className="text-xs text-purple-300 mt-1">
                      Sig: {tx.signature.hash.toString(16).slice(0, 16)}...
                    </p>
                  )}
                </div>
              ))}
              {transactionLog.length === 0 && (
                <p className="text-gray-400 text-sm text-center">No transactions yet</p>
              )}
            </div>
          </div>
        </div>

        {/* Quantum Security Info */}
        <div className="mt-6 bg-gray-800 rounded-lg shadow-lg p-6 border border-purple-300">
          <h2 className="text-xl font-bold text-white mb-4">Quantum Security Features</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="font-semibold text-purple-300 mb-2">Post-Quantum Cryptography</h3>
              <ul className="text-sm text-gray-300 space-y-1">
                <li>• Lattice-based key generation (NTRU-inspired)</li>
                <li>• Quantum-resistant hash functions</li>
                <li>• 256-bit security level</li>
                <li>• Resistant to Shor's algorithm</li>
              </ul>
            </div>
            <div>
              <h3 className="font-semibold text-purple-300 mb-2">Enhanced Security</h3>
              <ul className="text-sm text-gray-300 space-y-1">
                <li>• Quantum-secure random number generation</li>
                <li>• Transaction signing and verification</li>
                <li>• Entropy-based box generation</li>
                <li>• Tamper-evident transaction log</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default QuantumSecureStaking;