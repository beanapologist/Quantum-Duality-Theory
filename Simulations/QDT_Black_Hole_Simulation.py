```python
import numpy as np
from scipy.fft import fft, fftfreq
import matplotlib.pyplot as plt

class BlackHoleQDT:
    def __init__(self, mass, n_primes=10):
        self.mass = mass  # Solar masses
        self.G = 6.674e-11  
        self.c = 3e8
        self.T0 = self.G * self.mass * 2e30 / self.c**3
        self.omega0 = self.c**3 / (self.G * self.mass * 2e30)
        self.primes = self._generate_primes(n_primes)
        
    def _generate_primes(self, n):
        primes = []
        num = 2
        while len(primes) < n:
            if all(num % prime != 0 for prime in primes):
                primes.append(num)
            num += 1
        return np.array(primes)
    
    def tau(self, t):
        return sum(np.power(p, -t/self.T0) * np.cos(self.omega0*t/p) 
                  for p in self.primes)
    
    def quantum_tunneling(self, tau_val, alpha=0.5):
        return np.exp(-alpha * np.abs(tau_val))
    
    def gravitational_funneling(self, tau_val, beta=0.3):
        return 1.0 / (1.0 + beta * tau_val**2)
    
    def total_energy(self, t):
        tau_val = self.tau(t)
        qt = self.quantum_tunneling(tau_val)
        gf = self.gravitational_funneling(tau_val)
        return qt + gf, qt, gf
    
    def simulate(self, t_max, n_points=1000):
        t = np.linspace(0, t_max, n_points)
        tau_vals = np.array([self.tau(ti) for ti in t])
        e_total, qt, gf = zip(*[self.total_energy(ti) for ti in t])
        
        # QPO analysis
        dt = t[1] - t[0]
        freqs = fftfreq(len(t), dt)
        tau_fft = np.abs(fft(tau_vals))
        
        return {
            't': t,
            'tau': tau_vals,
            'e_total': e_total,
            'qt': qt,
            'gf': gf,
            'freqs': freqs[1:len(freqs)//2],
            'power': tau_fft[1:len(freqs)//2]
        }
    
    def analyze(self, results):
        e_conservation = np.abs(np.max(results['e_total']) - 
                              np.min(results['e_total']))
        peak_freqs = results['freqs'][np.argsort(results['power'])[-len(self.primes):]]
        
        return {
            'e_conservation': e_conservation,
            'peak_frequencies': peak_freqs,
            'mean_energy': np.mean(results['e_total']),
            'energy_std': np.std(results['e_total'])
        }
    
    def plot_results(self, results):
        fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(10, 12))
        
        # Time mediation
        ax1.plot(results['t'], results['tau'])
        ax1.set_title('Time Mediation Function τ(t)')
        ax1.set_xlabel('Time (s)')
        ax1.set_ylabel('τ(t)')
        
        # Energy components
        ax2.plot(results['t'], results['qt'], label='Quantum Tunneling')
        ax2.plot(results['t'], results['gf'], label='Gravitational Funneling')
        ax2.plot(results['t'], results['e_total'], label='Total Energy')
        ax2.set_title('Energy Distribution')
        ax2.set_xlabel('Time (s)')
        ax2.set_ylabel('Energy')
        ax2.legend()
        
        # Power spectrum
        ax3.semilogy(results['freqs'], results['power'])
        ax3.set_title('QPO Power Spectrum')
        ax3.set_xlabel('Frequency (Hz)')
        ax3.set_ylabel('Power')
        
        plt.tight_layout()
        return fig

def run_simulation(mass=10, t_max=100):
    bh = BlackHoleQDT(mass)
    results = bh.simulate(t_max)
    metrics = bh.analyze(results)
    fig = bh.plot_results(results)
    
    print(f"\nBlack Hole Mass: {mass} M☉")
    print(f"Energy Conservation: {metrics['e_conservation']:.2e}")
    print(f"Mean Energy: {metrics['mean_energy']:.4f}")
    print("\nQPO Frequencies:")
    for i, freq in enumerate(metrics['peak_frequencies'], 1):
        print(f"f_{i}: {freq:.2f} Hz")
    
    return results, metrics, fig

if __name__ == "__main__":
    results, metrics, fig = run_simulation()
    plt.show()
```
