# README — `dofiles/tool`

**Project:** SAR Forecasting – Labor Market Inputs for the Microsimulation Tool  
**Institution:** World Bank – ESAPV (South Asia Poverty & Equity)  
**Primary Author:** Kelly Y. Montoya (kmontoyamunoz@worldbank.org)  
**Last updated:** April 2026

---

## Purpose

The `tool` folder contains the do-files that **prepare all inputs required by the regional SAR microsimulation model** before the country-level simulation (e.g., `dofiles/model/india`) is run. The pipeline extracts and harmonises labor-market statistics from household surveys (SARMD), labor-force surveys (SARLAB), and microsimulated data; computes GDP-employment and productivity-income elasticities; pulls macro projections (GDP, population) from the MPO/MFM database; and downloads remittance inflows from MFMod. All outputs are written to a single Excel workbook (`input_MASTER.xlsx`) that feeds the regional tool.

---

## Execution Sequence

```
00_master.do  (or  00_master_informality.do)
|
+-- 01_inputs_hhss.do              household surveys -> inputs_hhss.dta / input_hhss (sheet)
|    +-- [India variant]
|        01_inputs_hhss_IND.do     PLFS panel -> inputs_hhss_IND.dta / input_hhss_IND (sheet)
|
+-- 01_inputs_hhss_informality.do  informality variant -> inputs_hhss_inf.dta / input_hhss_inf (sheet)
|
+-- 02_inputs_lfs.do               labor force surveys -> inputs_lfs.dta / input_lfs (sheet)
|
+-- 03_inputs_microsims.do         simulated datasets -> input-labor-microsimulated.dta / sheet
|
+-- 04_merge_inputs_labor.do       combines 01/02/03 -> input-labor (sheet)
|
+-- 05_elasticities.do             standard elasticities -> elasticities.dta / Elasticities (sheet)
|    +-- 05_elasticities_IND.do         India-specific (PLFS) -> elasticities_IND.dta / Elasticities IND
|    +-- 05_elasticities_informality.do informality variant -> elasticities_inf.dta / Elasticities inf
|
+-- 06_inputs_macro.do             GDP + population -> input_mpo_all.dta / input-mpo (sheet)
|
+-- 07_exports_inflows.do          remittances -> inflows (sheet)

Helper / utility files (not called in sequence):
    CPIs_no_dlw.do          standalone CPI construction snippet
    _country_folders.do     one-off folder scaffolding utility
    ppp2017/                PPP reference data subfolder
```

> **Note:** Steps 01-04 are typically commented out in `00_master.do` once baseline inputs exist; only steps 05-07 are active in a standard run.
> `00_master_informality.do` is an alternate entry point that substitutes `01_inputs_hhss_informality.do` and `05_elasticities_informality.do` for the standard skill-based files.

---

## Do-file Descriptions

---

### `00_master.do` — Main Entry Point (Standard Run)

**Objective:** Set all global macros, create the output directory structure, and call each input-preparation module in sequence.

**Key Inputs (user-configurable globals):**

| Global | Description |
|---|---|
| `$version` | Vintage date string (e.g., "Apr-8-2026") |
| `$inflows` | Remittances CSV filename |
| `$path` | Root path to Microsimulations folder on SharePoint/OneDrive |
| `$dofiles` | Path to this tool folder |
| `$mpo_version` | Subfolder for the current MPO round (e.g., SM2026) |
| `$downloads` | Local downloads folder (for remittances CSV) |

**Stable globals set internally:**

| Global | Description |
|---|---|
| `$cpi_version` | DLW CPI module version (14) |
| `$cpi_base` | CPI base year (2021) |
| `$povmod` | Path to MFM all-vintages DTA on the shared drive |
| `$input_master` | Output Excel filename (input_MASTER.xlsx) |
| `$input_hhss_e` | Elasticities input file from SARMD |
| `$input_lfs_e` | Elasticities input file from SARLAB |
| `$path_mpo` | Full path to _inputs subfolder under $mpo_version |

**Country and year scope:**
- HHSS loop: BGD BTN IND MDV NPL PAK LKA, years 2000-2022
- LFS loop: same countries, years 2000-2022
- Elasticities: BGD, LKA, MDV (year windows vary by country)

**Method:**
1. Sets Stata version to 17, adjusts timeouts for Datalibweb.
2. Declares all globals and creates `$mpo_version\_inputs` directory.
3. Sequentially calls do-files 01-07 (01-04 are commented out in production runs).

**Outputs:** Directory structure; downstream outputs come from each called module.

---

### `00_master_informality.do` — Entry Point (Informality Variant)

**Objective:** Identical structure to `00_master.do` but routes through the informality-based input and elasticity files, and restricts the elasticities scope to MDV only.

**Key differences from `00_master.do`:**
- Calls `01_inputs_hhss_informality.do` instead of `01_inputs_hhss.do`
- Calls `05_elasticities_informality.do` instead of `05_elasticities.do`
- Declares an additional global `$input_hhss_e_inf` pointing to `inputs_hhss_elasticities_inf.dta`
- Elasticities country scope: MDV only (2009-2019)

**Outputs:** Same as `00_master.do` but with informality-variant files.

---

### `01_inputs_hhss.do` — Household Survey Inputs (Standard)

**Objective:** Loop over all SAR countries and available survey years in SARMD, compute weighted labor-market aggregates, and export them alongside MPO macro data for use in elasticity estimation.

**Key Inputs:**
- **DLW Support module:** `Support_2005_CPI_v${cpi_version}_M` -> CPI and PPP deflators (`cpi2021`, `icp2021`)
- **SARMD modules per country-year:** `IND` (individual), `LBR` (labor), `INC` (income)
- **MPO macro file:** `$povmod` (MFM all-vintages DTA)
- **Globals:** `$countries_hhss`, `$init_year_hhss`, `$end_year_hhss`, `$cpi_base`, `$cpi_version`

**Active country-years (all others are skipped):**
- AFG: 2016, 2019
- BGD: 2005, 2010, 2016, 2022
- IND: 2004, 2009, 2011
- MDV: 2009, 2016, 2019
- NPL: 2022
- PAK: 2018
- LKA: 2006, 2009, 2012, 2016, 2019

**Method (per country-year):**
1. Load CPI/PPP deflators from DLW Support module.
2. Load and merge SARMD modules IND + LBR + INC.
3. Define working-age sample: `age > 14`.
4. Harmonize `lstatus_year` (employment status) and `occup_year`.
5. **Skill classification:** Skilled = ISCO 1-3, or ISCO 4-8 with complete secondary or above (`educat7 in {5,6,7}`); Unskilled = ISCO 9 or intermediate occupations with less than complete secondary.
6. Define `public_job` (ocusec == 1 among employed).
7. Recode `industrycat10` to 3-sector variable: 1=Agriculture, 2=Industry, 3=Services. Public jobs are assigned to Services.
8. Deflate labor income to 2021 PPP USD: `ip_ppp = ip / cpi2021 / icp2021`. BGD and NPL divide ip by 12 first (annual to monthly conversion).
9. Generate income variables split by skill x sector (`ip_sk_1/2/3`, `ip_unsk_1/2/3`) and worker counts (`emp_sk_1/2/3`, `emp_unsk_1/2/3`).
10. Post weighted sums and means into a postfile: total pop, WAP, active, inactive, employed, unemployed, sectoral workers (skilled/unskilled x 3 sectors), average incomes.
11. Append MPO macro series (GDP, sectoral GDP, population, private consumption) from the most recent MFM vintage.

**Special cases:**
- NPL 2022: `lstatus` is reconstructed from raw questionnaire variables.
- BGD 2022: `lstatus_year` updated for informal-sector workers with non-zero `ip`.

**Outputs:**
- `$path_mpo\inputs_hhss.dta` — long-format labor market aggregates
- `$path_mpo\inputs_hhss_elasticities.dta` — HHSS aggregates appended with MPO macro data
- Excel sheet `input_hhss` in `input_MASTER.xlsx`

---

### `01_inputs_hhss_IND.do` — India PLFS Inputs

**Objective:** Produce the same labor-market aggregates as `01_inputs_hhss.do` but using India's Periodic Labor Force Survey (PLFS) panel file instead of SARMD, covering 2017-2023.

**Key Inputs:**
- **PLFS compiled file:** `IND_allyears_PLFS_V1_final_v01_M_cpi_microsim.dta` (local path)
- Pre-existing variables in the file: `weight`, `sample`, `lstatus_year`, `emp_sk_1/2/3`, `emp_unsk_1/2/3`, `ip_total`, `ip_sk`, `ip_unsk`, `ip_sk_1/2/3`, `ip_unsk_1/2/3`
- **MPO macro file:** `$povmod`

**Method:**
1. Load the pre-processed PLFS panel.
2. Loop over unique years in the data.
3. Post identical weighted statistics as `01_inputs_hhss.do` (pop, WAP, active, inactive, employed, unemployed, sectoral workers and incomes by skill x sector).
4. Append MPO macro series.

**Outputs:**
- `$path_mpo\inputs_hhss_IND.dta`
- `$path_mpo\inputs_hhss_elasticities_IND` (DTA)
- Excel sheet `input_hhss_IND` in `input_MASTER.xlsx`

---

### `01_inputs_hhss_informality.do` — Household Survey Inputs (Informality Variant)

**Objective:** Same structure as `01_inputs_hhss.do` but classifies workers by **formality/informality** instead of skill level. Currently scoped to MDV (2009, 2016, 2019).

**Key Inputs:** Same as `01_inputs_hhss.do`.

**Key methodological difference — Informality classification:**
- Wage/salary workers (`empstat == 1`): informal if `socialsec == 0`.
- Self-employed and other (`empstat != 1`): informal if `educat4 != 4` (less than tertiary).
- Public jobs are classified as formal Services.

**Variables generated (replacing skill split):**
- `ip_inf_1/2/3`, `ip_for_1/2/3` — average income by informality x sector
- `emp_inf_1/2/3`, `emp_for_1/2/3` — worker counts by informality x sector

**Outputs:**
- `$path_mpo\inputs_hhss_inf.dta`
- `$path_mpo\inputs_hhss_elasticities_inf.dta`
- Excel sheet `input_hhss_inf` in `input_MASTER.xlsx`

---

### `02_inputs_lfs.do` — Labor Force Survey Inputs

**Objective:** Replicate the same labor-market aggregates as `01_inputs_hhss.do` but using SARLAB (labor force survey) data, providing more recent and higher-frequency coverage.

**Key Inputs:**
- **DLW Support module:** CPI/PPP deflators (same as 01)
- **SARLAB data:** loaded via `dlw, t(sarlab)`
- **Active country-years:**
  - BGD: 2005, 2010, 2013, 2015, 2016, 2022
  - BTN: 2018, 2019, 2020
  - IND: 2020, 2021, 2022, 2023
  - NPL: 2017
  - PAK: 2013, 2017, 2018, 2020
  - LKA: 2019, 2020, 2021, 2022

**Key differences from `01_inputs_hhss.do`:**
- Labor income variable is `wage_nc` (net cash wage) rather than `ip`.
- `lstatus_year` is overridden: anyone with non-zero `wage_nc` is classified as employed.
- No INC module merge needed.

**Method:** Identical structure to `01_inputs_hhss.do` after loading and merging CPI data.

**Outputs:**
- `$path_mpo\inputs_lfs.dta`
- `$path_mpo\inputs_lfs_elasticities.dta`
- Excel sheet `input_lfs` in `input_MASTER.xlsx`

---

### `03_inputs_microsims.do` — Microsimulated Data Inputs

**Objective:** Extract labor-market aggregates from previously simulated (counterfactual) micro-datasets and export them in the same long format as the survey-based inputs.

**Key Inputs:**
- All `.dta` files in the `$data` directory; file names follow `CCC_YYYY.dta` naming convention
- Expected variables: `fexp_s` (expansion factor), `edad`, `occupation_s`, `lai_m_s` (monthly labor income), `pc_inc_s`, `cohh`

**Occupation coding in simulated files:**

| `occupation_s` | Meaning |
|---|---|
| 0 | Inactive |
| 1 | Unemployed |
| 2 | Formal agriculture |
| 3 | Informal agriculture |
| 4 | Formal industry |
| 5 | Informal industry |
| 6 | Formal services |
| 7 | Informal services |

**Method:**
1. Loop over all `.dta` files in `$data`; parse country (chars 1-3) and year (chars 5-8) from filename.
2. Keep coherent households (`cohh == 1 & pc_inc_s != .`).
3. Define sample as age 15-64.
4. Construct `pea`, `ocupado`, `desocupa`, `d_informal`, `sector_3` from `occupation_s`.
5. Generate income variables: `ip_formal/informal x sector`.
6. Post weighted worker counts and average incomes into postfile.

**Outputs:**
- `$path\input-labor-microsimulated.dta`
- Versioned copy: `inputs_version_control\input-labor-microsimulated_${version}.dta`
- Excel sheet `input-labor-microsimulated` in `input_MASTER.xlsx`

---

### `04_merge_inputs_labor.do` — Merge Labor Inputs

**Objective:** Combine SEDLAC/SARMD survey-based inputs and microsimulated inputs into a single deduplicated file, and export to the master Excel.

**Key Inputs:**
- `$path\input-labor-sedlac.dta`
- `$path\input-labor-microsimulated.dta`

**Method:**
1. Load SEDLAC file and tag as `Source = "SEDLAC"`.
2. Append microsimulated file; tag as `Source = "Microsims"`.
3. Check for duplicates on `Country x Year x Indicator`. If duplicates exist, execution halts with an error.
4. If no duplicates, sort and export.

**Outputs:**
- Excel sheet `input-labor` in `input_MASTER.xlsx`
- Optional copy to SharePoint share path if `$mpo_share == 1`

---

### `05_elasticities.do` — Elasticity Estimation (Standard / Skill-based)

**Objective:** Estimate the historical responsiveness of employment and wages to GDP growth for each SAR country, producing a menu of elasticity estimates under multiple methodological approaches for the analyst to choose from.

**Key Inputs:**
- `$path_mpo/$input_hhss_e` (`inputs_hhss_elasticities.dta`) — stacked HHSS + MPO data
- Globals: `$countries`, `$min_year`, `$last_year` — parallel word lists (one entry per country)

**Data preparation:**
1. Load elasticity input file; reshape from long to wide on Indicator.
2. Rename GDP series: `agri` -> `gdp1`, `indus` -> `gdp2`, `serv` -> `gdp3`.
3. Compute aggregate workers by sector and skill level.
4. Compute sector-level **productivities**: `prod_X = gdpX / workers_X`.
5. Take logs of all employment, GDP, and income variables.
6. Compute year-on-year **growth rates**.
7. Compute **annual elasticities**: `elas = growth_workers / growth_gdp` (employment) and `elas = growth_income / growth_productivity` (wages).
8. Create interaction term: `iteration = ln_gdp x unskilled_rate`.
9. Export annual elasticities to sheet "Elasticities by year".

**Elasticity estimation methods (per country, per period):**

| Method code | Description |
|---|---|
| `avg` | Simple arithmetic mean of annual elasticities |
| `avg_1_99` | Mean excluding observations outside the 1st-99th percentile |
| `avg_1_99_imp` | Mean with outliers replaced by the period median before averaging |
| `reg` | OLS regression of ln(workers) on ln(gdp_sector) |
| `med_reg` | Quantile (median) regression — skipped for BGD, LKA, MDV (small samples) |
| `reg_gdp` | OLS with sector GDP + total GDP as regressors |
| `reg_iter` | OLS with sector GDP + interaction term (ln_gdp x unskilled rate) |

**Elasticities estimated:**
- `gdp_activity`: total GDP -> active population
- `gdp_sk_1/2/3`: sector GDP -> skilled workers in each sector
- `gdp_unsk_1/2/3`: sector GDP -> unskilled workers in each sector
- `prod_sk_1/2/3`: sector productivity -> average skilled income in each sector
- `prod_unsk_1/2/3`: sector productivity -> average unskilled income in each sector

**Outputs:**
- `$path_mpo\elasticities.dta`
- `$path_mpo\elasticities_${version}.dta` (versioned copy)
- Excel sheet "Elasticities" in `input_MASTER.xlsx`
- Excel sheet "Elasticities by year" with the annual elasticity series

---

### `05_elasticities_IND.do` — Elasticity Estimation (India PLFS)

**Objective:** Produce the same elasticity menu as `05_elasticities.do` but for India only, using the PLFS-based input file covering 2017-2023.

**Key differences from `05_elasticities.do`:**
- Hardcoded country: IND; period: 2017-2023.
- Input file: `$path_mpo\inputs_hhss_elasticities_IND`.
- Median regression is commented out (insufficient time series length).
- Annual elasticities exported to sheet "Elasticities by year IND".

**Outputs:**
- `$path_mpo\elasticities_IND.dta`
- `$path_mpo\elasticities_IND_${version}.dta`
- Excel sheets "Elasticities IND" and "Elasticities by year IND" in `input_MASTER.xlsx`

---

### `05_elasticities_informality.do` — Elasticity Estimation (Informality Variant)

**Objective:** Same methodology as `05_elasticities.do` but replaces the skilled/unskilled worker split with a **formal/informal** split.

**Key differences:**
- Input file: `$path_mpo/$input_hhss_e_inf` (`inputs_hhss_elasticities_inf.dta`).
- Worker variables renamed from `*skilled*`/`*unskilled*` to `*for*`/`*inf*`.
- Informality rate replaces unskilled rate in the interaction term: `iteration = ln_gdp x inf_rate`.
- All elasticities are computed for `for` (formal) and `inf` (informal) workers and incomes instead of skilled/unskilled.
- Median regression is included for countries outside {BGD, LKA, MDV}.

**Outputs:**
- `$path_mpo\elasticities_inf.dta`
- `$path_mpo\elasticities_inf_${version}.dta`
- Excel sheets "Elasticities inf" and "Elasticities by year, Inf" in `input_MASTER.xlsx`

---

### `06_inputs_macro.do` — Macro GDP and Population Inputs

**Objective:** Pull population projections from WDI and GDP/private consumption projections from the MFM database, merge them, and export to `input_MASTER.xlsx`.

**Key Inputs:**
- **WDI via `wbopendata`:** Indicators `SP.POP.TOTL`, `SP.POP.1564.TO`, `SP.POP.65UP.TO` (years 2004-2030, with projections)
- **MFM all-vintages file:** `$povmod` — variables: `pop`, `privconstant`, `gdpconstant`, `agriconstant`, `indusconstant`, `servconstant`

**Method:**
1. **WDI population:** Load for SAR countries; sum 15-64 and 65+ to get working-age population 15+; compute share `pop_15up / pop_total`; save `inputs_pop.dta`.
2. **MFM macro:** Load all-vintages file; retain only the most recent MPO vintage (maximum date); keep SAR countries; save `inputs_mpo_gdp.dta`.
3. **Merge:** Join on `countrycode x year`; compute `pop_15up = pop x share_pop`.
4. Rename to standard `v_` prefix variables and reshape to long format (Country, Year, Indicator, Value).
5. Drop observations with missing values and export.

**Output indicators (long format):**

| Indicator | Description |
|---|---|
| `v_priv` | Private consumption (constant USD) |
| `v_gdp` | Total GDP (constant USD) |
| `v_gdp_agriculture` | Agricultural GDP (constant USD) |
| `v_gdp_industry` | Industrial GDP (constant USD) |
| `v_gdp_services` | Services GDP (constant USD) |
| `v_pop_15up` | Working-age population (15+) |
| `v_pop_total` | Total population |

**Outputs:**
- `$path_mpo\inputs_pop.dta`
- `$path_mpo\inputs_mpo_gdp.dta`
- `$path_mpo\input_mpo_all.dta`
- Excel sheet "input-mpo" in `input_MASTER.xlsx`

---

### `07_exports_inflows.do` — Remittance Inflows

**Objective:** Retrieve remittance inflow data (Exports – Remittance Inflows, USD millions) and country CPI from the MFMod live data portal, and export them in long format to `input_MASTER.xlsx`.

**Key Inputs:**
- CSV file `${inflows}.csv` downloaded from `https://mtimodelling.worldbank.org/livempodata/mpodata.html`
  - Series: `cBXFSTREMTCD` (remittance inflows); `FPCPITOTLXN` (CPI)
- Globals: `$inflows` (filename), `$downloads` (download folder), `$date_inflows`

**Automated download (optional, requires Python + conda packages):**
A commented-out Python block using `selenium` and `webdriver_manager` can automate the entire download:
countries selected: AFG, BGD, BTN, IND, MDV, NPL, PAK, LKA.
Required packages: `selenium==4.21.0`, `webdriver_manager==4.0.1`.

**Method (data preparation):**
1. Copy CSV from downloads folder to `$path_mpo`.
2. Import CSV: rename columns using year values in row 1.
3. Drop pre-2001 years and empty rows.
4. Destring all numeric columns.
5. Map country names to ISO-3 codes.
6. Parse indicator from series code suffix (`TREMTCD` -> Inflows; `ITOTLXN` -> CPI).
7. Reshape wide to long on year.
8. Append date stamp and export.

**Outputs:**
- Excel sheet "inflows" in `input_MASTER.xlsx` with variables: `country`, `indicator`, `year`, `value`, `date`

---

### `CPIs_no_dlw.do` — CPI Construction Without Datalibweb (Utility Snippet)

**Objective:** Standalone utility snippet (not called by any master file) for constructing CPI series from the World Bank Inflation Database when Datalibweb is unavailable. Also contains a BGD LFS wage adjustment block as a reference example.

**Key Inputs:**
- World Bank Inflation Database ZIP (downloaded from thedocs.worldbank.org)
- SARLAB BGD data (for the wage deflation example)
- DLW Support module (for PPP)

**Method:**
1. Download and unzip the Inflation Database.
2. Load `hcpi_m.dta` (monthly headline CPI).
3. Compute annual CPI by averaging monthly values; normalize to 2017 base.
4. Extract PPP for Bangladesh from DLW Support module.
5. Compute real wage adjustments for BGD LFS rounds (2010, 2016, 2022) using wave-specific CPIs.

**Note:** This is a code reference/template, not part of the standard pipeline.

---

### `_country_folders.do` — Country Folder Scaffolding (Utility)

**Objective:** One-off helper to create empty country-level subfolders for a new MPO round in both a shared Z-drive and SharePoint paths.

**Note:** Originally written for the LAC regional model (country list: ARG BOL BRA CHL COL CRI DOM ECU SLV GTM HND MEX NIC PAN PRY PER URY). Not used in the SAR production pipeline, but can be repurposed by updating the `$countries` global and the path globals.

---

## Summary of Outputs Written to `input_MASTER.xlsx`

| Excel Sheet | Produced by | Description |
|---|---|---|
| `input_hhss` | `01_inputs_hhss.do` | Weighted labor stats from SARMD surveys |
| `input_hhss_IND` | `01_inputs_hhss_IND.do` | India PLFS labor stats (2017-2023) |
| `input_hhss_inf` | `01_inputs_hhss_informality.do` | SARMD stats with formal/informal split |
| `input_lfs` | `02_inputs_lfs.do` | Weighted labor stats from SARLAB surveys |
| `input-labor-microsimulated` | `03_inputs_microsims.do` | Stats from simulated datasets |
| `input-labor` | `04_merge_inputs_labor.do` | Unified survey + simulated labor inputs |
| `Elasticities by year` | `05_elasticities.do` | Annual GDP/productivity elasticities (all countries) |
| `Elasticities` | `05_elasticities.do` | Aggregated elasticity estimates by method |
| `Elasticities by year IND` | `05_elasticities_IND.do` | Annual elasticities for India (PLFS) |
| `Elasticities IND` | `05_elasticities_IND.do` | Aggregated elasticities for India |
| `Elasticities by year, Inf` | `05_elasticities_informality.do` | Annual elasticities (informality variant) |
| `Elasticities inf` | `05_elasticities_informality.do` | Aggregated elasticities (informality variant) |
| `input-mpo` | `06_inputs_macro.do` | GDP, sectoral GDP, population (MPO/WDI) |
| `inflows` | `07_exports_inflows.do` | Remittance inflows and CPI from MFMod |

---

## Key Variable Definitions

| Concept | Variable / Rule |
|---|---|
| Working-age sample | `age > 14` (surveys) or `age 15-64` (microsims) |
| Skilled worker | ISCO 1-3, or ISCO 4-8 with complete secondary+ (`educat7 in {5,6,7}`) |
| Unskilled worker | ISCO 9, or ISCO 4-8 with less than complete secondary |
| Formal worker (inf. variant) | Salaried with social security (`socialsec = 1`), or non-salaried with tertiary education |
| Informal worker (inf. variant) | Opposite of formal |
| Sector 1 | Agriculture (`industrycat10 = 1`) |
| Sector 2 | Industry (`industrycat10 in {2,3,4,5}`) |
| Sector 3 | Services (`industrycat10 in {6,7,8,9,10}`); public jobs always assigned here |
| Labor income — surveys | `ip` deflated: `ip / cpi2021 / icp2021` (divide by 12 first for BGD and NPL) |
| Labor income — LFS | `wage_nc / cpi2021 / icp2021` |
| Productivity | `gdpX / workers_X` (constant USD per worker, by sector) |
