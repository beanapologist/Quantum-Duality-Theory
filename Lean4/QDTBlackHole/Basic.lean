import Mathlib

/-!
# QDT Black Hole Simulation — Core Definitions

This file provides Lean 4 definitions that correspond directly to the Python
functions in `Simulations/QDT_Black_Hole_Simulation.py`.

## Python ↔ Lean correspondence

| Python method                        | Lean definition              |
|--------------------------------------|------------------------------|
| `quantum_tunneling(tau_val, alpha)`  | `quantumTunneling`           |
| `gravitational_funneling(tau_val, beta)` | `gravitationalFunneling` |
| `tau(t)` (single-term helper)        | `tauTerm`, `tauFunction`     |
| `total_energy(t)`                    | `totalEnergy`                |

## Physical constants (SI units)

The Python `BlackHoleQDT` class uses:
- `G = 6.674 × 10⁻¹¹ N·m²/kg²` (gravitational constant)
- `c = 3 × 10⁸ m/s`            (speed of light)
- `T₀ = G·M·2×10³⁰ / c³`       (characteristic time scale)
- `ω₀ = c³ / (G·M·2×10³⁰)`     (fundamental frequency, reciprocal of T₀)
-/

namespace QDTBlackHole

/-! ## Physical constants -/

/-- Gravitational constant (N·m²·kg⁻²) -/
noncomputable def G_const : ℝ := 6.674e-11

/-- Speed of light (m·s⁻¹) -/
noncomputable def c_light : ℝ := 3e8

/-- Solar mass in kilograms -/
noncomputable def solarMass : ℝ := 2e30

/-! ## Core functions -/

/-- **Quantum tunneling probability**

    `Q_t(τ) = exp(−α · |τ|)`

    Python: `quantum_tunneling(tau_val, alpha=0.5) = np.exp(-alpha * np.abs(tau_val))`

    For `α ≥ 0` this lies in the interval `(0, 1]`, reaching 1 only when `τ = 0`.
-/
noncomputable def quantumTunneling (tau_val alpha : ℝ) : ℝ :=
  Real.exp (-alpha * |tau_val|)

/-- **Gravitational funneling factor**

    `G_f(τ) = 1 / (1 + β · τ²)`

    Python: `gravitational_funneling(tau_val, beta=0.3) = 1.0 / (1.0 + beta * tau_val**2)`

    For `β > 0` this lies in the interval `(0, 1]`, reaching 1 only when `τ = 0`.
-/
noncomputable def gravitationalFunneling (tau_val beta : ℝ) : ℝ :=
  1 / (1 + beta * tau_val ^ 2)

/-- **Single-prime tau term**

    One summand of `τ(t)`: `p^(−t/T₀) · cos(ω₀ · t / p)`

    Python (inside the sum): `np.power(p, -t/self.T0) * np.cos(self.omega0 * t / p)`
-/
noncomputable def tauTerm (p T0 omega0 t : ℝ) : ℝ :=
  p ^ (-t / T0) * Real.cos (omega0 * t / p)

/-- **Time mediation function τ(t)**

    `τ(t) = Σ_{p ∈ primes} p^(−t/T₀) · cos(ω₀ · t / p)`

    Python: `tau(t)` sums `tauTerm` over the first `n_primes` primes.
-/
noncomputable def tauFunction (primes : List ℝ) (T0 omega0 t : ℝ) : ℝ :=
  (primes.map (fun p => tauTerm p T0 omega0 t)).sum

/-- **Total instantaneous energy**

    `E_total(τ) = Q_t(τ) + G_f(τ)`

    Python: `total_energy` returns `(qt + gf, qt, gf)` where `qt` and `gf`
    are evaluated at `τ(t)`.
-/
noncomputable def totalEnergy (tau_val alpha beta : ℝ) : ℝ :=
  quantumTunneling tau_val alpha + gravitationalFunneling tau_val beta

/-- **Characteristic time scale T₀**

    `T₀ = G · M_solar · mass / c³`

    Python: `self.T0 = self.G * self.mass * 2e30 / self.c**3`
-/
noncomputable def T0 (mass : ℝ) : ℝ :=
  G_const * mass * solarMass / c_light ^ 3

/-- **Fundamental angular frequency ω₀**

    `ω₀ = c³ / (G · M_solar · mass)`

    Python: `self.omega0 = self.c**3 / (self.G * self.mass * 2e30)`

    Note: `ω₀ = 1 / T₀` for positive mass.
-/
noncomputable def omega0 (mass : ℝ) : ℝ :=
  c_light ^ 3 / (G_const * mass * solarMass)

end QDTBlackHole
