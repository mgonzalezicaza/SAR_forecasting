# How the India Poverty Forecasting Model Works
### A Plain-Language Guide for the Non-Expert

**Project:** SAR Forecasting — World Bank ESAPV  
**Covers:** All three pipelines — `tool`, `model/india`, and `results`  
**Last updated:** May 2026

---

## The Big Picture

The goal of this project is to answer a simple but important question:

> **If India's economy grows at X% next year, what happens to poverty?**

We cannot directly observe the future. But we have two things that, combined, let us make a well-informed projection:

1. **A household survey** — a snapshot of ~100,000 Indian households, showing exactly how much each person earns, what sector they work in, what transfers they receive, and what they consume. This is the PLFS (Periodic Labor Force Survey).

2. **Macro forecasts** — the World Bank's official projections for India's GDP growth, employment, wages, population, remittances, and private consumption. These come from the Macro-Poverty Outlook (MPO) database.

The model's job is to **take the macro story and translate it into micro consequences** — to simulate what happens to each household in the survey if the economy evolves as the macro team expects.

The result is a projected distribution of consumption/income for 2024, 2025, 2026, 2027, and 2028 — from which poverty rates, Gini coefficients, and detailed profiles of who is poor can be computed.

---

## The Three Pipelines

The project is organized in three sequential stages:

```
┌──────────────────────────────────────────────────────────────┐
│  STAGE 1: TOOL                                               │
│  "Prepare all the ingredients"                               │
│  dofiles/tool/                                               │
│  → Computes elasticities and formats macro inputs            │
└─────────────────────────┬────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 2: MODEL                                              │
│  "Run the simulation"                                        │
│  dofiles/model/india/                                        │
│  → Applies macro shocks to each household one step at a time │
└─────────────────────────┬────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 3: RESULTS                                            │
│  "Summarize and report"                                      │
│  dofiles/results/                                            │
│  → Computes poverty rates, inequality, and profiles          │
└──────────────────────────────────────────────────────────────┘
```

---

# STAGE 1 — TOOL: Preparing the Ingredients

**Folder:** `dofiles/tool/`  
**Main file:** `00_master.do`  
**Output:** A single Excel workbook — `input_MASTER.xlsx`

This stage does not run the simulation yet. It is entirely about **gathering and organizing the numbers that the simulation will consume**.

---

### Step 1.1 — Extract labor market statistics from household surveys (`01_inputs_hhss.do` / `01_inputs_hhss_IND.do`)

**What it does:**  
Goes into the World Bank's microdata archive (Datalibweb/SARMD) and, for each available survey year in South Asia, computes a set of summary statistics:

- How many people work in agriculture, industry, and services?
- Of those, how many are skilled vs. unskilled?
- What is the average wage in each of these six groups?
- What share of the working-age population is employed? Unemployed? Inactive?

For India specifically, it uses the PLFS compiled panel (2017–2023) rather than the general SARMD archive, because India is not in SARMD for recent years.

All income figures are converted to **2021 PPP US dollars** (a common currency that allows meaningful comparisons across countries and years, stripping out inflation and exchange rate differences).

**Why it matters:**  
These historical statistics are the baseline against which the model measures change. They are also the raw material for computing elasticities in the next step.

---

### Step 1.2 — Extract the same statistics from labor force surveys (`02_inputs_lfs.do`)

**What it does:**  
Repeats the same computation as Step 1.1, but using a different data source — SARLAB (labor force surveys). These surveys are more frequent and more recent, but have less income detail. The key income variable here is net cash wages (`wage_nc`).

**Why it matters:**  
The labor force surveys fill gaps in coverage — for example, India 2020–2023 — where the household income surveys are not available.

---

### Step 1.3 — Extract statistics from previously simulated datasets (`03_inputs_microsims.do`)

**What it does:**  
Loads any previously produced simulation output files (`.dta` files from past model runs) and extracts the same labor market statistics from them. This allows the model to track consistency across vintages.

---

### Step 1.4 — Combine all three sources into one clean file (`04_merge_inputs_labor.do`)

**What it does:**  
Stacks the outputs from Steps 1.1–1.3 into a single long-format dataset, checks for duplicates, and exports to `input_MASTER.xlsx`. From this point on, there is one authoritative table of labor market statistics by country, year, and group.

---

### Step 1.5 — Estimate elasticities (`05_elasticities.do` / `05_elasticities_IND.do`)

This is the most analytically important step in Stage 1.

**What is an elasticity?**  
An elasticity is a number that tells you: *"When GDP grows by 1%, employment (or wages) in sector X tends to grow by Y%."* It is estimated from historical data — looking at the past relationship between macro growth and labor market outcomes.

For example, if the GDP–employment elasticity in Indian services is 0.6, that means a 1% rise in services GDP historically corresponded to a 0.6% rise in services employment.

**What it does:**  
For each SAR country, for each of the six sector-skill cells (skilled/unskilled × agriculture/industry/services), it estimates **seven variants** of each elasticity:

| Method | Description |
|---|---|
| Simple average | Average of year-on-year elasticities |
| Trimmed average | Same, but drops extreme outliers (outside 1st–99th percentile) |
| Imputed average | Outliers are replaced by the period median before averaging |
| OLS regression | Regresses log employment on log GDP |
| Median regression | OLS but minimizes absolute deviations (more robust to outliers) |
| OLS with aggregate GDP | Adds economy-wide GDP as additional control |
| OLS with interaction | Adds interaction between GDP and the unskilled employment share |

The analyst then inspects all seven estimates and selects the most credible one for the simulation. Having multiple methods is a feature, not a bug — it shows how sensitive the results are to estimation choices.

For India, a separate do-file (`05_elasticities_IND.do`) runs the same estimation but exclusively on the PLFS panel (2017–2023), since that is the most relevant recent history for India.

---

### Step 1.6 — Pull macro projections from the MPO database (`06_inputs_macro.do`)

**What it does:**  
Connects to the World Bank's Macro-Fiscal Model (MFM) database and downloads:

- **GDP forecasts** — total and by sector (agriculture, industry, services) — in constant USD.
- **Private consumption forecasts** — the macro aggregate that corresponds most closely to household welfare.
- **Population projections** — from WDI (World Development Indicators), split by total, working-age (15+), and elderly (65+).

These are all stored in a standard long format: one row per country-year-indicator.

---

### Step 1.7 — Download remittance inflows (`07_exports_inflows.do`)

**What it does:**  
Fetches remittance inflow projections (in USD millions) and country CPIs from the World Bank's MFMod live data portal. These feed directly into the non-labor income component of the simulation.

---

### What comes out of Stage 1?

One Excel file: **`input_MASTER.xlsx`**, with ~14 sheets. This file contains everything the simulation needs:
- Weighted employment and wage statistics by sector and skill (historical)
- Estimated elasticities (GDP-to-employment, productivity-to-wages)
- Macro projections (GDP, consumption, population, remittances)

The analyst reviews this file before running the model, and can manually adjust any input for scenario analysis.

---

# STAGE 2 — MODEL: Running the Simulation

**Folder:** `dofiles/model/india/`  
**Main file:** `00_master.do`  
**Survey data:** PLFS 2023 (~100,000 households)  
**Simulation horizon:** 2024 to 2028 (one year at a time)

This is the core of the project. The model takes the 2023 PLFS microdata and, year by year, updates each household to reflect how the economy has evolved according to the macro projections.

The key insight is that **the simulation is not a regression or a forecast model in the statistical sense**. It is a **sequential microsimulation**: the survey is used as a starting point, and the macro growth rates are applied to move people and incomes around in a way that is consistent with both the micro structure and the macro aggregates.

---

### Step 2.0 — Load data and set parameters (`00_master.do`, `01_parameters.do`)

**What it does:**  
- Loads the PLFS 2023 microdata.
- Reads all the macro growth matrices from the Excel input file into Stata memory.
- Sets the scenario flags: which year is being simulated, whether to use GDP rescaling, which remittance allocation method to use, etc.

**Key matrices loaded:**

| Matrix | What it contains |
|---|---|
| `growth_labor_income` | How much wages should grow in each of 6 sector-skill cells |
| `growth_macro_data` | GDP growth by sector (agriculture, industry, services) |
| `growth_labor` | Target activity rate, unemployment rate, and employment shares |
| `growth_nlabor` | Growth for pensions, capital income, remittances |
| `growth_pop_wdi` | Target total population |

---

### Step 2.1 — Construct all working variables (`02_variables.do`)

**What it does:**  
Takes the raw PLFS variables and creates the clean, consistently defined variables the model needs:

- Employment status: employed, unemployed, inactive
- Sector: agriculture, industry, services (3-way or 6-way with skilled/unskilled)
- Income: primary labor income, secondary income, non-labor income components (pensions, remittances, capital, social transfers)
- Controls for regressions: education, age, gender, household size, region, etc.
- Converts everything to **2021 PPP US dollars per month**

Think of this as the "data cleaning and variable construction" step.

---

### Step 2.2 — Estimate the occupation choice model (`03_occupation.do`)

**What it does:**  
Estimates a **multinomial logit model** of labor market status. This model predicts the probability that a person is inactive, unemployed, or employed in one of six sector-skill cells, given their observable characteristics (age, gender, education, region, household structure, etc.).

The model then extracts the **unexplained part** (residuals) — called latent utility scores `U0` through `U7`. These capture everything about a person's labor market attachment that we cannot see in the data.

**Why it matters:**  
When the model needs to reallocate people between sectors or labor force statuses in later steps, it uses these scores as a ranking device. Rather than randomly picking who moves, it moves the people who are "most on the margin" — those whose residual utility for their current status is the weakest. This makes the simulation behaviorally consistent.

---

### Step 2.3 — Estimate wage regressions by sector (`04_labor_income.do`)

**What it does:**  
Estimates three separate **OLS regressions** of log wages — one for agriculture, one for industry, one for services. The right-hand side includes age, education, gender, region, and employment type.

The model saves:
- The **coefficient vectors** (`b_1`, `b_2`, `b_3`): used to predict wages for workers who switch sectors.
- The **residual standard errors** (`sigma_1`, `sigma_2`, `sigma_3`): used to add realistic noise to those predictions.

**Why it matters:**  
When a worker moves from agriculture to services, we need to assign them a plausible wage in their new sector. We cannot just give them the average — we should use their individual characteristics (education, age, region) to predict a wage that fits them. That is what these regressions enable.

---

### Step 2.4 — Update population weights (`05_population.do`)

**What it does:**  
Adjusts the survey's sampling weights so that the weighted population matches the WDI population projection for the simulation year.

There are two methods:
- **Entropy balancing (re-weighting):** Adjusts weights so that the age-gender distribution of the simulated population matches the target structure — useful when the population is aging or the gender composition is changing.
- **Neutral scaling:** Simply multiplies all weights by a single factor equal to `(target population / current population)`. Simpler, but ignores demographic composition.

**Why it matters:**  
The survey represents 2023. By 2028, India will have more people, with a somewhat different age structure. If we do not adjust the weights, our poverty counts will be wrong.

---

### Step 2.5 — Update labor force participation (`06_activity.do`)

**What it does:**  
The macro input file contains a target labor force participation rate for the simulation year. This step reshuffles who is "active" (employed or unemployed) vs. "inactive" (out of the labor force) to hit that target.

**Method:**  
Sort people by their latent utility residual for inactivity (`U0`). Those with the weakest "pull" toward inactivity are the first to become active (or first to drop out). The cumulative sum of weights determines where the cutoff falls.

**Output:** `active_s` — a binary indicator (1=active) that replaces the observed 2023 status.

---

### Step 2.6 — Update the unemployment rate (`07_unemployment.do`)

**What it does:**  
Among those now classified as active (`active_s == 1`), reshuffles who is employed vs. unemployed to hit the target unemployment rate.

**Method:** Same ranking logic as Step 2.5 — uses `U1` (the latent utility for unemployment) to determine who moves between employed and unemployed status.

**Output:** `emplyd_s` and `unemplyd_s` — simulated employment indicators.

---

### Step 2.7 — Update sector and skill structure of employment (`08_struct_emp.do`)

This is the most complex labor market step.

**What it does:**  
Among those now classified as employed, reshuffles who works in which sector (agriculture, industry, services) and with what skill level (skilled, unskilled), to match the target employment shares from the macro input.

**Method (in plain language):**

1. Calculate how many workers each sector should have (the target).
2. Sectors that are *shrinking*: remove workers starting with those who have the weakest "preference" for that sector (lowest latent utility score). These workers become "displaced."
3. Sectors that are *growing*: fill vacancies first from displaced workers, then from the newly unemployed, then from the newly activated. This mirrors the real-world job-finding queue.
4. Any remaining unassigned workers are distributed proportionally.
5. Within each broad sector, the skilled/unskilled split is updated to match the target from the intrasectoral growth matrix.

**Output:** `occupation_s` — an 8-category variable encoding each person's new labor market status and sector-skill cell.

---

### Step 2.8 — Assign wages to workers who changed sector (`09_asign_labor_income.do`)

**What it does:**  
Workers who stayed in the same sector keep their observed 2023 wage. Workers who moved to a different sector receive a **predicted wage** in their new sector, using the OLS coefficients from Step 2.3.

Specifically:
- Predicted log wage = individual characteristics multiplied by sector-specific OLS coefficients
- A random noise term drawn from a normal distribution (with standard deviation = the sector's regression RMSE) is added
- The result is exponentiated to recover the wage in levels

Workers who became unemployed or inactive receive a missing income.

**Output:** `lai_m_s` — simulated primary labor income for each individual.

---

### Step 2.9 — Scale wages to macro targets (`10_income_rel_new_no_rescaling.do`)

**What it does:**  
After assigning wages to sector movers, the aggregate wage bill in each sector-skill cell will not perfectly match the macro-projected wage growth. This step applies a **calibration factor** to scale everyone's wages within each cell so that the average wage in that cell matches the target from `growth_labor_income`.

For India, this is done **without** additional rescaling to match GDP totals — only the micro labor income growth rates are targeted.

**Output:** `lai_m_s` scaled to match the micro wage growth targets.

---

### Step 2.10 — Compute total labor income (`11_total_labor_income.do`)

**What it does:**  
Adds primary and secondary job labor income together to get total individual labor income.

---

### Step 2.11 — Update non-labor income (`12_assign_nlai.do` and sub-files)

**What it does:**  
Projects each component of non-labor income separately:

| Component | Method |
|---|---|
| **Pensions** | Multiply by the pension growth rate from the input file, adjusted for population change |
| **Capital income** | Same, using the capital growth rate |
| **PDS food subsidy** | Hard-coded nominal expenditure values by scenario year, reflecting known budget allocations |
| **Other government schemes** | Same as PDS |
| **Domestic remittances** | Either neutral scaling (multiply all recipients proportionally) or random reallocation (new recipients drawn probabilistically) |
| **International remittances** | Same two options |
| **Other non-labor income** | Held constant in real terms |
| **Imputed rent** | Held constant in real terms |

After all components are updated, they are summed into `h_nlai_s` — total simulated household non-labor income.

---

### Step 2.12 — Aggregate to household income (`13_household_income.do`)

**What it does:**  
Aggregates all simulated individual labor incomes to the household level, then adds household non-labor income:

```
h_inc_s = sum(tot_lai_s for all members) + h_nlai_s
ipcf_ppp_s = h_inc_s / household_size
```

---

### Step 2.13 — Update the income-to-consumption ratio (`15_income_to_consumption.do`)

**What it does:**  
The PLFS is primarily a labor force and income survey. For poverty measurement, we need **consumption** — what households actually spend. These two are not the same; the gap between income and consumption varies systematically across households.

This step uses a **nearest-neighbor matching** approach: for each household, it finds the most similar household in the survey (in terms of income level, sector, education, demographics) and borrows that household's observed income-to-consumption ratio. The matched ratio is then applied to the simulated income to produce a simulated consumption estimate.

**Why it matters:**  
This is crucial for India specifically. The national poverty line is defined in consumption terms, and the relationship between income and consumption varies by household type. This step preserves that heterogeneity rather than applying a uniform conversion factor.

---

### Step 2.14 — Compute new consumption (`16_new_consumption.do`)

**What it does:**  
Applies the matched ratio to produce `welfare_s` — the simulated per-capita consumption for each household:

    welfare_s = pc_inc_s / new_ratio

For households where the ratio is zero or negative (edge case), welfare is set to `welfare_base × (1 + private consumption growth)` as a fallback.

> **Note for India:** The optional macro rescaling step (`$cons_re_scale`) is **turned off** (`"no"`) in the India run. This means the model does *not* force aggregate simulated consumption to match the national-accounts private consumption growth rate. The income-to-consumption matching in Step 2.13 is sufficient to bridge income to consumption without an additional macro anchor. The rescaling option remains available for other country runs.

---

### Step 2.15 — Save output (`17_output.do`)

**What it does:**  
Saves the final simulated dataset with clean variable labels. Also computes and displays:

- Poverty headcounts at three international lines ($3.00, $4.20, $8.30 per day in 2021 PPP)
- National poverty rate
- Gini coefficient

The file is saved as `IND_YYYY.dta` for each simulation year and as a combined multi-year file.

---

### How one year feeds into the next

The model runs **year by year**. After completing 2024, the output dataset becomes the new baseline for 2025. Shocks accumulate: if the employment structure shifted in 2024, the 2025 simulation starts from that new structure.

---

# STAGE 3 — RESULTS: Summarizing and Reporting

**Folder:** `dofiles/results/`  
**Main file:** `00_master.do`  
**Output:** `Results_IND.xlsm`

This stage takes all the simulation output files (both actual survey years and simulated years) and produces the summary statistics, charts, and tables needed for the Macro-Poverty Outlook.

---

### Step 3.0 — Load and harmonize all years (`01_data.do`)

**What it does:**  
Loads up to 6 years of data — a mix of actual survey years (pulled from the World Bank archive) and simulated years (from the model output). Harmonizes them into a single stacked dataset.

The `data` matrix (read from an Excel availability sheet) tells the code which years are actual observations and which are simulations. All income and welfare variables are converted to **2021 PPP US dollars per capita per month**.

---

### Step 3.1 — Construct analytical variables (`02_variables.do`)

**What it does:**  
Builds all variables needed for the analysis:

- **Poverty dummies** at three international lines: $3.00, $4.20, and $8.30 per day
- **National poverty line** indicator
- **Poverty gap** (how far below the line the poor are, as a share of the line)
- **Prosperity Gap** (how far the entire income distribution is from a $28/day standard)
- **Gini and Theil inequality indices**, computed year by year
- **Labor market variables**: sector shares, skill shares, average wages by cell
- **Non-labor income per capita**: broken into remittances, pensions, capital, public transfers
- **Demographic variables**: age groups, gender, urban/rural

---

### Step 3.2 — Static poverty profiles (`03_static_profiles.do`)

**What it does:**  
Produces a detailed cross-sectional profile of ~40 socioeconomic indicators separately for each poverty category:

- Extreme poor (below $3.00/day)
- Moderately poor (between $3.00 and $4.20)
- Vulnerable (between $4.20 and $8.30)
- Non-poor (above $8.30)
- Total population

For each group and each year, it computes shares by sector of employment, education, age group, gender, rural/urban residence, and income source.

Also updates the shared regional file `poverty_SAR.dta` with India's latest projected poverty rates — the database used for MPO tables across all South Asian countries.

---

### Step 3.3 — Growth Incidence Curves (`04_gics.do`)

**What it does:**  
A Growth Incidence Curve shows: *"For each percentile of the welfare distribution, by what percentage did average welfare grow between year X and year Y?"*

If the curve is steeper at the bottom (higher growth for the poor), growth was pro-poor. If it slopes downward, the rich gained more.

This step computes GICs for the national distribution, urban households, and rural households separately. Output is exported to three Excel sheets, ready for chart production.

---

### Step 3.4 — Poverty transition matrices (`05_transition_matrix.do`)

**What it does:**  
For each pair of consecutive simulated years, constructs a **transition matrix** showing how many people moved between poverty categories:

- How many who were poor in year T are still poor in year T+1?
- How many escaped poverty?
- How many fell into poverty?
- How many were non-poor in both years?

This is important because aggregate poverty rates can be stable while there is a lot of churning at the bottom of the distribution.

---

### Step 3.5 — Dynamic poverty profiles (`06_dynamic_profiles.do`)

**What it does:**  
For each simulated year, classifies the population into four mobility groups:

| Group | Definition |
|---|---|
| **New poor** | Not poor last year, poor this year |
| **Always poor** | Poor both years |
| **New non-poor** | Poor last year, not poor this year (escaped poverty) |
| **Always non-poor** | Not poor in either year |

For each group, it computes the same ~30 socioeconomic indicators as the static profiles. This tells us: *"Who are the people falling into poverty? What do they look like compared to those who escaped?"* This is the main input for the narrative in MPO country notes.

---

### Step 3.6 — WDI population series (`07_pop_wdi.do`)

**What it does:**  
Extracts the most recent vintage of MFM population projections for India and exports them to the results workbook, anchoring all per-capita calculations.

---

# Summary: The Full Chain in Plain Language

Here is the entire model in one narrative:

1. **We gather historical data** on how India's labor market has responded to GDP growth in the past — computing the elasticity of employment and wages to GDP in each sector-skill cell.

2. **We take the World Bank's official macro forecast** for India — GDP growth by sector, employment trends, remittance inflows, population projections, private consumption growth.

3. **We start with the 2023 household survey** (PLFS) — 100,000+ households, each with observed income, sector, education, and consumption.

4. **Year by year, we update the survey** to be consistent with the macro forecast:
   - Adjust weights so the total population matches the projection.
   - Move people between active/inactive and employed/unemployed to match participation and unemployment rate targets.
   - Reallocate employed workers across sector-skill cells to match projected employment shares.
   - Assign new wages to workers who changed sector, using estimated wage equations with a stochastic noise component.
   - Scale everyone's wages so that average wages per cell match the projected wage growth.
   - Update non-labor income components (pensions, remittances, social transfers) using program-specific growth rates.
   - Convert household income to consumption using a nearest-neighbor matched income-to-consumption ratio.
   - For India, no macro rescaling is applied — consumption is anchored to the matched ratio alone (the macro private-consumption rescaling switch is off).
   - Rescale final consumption so the aggregate matches macro private consumption growth.

5. **We save the simulated household dataset** for each year (2024–2028).

6. **We compute poverty rates, inequality, profiles, and mobility statistics** from the simulated datasets and package them into the MPO reporting workbook.

The end result is a projection of India's poverty and inequality trajectory that is:
- **Consistent with the macro forecast** (GDP, employment, wages, consumption all match their targets)
- **Micro-founded** (each number comes from an actual household in the survey, not a statistical abstraction)
- **Distributional** (it tells us who gains and who loses, not just the average)

---

## Key Concepts Reference

| Concept | Plain-Language Definition |
|---|---|
| **PPP (Purchasing Power Parity)** | A conversion that lets you compare incomes across countries and years by accounting for price level differences. "$1 in PPP terms" buys the same basket of goods everywhere. |
| **Microsimulation** | Running a macro scenario through individual household data, rather than just computing aggregate averages. |
| **Elasticity** | How much one thing changes when another changes by 1%. An employment-GDP elasticity of 0.5 means 1% GDP growth → 0.5% employment growth. |
| **Multinomial logit** | A statistical model that predicts which of several categories a person belongs to (e.g., which sector-skill cell), given their observable characteristics. |
| **Latent utility residuals** | The unexplained part of the occupation model — what makes a person "more likely" to work in agriculture than their observable characteristics would predict. Used as a ranking device when reallocating workers. |
| **Entropy balancing** | A re-weighting technique that adjusts survey weights to match a target population structure while changing the weights as little as possible. |
| **Growth Incidence Curve (GIC)** | A chart showing income growth rates by percentile. Useful for assessing whether growth is pro-poor. |
| **Poverty transition matrix** | A table showing how many people moved between poverty categories between two years. |
| **Prosperity Gap** | A measure of how far the whole distribution is from a high welfare standard ($28/day). Captures deprivation even among the non-poor. |
| **Private consumption** | The national accounts aggregate for household spending. Used as the macro anchor for the final consumption simulation. |
| **MFM / MPO** | Macro-Fiscal Model / Macro-Poverty Outlook — the World Bank's internal macro forecasting infrastructure. |
| **PLFS** | Periodic Labor Force Survey — India's main labor market survey, used as the micro foundation for the simulation. |
| **SARMD / SARLAB** | South Asia Region Micro Database / Labor database — the World Bank's harmonized survey archive for South Asia. |
