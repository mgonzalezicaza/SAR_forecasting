# India Poverty Forecasting Model — Technical Reference
### Methods, Assumptions, and Identification for Economists

**Project:** SAR Forecasting — World Bank ESAPV  
**Covers:** `dofiles/tool/`, `dofiles/model/india/`, `dofiles/results/`  
**Last updated:** May 2026

---

## Overview and Conceptual Framework

This model is a **top-down sequential microsimulation**. The core idea is to impose macro-level moment conditions on a micro distribution, year by year, while preserving as much of the observed cross-sectional heterogeneity as possible.

The approach sits between two poles:
- **Purely macro models** (e.g., CGE): internally consistent, but welfare is computed for a representative agent or aggregate household group — losing distributional information.
- **Structural micro models** (e.g., dynamic discrete choice): distributional, but computationally intensive, require strong behavioral assumptions, and cannot easily be anchored to official macro forecasts.

The microsimulation approach trades off internal behavioral consistency for tractability and anchoring. It is best understood as a **distributional accounting exercise**: given that the macro aggregates evolve as projected, how does the income/consumption distribution shift?

### Fundamental Identifying Assumption

> The cross-sectional structure of the 2023 PLFS — the joint distribution of individual characteristics, labor market status, income, and consumption — is a valid representation of the **structural** micro-level heterogeneity that will persist through the forecast horizon (2024–2028), conditional on the macro aggregates.

This means:
- The *shape* of the within-group distributions is assumed stable.
- Only the *location* (means, shares) shifts in response to macro shocks.
- No structural breaks in occupational sorting, wage-setting, or saving behavior are modeled.

---

## STAGE 1 — TOOL: Input Preparation and Elasticity Estimation

**Folder:** `dofiles/tool/`  
**Output:** `input_MASTER.xlsx`

---

### Step 1.1 — Labor Market Statistics from Household Surveys (`01_inputs_hhss.do` / `01_inputs_hhss_IND.do`)

**What is computed:**  
For each country-year, the following weighted moments are extracted from the microdata:

- Employment headcounts and shares by 6 cells: {agriculture, industry, services} x {skilled, unskilled}
- Population-weighted mean wages per cell, converted to 2021 PPP USD per month
- Labor force participation rate (LFPR), unemployment rate (UR), employment rate

For India, the source is a compiled PLFS panel (2017–2023), not SARMD, due to SARMD coverage gaps.

**Skill definition:**  
Workers are classified as *skilled* if they have completed secondary education or above. This is a binary split applied uniformly across all SAR countries.

**Explicit assumptions:**
- The PLFS sampling weights accurately represent the Indian working-age population.
- The secondary education threshold is a valid proxy for the skilled/unskilled wage premium discontinuity.
- PPP conversion using 2021 ICP rates adequately deflates nominal local wages to a comparable real basis.

**Implicit assumptions:**
- Sectoral classification from ISIC/NIC codes is consistent across survey waves.
- There is no systematic non-response bias correlated with income or sector.
- The PLFS wage measure (usual status + current weekly status) captures permanent income with acceptable noise.

---

### Step 1.2 — Labor Force Survey Statistics (`02_inputs_lfs.do`)

Uses `wage_nc` (net cash wages) from SARLAB. This measure excludes in-kind income, which may be substantial in agriculture and informal sectors.

**Implicit assumptions:**
- Non-cash compensation is either negligible or proportional across groups (so that relative wages are unaffected).
- SARLAB and PLFS wage concepts are sufficiently comparable after PPP conversion.

---

### Step 1.3 — Microsimulation Output Statistics (`03_inputs_microsims.do`)

Extracts the same moments from past simulation vintages to allow cross-vintage consistency checks. These inputs are informational only — they do not feed into the current simulation parameters directly.

---

### Step 1.4 — Merge and Export (`04_merge_inputs_labor.do`)

Stacks all three sources. When duplicates exist for the same country-year-source, the code flags but does not automatically resolve conflicts — the analyst must review.

**Implicit assumption:**  
Analyst judgment governs source priority when survey sources conflict for the same country-year. There is no formal weighting or reconciliation rule.

---

### Step 1.5 — Elasticity Estimation (`05_elasticities.do` / `05_elasticities_IND.do`)

This is the most econometrically consequential step. Elasticities translate GDP growth projections into employment and wage growth by sector-skill cell.

#### What is estimated

For each country c, year t, and sector-skill cell k, the basic growth rate of employment (or wages) relative to GDP is:

    eps_{k,t} = Delta ln L_{k,t} / Delta ln Y_{k,t}

where L_{k,t} is employment in cell k and Y_{k,t} is sector GDP.

#### Seven estimation variants

| Variant | Estimator | Notes |
|---|---|---|
| **Simple average** | Mean of year-on-year elasticities | Sensitive to outliers |
| **Trimmed average** | Drops eps outside [p1, p99] | Reduces influence of crisis years |
| **Imputed average** | Replaces outliers with period median | Preserves N while downweighting extremes |
| **OLS** | Delta ln L = alpha + eps * Delta ln Y + u | Assumes linearity; OLS is BLUE under Gauss-Markov |
| **Median regression** | Same spec, LAD estimator | More robust to heavy-tailed errors |
| **OLS + aggregate GDP** | Adds economy-wide GDP as control | Controls for aggregate demand shocks |
| **OLS + interaction** | Adds interaction with unskilled share | Tests heterogeneity by skill intensity |

#### Critical identification assumptions

1. **Exogeneity of sector GDP:** Cov(Delta ln Y_{k,t}, u_t) = 0. This fails if demand shocks simultaneously drive both GDP and employment — no IV strategy is employed. The model relies on the assumption that sectoral GDP is supply-driven or externally determined at annual frequency.

2. **Stability of the elasticity over the forecast horizon:** The estimated eps_k from 2017–2023 is assumed to hold through 2028. This rules out structural change in labor intensity, technological shifts (e.g., automation), or changes in informality rates.

3. **Linearity:** The log-log specification imposes a constant elasticity. It rules out threshold effects and diminishing returns.

4. **No reverse causality from labor markets to GDP:** At annual frequency with India's data limitations, this is untestable. For India (`05_elasticities_IND.do`), the median regression variant is dropped because there are only 6 observations (2017–2023).

#### How elasticities feed the model

The analyst manually selects one variant per cell and enters it into `input_MASTER.xlsx`. The model uses these to compute target employment shares and target wage growth rates per cell:

    Delta ln L_{k,t}^target = eps_k^emp * Delta ln Y_{k,t}^projected
    Delta ln w_{k,t}^target = eps_k^wage * Delta ln (Y_{k,t}/L_{k,t})^projected

**Implicit assumption:** The elasticity of wages to sector productivity (output per worker) is the relevant wage-setting mechanism — consistent with a competitive labor market or efficient bargaining, but inconsistent with monopsony, rigid nominal wages, or search frictions.

---

### Step 1.6 — Macro Projections (`06_inputs_macro.do`)

Downloads from MFM:
- Real GDP by sector (agriculture, industry, services), constant USD
- Real private consumption aggregate
- WDI population by age group (total, 15+, 65+)

**Explicit assumption:** MFM projections represent the central scenario. No uncertainty bands are propagated through the simulation. Alternative scenarios require re-running the full pipeline with different input matrices.

**Implicit assumption:** The sectoral GDP decomposition from national accounts maps cleanly onto the three-sector employment classification in the survey. In practice, India's service sector is heterogeneous (IT exports vs. informal retail) and this aggregation obscures important within-sector heterogeneity.

---

### Step 1.7 — Remittances (`07_exports_inflows.do`)

Fetches total remittance inflows (USD millions) and CPIs from the MFMod portal.

**Implicit assumption:** Aggregate national remittance inflow growth translates proportionally (or via a simple allocation rule) to individual household-level remittance income. The distribution of new remittance recipients is either held fixed (proportional scaling) or randomized (stochastic reallocation) — see Step 2.11.

---

## STAGE 2 — MODEL: Sequential Microsimulation

**Folder:** `dofiles/model/india/`  
**Baseline:** PLFS 2023  
**Horizon:** 2024–2028, iterated annually

The simulation imposes 6 layers of moment conditions sequentially. Each layer updates the microdata to satisfy a different macro aggregate. The ordering matters: each step takes the output of the previous step as its input.

**Global partial-equilibrium assumption:** All steps are partial equilibrium. There are no feedback effects from micro-level changes to macro aggregates. Prices, interest rates, and the wage schedule are taken as exogenous inputs. No agent optimization is re-solved after the shock.

---

### Step 2.0 — Parameter Loading (`01_parameters.do`)

All macro growth matrices are read from `input_MASTER.xlsx` into Stata matrices:

| Matrix | Dimension | Content |
|---|---|---|
| `growth_labor_income` | 6 x T | Cumulative wage growth factor per sector-skill cell |
| `growth_macro_data` | 3 x T | GDP growth by sector |
| `growth_labor` | 5 x T | LFPR, UR, 3 sectoral employment shares |
| `growth_nlabor` | K x T | Growth factors for K non-labor income components |
| `growth_pop_wdi` | 1 x T | Target total population |

All growth factors are expressed as **cumulative multipliers relative to the 2023 baseline** (i.e., a value of 1.05 means 5% above 2023 levels, not 5% growth from the prior year). This is important: the model always applies shocks relative to the 2023 micro baseline, preventing the compounding of simulation errors across years.

---

### Step 2.1 — Variable Construction (`02_variables.do`)

**Key variable definitions:**

- **Sector:** Based on NIC 2-digit codes mapped to 3 broad sectors. Workers with multiple jobs are assigned to their primary job's sector.
- **Skill:** Secondary education completion (edu >= 2 in harmonized education variable).
- **Labor income:** wage_sal (salaried) + wage_self (self-employment net income). Self-employment income is treated as pure labor income, which conflates returns to labor and returns to capital for own-account workers.
- **Non-labor income components:** PDS food subsidy, other govt. transfers, domestic remittances, international remittances, pensions, capital income, imputed rent, other income.
- **PPP conversion:** Nominal INR deflated by India CPI to 2021 prices, then converted at 2021 PPP exchange rate.

**Implicit assumptions:**
- Self-employment income is pure labor income (no capital returns). This overstates labor income of farm owners and business owners, and understates their capital income.
- The CPI appropriately deflates welfare across rural/urban and income strata. Spatial price variation within India is not modeled.

---

### Step 2.2 — Occupation Choice Model (`03_occupation.do`)

#### Specification

A **multinomial logit (MNL)** model is estimated with J = 8 outcomes:

    j in {inactive, unemployed, agr_unskilled, agr_skilled, ind_unskilled, ind_skilled, svc_unskilled, svc_skilled}

The probability of outcome j for individual i:

    P(y_i = j) = exp(x_i' * beta_j) / sum_{l=0}^{7} exp(x_i' * beta_l)

with inactive as the reference category (beta_0 = 0).

Covariates x_i: age, age-squared, gender, education dummies, household size, rural indicator, state fixed effects, household head indicator.

#### Latent utility residuals

For each individual and outcome j, the latent utility is:

    V_ij = x_i' * beta_j + epsilon_ij

The model recovers the unexplained part, approximated by:

    U_ij = ln P(y_i = j | x_i) - ln P_hat(y_i = j)

i.e., the individual's log-odds deviation from the population average in their cell. This residual, stored as `U0`–`U7`, captures unobserved heterogeneity in attachment to each labor market state.

#### Role in subsequent steps

Residuals U_ij serve as **sorting scores**. When the model needs to move delta_N workers out of state j, it removes those with the lowest U_ij — individuals who were marginally in that state. This is the discrete-choice analog of sorting along the margin of indifference.

#### Critical assumptions

1. **IIA (Independence of Irrelevant Alternatives):** MNL assumes epsilon_ij ~ iid Gumbel(0,1), which implies IIA. The relative odds of choosing agriculture over services is independent of whether the industrial option exists. This is violated if sectors are substitutes. A nested or mixed logit would be more appropriate but is not used.

2. **Stable preferences:** Coefficients beta_j estimated on 2023 data are applied unchanged during reallocation in 2024–2028. This assumes no change in the structural parameters of occupational sorting — no change in the education premium, no geographic shifts in job availability.

3. **Conditional on observables, the residuals are portable:** When a worker is assigned to a new sector, their residual from the old sector is used as a ranking device. The residual is treated as a permanent individual-specific unobservable, not as a sector-match-specific shock.

4. **The MNL adequately fits the data:** Poor in-sample fit would mean residuals are noisy proxies for true attachment, degrading the quality of the sorting algorithm.

---

### Step 2.3 — Wage Regressions (`04_labor_income.do`)

#### Specification

Three separate OLS regressions, one per broad sector s in {agr, ind, svc}:

    ln w_is = x_i' * beta_s + epsilon_is,   epsilon_is ~ N(0, sigma_s^2)

Covariates: age, age-squared, education dummies, gender, rural indicator, employment type (salaried vs. self-employed), state fixed effects.

Saved objects: beta_hat_s and sigma_hat_s = RMSE of the regression.

#### Use in simulation

When individual i moves to sector s':

    ln w_hat_is' = x_i' * beta_hat_s' + epsilon_tilde_is',   epsilon_tilde ~ N(0, sigma_hat_s'^2)

The stochastic draw is independent across individuals and simulation runs. **No random seed is set by default — results are not fully replicable across runs without fixing the seed.**

#### Critical assumptions

1. **Log-normality of wages:** OLS on log wages assumes multiplicative errors. In India, wages are heavily right-skewed and may have mass at zero. The log-normal assumption may understate variance at the bottom.

2. **Conditional independence of sector assignment and the error term:** E[epsilon_is | x_i, sector=s] = 0. This fails under selection into sectors — workers who sort into high-wage sectors may do so because of unobservables correlated with epsilon_is (ability, social networks). No Heckman-type selection correction is applied.

3. **Wage portability:** When a worker moves from sector s to s', their wage in s' is predicted as if they always worked in s'. This assumes full portability of human capital — no sector-specific capital depreciation, no transition costs, no learning period.

4. **Constant returns to observable characteristics:** beta_hat_s is held fixed during the forecast. This rules out changes in the education premium, wage convergence across regions, or labor market reform effects.

5. **Independence of the stochastic draw from individual history:** The noise term is iid across individuals. Workers with strong unobservables in one sector likely have strong unobservables in others (correlated productivity). This will lead to regression-to-the-mean in simulated wages for movers.

---

### Step 2.4 — Population Reweighting (`05_population.do`)

**Target:** sum_i w_i^new = N_t^WDI, where N_t^WDI is the WDI population projection for year t.

#### Method A — Entropy balancing

Solves:

    min_{w_i^new} sum_i w_i^new * ln(w_i^new / w_i^0)

subject to:
    sum_i w_i^new * c_i = m_t   (demographic cell constraints)
    sum_i w_i^new = N_t
    w_i^new >= 0

where c_i are age-gender cell indicators and m_t is the target cell population from WDI. The KL-divergence objective minimizes distortion to the original weights while satisfying the demographic constraints.

#### Method B — Neutral scaling

    w_i^new = w_i^0 * (N_t^WDI / N_2023^survey)

Preserves the joint distribution exactly but does not correct for demographic composition changes.

#### Critical assumptions

- **Method A:** WDI demographic projections (age-gender marginals) are correct. Constraints only target age-gender cells — other characteristics are adjusted passively.
- **Both methods:** No new individuals with different characteristics from the 2023 sample enter the population. Population growth is accommodated by up-weighting existing observations, not by adding synthetic individuals. This matters if new entrants to India's labor force have systematically different characteristics from 2023 survey respondents.

---

### Step 2.5 — Labor Force Participation (`06_activity.do`)

**Target:** LFPR_t from `growth_labor` matrix.

**Mechanism:** Sort working-age individuals by U_i0 (latent utility residual for inactivity). The cutoff U* is determined by cumulative weighted sum:

    U* : sum_{i: U_i0 <= U*} w_i = N_t^active - N_2023^active

Individuals on the wrong side of the cutoff have their `active_s` indicator flipped.

#### Critical assumptions

1. **Rank-preserving reallocation:** The ordering by inactivity residual is invariant to the macro shock. The model assumes the 1 million people entering the labor force are those with lowest attachment to inactivity in 2023 — ignoring general equilibrium changes in wage offers.

2. **Separability:** The decision to participate is modeled separately from unemployment and sector allocation. In reality, these are jointly determined.

3. **Exogenous LFPR target:** The target LFPR is taken from the macro input without modeling why it changes. If the change is partly driven by demographic shifts already captured in Step 2.4, there may be double-counting.

4. **No gender disaggregation of LFPR target:** India's male and female LFPRs trend very differently. The model uses a single national aggregate unless the growth_labor matrix is disaggregated.

---

### Step 2.6 — Unemployment Rate (`07_unemployment.do`)

**Target:** UR_t from `growth_labor` matrix.

Identical mechanism to Step 2.5, applied within the active population, using U_i1 (unemployment residual) as the sorting score.

#### Critical assumptions

All assumptions from Step 2.5 carry over. Additionally:

- **Unemployment is non-selective conditional on U_i1:** Workers who become unemployed are not systematically different from the employed after controlling for observed and unobserved determinants in the MNL. In practice, formal-sector workers are substantially more insulated from unemployment risk.
- **A single unemployment rate is the binding constraint.** The model does not separately model formal/informal employment or distinguish voluntary from involuntary unemployment.

---

### Step 2.7 — Sectoral Employment Reallocation (`08_struct_emp.do`)

**Targets:** Employment shares {sh_{k,t}} for k=1..6 from `growth_labor`, where sum_k sh_{k,t} = 1.

**Target headcount per cell:** N_{k,t}^target = sh_{k,t} * N_t^employed

#### Reallocation algorithm

**Step A — Identify surplus and deficit cells:**

    Delta_N_k = N_{k,t}^target - N_{k,2023}^employed

Cells with Delta_N_k < 0 are shrinking; cells with Delta_N_k > 0 are growing.

**Step B — Release workers from shrinking cells:**  
Within each shrinking cell k, rank workers by U_ik. Workers with the lowest U_ik are displaced first and enter a pool.

**Step C — Fill vacancies in growing cells:**  
Priority queue for filling vacancies:
1. Displaced workers from shrinking cells
2. Newly unemployed individuals (from Step 2.6)
3. Newly activated individuals (from Step 2.5)
4. Proportional allocation of any remainder

Within each priority tier, assignment is by U_ij for the target cell j (highest attachment first).

**Step D — Intra-sector skill split:**  
Within each broad sector, update the skilled/unskilled ratio to match the target, re-sorting workers by skill-cell residuals.

#### Critical assumptions

1. **Frictionless reallocation:** Workers can move between any pair of sectors without search costs, geographic barriers, or retraining requirements. A steel worker in Punjab can become a services worker in Mumbai within the simulation year.

2. **The priority queue mimics realistic job-finding behavior:** Displaced employed workers find jobs before the newly unemployed, who in turn find jobs before new entrants. This is a reasonable stylization but is not derived from a search model.

3. **No congestion effects:** As workers enter growing sectors, wages in those sectors are not driven down. Wages are updated independently (Step 2.9), so the model does not enforce the equilibrium condition that wages clear markets at new employment levels.

4. **Skill target feasibility:** The intra-sector skill split target may exceed what the observed education distribution can support. No feasibility constraint is enforced.

---

### Step 2.8 — Wage Assignment for Sector Movers (`09_asign_labor_income.do`)

**Stayers** (same sector as 2023): Retain observed 2023 wage. Their wage will be scaled in Step 2.9.

**Movers** (changed sector): Receive an imputed wage:

    ln w_hat_i = x_i' * beta_hat_s' + epsilon_tilde_i,   epsilon_tilde ~ N(0, sigma_hat_s'^2)

**Newly unemployed/inactive:** `lai_m_s` set to missing.

#### Critical assumptions (additional to Step 2.3)

1. **The OLS-predicted wage equals the market wage in the new sector:** Workers are paid exactly their marginal product given characteristics. No bargaining, no job-specific rents, no seniority premiums.

2. **The stochastic draw is independent of the worker's actual unobservable ability:** This causes regression-to-the-mean. The variance of simulated wages for movers will be lower than the variance of observed wages for natives of the destination sector.

---

### Step 2.9 — Wage Scaling to Macro Targets (`10_income_rel_new_no_rescaling.do`)

**Active variant for India:** `10_income_rel_new_no_rescaling.do`

After wage assignment, the mean wage in each cell k is w_bar_{k,t}^sim. The macro target is:

    w_bar_{k,t}^target = w_bar_{k,2023} * g_{k,t}^wage

The calibration factor:

    lambda_{k,t} = w_bar_{k,t}^target / w_bar_{k,t}^sim

All wages in cell k are scaled: w_i^scaled = w_i^sim * lambda_{k,t}.

This is a **proportional (multiplicative) scaling** — it shifts the mean without affecting within-cell variance or rank order.

#### The three variants and their differences

| File | Extra rescaling | Target |
|---|---|---|
| `10_income_rel.do` | Yes | Micro wage growth AND GDP total |
| `10_income_rel_new.do` | Yes | Micro wage growth + GDP consistency check |
| `10_income_rel_new_no_rescaling.do` | No | Micro wage growth targets only |

For India, GDP-level rescaling of labor income is **skipped** (`$inc_re_scale = "no"`). The income-to-consumption bridge (Steps 2.13–2.14) also does **not** apply a macro private consumption rescaling (`$cons_re_scale = "no"`). India's simulated consumption distribution is therefore anchored purely by the micro-level wage growth targets and the nearest-neighbor matched income-to-consumption ratios — with no national-accounts consistency constraint imposed. This is a deliberate methodological choice given the well-documented India survey-to-national-accounts consumption gap.

#### Critical assumptions

1. **Proportional scaling preserves the within-cell distribution:** All individuals in a cell receive the same factor. Relative wages within a cell are fixed — the model cannot simulate skill-biased technical change within sectors.

2. **The scaling factors are coherent across cells:** Each cell is scaled independently. There is no constraint ensuring the total simulated wage bill as a share of GDP is consistent with the macro labor share. This inconsistency is resolved later via consumption rescaling (Step 2.14).

---

### Step 2.10 — Total Labor Income (`11_total_labor_income.do`)

    tot_lai_is = lai_m_s_i + lai_sec_s_i

Secondary job income (`lai_sec_s`) grows at the same rate as primary income for the individual's sector. This assumes the secondary job is in the same sector as the primary job, or that secondary income growth is proportional to primary income growth regardless of sector.

---

### Step 2.11 — Non-Labor Income Projection (`12_assign_nlai.do` and sub-files)

#### Pensions and capital income

Simple proportional growth:

    nlai_{ih,t}^component = nlai_{ih,2023}^component * g_t^component

**Assumption:** The growth rate of aggregate pensions/capital income translates proportionally to each household's level. This is a strong homogeneity assumption — it implies pension income grows at the same rate for a widow in rural Rajasthan as for a retired government official in Delhi.

#### PDS food subsidy and other government schemes (`social_programs.do`)

Hard-coded annual per-capita values by scenario year based on government budget documents:

    nlai_{ih,t}^PDS = fixed_INR_value_t  (if household h receives PDS in 2023)
                    = 0                   (otherwise)

PDS participation is held fixed at 2023 levels — no new households enter or exit the program.

**Assumption:** PDS coverage is fully determined by 2023 status. In reality, coverage may expand with ONORC portability or contract with policy reform.

#### Domestic remittances (`12_assign_dom_rem_0.do` / `_1.do`)

Two variants:
- **Method 0 (neutral scaling):** rem_{ih,t} = rem_{ih,2023} * g_t^dom_rem. Extensive margin is fixed.
- **Method 1 (random reallocation):** Total aggregate remittance envelope is fixed; recipient households are randomly redrawn via a probit model on observable characteristics. Captures extensive margin but introduces simulation noise.

#### International remittances (`12_assign_int_rem_0.do` / `_1.do`)

Same two methods. Growth rate anchored to aggregate national remittance inflows from Step 1.7.

**Implicit assumption:** Country-level remittance inflow growth (from the balance of payments) maps to household-level growth at the same rate. This ignores changes in the number of migrants, informal channel routing, or household-level recipient dynamics.

---

### Step 2.12 — Household Income Aggregation (`13_household_income.do`)

    h_inc_s_h = sum_{i in h} tot_lai_s_i + h_nlai_s_h
    ipcf_ppp_s_h = h_inc_s_h / n_h

where n_h is household size, held fixed at 2023 levels.

**Critical assumption: Household composition is fixed.** The model does not simulate household formation, dissolution, fertility, or migration between households. A household with 4 members in 2023 has 4 members in 2028. Over a 5-year horizon, household fission (joint families splitting) is an important channel of welfare change in India and is entirely missed.

---

### Step 2.13 — Income-to-Consumption Ratio Matching (`15_income_to_consumption.do`)

The PLFS does not directly measure consumption for all households. An auxiliary consumption measure (from the HCES or a matched dataset) is used to compute the income-to-consumption ratio r_h = c_h / y_h for each household in the 2023 baseline.

**Nearest-neighbor matching** on:
- Per capita income quintile (5 bins)
- Sector of household head
- Education of household head
- Urban/rural indicator

For each household h, nearest neighbor h' is found within matching cells. The matched ratio r_{h'} = c_{h'} / y_{h'} is applied to simulated income:

    c_hat_{h,t} = r_{h'} * ipcf_ppp_s_{h,t}

#### Critical assumptions

1. **The income-to-consumption mapping is stable:** The ratio of consumption to income for a given household type is assumed not to change as incomes change. This is inconsistent with Engel's law (consumption share of income rises with income) and with life-cycle saving behavior.

2. **The matching is within cells:** Households matched to a different income quintile or sector could receive implausible ratios. Quality of matching degrades when simulated incomes shift households into new cells not occupied in 2023.

3. **No new income-to-consumption ratios are generated:** The set of possible ratios is bounded by what was observed in 2023. Extreme welfare changes may push households into regions where no good match exists.

4. **Cross-sectional matching substitutes for longitudinal tracking:** This is not a panel. The matching is a cross-sectional imputation that preserves the distribution of ratios but does not model the persistence of individual-level consumption-income gaps.

---

### Step 2.14 — Consumption Computation (`16_new_consumption.do`)

**Step A — Base computation:**

    welfare_s_{h,t} = pc_inc_s_{h,t} / r_{h'}

where `r_{h'}` is the income-to-consumption ratio from the nearest-neighbor donor matched in Step 2.13. For households where `r ≤ 0` (edge case), a fallback is applied:

    welfare_s_{h,t} = welfare_base_{h} * (1 + G_t^priv_cons)

**Step B — Macro rescaling (optional, `$cons_re_scale`):**

For India, `$cons_re_scale = "no"` — **this step is not executed**. Simulated consumption is determined entirely by the income-to-consumption ratio from Step 2.13, with no national-accounts anchor applied. The option exists for other country runs where macro consistency is required:

> If activated: population-weighted mean `c_bar_t^sim` is computed; a global rescaling factor `mu_t = c_bar_t^macro / c_bar_t^sim` is applied uniformly, where `c_bar_t^macro = c_bar_2023^survey * G_t^priv_cons`.

#### Critical assumptions

1. **For India, no national accounts anchor is applied.** Simulated welfare levels are grounded purely in the microdata structure and the micro wage growth targets. This avoids the India survey-to-national-accounts consumption gap problem but means there is no external consistency check on the level of simulated consumption.

2. **The income-to-consumption ratio is treated as time-invariant conditional on matching cells.** If the aggregate savings rate changes (e.g., precautionary savings in a downturn scenario), the assumed ratios will be incorrect.

3. **The global rescaling factor (if active) is uniform across the distribution.** Every household's consumption is scaled by the same factor regardless of income level. This preserves the *relative* distribution but cannot simulate distributional changes in the savings rate.

4. **The income-to-consumption conversion ratio (Step 2.13) and the macro rescaling (Step 2.14) are applied sequentially and independently.** If the income-to-consumption ratios were themselves affected by the macroeconomic environment (e.g., households save more in response to uncertainty), this sequential independence would be incorrect.

---

### Step 2.15 — Output (`17_output.do`)

Saves `IND_YYYY.dta` with clean variable labels. Reports:
- Poverty headcounts at $3.00, $4.20, $8.30/day (2021 PPP)
- National headcount poverty rate
- Gini coefficient

**Note on Gini computation:** Given that within-cell wage dispersion is preserved (stayers) or imposed via regression noise (movers), and given that the macro rescaling is uniform, the simulated Gini will tend to be conservative — it will not fully capture distributional changes driven by between-cell shifts.

---

### Iteration Structure and Path Dependence

The model runs:

    for t in {2024, 2025, 2026, 2027, 2028}:
        baseline = IND_{t-1}.dta  (or PLFS_2023.dta for t=2024)
        apply growth factors cumulative from 2023
        save IND_{t}.dta

Growth factors in `input_MASTER.xlsx` are expressed as **cumulative multipliers from 2023**, not year-on-year rates. This means the simulation always anchors to the 2023 baseline, preventing compounding of simulation errors across years.

This design **prevents error accumulation** but sacrifices **path dependence**: workers who moved sectors in 2024 do not carry additional tenure or adjustment into 2025 beyond what the cumulative growth factor implies.

---

## STAGE 3 — RESULTS: Estimation and Reporting

**Folder:** `dofiles/results/`  
**Output:** `Results_IND.xlsm`

---

### Step 3.0 — Data Assembly (`01_data.do`)

Loads and stacks up to 6 years: actual survey years (from Datalibweb) and simulated years (from Stage 2 output). All welfare variables are harmonized to 2021 PPP USD per capita per month.

The `data` matrix flags each year as observed (type=1) or simulated (type=0). Statistical inference is only valid for observed years — simulated years are scenario projections, not estimates with confidence intervals.

**Implicit assumption:** Harmonization of observed survey data across years (different PLFS waves) introduces no systematic bias. In practice, changes in PLFS methodology (household listing procedures, visit patterns) between waves can affect comparability.

---

### Step 3.1 — Analytical Variable Construction (`02_variables.do`)

**Poverty measures:**

- **Headcount ratio P0:** P0 = (1/N) * sum_i 1(c_i < z) at z in {$3.00, $4.20, $8.30}/day (2021 PPP)
- **Poverty gap P1:** P1 = (1/N) * sum_i max((z - c_i)/z, 0)
- **Prosperity Gap:** PG = (1/N) * sum_i ln(28 / c_i), a log distance from $28/day for the full distribution
- **Gini:** Standard Lorenz-based computation with survey weights
- **Theil T:** T = (1/N) * sum_i (c_i / c_bar) * ln(c_i / c_bar)

The Theil index is more sensitive to income changes at the top of the distribution; the Gini is more sensitive to the middle.

---

### Step 3.2 — Static Poverty Profiles (`03_static_profiles.do`)

Cross-sectional weighted tabulations of ~40 indicators by poverty group and year. These are descriptive — no causal claims are made about the characteristics associated with poverty.

**Implicit assumption:** The conditional means of characteristics given poverty status are estimated consistently from the simulated microdata. Since the simulation does not rebalance characteristics within poverty groups (it only shifts income levels), the profiles are mechanically driven by which pre-2023 household types end up below the poverty line — not by genuine mobility of characteristics.

---

### Step 3.3 — Growth Incidence Curves (`04_gics.do`)

The cross-sectional GIC (Ravallion-Chen) is estimated as:

    g(p) = [Q_t(p) - Q_{t-1}(p)] / Q_{t-1}(p)

where Q_t(p) is the p-th quantile of the welfare distribution in year t, estimated from the weighted empirical CDF.

GICs are computed for national, urban, and rural distributions separately.

**Critical assumptions:**

1. **Anonymity:** The GIC compares quantiles across years, not the same individuals. It is a cross-sectional, not a panel GIC. It tells us how quantile positions fared, not whether individuals moved between quantiles.

2. **No sampling uncertainty is reported:** The GIC is presented as a point estimate. Confidence intervals (via bootstrap or delta method) are not computed — visual differences in GIC shape cannot be formally tested.

---

### Step 3.4 — Transition Matrices (`05_transition_matrix.do`)

Weighted transition matrices:

    T_{jk,t} = P(category_t = k | category_{t-1} = j)

where j, k in {extreme poor, moderate poor, vulnerable, non-poor}.

**Critical assumption: The simulation is a pseudo-panel.** Each survey observation is present in both years (same 2023 PLFS data underlying all simulation years) with updated welfare values. The transition is therefore **deterministic conditional on the simulation outcomes** — no individual-level stochastic shock to welfare beyond what is introduced in the wage imputation (Step 2.8) and remittance reallocation (Step 2.11) steps.

The transition matrix from this model understates true mobility because: no household composition changes are modeled; within-cell consumption changes are limited to uniform scaling; health shocks, idiosyncratic income shocks, and life-cycle transitions are absent.

---

### Step 3.5 — Dynamic Poverty Profiles (`06_dynamic_profiles.do`)

Four mutually exclusive groups per year:

    New poor_t:      poor_t = 1  AND  poor_{t-1} = 0
    Always poor_t:   poor_t = 1  AND  poor_{t-1} = 1
    New non-poor_t:  poor_t = 0  AND  poor_{t-1} = 1
    Always non-poor: poor_t = 0  AND  poor_{t-1} = 0

For each group, the same ~30 socioeconomic indicators as in the static profiles are computed. The "new poor" and "new non-poor" profiles are the main input for the MPO narrative.

**Implicit assumption:** The characteristics of households that cross the poverty line in the simulation are representative of those that would cross in reality. Since the simulation does not model all channels of poverty entry/exit (health shocks, divorce, disability, catastrophic spending), profiles are biased toward labor market and income growth channels.

---

### Step 3.6 — Population (`07_pop_wdi.do`)

Exports the MFM population series for India to anchor per-capita computations in the results workbook. Pure data-retrieval step.

---

## Summary of Key Assumptions by Category

### Data and Measurement

| Assumption | Where | Consequence of violation |
|---|---|---|
| PLFS sampling weights represent 2023 population | Throughout | Biased baseline poverty estimates |
| Self-employment income is pure labor income | `02_variables.do` | Labor/capital misclassification; sector-specific bias in agriculture |
| CPI adequately deflates across regions and groups | `02_variables.do` | Mismeasurement of real welfare for rural/poor households |
| Log-normality of wages | `04_labor_income.do` | Biased wage imputation for movers; underestimated lower-tail variance |
| PLFS consumption module is valid welfare measure | Throughout | Baseline poverty rates may not align with official NSO estimates |

### Labor Market Model

| Assumption | Where | Consequence of violation |
|---|---|---|
| IIA in multinomial logit | `03_occupation.do` | Incorrect reallocation of substitute-sector workers |
| No selection into sectors (OLS wage equation) | `04_labor_income.do` | Biased wage predictions for movers; likely overestimates of mover wages |
| Full sector portability of human capital | `09_asign_labor_income.do` | Overstates welfare gains from structural transformation |
| Rank-preserving reallocation | Steps 2.5–2.7 | Incorrect characterization of who transitions — biased mobility profiles |
| Separability of participation, unemployment, sector choice | Steps 2.5–2.7 | Ignores substitution effects between labor force states |
| Frictionless inter-sector movement within one year | `08_struct_emp.do` | Overstates speed of structural transformation |

### Macro-Micro Consistency

| Assumption | Where | Consequence of violation |
|---|---|---|
| Elasticities stable over 2024–2028 | `05_elasticities.do` | Incorrect employment/wage targets if structural change occurs |
| GDP-to-employment elasticities exogenous | `05_elasticities.do` | Biased elasticity estimates due to reverse causality |
| Proportional wage scaling within cells | `10_income_rel.do` | No within-cell distributional change; Gini understated if skill premium rises |
| Global uniform consumption rescaling | `16_new_consumption.do` | Distributional neutrality of macro anchor; overestimates poverty reduction if growth is top-concentrated |
| National accounts private consumption = household welfare | `16_new_consumption.do` | Systematic bias if SNA/survey ratio changes over forecast period |
| No general equilibrium feedback | Throughout | Ignores price effects, wage convergence, and behavioral responses to income changes |

### Household Structure and Non-Labor Income

| Assumption | Where | Consequence of violation |
|---|---|---|
| Household composition fixed 2023–2028 | `13_household_income.do` | Ignores household fission, fertility decline, aging effects on per-capita income |
| PDS coverage fixed at 2023 levels | `social_programs.do` | Misses program expansion/contraction |
| Proportional scaling of pensions/capital income | `12_assign_nlai.do` | Ignores distributional change within income source |
| Income-to-consumption ratio stable conditional on matching cells | `15_income_to_consumption.do` | Misses saving rate changes in response to income shocks (Engel effects) |
| Secondary job income grows at primary job sector rate | `11_total_labor_income.do` | May misallocate secondary income growth across sectors |

---

## Known Limitations and Suggested Extensions

1. **No within-cell distributional dynamics.** All within-cell changes are proportional scalings. Skill-biased technical change, rising urban wage dispersion, or polarization of the labor market cannot be captured without a richer within-cell wage model (e.g., a parametric distribution shift or quantile-specific scaling).

2. **No price heterogeneity.** A single national CPI is used. Spatial and commodity-specific price changes — e.g., food price inflation hitting rural poor disproportionately — are not modeled. A rural/urban CPI split would be a minimal improvement.

3. **No general equilibrium.** Prices, wages, and interest rates are exogenous. Behavioral responses to policy changes (labor supply elasticity, migration responses, savings responses) are not endogenized. A CGE-microsimulation link would address this at the cost of additional structural assumptions.

4. **Stochastic simulation not fully reproducible.** The random draws in `09_asign_labor_income.do` and `12_assign_dom/int_rem_1.do` are not seeded by default. Results vary across runs. Setting a seed and running Monte Carlo replicates would allow simulation uncertainty to be quantified.

5. **The transition matrix is a pseudo-panel artifact.** It does not reflect genuine individual mobility — it reflects which household types cross the poverty line under the simulation. Panel data (actual PLFS panels or matching rounds) would allow genuine transition estimation.

6. **No uncertainty quantification.** The model produces point estimates only. A Monte Carlo framework around the elasticity estimates, the stochastic wage draws, and the matching procedure would allow confidence intervals around poverty projections — essential for communicating forecast uncertainty to policy audiences.

7. **Informality not modeled as a margin of adjustment.** Workers are classified by sector and skill but not by formal/informal status. The `00_master_informality.do` and `05_elasticities_informality.do` files exist as a prototype but are not the active pipeline for India. Formal/informal transitions are a key channel in India's labor market, particularly during downturns.
