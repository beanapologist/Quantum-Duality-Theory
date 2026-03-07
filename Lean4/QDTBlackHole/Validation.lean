import Mathlib
import QDTBlackHole.Basic
import QDTBlackHole.QuantumTunneling
import QDTBlackHole.GravitationalFunneling
import QDTBlackHole.TimeMediationFun
import QDTBlackHole.EnergyDynamics

/-!
# Concrete Parameter Validation

This file instantiates the abstract theorems with the **exact default parameters**
used in `QDT_Black_Hole_Simulation.py` and verifies that the formal properties
hold for those values.

## Python default parameters

```python
class BlackHoleQDT:
    def __init__(self, mass, n_primes=10):
        ...

def quantum_tunneling(self, tau_val, alpha=0.5): ...
def gravitational_funneling(self, tau_val, beta=0.3): ...
```

So the default values are:
- `alpha = 0.5`  (quantum tunneling damping)
- `beta  = 0.3`  (gravitational funneling strength)
- `mass  = 10`   (solar masses, used in `run_simulation`)

## Verified concrete results

| Lemma                          | Python equivalent                       |
|--------------------------------|-----------------------------------------|
| `alpha_default_nonneg`         | `alpha = 0.5 ≥ 0`                       |
| `beta_default_pos`             | `beta = 0.3 > 0`                        |
| `qt_at_zero_default`           | `quantum_tunneling(0, 0.5) == 1.0`      |
| `gf_at_zero_default`           | `gravitational_funneling(0, 0.3) == 1.0`|
| `total_energy_at_zero_default` | `total_energy(0) == (2.0, 1.0, 1.0)`   |
| `qt_bounded_default`           | `0 < qt ≤ 1` for all τ                  |
| `gf_bounded_default`           | `0 < gf ≤ 1` for all τ                  |
| `energy_bounded_default`       | `0 < e_total ≤ 2` for all τ             |
| `mass_default_pos`             | `mass = 10 > 0`                         |
| `T0_default_pos`               | `T0(10) > 0`                            |
| `omega0_default_pos`           | `ω₀(10) > 0`                            |
| `T0_omega0_default`            | `T0(10) * ω₀(10) = 1`                  |
-/

namespace QDTBlackHole

/-! ## Default simulation parameters -/

/-- Default quantum tunneling damping coefficient `α = 0.5` -/
def alpha_default : ℝ := 0.5

/-- Default gravitational funneling strength `β = 0.3` -/
def beta_default : ℝ := 0.3

/-- Default black hole mass in solar masses (used in `run_simulation(mass=10)`) -/
def mass_default : ℝ := 10

/-! ## Verification of parameter constraints -/

/-- `α = 0.5 ≥ 0`, satisfying the non-negativity requirement for Q_t bounds. -/
lemma alpha_default_nonneg : (0 : ℝ) ≤ alpha_default := by
  norm_num [alpha_default]

/-- `α = 0.5 > 0`, satisfying the strict positivity requirement for strict Q_t bounds. -/
lemma alpha_default_pos : (0 : ℝ) < alpha_default := by
  norm_num [alpha_default]

/-- `β = 0.3 > 0`, satisfying the positivity requirement for G_f bounds. -/
lemma beta_default_pos : (0 : ℝ) < beta_default := by
  norm_num [beta_default]

/-- Default mass `10 M☉ > 0`, needed for well-defined T₀ and ω₀. -/
lemma mass_default_pos : (0 : ℝ) < mass_default := by
  norm_num [mass_default]

/-! ## Concrete values at τ = 0 -/

/-- With default α, quantum tunneling at τ = 0 is exactly 1.
    Matches Python: `quantum_tunneling(0, alpha=0.5) == 1.0` -/
lemma qt_at_zero_default : quantumTunneling 0 alpha_default = 1 :=
  quantumTunneling_at_zero _

/-- With default β, gravitational funneling at τ = 0 is exactly 1.
    Matches Python: `gravitational_funneling(0, beta=0.3) == 1.0` -/
lemma gf_at_zero_default : gravitationalFunneling 0 beta_default = 1 :=
  gravitationalFunneling_at_zero _

/-- With default parameters, total energy at τ = 0 is exactly 2.
    Matches Python: `total_energy(t=0)` returns `(2.0, 1.0, 1.0)`. -/
lemma total_energy_at_zero_default :
    totalEnergy 0 alpha_default beta_default = 2 :=
  totalEnergy_at_zero _ _

/-! ## Concrete bounds for all τ -/

/-- With default α = 0.5, quantum tunneling is always in `(0, 1]` for all τ.
    Validates Python invariant: `0 < qt ≤ 1`. -/
theorem qt_bounded_default (tau_val : ℝ) :
    quantumTunneling tau_val alpha_default ∈ Set.Ioc 0 1 :=
  quantumTunneling_mem_Ioc tau_val alpha_default_nonneg

/-- With default β = 0.3, gravitational funneling is always in `(0, 1]` for all τ.
    Validates Python invariant: `0 < gf ≤ 1`. -/
theorem gf_bounded_default (tau_val : ℝ) :
    gravitationalFunneling tau_val beta_default ∈ Set.Ioc 0 1 :=
  gravitationalFunneling_mem_Ioc tau_val beta_default_pos

/-- With default parameters, total energy is always in `(0, 2]` for all τ.
    Validates the Python `analyze` result: `e_total ∈ (0, 2]`. -/
theorem energy_bounded_default (tau_val : ℝ) :
    totalEnergy tau_val alpha_default beta_default ∈ Set.Ioc 0 2 :=
  totalEnergy_mem_Ioc tau_val alpha_default_nonneg beta_default_pos

/-! ## Physical scales for default mass -/

/-- The characteristic time scale `T₀(10 M☉)` is strictly positive. -/
theorem T0_default_pos : 0 < T0 mass_default :=
  T0_pos mass_default_pos

/-- The fundamental frequency `ω₀(10 M☉)` is strictly positive. -/
theorem omega0_default_pos : 0 < omega0 mass_default :=
  omega0_pos mass_default_pos

/-- `T₀(10 M☉) · ω₀(10 M☉) = 1`. -/
theorem T0_omega0_default : T0 mass_default * omega0 mass_default = 1 :=
  T0_mul_omega0 mass_default_pos

/-! ## Energy conservation bound for default parameters -/

/-- For default parameters, the variation of total energy across any two
    time-mediation values is strictly less than 2.
    This bounds the Python `e_conservation` metric. -/
theorem energy_conservation_bound_default (tau1 tau2 : ℝ) :
    |totalEnergy tau1 alpha_default beta_default -
     totalEnergy tau2 alpha_default beta_default| < 2 :=
  totalEnergy_variation_lt_two tau1 tau2 alpha_default_nonneg beta_default_pos

/-! ## Strict damping with default α -/

/-- With `α = 0.5 > 0`, quantum tunneling is strictly less than 1 at any τ ≠ 0.
    Matches the physical intuition that non-zero time-mediation reduces tunneling. -/
theorem qt_lt_one_default {tau_val : ℝ} (htau : tau_val ≠ 0) :
    quantumTunneling tau_val alpha_default < 1 :=
  quantumTunneling_lt_one_of_ne_zero htau alpha_default_pos

end QDTBlackHole
