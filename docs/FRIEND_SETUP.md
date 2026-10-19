# Setup for Another Computer

A live PostgreSQL server cannot be uploaded to GitHub as an active connection.
GitHub stores files, not a running local database service. This repository
contains everything needed to reconstruct the database safely.

## Fastest option: view the completed project

The saved dataset, results, and graphs are already included. A friend can clone
the repository, open the RStudio project, and run:

```r
source("02_simple_analysis.R")
source("03_validate_project.R")
```

PostgreSQL is not required merely to view or regenerate the saved analysis.

## Full option: recreate the database and experiment

1. Install PostgreSQL, pgAdmin, R, and RStudio.
2. Open the RStudio project.
3. Install the required packages once:

```r
install.packages(c("DBI", "RPostgres", "microbenchmark", "rstudioapi"))
```

4. Ensure the local PostgreSQL service is running on port 5432 and the
   `postgres` account is available.
5. Run:

```r
source("database_setup.R")
```

6. Enter that computer's local PostgreSQL password when prompted. The password
   is used only for the current session and is not saved.
7. To collect a completely new set of timings, run:

```r
source("01_collect_timings.R")
```

8. Regenerate the analysis:

```r
source("02_simple_analysis.R")
source("03_validate_project.R")
```

New timings will differ slightly because computers, caching, and background
activity differ. That is expected.

## Manual pgAdmin option

Instead of `database_setup.R`, create a database named `indexing_project` in
pgAdmin and run `sql/01_create_benchmark_tables.sql` inside it. Then run
`sql/02_verify_execution_plans.sql` to demonstrate the scan types.
