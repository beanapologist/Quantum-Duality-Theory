import Mathlib
import QDTBlackHole.Basic

/-!
# Gravitational Funneling — Formal Properties

This file proves the key mathematical properties of the gravitational funneling
factor

  `G_f(τ, β) = 1 / (1 + β · τ²)`

which is implemented in Python as:

```python
def gravitational_funneling(self, tau_val, beta=0.3):
    return 1.0 / (1.0 + beta * tau_val**2)
```

## Main results

| Theorem                                 | Statement                             |
|-----------------------------------------|---------------------------------------|
| `gravitationalFunneling_denom_pos`      | `0 < 1 + β·τ²` when `β > 0`          |
| `gravitationalFunneling_pos`            | `0 < G_f(τ, β)` when `β > 0`         |
| `gravitationalFunneling_le_one`         | `G_f(τ, β) ≤ 1` when `β > 0`         |
| `gravitationalFunneling_at_zero`        | `G_f(0, β) = 1` for all β            |
| `gravitationalFunneling_mem_Ioc`        | `G_f(τ, β) ∈ (0, 1]` when `β > 0`   |
| `gravitationalFunneling_strictMono_neg` | G_f is strictly decreasing in `τ²` when `β > 0` |
-/

namespace QDTBlackHole

/-! ### Denominator positivity -/

/-- The denominator `1 + β·τ²` is strictly positive when `β > 0`,
    because `τ² ≥ 0` so `β·τ² ≥ 0` and `1 + β·τ² ≥ 1 > 0`. -/
lemma gravitationalFunneling_denom_pos (tau_val : ℝ) {beta : ℝ} (h : 0 < beta) :
    0 < 1 + beta * tau_val ^ 2 := by
  have hsq  : 0 ≤ tau_val ^ 2        := sq_nonneg _
  have hmul : 0 ≤ beta * tau_val ^ 2 := mul_nonneg h.le hsq
  linarith

/-- The denominator is at least 1: `1 ≤ 1 + β·τ²` when `β ≥ 0`. -/
lemma gravitationalFunneling_denom_ge_one (tau_val : ℝ) {beta : ℝ} (h : 0 ≤ beta) :
    1 ≤ 1 + beta * tau_val ^ 2 := by
  have hmul : 0 ≤ beta * tau_val ^ 2 := mul_nonneg h (sq_nonneg _)
  linarith

/-! ### Positivity -/

/-- The gravitational funneling factor is strictly positive when `β > 0`. -/
theorem gravitationalFunneling_pos (tau_val : ℝ) {beta : ℝ} (h : 0 < beta) :
    0 < gravitationalFunneling tau_val beta := by
  unfold gravitationalFunneling
  exact div_pos one_pos (gravitationalFunneling_denom_pos tau_val h)

/-- Corollary: the factor is non-negative when `β > 0`. -/
theorem gravitationalFunneling_nonneg (tau_val : ℝ) {beta : ℝ} (h : 0 < beta) :
    0 ≤ gravitationalFunneling tau_val beta :=
  le_of_lt (gravitationalFunneling_pos tau_val h)

/-! ### Upper bound -/

/-- The gravitational funneling factor is at most 1 when `β > 0`.

    Since the denominator `1 + β·τ² ≥ 1`, the ratio `1/(1+β·τ²) ≤ 1`. -/
theorem gravitationalFunneling_le_one (tau_val : ℝ) {beta : ℝ} (h : 0 < beta) :
    gravitationalFunneling tau_val beta ≤ 1 := by
  unfold gravitationalFunneling
  rw [div_le_one (gravitationalFunneling_denom_pos tau_val h)]
  linarith [mul_nonneg h.le (sq_nonneg tau_val)]

/-! ### Value at zero -/

/-- At `τ = 0`, the denominator reduces to 1, giving `G_f(0, β) = 1`. -/
theorem gravitationalFunneling_at_zero (beta : ℝ) :
    gravitationalFunneling 0 beta = 1 := by
  unfold gravitationalFunneling
  simp

/-! ### Boundedness -/

/-- For `β > 0`, the gravitational funneling factor lies in the
    half-open interval `(0, 1]`.

    This validates the Python invariant: `0 < gf ≤ 1` for all `τ`. -/
theorem gravitationalFunneling_mem_Ioc (tau_val : ℝ) {beta : ℝ} (h : 0 < beta) :
    gravitationalFunneling tau_val beta ∈ Set.Ioc 0 1 :=
  ⟨gravitationalFunneling_pos tau_val h, gravitationalFunneling_le_one tau_val h⟩

/-! ### Monotonicity -/

/-- `G_f` is strictly decreasing as `|τ|` grows (for fixed `β > 0`).

    If `τ₁² < τ₂²` (i.e. `|τ₁| < |τ₂|`), then `G_f(τ₂, β) < G_f(τ₁, β)`:
    larger time-mediation magnitude means less gravitational funneling. -/
theorem gravitationalFunneling_strictMono_neg {beta : ℝ} (hβ : 0 < beta)
    {tau1 tau2 : ℝ} (h : tau1 ^ 2 < tau2 ^ 2) :
    gravitationalFunneling tau2 beta < gravitationalFunneling tau1 beta := by
  unfold gravitationalFunneling
  have hd1 : 0 < 1 + beta * tau1 ^ 2 := gravitationalFunneling_denom_pos tau1 hβ
  have hd2 : 0 < 1 + beta * tau2 ^ 2 := gravitationalFunneling_denom_pos tau2 hβ
  rw [div_lt_div_iff hd2 hd1]
  simp only [one_mul]
  linarith [mul_lt_mul_of_pos_left h hβ]

/-! ### Symmetry -/

/-- `G_f` is an even function of `τ`: `G_f(τ, β) = G_f(−τ, β)`. -/
theorem gravitationalFunneling_even (tau_val beta : ℝ) :
    gravitationalFunneling tau_val beta = gravitationalFunneling (-tau_val) beta := by
  unfold gravitationalFunneling
  ring_nf

end QDTBlackHole
