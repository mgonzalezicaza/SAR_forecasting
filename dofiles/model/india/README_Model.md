# India Microsimulation Model — Detailed README

**Project:** SAR Poverty Micro-simulations — India (IND)  
**Institution:** World Bank — ESAPV  
**Authors:** Sergio Olivieri & Kelly Y. Montoya  
**Last updated:** March 2025  

---

## Overview

This microsimulation model projects poverty and inequality in India from a base survey year (currently 2023) to a final forecast year (currently 2028). It does so by applying macroeconomic growth rates — from GDP, sectoral value-added, labor market projections, and population data — onto a micro-level household survey (PLFS). The model sequentially updates population weights, labor market status, labor incomes, non-labor incomes, transfers, and finally household consumption to produce distributional welfare outcomes.

The model is driven by an Excel input file and run entirely through Stata. All do-files are called sequentially from the master script.

---

## Execution Sequence

```
00_master.do
 ├── 01_parameters.do
 ├── 02_variables.do
 ├── 03_occupation.do
 ├── 04_labor_income.do
 ├── 05_population.do
 ├── 06_activity.do
 ├── 07_unemployment.do
 ├── 08_struct_emp.do
 ├── 09_asign_labor_income.do
 ├── 10_income_rel_new_no_rescaling.do  [or 10_income_rel.do / 10_income_rel_new.do]
 ├── 11_total_labor_income.do
 ├── 12_assign_nlai.do
 │    ├── social_programs.do
 │    ├── 12_assign_dom_rem_0.do  [or _1.do]
 │    └── 12_assign_int_rem_0.do  [or _1.do]
 ├── 13_household_income.do
 ├── 15_income_to_consumption.do
 ├── 16_new_consumption.do
 └── 17_output.do
```

> **Note:** `14_relative_prices.do` is currently commented out in `00_master.do` and not executed in the standard India run.

---

## Do-file Descriptions

---

### `00_master.do` — Master Control Script

**Objective:** Orchestrates the full model run. Sets all global options, loads input data, loads utility programs, and calls each do-file in sequence.

**Key Inputs:**
- `priv_path`: Root path to OneDrive working folder.
- `path`: Path to the India simulation folder (`SM2026/IND`).
- `thedo`: Path to the India model do-files directory.
- **Excel input file** (`Microsimulation_Inputs_IND_conflict.xlsm`): Contains all macro growth rates and scenario parameters (sheets: `input_setup`, `input_gdp`, `input_gdp2`, `input_labor`, `input_intrasectoral`, `input_nonlabor`, `input_pop_wdi`).
- **DLW CPI/PPP file** (via `dlw` command): `Final_CPI_PPP_to_be_used.dta` — provides `cpi2021` and `icp2021` for converting income to 2021 PPP dollars.
- **Survey microdata**: `IND_allyears_PLFS_V1_final_v01_M_cpi_microsim.dta` — imputed PLFS dataset filtered to base year (2023).

**Key Global Parameters Set:**
| Global | Description |
|---|---|
| `$sector_model` | `6` (6-sector model: agriculture/industry/services × skilled/unskilled) |
| `$inc_re_scale` | `"no"` — whether to rescale labor income using GDP |
| `$matching` | `"yes"` — activates nearest-neighbor matching for income-to-consumption ratio |
| `$standardization` | `"yes"` — standardizes variables before matching |
| `$rn_int_remitt` | `"no"` — neutral distribution for international remittances |
| `$rn_dom_remitt` | `"no"` — neutral distribution for domestic remittances |
| `$cons_re_scale` | `"yes"` — rescales final consumption to match private consumption growth |
| `$year` | `2023` — base year |
| `$final_year` | `2028` — last year to simulate |
| `$ppp` | `2021` — PPP vintage |
| `$country` | `"IND"` |

**Key Outputs:**
- Merged in-memory dataset combining survey microdata with CPI/PPP factors.
- Summary statistics printed: poverty headcounts at three lines, Gini coefficient (base and simulated).
- Running time displayed via `etime`.

---

### `01_parameters.do` — Model Parameter Loading

**Objective:** Reads all macro growth rate matrices from the Excel input file and stores them as Stata matrices. Selects the appropriate do-file for step 10 (income growth) based on the `$sector_model` and `$inc_re_scale` globals.

**Key Inputs:**
- Excel file (`$inputs`), sheets:
  - `input_setup`: scenario type (`national`/`inter`), model year, number of sectors, weight flag.
  - `input_gdp` / `input_gdp2`: sectoral GDP growth rates (3-sector or 6-sector).
  - `input_labor`: labor market growth rates (activity rate, unemployment rate, sectoral employment shares).
  - `input_intrasectoral`: within-sector skilled/unskilled ratios by sector.
  - `input_nonlabor`: growth rates for non-labor income components (remittances, pensions, capital).
  - `input_pop_wdi`: WDI total population target.

**Key Outputs (Stata matrices):**
| Matrix | Contents |
|---|---|
| `growth_labor_income` | Average labor income growth by sector (6 sectors + total) |
| `growth_macro_data` | Sectoral GDP growth rates (3 sectors + aggregate) |
| `growth_labor` | Activity rate growth, unemployment rate growth, employment shares by sector |
| `growth_intrasectoral` | Unskilled/skilled ratio change by broad sector |
| `growth_nlabor` | Growth rates for remittances, pensions, capital |
| `growth_pop_wdi` | Target total population (millions) |

**Key Global set:**
- `$do_income`: set to `"10_income_rel_new_no_rescaling"` (for 6-sector model, no rescaling).
- `$national`, `$tipo`, `$model`, `$m`, `$weights`: parsed from `input_setup`.

**Method:**
- A Mata function `st_shares()` is defined for computing running cumulative shares (used later for sector reallocation).

---

### `02_variables.do` — Variable Preparation

**Objective:** Cleans, recodes, and constructs all working variables needed for the model from the raw survey microdata.

**Key Inputs (from survey):**
- `welfare_s2s_ppp21`: welfare measure (renamed to `welfare_ppp`).
- `lstatus_year`, `lstatus`: labor status indicators.
- `ip_ppp`, `inp_ppp`, `ila_ppp`: primary labor income (PPP), secondary labor income (PPP), total labor income (PPP).
- `industrycat10_2`: 10-category industry variable (recoded to 3 sectors).
- `sector_3`: pre-coded 3-sector main activity variable.
- `empstat_year`, `empstat_2_year`: employment status (primary and secondary jobs).
- `educat5`, `educat7`: education level.
- `sk`, `unsk`: pre-coded skilled/unskilled indicators.
- `occup_year`: occupation code (ILO 1-digit).
- `age`, `male`, `urban`, `marital`, `relationharm`, `subnatid1`, `hsize`, `weight`, `hhid`, `pid`.
- Non-labor income variables: `capital`, `pensions`, `otherinla`, `remitt`, `int_remit`, `dom_remit`, `ns_remit`, `renta_imp`, plus `pds` and `oth_schemes` (social transfer programs).

**Key Outputs (variables created):**

*Employment/Labor Market:*
- `emplyd`: =1 if employed (primary job).
- `unemplyd`: =1 if unemployed.
- `active`: =1 if active in labor market (employed or unemployed).
- `skilled` / `unskilled`: skill classification (from pre-coded `sk` variable).
- `sect_main` (3 sectors), `sect_secu` (3 sectors), `sect_main6` (6 sectors), `sect_secu6` (6 sectors): sector codes for primary and secondary jobs.
- `salaried`, `self_emp`, `unpaid`: employment relationship dummies (primary).
- `salaried2`, `self_emp2`, `unpaid2`: employment relationship dummies (secondary).
- `labor_rel`, `labor_rel2`: employment relationship type (labeled).
- `occupation`: 8-category variable (0=inactive, 1=unemployed, 2–7=sector × skill).

*Income:*
- `conv_factor`: CPI × ICP conversion factor for PPP deflation.
- `lai_m`, `lai_s`: primary and secondary labor income (PPP), from `ip_ppp`/`inp_ppp`.
- `tot_lai`: total individual labor income (PPP).
- `h_lai`: household total labor income (PPP).
- `h_capital_ppp`, `h_pensions_ppp`, `h_otherinla_ppp`, `h_remitt_ppp`, `h_int_remit_ppp`, `h_dom_remit_ppp`, `h_ns_remit_ppp`, `h_renta_imp_ppp`, `h_transfers_ppp`: household non-labor income components (PPP).
- `h_inc`: total household income (PPP).
- `h_nlai`: total household non-labor income (PPP).
- `ipcf_ppp`: per capita household income (PPP).

*Regression Controls:*
- `educ_lev`: 4-level education variable (1=none/primary, 2=secondary, 3=tertiary, etc.).
- `married`: marital status dummy.
- `remitt_any`: =1 if household receives any remittances.
- `oth_pub`: =1 if another household member holds a public sector job.
- `depen`: dependency ratio (share of household aged <15 or >64).
- `ln_lai_m`: log of primary labor income.
- `sample_1`, `sample_2`: education-based sample splits (low/high educated).
- `skill_edu`: combined skill-education indicator.

---

### `03_occupation.do` — Occupation Choice Model (Multinomial Logit)

**Objective:** Estimates a multinomial logit (MNL) model of individual labor market status and sector-skill occupation. Saves residuals (latent utilities) that will be used to re-sort individuals when the labor market structure is updated.

**Inputs:**
- In-memory dataset with all variables from `02_variables.do`.
- Sample: working-age individuals with `sample == 1`.

**Model:**
- **Dependent variable:** `occupation` (8 categories: 0=inactive through 7=unskilled-services).
- **Base category:** minimum observed value of `occupation`.
- **Right-hand side variables:**
  - Age and age-squared (`c.age##c.age`).
  - Urban indicator.
  - Gender × household head × marital status interaction (`ib0.male#ibn.h_head#ib0.married`).
  - Gender × skill-education interaction (`ib0.male#ibn.skill_edu`).
  - `remitt_any`, `depen`, `oth_pub`, `atschool`.
  - Regional fixed effects (`ib1.region`).
- **Estimation:** Weighted (`[aw = weight]`), with `difficult` option for convergence.
- **Seed:** 23081985.

**Outputs:**
- Residual utility variables `U0` through `U7` (one per occupation category), generated by the custom `simchoiceres` program. These capture unexplained variation and are used later to rank individuals for reallocation.

---

### `04_labor_income.do` — Labor Income Regression (OLS by Sector)

**Objective:** Estimates OLS regressions of log labor income separately by broad sector (agriculture, industry, services). Stores coefficients and residual standard errors for income imputation of workers who change sectors.

**Inputs:**
- In-memory dataset, restricted to `sample == 1` and employed workers with valid labor income.
- Sectors: 3 broad categories (`sect_main` = 1, 2, 3).

**Model:**
- **Dependent variable:** `ln_lai_m` (log primary labor income in PPP).
- **Right-hand side variables:**
  - Age and age-squared (`c.age##c.age`).
  - Urban indicator.
  - Gender × household head interaction (`ib0.male##ib0.h_head`).
  - Gender × skill-education interaction (`ib0.male#ibn.skill_edu`).
  - `salaried`, `public_job`, `skilled`.
  - Regional fixed effects (`ib1.region`).
- **Estimation:** Weighted (`[aw = weight]`), separately for each of the 3 sectors.

**Outputs (Stata objects):**
- `b_1`, `b_2`, `b_3`: coefficient vectors for agriculture, industry, and services respectively.
- `sigma_1`, `sigma_2`, `sigma_3`: root mean squared errors (RMSE) for each sector — used as stochastic residual standard deviations when predicting income for new workers.

---

### `05_population.do` — Population Growth

**Objective:** Adjusts survey sampling weights to reflect projected population growth, either through entropy balancing (re-weighting to match demographic targets) or a simpler neutral scaling.

**Inputs:**
- `weight`: original survey sampling weights.
- `growth_pop_wdi` matrix: WDI target total population (millions) for the simulation year.
- `vec_pop_grw1` matrix (loaded externally): population growth rates by gender × age-group cells.

**Method — Option 1: Re-weighting (`$weights == 1`):**
1. Creates 10 age-group × gender cells (`groupvar`) using indicator variables.
2. Computes baseline population totals by cell.
3. Scales cell totals by the provided growth vector (`vec_pop_grw1`) to get targets.
4. Uses `maxentropy` (entropy balancing) at the household level, with household head as the anchor, to re-weight the survey such that the population structure matches the targets.
5. New weights stored as `fexp_s`.

**Method — Option 2: Neutral scaling (`$weights == 0`):**
1. Computes the ratio of the WDI target population to current weighted population.
2. Multiplies all weights uniformly: `fexp_s = weight * ratio_pop`.
3. Issues a warning if resulting population differs from WDI target by more than 10,000 people.

**Outputs:**
- `fexp_s`: simulated survey weights reflecting projected population.

---

### `06_activity.do` — Labor Force Participation

**Objective:** Simulates the change in the labor force participation (activity) rate by reallocating individuals between active and inactive status according to the target growth rate from the input file.

**Inputs:**
- `lf_samp`: baseline labor force participation indicator (active = 1).
- `growth_labor[1,1]`: target growth rate in the labor force participation rate.
- `fexp_s`: simulated weights from `05_population.do`.
- `U0`: latent utility residuals from the occupation model (used to rank individuals).

**Method:**
1. Computes the baseline activity rate.
2. Applies the growth rate to get the target share of active individuals.
3. Sorts individuals in descending order of current activity status, then by `U0` (latent utility), then by ID.
4. Cumulatively sums weighted population. Those in the top share (up to the target) are assigned `active_s = 1`; the rest are assigned `active_s = 0`.
5. Verifies the new rate matches the target (warns if difference > 1 pp).

**Outputs:**
- `active_s`: simulated labor force participation status.

---

### `07_unemployment.do` — Unemployment Rate

**Objective:** Simulates the change in the unemployment rate among the active population, reassigning employed/unemployed status to reach the target unemployment rate.

**Inputs:**
- `unemplyd`: baseline unemployment indicator.
- `lf_samp`: baseline active indicator.
- `active_s`: simulated active indicator from `06_activity.do`.
- `growth_labor[2,1]`: target growth rate for the unemployment rate.
- `U1`: latent utility residual for unemployment (from occupation model).

**Method:**
1. Computes baseline unemployment rate (among active).
2. Applies growth rate to get target unemployment share.
3. Among `active_s == 1`, sorts by current unemployment status (descending), then by `U1`, then ID.
4. Cumulatively assigns `unemplyd_s = 1` up to the target share; remainder = 0.
5. Derives `emplyd_s = 1 - unemplyd_s` among the active.
6. Verifies against target (warns if difference > 1 pp).

**Outputs:**
- `unemplyd_s`: simulated unemployment indicator.
- `emplyd_s`: simulated employment indicator.

---

### `08_struct_emp.do` — Employment Structure by Sector

**Objective:** Reallocates employed workers across sectors (and within-sector skill groups) to match target employment share growth rates from macro inputs. Public sector workers are held fixed in their sector.

**Inputs:**
- `sectorg` (`sect_main6`): 6-category sector × skill classification.
- `growth_labor[3..end,1]` → `growth_estru`: employment growth rates by sector.
- `growth_intrasectoral`: within-sector skilled/unskilled share change.
- `emplyd_s`, `active_s`, `unemplyd_s`: simulated labor market status.
- `U1` through `U7`: occupation-specific latent utility residuals.
- `public_job`: indicator for public sector employment (fixed).

**Method:**

**Step 1 — Setup:** Computes baseline and simulated sector employment totals. Calls Mata routine `st_repond_1` to compute target employment by sector.

**Step 2 — Shrinking sectors:** Processes sectors with negative employment growth first. Workers are removed from the sector in ascending utility order (`P_s` = `U_{s+1}`), preserving those with the highest "preference" for that sector.

**Step 3 — Growing sectors:** Workers are added to growing sectors in a priority order: (1) workers displaced from other sectors, (2) newly unemployed, (3) newly activated (previously inactive). This mirrors a realistic queue of who gets jobs first.

**Step 4 — Residual allocation:** Any remaining unassigned workers are distributed proportionally across sectors until all have been allocated.

**Step 5 — Occupation and sector variables:** Creates `sect_main6_s` (6-sector), `sect_main_s` (3-sector), and `occupation_s` (8-category occupation status).

**Step 6 — Intrasectoral division:** 
- In the 6-sector model (`$m != 1`): skilled/unskilled status is directly implied by the sector-skill cell (odd sectors = skilled, even = unskilled). Creates `unskilled_s`, `skilled_s`.
- In the 3-sector model: uses a random reallocation within each sector to hit the intrasectoral unskilled share target.

**Outputs:**
- `sect_main6_s`: simulated 6-cell sector-skill assignment.
- `sect_main_s`: simulated 3-sector assignment.
- `occupation_s`: full 8-category simulated occupation status.
- `unskilled_s`, `skilled_s`: simulated skill status.
- `sectorg_s`: simulated sector grouping variable.

---

### `09_asign_labor_income.do` — Assign Labor Income to Sector Movers

**Objective:** Imputes a counterfactual labor income for workers who changed their sector or occupation status, using OLS coefficients estimated in `04_labor_income.do`. Workers who stayed in the same sector keep their observed income.

**Inputs:**
- `occupation`, `occupation_s`: baseline and simulated occupation.
- `sect_main6_s`: simulated 6-sector assignment.
- `b_1`, `b_2`, `b_3`: OLS coefficient matrices from `04_labor_income.do`.
- `sigma_1`, `sigma_2`, `sigma_3`: RMSE scalars.
- `salaried`, `public_job`, `skilled`: employment characteristics.
- `aleat_ila`: uniform random variable (seed: 23081985) for stochastic income draws.

**Method:**

**Step 1 — Salaried status for movers:** Workers changing occupation are assigned the average salaried share of their new sector (by education level). This determines whether they become wage workers or self-employed.

**Step 2 — Public/private status for movers:** Similarly, workers changing sector are assigned a public vs. private job probability matching their new sector's distribution.

**Step 3 — Income imputation:** For workers moving to a new sector (from any previous status), a predicted log-income is computed via `mat score` using the OLS coefficients of the destination sector. A stochastic residual drawn from `N(0, σ)` is added: `predila_n = X'b + invnorm(aleat_ila) * sigma`. The result is exponentiated to recover levels.

**Step 4 — Final assignment:**
- Workers who stayed in the same sector with same skill: keep original `lai_m`.
- Workers who moved sectors, changed skill, or entered from non-employment: receive imputed `predila_n`.
- Those who became inactive or unemployed: `lai_m_s = .`.
- Those outside sample: keep original `lai_m`.

**Outputs:**
- `lai_m_s`: simulated primary labor income (PPP) at the individual level.
- `salaried_s`, `public_job_s`: simulated employment relationship indicators.

---

### `10_income_rel.do` — Income Growth (3-Sector, with GDP Rescaling)

**Objective:** Grows simulated labor incomes to match sectoral GDP growth rates (3-sector, macro data), then rescales the total to match aggregate GDP growth. Used when `$sector_model == 3`.

**Inputs:**
- `lai_m_s`, `lai_s_s` (created here as clone of `lai_s`): primary and secondary labor income.
- `growth_macro_data`: GDP growth rates by 3 sectors + aggregate.
- `var0`, `var1`: total labor income by sector (baseline and simulated).

**Method:**
1. Computes total labor income by sector (baseline and simulated) for primary and secondary jobs.
2. Calculates an adjustment factor `H = (M*(1+V) / C) - 1` in Mata, where M=baseline, V=target growth, C=simulated. This adjusts simulated incomes so that the *total* labor income by sector matches the macro target.
3. Applies the adjustment multiplicatively to `lai_m_s` and `lai_s_s` by sector.
4. Rescales all incomes within each sector so that total income sums to baseline, then applies the aggregate GDP growth rate uniformly.
5. Verifies that aggregate income growth matches total GDP target (warns if > 1 pp off).

**Outputs:**
- `lai_m_s`, `lai_s_s`: simulated primary and secondary labor income, calibrated to macro targets.

---

### `10_income_rel_new.do` — Income Growth (6-Sector, with GDP Rescaling)

**Objective:** Grows simulated labor incomes at the 6-sector level to match micro growth rates (average wages per sector), then additionally rescales to match sectoral macro GDP totals and aggregate GDP. Used when `$sector_model == 6` and `$inc_re_scale == "yes"`.

**Inputs:**
- `lai_m_s`, `lai_s`: primary and secondary labor income.
- `growth_labor_income`: average labor income growth rates by 6 sectors + total.
- `growth_macro_data`: sectoral GDP growth rates (3 sectors + aggregate).

**Method (5 steps):**
1. **Micro calibration (6 sectors):** Computes average wage by 6-sector cell (baseline vs. simulated). Adjusts so the mean wage in each cell matches the target from `growth_labor_income`.
2. **Average income rescaling:** Rescales so average total labor income (across all employed) matches the baseline average. Then applies the total average labor income growth rate.
3. **Macro calibration (3 sectors):** Applies an additional adjustment to ensure total labor income by 3-sector matches the macro GDP growth rates.
4. **Aggregate GDP rescaling:** Final proportional rescaling so total income growth matches GDP total.
5. **Verification checks** at each stage.

**Outputs:**
- `lai_m_s`, `lai_s_s`: fully calibrated simulated labor incomes.

---

### `10_income_rel_new_no_rescaling.do` — Income Growth (6-Sector, No GDP Rescaling)

**Objective:** Same as `10_income_rel_new.do` but **omits** the macro GDP rescaling steps (steps 3–4 above). Used when `$sector_model == 6` and `$inc_re_scale == "no"` (the active option for India).

**Inputs/Outputs:** Same structure as `10_income_rel_new.do`.

**Method:**  
Steps 1–2 only (micro calibration and average income rescaling). Does not align to macro GDP totals. Incomes are calibrated purely to the micro labor income growth rates from the input file.

---

### `11_total_labor_income.do` — Total Individual Labor Income

**Objective:** Computes the total individual simulated labor income by combining primary (`lai_m_s`) and secondary (`lai_s_s`) job incomes, and verifies against the target growth rate.

**Inputs:**
- `tot_lai`: baseline total individual labor income.
- `lai_m`, `lai_s`: baseline primary and secondary labor income.
- `lai_m_s`, `lai_s_s`: simulated primary and secondary labor income.

**Method:**
1. Computes baseline individual total: `aux1 = lai_m + lai_s` (with handling for negative primary income).
2. Computes simulated individual total: `aux2 = lai_m_s + lai_s_s` (same logic).
3. `tot_lai_s = tot_lai - aux1 + aux2` — i.e., starts from baseline total and adds the change.
4. Verification: checks that simulated total labor income grew at the target rate (GDP-based for 3-sector model, average wage-based for 6-sector). Warns if > 1 pp off.

**Outputs:**
- `tot_lai_s`: simulated total individual labor income.

---

### `12_assign_nlai.do` — Non-Labor Income Assignment (Dispatcher)

**Objective:** Projects all non-labor income components to the simulation year and assembles the total simulated household non-labor income.

**Inputs:**
- Household-level non-labor income variables: `h_pensions`, `h_capital`, `h_otherinla`, `h_ns_remit`, `h_renta_imp`, `h_pds`, `h_oth_schemes`, `h_int_remit`, `h_dom_remit`.
- `growth_nlabor`: growth rates for remittances, pensions, capital.
- Globals `$rn_dom_remitt` and `$rn_int_remitt`: control allocation method for remittances.

**Method by component:**

| Component | Method |
|---|---|
| **Pensions** | Neutral: scaled by `growth_nlabor[2,1]` adjusted for population change. |
| **Capital income** | Neutral: scaled by `growth_nlabor[3,1]` adjusted for population change. |
| **Other non-labor income (`h_otherinla`)** | Held constant in real terms (`h_otherinla_s = h_otherinla`). |
| **Other remittances (`h_ns_remit`)** | Held constant in real terms (`h_ns_remit_s = h_ns_remit`). |
| **Imputed rent (`h_renta_imp`)** | Held constant in real terms (`h_renta_imp_s = h_renta_imp`). |
| **Social transfer programs (PDS, other schemes)** | Delegated to `social_programs.do`. |
| **Domestic remittances** | Delegated to `12_assign_dom_rem_0.do` (neutral) or `12_assign_dom_rem_1.do` (random allocation). |
| **International remittances** | Delegated to `12_assign_int_rem_0.do` (neutral) or `12_assign_int_rem_1.do` (random allocation). |

After all components are updated, the total simulated household non-labor income is:
```
h_nlai_s = h_*_remit_s + h_pensions_s + h_capital_s + h_renta_imp_s + h_otherinla_s + h_transfers_s
```

**Outputs:**
- `h_pensions_s`, `h_capital_s`, `h_otherinla_s`, `h_ns_remit_s`, `h_renta_imp_s`, `h_transfers_s`: simulated non-labor income components.
- `h_dom_remit_s`, `h_int_remit_s`: simulated remittance variables.
- `h_nlai_s`: total simulated household non-labor income.

---

### `social_programs.do` — Social Transfer Program Simulation (India)

**Objective:** Simulates changes in government cash transfer programs (PDS food subsidies and other schemes) using program-specific expenditure targets provided by the fiscal/policy team.

**Inputs:**
- `h_pds`: baseline household PDS (Public Distribution System) transfer receipts.
- `h_oth_schemes`: baseline household receipts from other government schemes.
- `$model`: the scenario year (2024, 2025, 2026, 2027, or 2028).

**Method:**  
Computes a real growth rate (`gr_pds`, `gr_oth`) for each program based on hard-coded nominal expenditure values (reflecting known budget allocations), normalized to a 2023 baseline.

| Scenario Year | PDS Growth Rate | Other Schemes Growth Rate |
|---|---|---|
| 2024 | (186194/201037) − 1 ≈ −7.4% | (173026.91/177037.69) − 1 ≈ −2.3% |
| 2025 | (178985/201037) − 1 ≈ −11.0% | (169467.53/177037.69) − 1 ≈ −4.3% |
| 2026–2028 | same as 2025 | (166551.90/177037.69) − 1 ≈ −5.9% |

**Outputs:**
- `h_pds_s`: simulated PDS transfer income.
- `h_oth_schemes_s`: simulated other government scheme income.

---

### `12_assign_dom_rem_0.do` — Domestic Remittances (Neutral Distribution)

**Objective:** Scales domestic remittances proportionally for all recipient households to match the target growth rate from macro inputs, accounting for the population weight change.

**Inputs:**
- `h_dom_remit`: baseline household domestic remittances (PPP).
- `growth_capital[1,1]`: target growth rate for domestic remittances.
- `weight`, `fexp_s`: baseline and simulated weights.

**Method:**
1. Computes aggregate baseline and simulated domestic remittances (in millions, weighted).
2. Derives an adjustment factor `H = (M*(1+V)/C) - 1` such that the total remittances after scaling by `(1 + H)` will match the macro target.
3. All recipient households receive a uniform proportional increase/decrease.
4. Verifies that the growth rate is achieved (warns if > 1 pp off).

**Outputs:**
- `h_dom_remit_s`: simulated domestic remittances.

---

### `12_assign_dom_rem_1.do` — Domestic Remittances (Random Allocation)

**Objective:** Models domestic remittance growth by selectively adding new recipient households (if growth is positive) or reducing amounts for existing recipients (if negative), with spatial targeting by region and urban/rural area.

**Inputs:**
- `h_dom_remit`: baseline domestic remittances.
- `growth_capital[1,1]`: scalar target (or vector for multiple scenarios).
- `fexp_s`, `weight`.
- Region × urban cross-tabulation summaries (mean, median, weighted count) via the custom `mtab1` program.
- Mata routines: `st_order`, `st_transf`, `st_corr2`.

**Method:**
1. Computes aggregate gap (`Tr`) between baseline (weighted by baseline weights) and target.
2. If `Tr > 0` (growth scenario): identifies the proportion and average transfer needed, then assigns new domestic remittance recipients within each region × urban/rural cell using cumulative weight ranking. Applies a correction factor to exactly hit the target.
3. If `Tr < 0` (contraction scenario): proportionally scales down existing recipients using a derived correction factor.
4. For multi-scenario runs (multiple years), carries forward from the previous year's simulated value.
5. Identifies the correct simulated variable for the scenario being run.

**Outputs:**
- `h_dom_remit_s`: simulated domestic remittances (with realistic household-level distributional changes).

---

### `12_assign_int_rem_0.do` — International Remittances (Neutral Distribution)

**Objective:** Scales international remittances proportionally across all recipient households, analogous to `12_assign_dom_rem_0.do`.

**Inputs:**
- `h_int_remit`: baseline international remittances.
- `growth_remitt[1,1]`: target growth rate for international remittances (from `growth_nlabor`).
- `weight`, `fexp_s`.

**Method:** Identical to `12_assign_dom_rem_0.do` but applied to `h_int_remit`.

**Outputs:**
- `h_int_remit_s`: simulated international remittances.

---

### `12_assign_int_rem_1.do` — International Remittances (Random Allocation)

**Objective:** Models international remittance flows using random household assignment (new recipients) or proportional scaling, analogous to `12_assign_dom_rem_1.do`.

**Inputs/Method/Outputs:** Identical structure to `12_assign_dom_rem_1.do` but applied to `h_int_remit` and using `growth_remitt[1,1]` as the target rate.

---

### `13_household_income.do` — Household Income Aggregation

**Objective:** Aggregates individual-level simulated labor incomes to the household level and combines with household non-labor income to produce total household income.

**Inputs:**
- `tot_lai_s`: simulated individual total labor income.
- `h_nlai_s`: simulated household non-labor income.
- `h_lai`, `h_nlai`, `h_inc`: baseline household labor income, non-labor income, and total income.

**Method:**
1. Creates `h_lai_obs = h_lai * -1` (negative of baseline labor income, for income difference approach).
2. Aggregates simulated individual labor income to household: `h_lai_s = Σ(tot_lai_s)` by household.
3. Creates `h_nlai_obs = h_nlai * -1` analogously.
4. Computes simulated household income as:  
   `h_inc_s = h_inc + h_lai_obs + h_lai_s + h_nlai_obs + h_nlai_s`  
   (i.e., replaces baseline labor and non-labor components with simulated ones).
5. Floors at 0. Sets missing if baseline `h_inc` is missing.
6. Computes per capita: `pc_inc_s = h_inc_s / h_size`.

**Outputs:**
- `h_lai_s`: simulated household total labor income.
- `h_inc_s`: simulated total household income.
- `pc_inc_s`: simulated per capita household income.

---

### `14_relative_prices.do` — Relative Price Adjustment *(Currently Inactive)*

**Objective:** Adjusts poverty lines for food vs. non-food price differentials. This do-file exists but is **commented out** in `00_master.do` and is therefore not executed in the standard India run.

**Method (when activated):**  
Applies `growth_pl[1,1]` (relative price growth rate) multiplicatively to the PPP poverty lines (`lp_685usd_ppp`, `lp_365usd_ppp`, `lp_215usd_ppp` for 2017 PPP, or corresponding 2011 lines).

---

### `15_income_to_consumption.do` — Income-to-Consumption Ratio Matching

**Objective:** Derives each household's income-to-consumption ratio and, optionally, updates it via nearest-neighbor statistical matching to better reflect how the simulated income maps to consumption.

**Inputs:**
- `welfare_base` (renamed from `welfare_ppp`): baseline per capita consumption.
- `pc_inc_s`: simulated per capita income.
- `pc_inc_base` (renamed from `ipcf_ppp`): baseline per capita income.
- `growth_macro_data[last row,1]`: private consumption growth rate.
- Globals: `$matching`, `$standardization`.

**Method — Matching OFF (`$matching == "no"`):**
- `new_ratio = pc_inc_base / welfare_base` (original observed ratio kept).

**Method — Matching ON (`$matching == "yes"`):**
1. Saves dataset to disk (`simulated.dta`).
2. Constructs income ventiles (`vtile`) using baseline welfare.
3. Standardizes matching variables (age, household size, baseline income, simulated income) using z-scores.
4. Creates **donor** dataset: baseline characteristics (original income, original ratio).
5. Creates **receiver** dataset: simulated characteristics (new income, needs new ratio).
6. Performs a **Cartesian join** between receiver and donor, within cells defined by `region × vtile × urban`.
7. Computes **Euclidean distance** across standardized age, household size, and income.
8. For each receiver household, selects the nearest donor (minimum distance).
9. Adopts the donor's income-to-consumption ratio **only if** it is within ±20% of the receiver's original ratio; otherwise retains the original.

**Outputs:**
- `new_ratio`: matched income-to-consumption ratio for each household.
- Saved file: `simulated.dta` (intermediate, erased in `17_output.do`).

---

### `16_new_consumption.do` — Simulated Consumption

**Objective:** Converts simulated per capita income into simulated per capita consumption using the matched ratio, then optionally rescales to match aggregate private consumption growth.

**Inputs:**
- `pc_inc_s`: simulated per capita income.
- `new_ratio`: income-to-consumption ratio from `15_income_to_consumption.do`.
- `welfare_base`: baseline per capita consumption.
- `growth_cons = growth_macro_data[last row, 1]`: private consumption growth rate.
- Global `$cons_re_scale`.

**Method:**
1. `welfare_s = pc_inc_s / new_ratio`.  
   For households where `new_ratio ≤ 0`: `welfare_s = welfare_base * (1 + growth_cons)` (fallback).
2. **Rescaling ON (`$cons_re_scale == "yes"`):**
   - Computes mean baseline and simulated consumption (weighted).
   - Scales `welfare_s` so its mean matches baseline mean exactly.
   - Applies the private consumption growth rate: `welfare_s *= (1 + growth_cons)`.
   - Verifies result against macro target (warns if > 1 pp off).

**Outputs:**
- `welfare_s`: simulated per capita household consumption (PPP, 2021), calibrated to private consumption growth.

---

### `17_output.do` — Final Output Database

**Objective:** Organizes the final output dataset, labels variables, computes poverty and inequality measures, and saves the results.

**Inputs:** Full in-memory dataset at end of simulation.

**Method:**

**Step 1 — Variable ordering:** Orders key output variables first (`hhid`, `pid`, `fexp_base`, `fexp_s`, `welfare_base`, `welfare_s`, occupation/sector/skill/income variables baseline and simulated).

**Step 2 — Variable labeling:** Applies descriptive labels to all key output variables.

**Step 3 — Poverty and inequality:**
- Constructs poverty lines using 2021 PPP vintage:
  - `pl1 = $3.00/day × (365/12)` (extreme poverty)
  - `pl2 = $4.20/day × (365/12)`
  - `pl3 = $8.30/day × (365/12)`
- Computes headcount ratio and poverty gap using `apoverty` for both `welfare_base` and `welfare_s`.
- Computes Gini coefficient for `welfare_s` using `ainequal`.
- Stores all poverty/inequality measures in matrix `all_p`.
- Generates per-household poverty indicators: `poor1_base`, `poor2_base`, `poor3_base`, `poor1`, `poor2`, `poor3` (for all three lines).

**Step 4 — Saving:**  
Saves the dataset with a filename encoding all key scenario parameters:
```
IND_{model}_{sector_model}s_dom_{rn_dom_remitt}_int_{rn_int_remitt}_inc_{inc_re_scale}_cons_{cons_re_scale}_matching_{matching}_st_{standardization}.dta
```
into `${data_out}` (= `SM2026/IND/Data/`).

---

## Input File Structure (Excel)

The Excel file `Microsimulation_Inputs_IND_conflict.xlsm` must contain the following sheets:

| Sheet | Contents |
|---|---|
| `input_setup` | Model type (`national`/`inter`), scenario year, sector count, weighting flag |
| `input_gdp` | Sectoral GDP growth rates (3 sectors + aggregate total), one rate per row |
| `input_gdp2` | Average labor income growth rates (6 sectors + total), one rate per row |
| `input_labor` | Activity rate growth [row 1], unemployment rate growth [row 2], sectoral employment share growth [rows 3+] |
| `input_intrasectoral` | Within-sector unskilled share growth (3 rows, one per broad sector) |
| `input_nonlabor` | Growth rates for: remittances [1], pensions [2], capital [3] |
| `input_pop_wdi` | WDI total population target (millions) |

---

## Key Output Variables

| Variable | Description |
|---|---|
| `welfare_base` | Baseline per capita consumption (2021 PPP, monthly) |
| `welfare_s` | Simulated per capita consumption (2021 PPP, monthly) |
| `fexp_base` | Baseline survey weights |
| `fexp_s` | Simulated survey weights (population-adjusted) |
| `occupation_base` / `occupation_s` | Baseline/simulated occupation category (0–7) |
| `sect_main_base` / `sect_main_s` | Baseline/simulated 3-sector classification |
| `skilled_base` / `skilled_s` | Baseline/simulated skill level |
| `pc_inc_base` / `pc_inc_s` | Baseline/simulated per capita family income (PPP) |
| `poor1_base` / `poor1` | Poverty indicator at $3.00/day line |
| `poor2_base` / `poor2` | Poverty indicator at $4.20/day line |
| `poor3_base` / `poor3` | Poverty indicator at $8.30/day line |

---

## Software and Package Dependencies

- **Stata 17+**
- External packages (auto-installed in `00_master.do`): `etime`, `apoverty`, `ainequal`, `ainequal0`
- Custom programs (loaded from `$thedo/programs/`): `simchoiceres`, `maxentropy`, `mtab1`, `st_order`, `st_transf`, `st_corr2`, `st_repond_1`, `st_mat`, `st_gr` (Mata-based routines)
- DLW (`dlw`) command for World Bank data access
