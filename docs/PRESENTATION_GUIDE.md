# Presentation Guide

## 1. Introduce the question

“My project investigates whether database indexing reduces equality-query
response time compared with having no index.”

## 2. Show the nine PostgreSQL tables

“I created one database with three table sizes: 10,000, 100,000 and 500,000
rows. For every size, I created No-index, B+ tree and Hash versions. Therefore,
the experiment has nine tables.”

## 3. Explain fairness

“Tables of the same size contain equivalent records. Only the indexing method
changes, so the comparison is fair.”

## 4. Show one generated table

“Each record has a record ID, lookup key, generated student name and score. The
query searches for a lookup key and returns the score.”

## 5. Show the execution plans

Point to `Parallel Seq Scan` or `Seq Scan` for No index, and `Index Scan` for
B+ tree and Hash.

“Without an index, PostgreSQL scans the table. With B+ tree or Hash,
PostgreSQL uses an index scan.”

## 6. Explain the 30 measurements

“A single execution can be misleading. R selected 30 valid lookup keys for
each size and searched every key under all three methods. This produced 270
real measurements. The same key was used across methods, so the comparison is
paired.”

## 7. Explain the statistics

“The mean shows average response time, standard deviation shows variation, and
speed-up compares No index with each indexed method. I used paired t-tests
because the same lookup keys were tested under each method.”

## 8. Present the main results

“At 500,000 rows, No index averaged 71.07 milliseconds, B+ tree averaged 1.77
milliseconds and Hash averaged 1.67 milliseconds. B+ tree was approximately
40 times faster and Hash was approximately 43 times faster than No index.”

## 9. Explain the p-value

“The indexed-versus-unindexed p-values were below 0.05, providing strong
evidence that both indexes reduced response time. B+ tree versus Hash was not
significant, so I cannot claim that Hash is definitely better.”

## 10. Final conclusion

“Indexing significantly reduced equality-search response time under the tested
conditions, especially for the largest table. Both B+ tree and Hash were much
faster than No index, but there was no statistically clear winner between the
two indexed methods.”

## Optional syllabus connection

If asked how the project uses the syllabus, show `04_syllabus_math.R` and say:

“The sample mean estimates expected response time, the sample variance measures
variation, the proportion of matched searches where an index is faster gives an
empirical probability, and correlation describes how No-index time changes as
table size grows.”

## Files to show

1. Nine tables in pgAdmin.
2. Three execution-plan examples.
3. `data/query_times.csv`.
4. `results/summary_statistics.csv`.
5. `plots/mean_response_times.png`.
6. `results/final_conclusion.txt`.
