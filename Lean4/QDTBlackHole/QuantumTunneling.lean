import Mathlib
import QDTBlackHole.Basic

/-!
# Quantum Tunneling — Formal Properties

This file proves the key mathematical properties of the quantum tunneling
probability function

  `Q_t(τ, α) = exp(−α · |τ|)`

which is implemented in Python as:

```python
def quantum_tunneling(self, tau_val, alpha=0.5):
    return np.exp(-alpha * np.abs(tau_val))
```

## Main results

| Theorem                              | Statement                              |
|--------------------------------------|----------------------------------------|
| `quantumTunneling_pos`               | `0 < Q_t(τ, α)` for all τ, α          |
| `quantumTunneling_le_one`            | `Q_t(τ, α) ≤ 1` when `α ≥ 0`          |
| `quantumTunneling_at_zero`           | `Q_t(0, α) = 1` for all α             |
| `quantumTunneling_lt_one_of_ne_zero` | `Q_t(τ, α) < 1` when `τ ≠ 0, α > 0`  |
| `quantumTunneling_mem_Ioc`           | `Q_t(τ, α) ∈ (0, 1]` when `α ≥ 0`    |
| `quantumTunneling_strictMono_neg`    | Q_t is strictly decreasing in `|τ|` when `α > 0` |
-/

namespace QDTBlackHole

/-! ### Positivity -/

/-- The quantum tunneling probability is always strictly positive,
    regardless of `tau_val` or `alpha`. This follows directly from
    `exp` being everywhere positive. -/
theorem quantumTunneling_pos (tau_val alpha : ℝ) :
    0 < quantumTunneling tau_val alpha := by
  unfold quantumTunneling
  exact Real.exp_pos _

/-- Corollary: the quantum tunneling probability is non-negative. -/
theorem quantumTunneling_nonneg (tau_val alpha : ℝ) :
    0 ≤ quantumTunneling tau_val alpha :=
  le_of_lt (quantumTunneling_pos tau_val alpha)

/-! ### Upper bound -/

/-- When `α ≥ 0`, the exponent `−α · |τ|` is non-positive,
    so `exp(−α · |τ|) ≤ exp(0) = 1`. -/
theorem quantumTunneling_le_one (tau_val : ℝ) {alpha : ℝ} (h : 0 ≤ alpha) :
    quantumTunneling tau_val alpha ≤ 1 := by
  unfold quantumTunneling
  rw [Real.exp_le_one_iff]
  have habs : 0 ≤ |tau_val| := abs_nonneg _
  linarith [mul_nonneg h habs]

/-- For `α > 0` and `τ ≠ 0`, the exponent is strictly negative,
    giving `Q_t(τ, α) < 1`. -/
theorem quantumTunneling_lt_one_of_ne_zero {tau_val : ℝ} (htau : tau_val ≠ 0)
    {alpha : ℝ} (h : 0 < alpha) : quantumTunneling tau_val alpha < 1 := by
  unfold quantumTunneling
  rw [Real.exp_lt_one_iff]
  have habs : 0 < |tau_val| := abs_pos.mpr htau
  linarith [mul_pos h habs]

/-! ### Value at zero -/

/-- At `τ = 0`, the exponent vanishes: `Q_t(0, α) = exp(0) = 1`. -/
theorem quantumTunneling_at_zero (alpha : ℝ) :
    quantumTunneling 0 alpha = 1 := by
  unfold quantumTunneling
  simp [Real.exp_zero]

/-! ### Boundedness -/

/-- For `α ≥ 0`, the quantum tunneling probability is bounded in the
    half-open interval `(0, 1]`.

    This validates the Python invariant: `0 < qt ≤ 1` for all `τ`. -/
theorem quantumTunneling_mem_Ioc (tau_val : ℝ) {alpha : ℝ} (h : 0 ≤ alpha) :
    quantumTunneling tau_val alpha ∈ Set.Ioc 0 1 :=
  ⟨quantumTunneling_pos tau_val alpha, quantumTunneling_le_one tau_val h⟩

/-! ### Monotonicity -/

/-- For fixed `α > 0`, `Q_t` is strictly decreasing as `|τ|` increases.
    The larger the time-mediation magnitude, the smaller the tunneling probability.

    Formally: if `|τ₁| < |τ₂|` then `Q_t(τ₂, α) < Q_t(τ₁, α)`. -/
theorem quantumTunneling_strictMono_neg {alpha : ℝ} (hα : 0 < alpha)
    {tau1 tau2 : ℝ} (h : |tau1| < |tau2|) :
    quantumTunneling tau2 alpha < quantumTunneling tau1 alpha := by
  unfold quantumTunneling
  apply Real.exp_lt_exp.mpr
  linarith [mul_lt_mul_of_pos_left h hα]

/-- For fixed `τ`, `Q_t` is strictly decreasing as `α` increases:
    stronger damping reduces the tunneling probability. -/
theorem quantumTunneling_strictMono_neg_alpha (tau_val : ℝ) (htau : tau_val ≠ 0)
    {alpha1 alpha2 : ℝ} (h : alpha1 < alpha2) :
    quantumTunneling tau_val alpha2 < quantumTunneling tau_val alpha1 := by
  unfold quantumTunneling
  apply Real.exp_lt_exp.mpr
  have habs : 0 < |tau_val| := abs_pos.mpr htau
  linarith [mul_lt_mul_of_pos_right h habs]

/-! ### Symmetry -/

/-- `Q_t` depends only on `|τ|`, so it is symmetric in `τ`:
    `Q_t(τ, α) = Q_t(−τ, α)`. -/
theorem quantumTunneling_even (tau_val alpha : ℝ) :
    quantumTunneling tau_val alpha = quantumTunneling (-tau_val) alpha := by
  unfold quantumTunneling
  simp [abs_neg]

end QDTBlackHole
