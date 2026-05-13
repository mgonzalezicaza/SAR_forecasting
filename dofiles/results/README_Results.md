# SAR Forecasting — Results Pipeline
## `dofiles/results/`

This folder contains the **post-simulation results pipeline** that takes the microsimulated household-level datasets produced by the India (and other SAR country) model and computes all summary statistics, distributional indicators, and tabular outputs required for the MPO (Macro-Poverty Outlook) reporting cycle.

The pipeline is self-contained and country-agnostic: a single global switch (`$country`) selects which SAR country is processed. It runs entirely within a single Stata session and writes all outputs to a country-specific Excel workbook.

---

## Execution Sequence

```
00_master.do
│
├── 01_data.do              — Load & harmonise actual + simulated surveys
├── 02_variables.do         — Construct analytical variables
├── 03_static_profiles.do   — Poverty-group profiles (cross-section)
├── 04_gics.do              — Growth Incidence Curves
├── 05_transition_matrix.do — Poverty transition matrices
├── 06_dynamic_profiles.do  — Year-on-year poverty mobility profiles
└── 07_pop_wdi.do           — WDI population projection series
```

---

## Do-File Descriptions

---

### `00_master.do` — Master Orchestrator

**Objective:** Initialise the environment, set all global parameters, read the data-availability matrix, and sequentially call every downstream do-file.

**Key Inputs:**

| Input | Description |
|---|---|
| `$path` | Root project directory (local machine path) |
| `$data_path` | Simulated data directory |
| `$thedo` | Path to this `results/` folder |
| `Data availability by country.xlsx` | Excel sheet mapping each country-year to `"ok"` (actual survey) or `"sim"` (simulated) |
| `$povmod` | Shared MFM macro vintages DTA file (network path) |

**Key Globals Set:**

| Global | Example | Purpose |
|---|---|---|
| `$country` | `BGD` | ISO3 country code to process |
| `$cpi_version` | `14` | CPI/PPP support module version |
| `$min_sim_year` | `2023` | First year treated as a simulation vintage |
| `$ppp` | `2021` | PPP base year |
| `$pline1/2/3` | `300 / 420 / 830` | Poverty line thresholds x100 (in 2021 PPP cents/day) |
| `$prs_gp` | `28` | Prosperity Gap reference income (USD/day) |

**Method:**
1. Resets Stata memory (`drop _all`, `frame reset`).
2. Sets Stata version to 17.0 for reproducibility.
3. Starts an `etime` timer.
4. Reads the data-availability Excel sheet into a matrix `data` (rows: year, actual/sim flag; columns: up to 6 survey years).
5. Converts `"ok"` to `0` (actual) and `"sim"` to `1` (simulated) and stores as a numeric matrix.
6. Defines the output Excel workbook path (`Results_${country}.xlsm`).
7. Calls each of the seven downstream do-files in sequence.
8. Reports total elapsed time.

**Outputs:** All downstream outputs; the `data` matrix is passed as a shared in-memory object to all child do-files.

---

### `01_data.do` — Data Loading and Harmonisation

**Objective:** Build a unified longitudinal dataset by loading, cleaning, and harmonising up to 6 survey years per country — mixing actual SARMD surveys and pre-produced simulation DTA files — into a single panel-style tempfile.

**Key Inputs:**

| Input | Source |
|---|---|
| SARMD modules `IND`, `LBR`, `INC` | Datalibweb (`dlw`) for actual years |
| CPI/PPP support module | `dlw` Support_2005_CPI_v${cpi_version}_M |
| Simulated DTA | `${data_path}/${country}/Data/${country}_YYYY_6s_dom_yes_int_no_inc_no_cons_no_matching_yes_st_yes.dta` |
| `data` matrix | Passed from `00_master.do` — year and actual/sim flags |

**Method — Actual Survey Years (`data[2,i] == 0`):**
1. Downloads the CPI/PPP conversion factors from Datalibweb for the target year.
2. Downloads three SARMD modules (`IND`, `LBR`, `INC`) and merges them on `hhid`/`pid`.
3. Applies country-year-specific fixes (e.g., Bangladesh 2022 welfare deflation correction using `welfaredef`).
4. Retains a focused set of variables: welfare, income components, labor status, demographics.
5. Converts all income variables from local currency to **2021 PPP USD per capita per month** using `cpi${ppp}` and `icp${ppp}`.
6. **Skill classification** (ILO-based): workers in ISCO-08 groups 1-3 are high-skilled; groups 4-8 are classified by educational attainment (complete secondary+ = high-skilled); group 9 = low-skilled.
7. **Sector classification**: `industrycat10` is recoded into 3 macro-sectors (Agriculture = 1; Industry = 2-5; Services = 6-10).
8. **Occupation composite** (`occupation_s`): a 0-7 categorical variable combining labor force status, sector, and skill level:
   - 0 = Inactive
   - 1 = Unemployed
   - 2 = Skilled Agriculture
   - 3 = Unskilled Agriculture
   - 4 = Skilled Industry
   - 5 = Unskilled Industry
   - 6 = Skilled Services
   - 7 = Unskilled Services
9. Constructs non-labor income variables at the household level (remittances by type, pensions, capital, other).
10. Defines labor relationship (`labor_rel`): salaried / self-employed / unpaid / unemployed.

**Method — Simulated Years (`data[2,i] == 1`):**
1. Loads the pre-produced simulation DTA file directly.
2. Reconstructs `emplyd_s` and `unemplyd_s` from `occupation_s`.
3. Re-aggregates non-labor income to the household level for consistency with actual-year treatment.

**Output:** Single in-memory Stata dataset (a tempfile named by `$country`) containing all survey years stacked, harmonised, and PPP-converted, ready for analysis.

---

### `02_variables.do` — Analytical Variable Construction

**Objective:** Derive all analytical variables needed for poverty, inequality, labor market, and distributional analysis from the harmonised dataset produced in `01_data.do`.

**Key Inputs:** The in-memory dataset from `01_data.do`.

**Method — Step by Step:**

1. **CPI/PPP gap filling:** Imputes missing CPI and ICP conversion factors with their sample means.
2. **National poverty line in PPP:** Converts `pline_nat` to PPP terms (`pline_nat_ppp`).
3. **International poverty lines:** Creates three daily poverty lines in PPP USD/month:
   - `lp_${pline1}usd_s`, `lp_${pline2}usd_s`, `lp_${pline3}usd_s`
4. **Poverty indicators:**
   - `poorX1` = below line X (for all three lines)
   - `gap_X` = poverty gap (% of line)
   - `poor_nat` = below national poverty line (via `apoverty`)
   - `poorX2` = exclusive poverty tiers (between lines only)
   - `nonpoor` = above highest line
5. **Prosperity Gap:** `pg = ($prs_gp x 365/12) / welfare_s`, truncated to the threshold for those above it.
6. **Labor market variables:**
   - `inactive`, `sal`, `self`, `unpd`
   - `emp_agr`, `emp_ind`, `emp_ser` (sector employment dummies)
   - `agr_unsk`, `ind_unsk`, `ser_unsk` (unskilled by sector)
   - `inc`, `inc_sk`, `inc_unsk` (labor income by skill level)
   - `inc_agr/ind/ser` x skill combinations (6 sector-skill cells)
7. **Population disaggregations:** `female`, `rural`, and seven age-band dummies (0-14, 15-24, ..., 65+); `pop_*` mirrors for each subgroup.
8. **Per-capita income aggregation:**
   - `h_lai_s` = household total labor income (sum across members)
   - `pc_lai_s` = per-capita labor income
   - `pc_X_s` = per-capita of each non-labor income component
   - `h_nlai_s` / `pc_nlai_s` = total non-labor income
   - `pc_pubtr_s` = public transfers; `pc_privttr_s` = private transfers (all remittance types)
9. **Inequality:** Gini and Theil coefficients computed year by year using `ainequal`.
10. **Frame copy:** Saves a copy of the full processed dataset as Stata frame `processed` for use by `06_dynamic_profiles.do`.

**Key Outputs (variables added to dataset):**

| Variable | Description |
|---|---|
| `poor{X}1` | Poverty dummy, line X |
| `gap_{X}` | Poverty gap ratio |
| `pg` | Prosperity Gap ratio |
| `gini`, `theil` | Inequality measures |
| `pc_lai_s` | Per-capita labor income (PPP) |
| `pc_nlai_s` | Per-capita non-labor income (PPP) |
| `occupation_s` | 0-7 occupation cell |
| `emp_agr/ind/ser` | Sector employment dummies |

---

### `03_static_profiles.do` — Static Poverty Profiles

**Objective:** Compute detailed socio-economic profiles for each poverty/vulnerability group in a cross-sectional (pooled across years) view, and export summary statistics for MPO reporting.

**Key Inputs:** The in-memory dataset (all years), variables from `02_variables.do`.

**Poverty Categories Profiled:**

| Category | Definition |
|---|---|
| `poor${pline3}1` | Below upper poverty line |
| `poor${pline2}1` | Below middle poverty line |
| `poor${pline1}1` | Below lower poverty line |
| `nonpoor` | Above upper poverty line |
| `total` | All individuals |

**Method:**

1. **Variable cloning by category:** For each of the 5 poverty groups, creates suffixed copies of ~40 variables (demographics, labor market, income components, age distribution, etc.), masked to that group only.
2. **Descriptive collapse:** `collapse (sum) pop* (mean) [all profile vars] [iw=fexp_s], by(year)`.
3. **Transpose:** `xpose` converts the collapsed data to long-format (indicator x year columns) for Excel-friendly export.
4. **Saves** `descriptives.dta` in the country folder as an intermediate file (used later by `06_dynamic_profiles.do`).
5. **MPO team output:**
   - Extracts poverty rates for all three international lines + Gini + Prosperity Gap.
   - Appends to the shared regional file `poverty_SAR.dta`.
   - Reshapes and saves `Pov_SAR_micro.dta` with country names and formatted poverty rate columns.

**Outputs:**

| File | Description |
|---|---|
| `${country_path}/descriptives.dta` | Intermediate profile data (indicator x year), consumed by `06_dynamic_profiles.do` |
| `${data_path}/poverty_SAR.dta` | Updated regional poverty database (all SAR countries) |
| `${data_path}/Pov_SAR_micro.dta` | Formatted regional poverty rates with country names |

---

### `04_gics.do` — Growth Incidence Curves

**Objective:** Calculate and export Growth Incidence Curves (GICs) — the annualised growth rate of mean welfare by consumption percentile — at the national, urban, and rural levels.

**Key Inputs:** In-memory dataset with `welfare_s`, `fexp_s`, `year`, `urban`/`rural`.

**Method:**

1. **Percentile ranking:** For each year, assigns consumption percentiles (1-100) using `xtile` on `welfare_s`, separately for:
   - National (`pctile_all`)
   - Urban (`pctile_urban`)
   - Rural (`pctile_rural`)
2. **Collapse by percentile:** `collapse welfare_s [iw=fexp_s], by(year pctile_*)` to get mean welfare per percentile per year.
3. **Reshape wide** on `year`, producing one column of mean welfare per year.
4. **GIC calculation:** For each non-base year `a`, computes `r_a = (welfare_a / welfare_{a-1} - 1) x 100` — the percentage growth rate relative to the immediately preceding year.
5. **Export** each of the three geographic levels to a separate Excel sheet.

**Outputs (Excel sheets in `${outfile}`):**

| Sheet | Content |
|---|---|
| `GICs` | National GIC — percentile x growth rate per year-pair |
| `GICs_urban` | Urban GIC |
| `GICs_rural` | Rural GIC |

---

### `05_transition_matrix.do` — Poverty Transition Matrices

**Objective:** Construct year-on-year poverty transition matrices showing how many individuals (weighted) move between poverty categories between consecutive simulated years.

**Key Inputs:**

| Input | Description |
|---|---|
| In-memory dataset | Simulated years only (`simulation == 1` and `year >= $min_sim_year`) |
| `welfare_base` | Baseline (pre-simulation) welfare from survey |
| `poor*1`, `nonpoor` | Poverty dummies computed in `02_variables.do` |
| `fexp_base`, `fexp_s` | Survey expansion weights |

**Method:**

1. **Filter** to simulated years only.
2. **Reshape wide** on `year` so each row is one individual with welfare and poverty status for all simulated years as columns.
3. **Baseline poverty categories** (from `welfare_base`): assigns each individual to `Poor $pline3`, `Poor $pline2`, `Poor $pline1`, or `Non-poor` based on their pre-simulation welfare.
4. **First simulated year:** Collapses weighted counts of individuals in each origin-category into destination-category bins (`poor{X}2`, `nonpoor`).
5. **Subsequent years:** Uses the previous simulated year's poverty status as the origin category, repeating the same collapse.
6. **Appends** all year-specific transition tables.
7. **Exports** to Excel.

**Output (Excel sheet in `${outfile}`):**

| Sheet | Content |
|---|---|
| `matrix_categories` | Long-format transition matrix: `year`, `prev_cat_` (origin group), weighted counts in each destination category |

---

### `06_dynamic_profiles.do` — Dynamic (Mobility) Profiles

**Objective:** Produce year-on-year poverty mobility profiles, characterising the demographic and economic attributes of individuals who enter poverty, remain poor, exit poverty, or remain non-poor between consecutive simulated years.

**Key Inputs:**

| Input | Description |
|---|---|
| Frame `processed` | Copy saved in `02_variables.do` — full dataset including all years |
| `sim_years` | Matrix of simulated year values (set in `05_transition_matrix.do`) |
| `welfare_base` | Pre-simulation welfare for first-year transitions |
| `poor*1`, `occupation_s`, `active_s`, etc. | Status variables for each year |

**Poverty Mobility Categories (per year):**

| Category | Definition |
|---|---|
| `new_poor{X}` | Not poor previous year, poor this year |
| `always_poor{X}` | Poor both this year and previous year |
| `new_nonpoor` | Poor previous year, not poor this year |
| `always_nonpoor` | Not poor either year |
| `total` | All individuals |

**Method:**

1. Switches to frame `processed`; filters to simulated years only.
2. **Reshapes wide** on year for all welfare, income, labor, and demographic variables.
3. For the **first simulated year**, compares current poverty status against `welfare_base` to define mobility categories.
4. For **subsequent years**, compares current year to the immediately preceding year.
5. For each simulated year x mobility category combination, creates ~30 suffixed variable copies (demographics, income, labor status, age groups, non-labor income components).
6. **Collapses** to a single-row summary per year-category.
7. **Transposes** to indicator-row format and saves as a tempfile per year.
8. **Merges** all year-tempfiles into one wide table.
9. **Appends** the static profile data from `descriptives.dta` (produced in `03_static_profiles.do`).
10. Deduplicates, then **exports to Excel**.
11. **Erases** the intermediate `descriptives.dta` file.

**Output (Excel sheet in `${outfile}`):**

| Sheet | Content |
|---|---|
| `descriptives` | Combined static + dynamic profile table — indicator x year, covering all poverty groups and mobility categories |

---

### `07_pop_wdi.do` — WDI Population Projections

**Objective:** Extract and export the macro population projection series for the target country from the shared MFM (Macro-Fiscal Model) vintage dataset, to anchor the microsimulation's population reweighting.

**Key Inputs:**

| Input | Description |
|---|---|
| `$povmod` | Network DTA file: `MFM-allvintages.dta` — all MFM macro vintages for all countries |

**Method:**

1. Loads the MFM vintages file.
2. Parses the `date` string variable and keeps only the **most recent vintage** (maximum date).
3. Filters to the target `$country`.
4. Retains only `year` and `pop` (population in thousands).
5. Exports directly to Excel.

**Output (Excel sheet in `${outfile}`):**

| Sheet | Content |
|---|---|
| `pop_wdi` | Two-column table: `year` and `pop` (WDI/MFM population projection) |

---

## Output Summary

All results are written to a single country-level Excel workbook:

```
${path}/${country}/Results_${country}.xlsm
```

| Sheet | Produced by | Content |
|---|---|---|
| `GICs` | `04_gics.do` | National GIC per year-pair |
| `GICs_urban` | `04_gics.do` | Urban GIC |
| `GICs_rural` | `04_gics.do` | Rural GIC |
| `matrix_categories` | `05_transition_matrix.do` | Poverty transition matrix |
| `descriptives` | `06_dynamic_profiles.do` | Static + dynamic socio-economic profiles |
| `pop_wdi` | `07_pop_wdi.do` | WDI population projection series |

In addition, two shared regional datasets are updated:

| File | Updated by | Content |
|---|---|---|
| `${data_path}/poverty_SAR.dta` | `03_static_profiles.do` | Poverty rates for all SAR countries |
| `${data_path}/Pov_SAR_micro.dta` | `03_static_profiles.do` | Formatted poverty rates with country names |

---

## Key Design Decisions

- **Actual vs. simulated years are handled transparently:** The `data` matrix controls which years pull from Datalibweb and which load from the simulation folder. All downstream analysis code treats both year types identically.
- **Frame `processed`:** Stata's `frame` mechanism is used to preserve the full processed dataset across `03_static_profiles.do`'s destructive `preserve`/`restore` blocks, so `06_dynamic_profiles.do` can access the complete data.
- **PPP consistency:** All welfare and income variables are expressed in **2021 PPP USD per capita per month** throughout the pipeline.
- **Poverty thresholds:** Set as `$pline1/2/3` in units of PPP cents x 100 (e.g., `300` = $3.00/day). Conversion to monthly: `(X / 100) x (365 / 12)`.
- **Country-switching:** Changing `$country` in `00_master.do` is the only required change to process any of the 8 SAR countries (AFG, BGD, BTN, IND, MDV, NPL, PAK, LKA).
