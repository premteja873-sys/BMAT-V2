# Local Website Guide

The Version 2 project includes a presentation-only Shiny website. It reads the
existing 270 real measurements and result files. It does not connect to
PostgreSQL, request a password, or create new timings.

## Start the website

Open the project in RStudio and run:

```r
source("run_website.R")
```

The browser opens at a local address similar to:

```text
http://127.0.0.1:3838/
```

If Shiny is not installed, the launcher installs it once.

## Website sections

- **Overview:** research question, nine-table design, 270 measurements and final finding.
- **Database:** columns, sample record and all nine benchmark table names.
- **Search:** enter a record ID and see the same returned record under all three methods.
- **Mathematics:** mean, standard deviation, speed-up and paired-test explanation.
- **Syllabus:** expected value, variance, empirical probability and correlation.
- **Graph:** mean comparison and 30-run boxplot.
- **Test cases:** valid input, invalid input, row count and data-integrity checks.
- **Conclusion:** the ready-to-present final conclusion.

## Important interpretation

The Search page demonstrates the controlled sample record. The response-time
summary is based on the saved 30-run measurements for the selected table size;
the website does not pretend that a new timing was collected for each click.
This makes the presentation reproducible and avoids changing the experiment
during the demonstration.
