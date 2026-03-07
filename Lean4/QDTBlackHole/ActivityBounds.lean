import Mathlib
import QDTBlackHole.Basic
import QDTBlackHole.QuantumTunneling
import QDTBlackHole.GravitationalFunneling
import QDTBlackHole.TimeMediationFun
import QDTBlackHole.EnergyDynamics

/-!
# Activity Bounds and Energy Balance

This file proves two new families of results for the QDT black hole formalization:

**1. Activity bounds for τ(t)** — controls on how large `|τ(t)|` can get,
and a quantitative exponential-decay envelope bounding activity spikes.

**2. Energy balance near 1** — the AM-GM product inequality relating `Q_t`
and `G_f`, continuity of all three energy functions, and an intermediate-value
theorem showing total energy achieves the duality balance value 1.

## Sup bound and activity decay

The time mediation function satisfies:
- `|τ(t)| ≤ n_primes`               for all `t ≥ 0` (global sup bound)
- `|τ(t)| ≤ n_primes * p_min^(−t/T₀)` (exponential decay envelope)

The decay bound controls *activity spikes*: for any `δ > 0`,
`|τ(t)| < δ` whenever `t > T₀ * Real.log (n_primes / δ) / Real.log p_min`.

## Energy balance

The energy components satisfy the AM-GM product bound:
```
Q_t(τ) * G_f(τ) ≤ (E_total(τ) / 2)²
```
By continuity and the intermediate value theorem, there exists `τ₀` with `0 ≤ τ₀`
where `E_total(τ₀) = 1` — the **duality balance point** where neither quantum
nor gravitational effects dominate.

## Main results

| Theorem                             | Statement                                          |
|-------------------------------------|----------------------------------------------------|
| `tauFunction_sup_le_nprimes`        | `|τ(t)| ≤ n` for t ≥ 0, primes ≥ 1, T₀ > 0       |
| `tauFunction_activity_decay`        | `|τ(t)| ≤ n * p_min^(−t/T₀)` (decay envelope)     |
| `totalEnergy_amgm`                  | `Q_t · G_f ≤ (E_total/2)²` (AM-GM product bound)  |
| `quantumTunneling_continuous`       | Q_t is continuous in τ                             |
| `gravitationalFunneling_continuous` | G_f is continuous in τ                             |
| `totalEnergy_continuous`            | E_total is continuous in τ                         |
| `totalEnergy_exists_eq_one`         | `∃ τ₀, 0 ≤ τ₀ ∧ E_total(τ₀) = 1` (duality balance) |
-/

namespace QDTBlackHole

/-! ## Private helper lemmas -/

/-- Sum of a constant-mapped list equals length times the constant. -/
private lemma list_sum_const_eq_length_mul {α : Type*} (l : List α) (c : ℝ) :
    (l.map (fun _ => c)).sum = (l.length : ℝ) * c := by
  induction l with
  | nil => simp
  | cons _ tl ih =>
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    push_cast
    linarith

/-- The damping factor `p^(−t/T₀)` is anti-monotone in the base `p` when
    the exponent is non-positive (`t ≥ 0, T₀ > 0`): a larger base yields a
    smaller (more heavily damped) value.

    Formally: `p₁ ≤ p₂ → p₂^(−t/T₀) ≤ p₁^(−t/T₀)`. -/
private lemma tauTerm_dampingFactor_anti_mono
    {p₁ p₂ : ℝ} (hp₁ : 0 < p₁) (hp₁₂ : p₁ ≤ p₂)
    {T0 : ℝ} (hT0 : 0 < T0) {t : ℝ} (ht : 0 ≤ t) :
    p₂ ^ (-t / T0) ≤ p₁ ^ (-t / T0) := by
  have hexp_nn : 0 ≤ t / T0 := div_nonneg ht hT0.le
  have hp₂ : 0 < p₂ := lt_of_lt_of_le hp₁ hp₁₂
  -- Rewrite p^(-t/T₀) = (p^(t/T₀))⁻¹ for each positive base
  have hrw : ∀ {p : ℝ}, 0 < p → p ^ (-t / T0) = (p ^ (t / T0))⁻¹ := fun {p} hp => by
    rw [show -t / T0 = -(t / T0) from by ring]
    exact Real.rpow_neg hp.le _
  rw [hrw hp₁, hrw hp₂]
  -- Larger base → larger positive power → smaller inverse
  exact inv_le_inv_of_le
    (Real.rpow_pos_of_pos hp₁ _)
    (Real.rpow_le_rpow hp₁.le hp₁₂ hexp_nn)

/-! ## Sup bound on |τ(t)| -/

/-- **Global sup bound on τ(t)**: for `t ≥ 0`, all primes `p ≥ 1`, and
    `T₀ > 0`, the absolute value of the time mediation function is bounded
    above by the number of primes:

      `|τ(t)| ≤ n_primes`

    The bound is tight: it is achieved exactly at `t = 0` (see
    `tauFunction_at_tzero`), where every cosine factor equals 1 and every
    damping factor equals 1.

    **Python connection**: The default Python simulation uses `n_primes = 10`,
    so `|tau_val| ≤ 10` for all non-negative `t`. -/
theorem tauFunction_sup_le_nprimes
    (primes : List ℝ) {T0 omega0 : ℝ} (hT0 : 0 < T0)
    {t : ℝ} (ht : 0 ≤ t) (hprimes : ∀ p ∈ primes, (1 : ℝ) ≤ p) :
    |tauFunction primes T0 omega0 t| ≤ (primes.length : ℝ) :=
  calc |tauFunction primes T0 omega0 t|
      ≤ (primes.map (fun p => p ^ (-t / T0))).sum :=
          tauFunction_abs_le_sum_damping primes T0 omega0 t
            (fun p hp => lt_of_lt_of_le one_pos (hprimes p hp))
    _ ≤ (primes.map (fun _ => (1 : ℝ))).sum := by
          apply List.sum_le_sum
          intro x hx
          simp only [List.mem_map] at hx
          obtain ⟨p, hp, rfl⟩ := hx
          exact tauTerm_dampingFactor_le_one (hprimes p hp) hT0 ht
    _ = (primes.length : ℝ) := by
          rw [list_sum_const_eq_length_mul]; simp

/-! ## Quantitative activity decay envelope -/

/-- **Exponential decay envelope for activity spikes**: when all primes are
    ≥ `p_min > 0` and `t ≥ 0`, `T₀ > 0`:

      `|τ(t)| ≤ n_primes * p_min^(−t/T₀)`

    Because `p^(−t/T₀)` is anti-monotone in `p`, every term in the sum is
    bounded by the contribution from the *smallest* prime `p_min`, giving a
    single exponentially-decaying envelope.

    **Corollary (activity spike control)**: for any threshold `δ > 0`,
    `|τ(t)| < δ` whenever `t > T₀ * Real.log (n / δ) / Real.log p_min`
    (obtained by solving `n * p_min^(−t/T₀) < δ`). -/
theorem tauFunction_activity_decay
    (primes : List ℝ) {T0 omega0 : ℝ} (hT0 : 0 < T0)
    {t : ℝ} (ht : 0 ≤ t) {p_min : ℝ} (hp_min : 0 < p_min)
    (hprimes : ∀ p ∈ primes, p_min ≤ p) :
    |tauFunction primes T0 omega0 t| ≤
    (primes.length : ℝ) * p_min ^ (-t / T0) :=
  calc |tauFunction primes T0 omega0 t|
      ≤ (primes.map (fun p => p ^ (-t / T0))).sum :=
          tauFunction_abs_le_sum_damping primes T0 omega0 t
            (fun p hp => lt_of_lt_of_le hp_min (hprimes p hp))
    _ ≤ (primes.map (fun _ => p_min ^ (-t / T0))).sum := by
          apply List.sum_le_sum
          intro x hx
          simp only [List.mem_map] at hx
          obtain ⟨p, hp, rfl⟩ := hx
          exact tauTerm_dampingFactor_anti_mono hp_min (hprimes p hp) hT0 ht
    _ = (primes.length : ℝ) * p_min ^ (-t / T0) := by
          rw [list_sum_const_eq_length_mul]

/-! ## AM-GM product bound on energy components -/

/-- **AM-GM inequality for energy components**:

      `Q_t(τ) · G_f(τ) ≤ (E_total(τ) / 2)²`

    This follows from the AM-GM inequality `a · b ≤ ((a + b) / 2)²`,
    which holds because `(a − b)² ≥ 0`.

    **Physical interpretation**: the product of the quantum tunneling
    probability and gravitational funneling factor is maximised when the two
    are equal (`Q_t = G_f`), giving `E_total = 2·Q_t` at that point.
    The bound states that this product never exceeds `(E_total/2)²`. -/
theorem totalEnergy_amgm
    (tau_val : ℝ) {alpha : ℝ} (ha : 0 ≤ alpha) {beta : ℝ} (hb : 0 < beta) :
    quantumTunneling tau_val alpha * gravitationalFunneling tau_val beta ≤
    (totalEnergy tau_val alpha beta / 2) ^ 2 := by
  have hqt := quantumTunneling_nonneg tau_val alpha
  have hgf := gravitationalFunneling_nonneg tau_val hb
  unfold totalEnergy
  nlinarith [sq_nonneg (quantumTunneling tau_val alpha - gravitationalFunneling tau_val beta)]

/-! ## Continuity of the energy functions -/

/-- The quantum tunneling probability `Q_t(τ, α) = exp(−α·|τ|)` is continuous
    as a function of `τ` (for fixed `α`). -/
theorem quantumTunneling_continuous (alpha : ℝ) :
    Continuous (fun τ => quantumTunneling τ alpha) := by
  unfold quantumTunneling
  exact Real.continuous_exp.comp (continuous_const.mul continuous_abs)

/-- The gravitational funneling factor `G_f(τ, β) = 1/(1 + β·τ²)` is
    continuous as a function of `τ` (for fixed `β > 0`).

    The denominator `1 + β·τ²` is always strictly positive, so the
    rational expression is everywhere well-defined and continuous. -/
theorem gravitationalFunneling_continuous {beta : ℝ} (hb : 0 < beta) :
    Continuous (fun τ => gravitationalFunneling τ beta) := by
  unfold gravitationalFunneling
  have hdenom_cont : Continuous (fun τ : ℝ => 1 + beta * τ ^ 2) :=
    continuous_const.add (continuous_const.mul (continuous_id.pow 2))
  exact continuous_const.div hdenom_cont
    (fun τ => (gravitationalFunneling_denom_pos τ hb).ne')

/-- The total energy `E_total(τ, α, β) = Q_t(τ, α) + G_f(τ, β)` is
    continuous as a function of `τ`. -/
theorem totalEnergy_continuous (alpha : ℝ) {beta : ℝ} (hb : 0 < beta) :
    Continuous (fun τ => totalEnergy τ alpha beta) :=
  (quantumTunneling_continuous alpha).add (gravitationalFunneling_continuous hb)

/-! ## Duality balance: E_total achieves the value 1 -/

/-- **Duality balance theorem** (Intermediate Value Theorem):

    For any `α > 0`, `β > 0`, there exists `τ₀` with `0 ≤ τ₀` such that

      `E_total(τ₀, α, β) = 1`

    **Proof sketch**:
    - `E_total(0) = 2 > 1` (proved in `EnergyDynamics`).
    - At `τ₁ = Real.log 4 / α + 2 / Real.sqrt β`:
        - `Q_t(τ₁) ≤ exp(−log 4) = 1/4`
        - `G_f(τ₁) ≤ 1/(1 + 4) = 1/5` (since `β·τ₁² ≥ 4`)
        - `E_total(τ₁) ≤ 9/20 < 1`
    - By the intermediate value theorem on the continuous function `E_total`,
      there exists `τ₀ ∈ [0, τ₁]` with `E_total(τ₀) = 1`.

    **Physical interpretation**: "1" is the duality balance point where quantum
    tunneling and gravitational funneling are in equilibrium.  The Python
    simulation observes `mean_energy ≈ 1` precisely because the trajectory
    spends symmetric time above and below this balance. -/
theorem totalEnergy_exists_eq_one
    {alpha : ℝ} (ha : 0 < alpha) {beta : ℝ} (hb : 0 < beta) :
    ∃ τ₀ : ℝ, 0 ≤ τ₀ ∧ totalEnergy τ₀ alpha beta = 1 := by
  have hsqrt_pos : 0 < Real.sqrt beta := Real.sqrt_pos.mpr hb
  -- ── Step 1: find τ₁ > 0 with E_total(τ₁) ≤ 1 ──────────────────────────────
  -- Take τ₁ = log 4 / α + 2 / √β.  At this point:
  --   Q_t(τ₁) ≤ exp(−log 4) = 1/4   (since α·τ₁ ≥ log 4)
  --   G_f(τ₁) ≤ 1/5                 (since β·τ₁² ≥ 4)
  --   E_total(τ₁) ≤ 1/4 + 1/5 = 9/20 ≤ 1
  have h_exists : ∃ τ₁ : ℝ, 0 < τ₁ ∧ totalEnergy τ₁ alpha beta ≤ 1 := by
    refine ⟨Real.log 4 / alpha + 2 / Real.sqrt beta, by positivity, ?_⟩
    set τ₁ := Real.log 4 / alpha + 2 / Real.sqrt beta with hτ₁_def
    have hτ₁_pos : 0 < τ₁ := by positivity
    -- Bound Q_t(τ₁) ≤ 1/4
    have hqt_le : quantumTunneling τ₁ alpha ≤ 1 / 4 := by
      unfold quantumTunneling
      rw [abs_of_pos hτ₁_pos,
          show (1 : ℝ) / 4 = Real.exp (-Real.log 4) by
            rw [Real.exp_neg, Real.exp_log (by norm_num : (0 : ℝ) < 4)]; norm_num]
      apply Real.exp_le_exp.mpr
      -- Need: -alpha * τ₁ ≤ -Real.log 4, i.e., Real.log 4 ≤ alpha * τ₁
      suffices h : Real.log 4 ≤ alpha * τ₁ by linarith
      rw [hτ₁_def, mul_add]
      -- alpha * (Real.log 4 / alpha) = Real.log 4 (cancel alpha ≠ 0)
      have hlog4_eq : alpha * (Real.log 4 / alpha) = Real.log 4 := by
        field_simp [ne_of_gt ha]
      linarith [hlog4_eq,
                mul_nonneg ha.le (div_nonneg (by norm_num : (0 : ℝ) ≤ 2) hsqrt_pos.le)]
    -- Bound G_f(τ₁) ≤ 1/5
    have hgf_le : gravitationalFunneling τ₁ beta ≤ 1 / 5 := by
      -- First establish β·τ₁² ≥ 4
      have htau_ge : 2 / Real.sqrt beta ≤ τ₁ := by
        simp only [hτ₁_def]
        linarith [div_nonneg (Real.log_pos (by norm_num : (1 : ℝ) < 4)).le ha.le]
      have hsq_bound : 4 ≤ beta * τ₁ ^ 2 := by
        have h1 : (2 / Real.sqrt beta) ^ 2 = 4 / beta := by
          rw [div_pow, Real.sq_sqrt hb.le]; ring
        have h2 : beta * (4 / beta) = 4 := by field_simp
        calc (4 : ℝ)
            = beta * (4 / beta)                     := h2.symm
          _ = beta * (2 / Real.sqrt beta) ^ 2        := by rw [← h1]
          _ ≤ beta * τ₁ ^ 2                          :=
                mul_le_mul_of_nonneg_left
                  (pow_le_pow_left (by positivity) htau_ge 2) hb.le
      -- Now derive G_f(τ₁) ≤ 1/5
      have hdenom_pos : (0 : ℝ) < 1 + beta * τ₁ ^ 2 :=
        gravitationalFunneling_denom_pos τ₁ hb
      unfold gravitationalFunneling
      rw [div_le_div_iff hdenom_pos (by norm_num : (0 : ℝ) < 5)]
      linarith
    -- Combine the two bounds
    unfold totalEnergy
    linarith
  -- ── Step 2: apply IVT on [0, τ₁] ────────────────────────────────────────────
  obtain ⟨τ₁, hτ₁_pos, hτ₁_le⟩ := h_exists
  have hcont : ContinuousOn (fun τ => totalEnergy τ alpha beta) (Set.Icc 0 τ₁) :=
    (totalEnergy_continuous alpha hb).continuousOn
  -- f = const 1, g = E_total: f(0) ≤ g(0) and g(τ₁) ≤ f(τ₁)
  obtain ⟨τ₀, hτ₀_mem, hτ₀_eq⟩ :=
    isPreconnected_Icc.intermediate_value₂
      (Set.left_mem_Icc.mpr hτ₁_pos.le)
      (Set.right_mem_Icc.mpr le_rfl)
      continuousOn_const
      hcont
      (by linarith [totalEnergy_at_zero alpha beta])
      (by linarith)
  exact ⟨τ₀, (Set.mem_Icc.mp hτ₀_mem).1, hτ₀_eq.symm⟩

end QDTBlackHole
