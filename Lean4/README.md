# Lean 4 Formalization: QDT Black Hole Simulation

This directory contains a formal Lean 4 proof project that validates the
mathematical equations in
[`Simulations/QDT_Black_Hole_Simulation.py`](../Simulations/QDT_Black_Hole_Simulation.py).

## Structure

```
Lean4/
├── lean-toolchain              # Specifies Lean 4 version (v4.14.0)
├── lakefile.lean               # Lake build file; depends on Mathlib4
├── QDTBlackHole.lean           # Root module (re-exports all submodules)
└── QDTBlackHole/
    ├── Basic.lean              # Core definitions (functions + constants)
    ├── QuantumTunneling.lean   # Proofs for Q_t(τ, α) = exp(−α·|τ|)
    ├── GravitationalFunneling.lean  # Proofs for G_f(τ, β) = 1/(1+β·τ²)
    ├── TimeMediationFun.lean   # Proofs for τ(t) = Σ p^(−t/T₀)·cos(ω₀t/p)
    ├── EnergyDynamics.lean     # Proofs for E_total = Q_t + G_f
    └── Validation.lean         # Concrete instantiation with Python defaults
```

## Python ↔ Lean correspondence

| Python method                          | Lean definition / theorem                          |
|----------------------------------------|----------------------------------------------------|
| `quantum_tunneling(tau_val, alpha=0.5)`| `quantumTunneling tau_val alpha`                   |
| `gravitational_funneling(tau_val, beta=0.3)` | `gravitationalFunneling tau_val beta`        |
| `tau(t)` (per-prime term)              | `tauTerm p T0 omega0 t`                            |
| `tau(t)` (full sum)                    | `tauFunction primes T0 omega0 t`                   |
| `total_energy(t)` → `qt + gf`          | `totalEnergy tau_val alpha beta`                   |
| `self.T0`                              | `T0 mass`                                          |
| `self.omega0`                          | `omega0 mass`                                      |

## Validated properties

### Quantum tunneling `Q_t(τ, α) = exp(−α·|τ|)`

| Theorem                              | Mathematical statement              |
|--------------------------------------|-------------------------------------|
| `quantumTunneling_pos`               | `Q_t > 0` for all τ, α             |
| `quantumTunneling_le_one`            | `Q_t ≤ 1` when `α ≥ 0`             |
| `quantumTunneling_at_zero`           | `Q_t(0, α) = 1`                     |
| `quantumTunneling_lt_one_of_ne_zero` | `Q_t < 1` when `τ ≠ 0` and `α > 0` |
| `quantumTunneling_mem_Ioc`           | `Q_t ∈ (0, 1]` when `α ≥ 0`        |
| `quantumTunneling_strictMono_neg`    | Q_t is strictly decreasing in `|τ|` |
| `quantumTunneling_even`              | Q_t is an even function of τ        |

### Gravitational funneling `G_f(τ, β) = 1/(1 + β·τ²)`

| Theorem                                 | Mathematical statement              |
|-----------------------------------------|-------------------------------------|
| `gravitationalFunneling_pos`            | `G_f > 0` when `β > 0`             |
| `gravitationalFunneling_le_one`         | `G_f ≤ 1` when `β > 0`             |
| `gravitationalFunneling_at_zero`        | `G_f(0, β) = 1`                     |
| `gravitationalFunneling_mem_Ioc`        | `G_f ∈ (0, 1]` when `β > 0`        |
| `gravitationalFunneling_strictMono_neg` | G_f strictly decreasing in `|τ|`   |
| `gravitationalFunneling_even`           | G_f is an even function of τ        |

### Time mediation function `τ(t) = Σ p^(−t/T₀)·cos(ω₀·t/p)`

| Theorem                            | Mathematical statement                         |
|------------------------------------|------------------------------------------------|
| `tauTerm_dampingFactor_pos`        | `p^(−t/T₀) > 0` for prime `p > 0`             |
| `tauTerm_dampingFactor_le_one`     | `p^(−t/T₀) ≤ 1` for `p ≥ 1, t ≥ 0, T₀ > 0`  |
| `tauTerm_abs_le_dampingFactor`     | `|τ_term| ≤ p^(−t/T₀)` for `p > 0`           |
| `tauTerm_at_tzero`                 | Each term = 1 at `t = 0`                       |
| `tauFunction_at_tzero`             | `τ(0) = n` for n primes                        |
| `tauFunction_abs_le_sum_damping`   | `|τ(t)| ≤ Σ p^(−t/T₀)` (global bound)         |
| `T0_pos`                           | `T₀ > 0` for positive mass                     |
| `omega0_pos`                       | `ω₀ > 0` for positive mass                     |
| `T0_mul_omega0`                    | `T₀ · ω₀ = 1` (reciprocal relationship)        |

### Total energy `E_total(τ, α, β) = Q_t + G_f`

| Theorem                          | Mathematical statement                               |
|----------------------------------|------------------------------------------------------|
| `totalEnergy_pos`                | `E_total > 0` when `α ≥ 0, β > 0`                   |
| `totalEnergy_le_two`             | `E_total ≤ 2` when `α ≥ 0, β > 0`                   |
| `totalEnergy_at_zero`            | `E_total(0, α, β) = 2`                               |
| `totalEnergy_mem_Ioc`            | `E_total ∈ (0, 2]` when `α ≥ 0, β > 0`              |
| `totalEnergy_variation_lt_two`   | `|E(τ₁) − E(τ₂)| < 2` (energy conservation bound)  |
| `totalEnergy_even`               | E_total is an even function of τ                    |

### Concrete validation with Python defaults (α = 0.5, β = 0.3, mass = 10)

| Lemma                            | Python equivalent                             |
|----------------------------------|-----------------------------------------------|
| `qt_at_zero_default`             | `quantum_tunneling(0) == 1.0`                 |
| `gf_at_zero_default`             | `gravitational_funneling(0) == 1.0`           |
| `total_energy_at_zero_default`   | `total_energy(t=0)` ≡ `(2.0, 1.0, 1.0)`     |
| `qt_bounded_default`             | `0 < qt ≤ 1` for all τ                        |
| `gf_bounded_default`             | `0 < gf ≤ 1` for all τ                        |
| `energy_bounded_default`         | `0 < e_total ≤ 2` for all τ                   |
| `T0_default_pos`                 | `T0(10) > 0`                                  |
| `T0_omega0_default`              | `T0(10) * omega0(10) = 1`                     |
| `energy_conservation_bound_default` | `e_conservation < 2` (Python `analyze`)   |
| `qt_lt_one_default`              | `qt < 1` for any τ ≠ 0                        |

## Building and checking

### Prerequisites

- [Lean 4](https://leanprover.github.io/) (`v4.14.0`, specified in `lean-toolchain`)
- [elan](https://github.com/leanprover/elan) (Lean version manager)
- [Mathlib4](https://github.com/leanprover-community/mathlib4)
- [Lake](https://github.com/leanprover/lake) (Lean build tool, bundled with Lean 4)

### Install Lean 4 via elan

```bash
curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
source ~/.profile   # or restart your shell
```

### Build the project

```bash
cd Lean4
lake exe cache get    # download pre-built Mathlib cache (much faster)
lake build            # compile all proofs
```

If `lake exe cache get` is unavailable (first-time setup), run `lake build`
directly; it will compile Mathlib from source (this takes ~1 hour).

### Check a single file

```bash
cd Lean4
lean QDTBlackHole/QuantumTunneling.lean
```

## Design decisions

1. **`noncomputable`**: All functions are marked `noncomputable` because they
   use `Real.exp`, `Real.rpow`, and `Real.cos` which are not computationally
   decidable in Lean 4's kernel. This is standard for real-analysis
   formalization.

2. **Mathlib**: The proofs rely on the `Real.exp_pos`, `Real.exp_le_one_iff`,
   `Real.rpow_pos_of_pos`, `sq_nonneg`, and `div_pos` lemmas from
   [Mathlib4](https://leanprover-community.github.io/mathlib4_docs/).

3. **`List ℝ` for primes**: The Python code builds a `numpy` array of the
   first `n` primes. In Lean 4 we use `List ℝ` with a positivity hypothesis
   `∀ p ∈ primes, 0 < p`, keeping the formalization concrete.

4. **Scope**: The formal proofs validate the *mathematical properties* of the
   model equations, not the numerical accuracy of the Python simulation.
   The Python code uses floating-point arithmetic; the Lean proofs use exact
   real arithmetic.
