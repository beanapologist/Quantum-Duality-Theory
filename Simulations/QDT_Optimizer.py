import numpy as np
from typing import Dict, Tuple, List
from dataclasses import dataclass

@dataclass
class QDTConstants:
    """Core QDT constants based on established values."""
    PHI: float = 1.618033988749895  # Golden ratio
    LAMBDA: float = 0.867           # Coupling constant
    GAMMA: float = 0.4497           # Damping coefficient
    BETA: float = 0.310             # Fractal recursion
    ALPHA: float = 0.520            # Prime recursion
    ETA: float = 0.520              # Stabilizing term


class QDTOptimizer:
    """Baseline QDT Optimizer with energy conservation and scale coupling."""
    
    def __init__(self, input_dim: int):
        self.input_dim = input_dim
        self.constants = QDTConstants()
        
    def _initialize_parameters(self) -> np.ndarray:
        """Initialize parameters with QDT-based constraints."""
        params = np.random.uniform(0, self.constants.PHI, self.input_dim)
        params *= self.constants.LAMBDA  # Apply coupling constraint
        return params
    
    def _tokenize_parameters(self, params: np.ndarray) -> np.ndarray:
        """Enhanced parameter tokenization with recursive coupling."""
        merges = [
            (self.constants.ALPHA, self.constants.BETA),
            (self.constants.BETA, self.constants.GAMMA),
            (self.constants.GAMMA, self.constants.LAMBDA)
        ]
        
        tokenized = np.zeros_like(params)
        for i in range(len(params)):
            merge_pair = merges[i % len(merges)]
            coupling = merge_pair[0] + merge_pair[1] * np.exp(-self.constants.ETA * i)
            tokenized[i] = params[i] * coupling
            
        return tokenized
    
    def _forward_pass(self, tokenized_params: np.ndarray, target_energy: float) -> Tuple[float, Dict]:
        """Forward pass with energy conservation."""
        weights = self._initialize_weights()
        hidden_1 = np.tanh(weights['layer1'] @ tokenized_params) * self.constants.LAMBDA
        hidden_2 = np.tanh(weights['layer2'] @ hidden_1) * self.constants.BETA
        achieved_energy = float(weights['layer3'] @ hidden_2)
        damping = np.exp(-self.constants.GAMMA * abs(target_energy - achieved_energy))
        achieved_energy *= damping
        return achieved_energy, {'hidden_1': hidden_1, 'hidden_2': hidden_2, 'damping': damping}
    
    def _initialize_weights(self) -> Dict[str, np.ndarray]:
        """Initialize weight matrices with QDT constraints."""
        hidden_size = max(32, self.input_dim * 2)
        return {
            'layer1': np.random.normal(0, 1/np.sqrt(self.input_dim), (hidden_size, self.input_dim)),
            'layer2': np.random.normal(0, 1/np.sqrt(hidden_size), (hidden_size, hidden_size)),
            'layer3': np.random.normal(0, 1/np.sqrt(hidden_size), (1, hidden_size))
        }
    
    def _compute_stability_score(self, achieved_energy: float, target_energy: float, activations: Dict) -> float:
        """Compute stability score with multi-scale feedback."""
        energy_diff = abs(target_energy - achieved_energy) / abs(target_energy)
        scale_penalty = 0.0
        for i in range(len(activations['hidden_1'])):
            for j in range(i + 1, len(activations['hidden_1'])):
                scale_penalty += abs(activations['hidden_1'][i] - activations['hidden_1'][j])
        scale_penalty *= self.constants.BETA
        stability = (1 - energy_diff) * self.constants.LAMBDA - scale_penalty * (1 - self.constants.LAMBDA)
        return float(np.clip(stability, 0, 1))
    
    def optimize(self, target_energy: float) -> Dict:
        """Main optimization method."""
        initial_params = self._initialize_parameters()
        tokenized_params = self._tokenize_parameters(initial_params)
        achieved_energy, activations = self._forward_pass(tokenized_params, target_energy)
        stability_score = self._compute_stability_score(achieved_energy, target_energy, activations)
        return {
            "target_energy": target_energy,
            "achieved_energy": achieved_energy,
            "energy_difference": abs(achieved_energy - target_energy),
            "stability_score": stability_score,
            "parameters": tokenized_params.tolist(),
            "coupling_strength": float(activations['damping']),
            "scale_distribution": {
                "hidden_1_mean": float(np.mean(activations['hidden_1'])),
                "hidden_2_mean": float(np.mean(activations['hidden_2'])),
                "hidden_1_std": float(np.std(activations['hidden_1'])),
                "hidden_2_std": float(np.std(activations['hidden_2']))
            }
        }