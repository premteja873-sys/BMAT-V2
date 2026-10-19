# Statistical Comparison of Database Query Response Time With and Without Indexing Using R

## Project aim

This project tests whether PostgreSQL equality searches are faster with an
index than without an index. It compares No index, B+ tree (PostgreSQL
`btree`) and Hash indexing using real response-time measurements analysed in R.

## Experiment

- One PostgreSQL database: `indexing_project`
- Three table sizes: 10,000, 100,000 and 500,000 rows
- Three methods at every size: No index, B+ tree and Hash
- Nine benchmark tables in total
- Thirty matched searches per size-and-method condition
- Total measurements: 3 x 3 x 30 = 270
- Same lookup key used across the three methods within each matched search
- Warm-up queries performed before measurement
- Method order randomized to reduce systematic order effects

The three tables at a given size contain equivalent generated records. They
are separate tables and are not connected by foreign keys. Only the indexing
setup differs.

## Simple statistical analysis

The project deliberately uses a small set of understandable methods:

1. Mean response time: which method was fastest on average?
2. Median response time: what was the middle observed time?
3. Standard deviation: how much did the timings vary?
4. Speed-up: No-index mean divided by indexed mean.
5. Paired t-test: were matched response-time differences statistically clear?
6. Bar chart and boxplot: visual comparison of the methods.

## Main real result

At 500,000 rows:

- No index mean: approximately 71.07 ms
- B+ tree mean: approximately 1.77 ms
- Hash mean: approximately 1.67 ms
- B+ tree: approximately 40 times faster than No index
- Hash: approximately 43 times faster than No index

The paired tests found strong evidence that both indexed methods were faster
than No index. Hash had a slightly smaller observed mean than B+ tree, but the
difference between the two indexed methods was not statistically clear.

## Files to use

- `00_setup.R`: creates/checks project folders.
- `01_collect_timings.R`: original reproducible collection script. Do not run
  it unless a completely new timing experiment is required.
- `database_setup.R`: safely recreates `indexing_project` and all nine tables
  on another computer; it requests the local password without saving it.
- `02_simple_analysis.R`: reads the saved CSV and creates all simple results.
- `03_validate_project.R`: checks the completed project.
- `data/query_times.csv`: the 270 original real measurements.
- `results/`: final numerical results and conclusion.
- `plots/`: two presentation-ready graphs.
- `sql/`: PostgreSQL table creation and execution-plan verification.
- `docs/`: abstract, methodology and presentation guide.
- `docs/FRIEND_SETUP.md`: exact instructions for another computer.

## How to reproduce the saved analysis

Open `DatabaseIndexingStatistics_Simple.Rproj` in RStudio and run:

```r
source("00_setup.R")
source("02_simple_analysis.R")
source("03_validate_project.R")
```

This uses the existing CSV and does not need a PostgreSQL password.

## Using the project on another computer

The saved CSV, results, and graphs work immediately after cloning. A live local
PostgreSQL server cannot be embedded in GitHub, because it is a running service
on one computer. To recreate the full database, install PostgreSQL and run:

```r
source("database_setup.R")
```

The script creates the `indexing_project` database when necessary, rebuilds all
nine tables, verifies them, and never stores the password. See
`docs/FRIEND_SETUP.md` for the complete sequence.

## Important limitation

The results describe equality searches on this PostgreSQL database and this
computer. Individual timings can change with caching and background system
activity. The paired t-test is a simple primary analysis; timing data can be
skewed, so results should be interpreted as evidence under the tested
conditions rather than a universal guarantee.
