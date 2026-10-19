# Abstract

Database indexing is commonly used to reduce the time required to search for
information. However, query response time changes between executions because
of caching and other system activity, so comparing only one execution can be
misleading. This project uses PostgreSQL and R to compare equality-search
response times under three methods: no index, B+ tree indexing and Hash
indexing. Equivalent tables containing 10,000, 100,000 and 500,000 records
were created for every method. For each table size, 30 lookup keys were tested
under all three methods, producing 270 real response-time measurements. R was
used to calculate the mean, median and standard deviation, create comparison
graphs, calculate speed-up and perform paired t-tests. The results showed that
both indexed methods were significantly faster than no indexing, particularly
for the 500,000-row tables. At 500,000 rows, No index averaged approximately
71.07 milliseconds, B+ tree averaged 1.77 milliseconds and Hash averaged 1.67
milliseconds. B+ tree was approximately 40 times faster and Hash was
approximately 43 times faster than No index. The difference between B+ tree
and Hash was not statistically clear. The project demonstrates how basic
statistical methods can be used to evaluate database performance.

**Keywords:** mean, standard deviation, paired t-test, database indexing,
query response time, PostgreSQL, R
