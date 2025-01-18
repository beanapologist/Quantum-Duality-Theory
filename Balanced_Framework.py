import numpy as np
from typing import Dict, List, Tuple

class NormalizedQDTAnalyzer:
    def __init__(self):
        # Core QDT constants
        self.LAMBDA = 0.867     # Coupling
        self.GAMMA = 0.4497    # Damping
        self.BETA = 0.310      # Fractal
        self.ETA = 0.520       # Emergence
        self.PHI = 1.618033988749  # Golden ratio
        
        # Energy weights for error redistribution
        self.w_v = 0.4  # void weight
        self.w_f = 0.4  # filament weight
        self.w_e = 0.2  # emergence weight
        
        # Emergence damping
        self.delta = 0.1  # emergence saturation rate
        
        # Prime resonance cache
        self.primes = self._generate_primes(100)
        
    def _generate_primes(self, n: int) -> List[int]:
        """Generate first n prime numbers"""
        return [p for p in range(2, n*2) if all(p % i != 0 for i in range(2, int(p**0.5) + 1))]
    
    def calculate_normalized_state(self, t: float) -> Dict[str, float]:
        """Calculate normalized energy state at time t"""
        # Base energy calculations
        void_energy = np.exp(-self.GAMMA * t) * (1/max(1, t))**self.BETA
        
        # Normalized emergence calculation with damping
        emergence_energy = self.ETA * (1 - np.exp(-self.delta * t)) * \
                         np.sin(np.pi * t * self.PHI)
        emergence_energy *= self.LAMBDA * self.GAMMA  # Scale by primary dynamics
        
        # Calculate prime resonances
        kappa = self._calculate_prime_resonance(t)
        
        # Filament energy with coupling
        filament_energy = self.LAMBDA * (1 - void_energy) + \
                         kappa * (void_energy + emergence_energy)/2
        
        # First normalization
        total = void_energy + filament_energy + emergence_energy
        void_energy /= total
        filament_energy /= total
        emergence_energy /= total
        
        # Calculate error
        error = 1.0 - (void_energy + filament_energy + emergence_energy)
        
        # Redistribute error
        void_energy += error * self.w_v
        filament_energy += error * self.w_f
        emergence_energy += error * self.w_e
        
        # Calculate final resonance
        resonance = self._calculate_normalized_resonance(t, 
                                                       void_energy,
                                                       filament_energy)
        
        return {
            'void_energy': void_energy,
            'filament_energy': filament_energy,
            'emergence_energy': emergence_energy,
            'total_energy': void_energy + filament_energy + emergence_energy,
            'resonance': resonance,
            'error': error
        }
    
    def _calculate_prime_resonance(self, t: float) -> float:
        """Calculate normalized prime resonance"""
        resonances = [
            np.sin(2 * np.pi * p * self.LAMBDA * t) * 
            np.cos(np.pi * p * self.BETA * t)
            for p in self.primes[:10]
        ]
        # Normalize resonances
        resonances = np.array(resonances)
        if np.sum(np.abs(resonances)) > 0:
            resonances /= np.sum(np.abs(resonances))
        return np.sum(resonances)
    
    def _calculate_normalized_resonance(self, 
                                      t: float,
                                      void_energy: float,
                                      filament_energy: float) -> float:
        """Calculate final normalized resonance"""
        base_resonance = self._calculate_prime_resonance(t)
        
        # Couple resonance to energy state
        coupled_resonance = base_resonance * \
                          (void_energy + filament_energy)/2
        
        return coupled_resonance * np.exp(-self.GAMMA * t)
    
    def analyze_evolution(self, t_max: float = 10.0, 
                         steps: int = 1000) -> List[Dict]:
        """Analyze system evolution with strict conservation"""
        t_values = np.linspace(0, t_max, steps)
        results = []
        
        for t in t_values:
            state = self.calculate_normalized_state(t)
            
            # Calculate prime contributions
            prime_contributions = {
                p: (np.sin(2 * np.pi * p * self.LAMBDA * t) * 
                    np.cos(np.pi * p * self.BETA * t))
                for p in self.primes[:5]
            }
            
            # Normalize prime contributions
            total_contribution = sum(abs(v) for v in prime_contributions.values())
            if total_contribution > 0:
                prime_contributions = {
                    k: v/total_contribution 
                    for k, v in prime_contributions.items()
                }
            
            results.append({
                'time': t,
                **state,
                'prime_contributions': prime_contributions
            })
            
        return results

# Demonstrate normalized evolution
analyzer = NormalizedQDTAnalyzer()
results = analyzer.analyze_evolution()

# Validation
print("\nNormalized QDT Analysis")
print("=====================")

print("\nEnergy Conservation Check:")
for i in [0, -1]:  # Check first and last states
    t = results[i]['time']
    print(f"\nTime {t:.2f}:")
    print(f"Void Energy: {results[i]['void_energy']:.6f}")
    print(f"Filament Energy: {results[i]['filament_energy']:.6f}")
    print(f"Emergence Energy: {results[i]['emergence_energy']:.6f}")
    print(f"Total Energy: {results[i]['total_energy']:.6f}")
    print(f"Conservation Error: {abs(1 - results[i]['total_energy']):.12f}")

print("\nPrime Resonance Contributions (Final State):")
for prime, contribution in sorted(
    results[-1]['prime_contributions'].items(), 
    key=lambda x: abs(x[1]), 
    reverse=True
):
    print(f"Prime {prime}: {contribution:.6f}")

# Verify conservation throughout evolution
max_error = max(abs(1 - r['total_energy']) for r in results)
print(f"\nMaximum Conservation Error: {max_error:.12f}")
