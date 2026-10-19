# Simplified Methodology

## 1. Research question

Does indexing reduce the response time of a PostgreSQL equality-search query?

## 2. Experimental factors

Two factors were varied:

- Table size: 10,000, 100,000 and 500,000 rows.
- Search method: No index, B+ tree and Hash.

This produced nine conditions. Separate tables were used so the data and query
could remain equivalent while the indexing method changed.

## 3. Generated data

Every table contains `record_id`, `lookup_key`, `student_name` and `score`.
Tables at the same size contain equivalent generated records. The query uses
`lookup_key` and returns `score`.

## 4. Repeated measurements

Thirty valid lookup keys were sampled for each table size. Each selected key
was searched under all three methods, so the observations were matched by
`block_id` and `lookup_key`. This produced:

3 sizes x 3 methods x 30 measurements = 270 timings.

Warm-up queries were not recorded. The method order was randomized within each
matched search to reduce systematic order effects.

## 5. Statistical analysis

- Mean: average response time across 30 measurements.
- Median: middle response time.
- Standard deviation: variability of the timings.
- Speed-up: No-index mean divided by the indexed-method mean.
- Paired t-test: compares matched response times for the same lookup keys.
- A 5% significance level is used: p-values below 0.05 are treated as
  statistically significant evidence of a difference.

The paired test is used because the same lookup keys were tested under each
method. A significant result is interpreted together with the observed means
to identify which method was faster.

## 6. Database verification

`EXPLAIN (ANALYZE, BUFFERS)` verifies the intended PostgreSQL strategy:

- No index: sequential scan.
- B+ tree: index scan using the `btree` index.
- Hash: index scan using the Hash index.

Execution-plan screenshots demonstrate how PostgreSQL searched. The final
statistical conclusion uses the 30 repeated R measurements, not a single
execution time.

## 7. Syllabus connection

The separate `04_syllabus_math.R` script uses the same real timings to estimate
expected response time with the sample mean, calculate variance, calculate the
empirical probability that an index is faster for a matched search, and measure
Pearson and Spearman correlation between table size and No-index response time.
These are supporting syllabus calculations; they do not replace the main
paired comparison.

## 8. Limitations

- Results apply to equality searches in this experimental setup.
- Timings can be influenced by caching and background computer activity.
- PostgreSQL names its ordered index type `btree`; this project describes it
  as the practical B+ tree indexing method.
- The paired t-test is intentionally simple, but extreme skewness or dependent
  timing effects can affect its assumptions.
