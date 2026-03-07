import Mathlib
import QDTBlackHole.Basic

/-!
# Time Mediation Function — Formal Properties

This file formalizes properties of the time mediation function

  `τ(t) = Σ_{p ∈ primes} p^(−t/T₀) · cos(ω₀ · t / p)`

which is implemented in Python as:

```python
def tau(self, t):
    return sum(np.power(p, -t/self.T0) * np.cos(self.omega0*t/p)
              for p in self.primes)
```

## Structure of τ(t)

Each summand `p^(−t/T₀) · cos(ω₀·t/p)` consists of:
- An **exponential damping** factor `p^(−t/T₀)` that is strictly positive
  for prime `p > 0` and any real `t`.
- A **cosine oscillation** `cos(ω₀·t/p)` with amplitude in `[−1, 1]`.

## Main results

| Lemma / Theorem                   | Statement                                              |
|-----------------------------------|--------------------------------------------------------|
| `tauTerm_dampingFactor_pos`       | `p^(−t/T₀) > 0` when `p > 0`                          |
| `tauTerm_abs_le_dampingFactor`    | `|tauTerm| ≤ p^(−t/T₀)` when `p > 0`                  |
| `tauTerm_at_tzero`                | `tauTerm p T0 ω₀ 0 = 1` when `p > 0, T0 ≠ 0`          |
| `tauFunction_at_tzero`            | `τ(0) = n` for a list of `n` positive primes           |
| `tauFunction_abs_le_sum_damping`  | `|τ(t)| ≤ Σ p^(−t/T₀)` when all primes > 0            |
| `T0_pos`                          | `T₀ > 0` for positive mass                             |
| `omega0_pos`                      | `ω₀ > 0` for positive mass                             |
| `T0_mul_omega0`                   | `T₀ · ω₀ = 1` for positive mass                        |
-/

namespace QDTBlackHole

/-! ### Damping factor positivity -/

/-- The exponential damping factor `p^(−t/T₀)` is strictly positive
    for any prime `p > 0`.

    This holds because `Real.rpow` of a positive base is always positive. -/
theorem tauTerm_dampingFactor_pos {p : ℝ} (hp : 0 < p) (T0 t : ℝ) :
    0 < p ^ (-t / T0) :=
  Real.rpow_pos_of_pos hp _

/-- The damping factor is at most 1 when `t ≥ 0`, `p ≥ 1`, and `T₀ > 0`.

    For `t ≥ 0`, `p ≥ 1`, and `T₀ > 0`, the exponent `−t/T₀ ≤ 0`,
    so `p^(−t/T₀) ≤ p^0 = 1`. -/
theorem tauTerm_dampingFactor_le_one {p : ℝ} (hp : 1 ≤ p) {T0 : ℝ} (hT0 : 0 < T0)
    {t : ℝ} (ht : 0 ≤ t) :
    p ^ (-t / T0) ≤ 1 := by
  rw [← Real.rpow_zero p]
  apply Real.rpow_le_rpow_of_exponent_ge (by linarith) hp
  have : 0 ≤ t / T0 := div_nonneg ht hT0.le
  linarith

/-! ### Amplitude bound -/

/-- Each term `|p^(−t/T₀) · cos(ω₀·t/p)|` is bounded by the
    (positive) damping factor `p^(−t/T₀)`.

    This follows because `|cos(·)| ≤ 1`. -/
theorem tauTerm_abs_le_dampingFactor {p : ℝ} (hp : 0 < p) (T0 omega0 t : ℝ) :
    |tauTerm p T0 omega0 t| ≤ p ^ (-t / T0) := by
  unfold tauTerm
  rw [abs_mul]
  have hcos : |Real.cos (omega0 * t / p)| ≤ 1 := by
    rw [abs_le]
    exact ⟨Real.neg_one_le_cos _, Real.cos_le_one _⟩
  have hdamp : 0 ≤ p ^ (-t / T0) := le_of_lt (tauTerm_dampingFactor_pos hp T0 t)
  calc |p ^ (-t / T0)| * |Real.cos (omega0 * t / p)|
      ≤ |p ^ (-t / T0)| * 1 := by
          apply mul_le_mul_of_nonneg_left hcos (abs_nonneg _)
    _ = p ^ (-t / T0) := by rw [mul_one, abs_of_nonneg hdamp]

/-! ### Value at t = 0 -/

/-- At `t = 0` the single-prime tau term equals 1:
    `p^(0) · cos(0) = 1 · 1 = 1` (for any `T₀ ≠ 0`). -/
theorem tauTerm_at_tzero {p : ℝ} (hp : 0 < p) (T0 omega0 : ℝ) :
    tauTerm p T0 omega0 0 = 1 := by
  unfold tauTerm
  simp [Real.rpow_zero, Real.cos_zero]

/-- At `t = 0`, the full tau function equals the number of primes in the list,
    because each term contributes exactly 1.

    `τ(0) = Σ_{p ∈ primes} 1 = |primes|`

    This matches the Python simulation: at `t = 0`, `tau_val = n_primes`. -/
theorem tauFunction_at_tzero (primes : List ℝ) (T0 omega0 : ℝ)
    (hprimes : ∀ p ∈ primes, (0 : ℝ) < p) :
    tauFunction primes T0 omega0 0 = (primes.length : ℝ) := by
  unfold tauFunction
  induction primes with
  | nil => simp
  | cons hd tl ih =>
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    rw [tauTerm_at_tzero (hprimes hd (List.mem_cons_self _ _))]
    have htl : ∀ p ∈ tl, (0 : ℝ) < p := fun p hp =>
      hprimes p (List.mem_cons_of_mem _ hp)
    rw [ih htl]
    push_cast
    ring

/-! ### Global amplitude bound for τ(t) -/

/-- The absolute value of `τ(t)` is bounded by the sum of the damping factors.

    `|τ(t)| ≤ Σ_{p ∈ primes} p^(−t/T₀)`

    This gives an upper envelope for the time mediation oscillations. -/
theorem tauFunction_abs_le_sum_damping (primes : List ℝ) (T0 omega0 t : ℝ)
    (hprimes : ∀ p ∈ primes, (0 : ℝ) < p) :
    |tauFunction primes T0 omega0 t| ≤
    (primes.map (fun p => p ^ (-t / T0))).sum := by
  unfold tauFunction
  induction primes with
  | nil => simp
  | cons hd tl ih =>
    simp only [List.map_cons, List.sum_cons]
    calc |tauTerm hd T0 omega0 t +
          (tl.map (fun p => tauTerm p T0 omega0 t)).sum|
        ≤ |tauTerm hd T0 omega0 t| +
          |(tl.map (fun p => tauTerm p T0 omega0 t)).sum| := abs_add _ _
      _ ≤ hd ^ (-t / T0) +
          (tl.map (fun p => p ^ (-t / T0))).sum := by
            have htl : ∀ p ∈ tl, (0 : ℝ) < p := fun p hp =>
              hprimes p (List.mem_cons_of_mem _ hp)
            linarith [tauTerm_abs_le_dampingFactor (hprimes hd (List.mem_cons_self _ _)) T0 omega0 t,
                      ih htl]

/-! ### Physical constants are positive -/

/-- `G_const > 0` -/
lemma G_const_pos : (0 : ℝ) < G_const := by norm_num [G_const]

/-- `c_light > 0` -/
lemma c_light_pos : (0 : ℝ) < c_light := by norm_num [c_light]

/-- `solarMass > 0` -/
lemma solarMass_pos : (0 : ℝ) < solarMass := by norm_num [solarMass]

/-- The characteristic time scale `T₀ = G·M·mass / c³` is strictly positive
    for any positive mass. -/
theorem T0_pos {mass : ℝ} (hmass : 0 < mass) : 0 < T0 mass := by
  unfold T0
  positivity

/-- The fundamental frequency `ω₀ = c³ / (G·M·mass)` is strictly positive
    for any positive mass. -/
theorem omega0_pos {mass : ℝ} (hmass : 0 < mass) : 0 < omega0 mass := by
  unfold omega0
  positivity

/-- `T₀ · ω₀ = 1` (they are reciprocals).

    This reflects the Python invariant `self.T0 * self.omega0 == 1`. -/
theorem T0_mul_omega0 {mass : ℝ} (hmass : 0 < mass) :
    T0 mass * omega0 mass = 1 := by
  unfold T0 omega0
  have hGmM_pos : 0 < G_const * mass * solarMass := by positivity
  have hc3_pos  : 0 < c_light ^ 3 := by positivity
  field_simp [ne_of_gt hGmM_pos, ne_of_gt hc3_pos]

end QDTBlackHole
