# 04_syllabus_math.R
# Small syllabus bridge using the existing real timing data.
# This does not change the Version 2 experiment or its main conclusion.
# It uses expected value/mean, variance, empirical probability,
# covariance/correlation, and the paired-data idea.

dir.create("results", showWarnings = FALSE)
dir.create("plots", showWarnings = FALSE)

timings <- read.csv("data/query_times.csv", stringsAsFactors = FALSE)
method_order <- c("No index", "B+ tree", "Hash")
timings$index_method <- factor(timings$index_method, levels = method_order)

# 1. Expected value and variance estimated from the sample.
# The sample mean estimates the expected response time E(X).
expected_value <- aggregate(
  response_time_ms ~ table_size + index_method,
  data = timings,
  FUN = mean
)
names(expected_value)[3] <- "estimated_expected_time_ms"

variance <- aggregate(
  response_time_ms ~ table_size + index_method,
  data = timings,
  FUN = var
)
names(variance)[3] <- "sample_variance_ms_squared"

syllabus_summary <- merge(
  expected_value,
  variance,
  by = c("table_size", "index_method")
)
syllabus_summary <- syllabus_summary[
  order(syllabus_summary$table_size, syllabus_summary$index_method),
]

write.csv(
  syllabus_summary,
  "results/syllabus_expected_value_variance.csv",
  row.names = FALSE
)

# 2. Empirical probability that indexing is faster.
# The probability is the proportion of matched searches where the indexed
# response time was lower than the matching No-index response time.
matched_times <- function(data, first_method, second_method) {
  first <- subset(
    data,
    index_method == first_method,
    select = c("table_size", "block_id", "lookup_key", "response_time_ms")
  )
  second <- subset(
    data,
    index_method == second_method,
    select = c("table_size", "block_id", "lookup_key", "response_time_ms")
  )

  names(first)[4] <- "first_time_ms"
  names(second)[4] <- "second_time_ms"

  merge(
    first,
    second,
    by = c("table_size", "block_id", "lookup_key"),
    sort = TRUE
  )
}

probability_rows <- list()
row_number <- 1L

for (size in sort(unique(timings$table_size))) {
  current <- subset(timings, table_size == size)
  no_bplus <- matched_times(current, "No index", "B+ tree")
  no_hash <- matched_times(current, "No index", "Hash")

  probability_rows[[row_number]] <- data.frame(
    table_size = size,
    comparison = "B+ tree faster than No index",
    successful_pairs = sum(no_bplus$second_time_ms < no_bplus$first_time_ms),
    pairs = nrow(no_bplus),
    empirical_probability = mean(no_bplus$second_time_ms < no_bplus$first_time_ms)
  )
  row_number <- row_number + 1L

  probability_rows[[row_number]] <- data.frame(
    table_size = size,
    comparison = "Hash faster than No index",
    successful_pairs = sum(no_hash$second_time_ms < no_hash$first_time_ms),
    pairs = nrow(no_hash),
    empirical_probability = mean(no_hash$second_time_ms < no_hash$first_time_ms)
  )
  row_number <- row_number + 1L
}

probability_results <- do.call(rbind, probability_rows)
write.csv(
  probability_results,
  "results/syllabus_empirical_probability.csv",
  row.names = FALSE
)

# 3. Pearson and Spearman correlation for the No-index condition.
# We use log values because both table size and response time span wide ranges.
no_index <- subset(timings, index_method == "No index")

pearson <- cor.test(
  log(no_index$table_size),
  log(no_index$response_time_ms),
  method = "pearson"
)

spearman <- cor.test(
  no_index$table_size,
  no_index$response_time_ms,
  method = "spearman",
  exact = FALSE
)

correlation_lines <- c(
  "CORRELATION OF TABLE SIZE AND NO-INDEX RESPONSE TIME",
  "====================================================",
  "",
  "Pearson correlation on log(table size) and log(response time):",
  sprintf("r = %.4f, p-value = %.4g", unname(pearson$estimate), pearson$p.value),
  "",
  "Spearman rank correlation on table size and response time:",
  sprintf("rho = %.4f, p-value = %.4g", unname(spearman$estimate), spearman$p.value),
  "",
  "Interpretation: a positive coefficient means response time tends to increase",
  "as table size increases. This is supporting evidence, not the primary test."
)

writeLines(correlation_lines, "results/syllabus_correlation.txt")

png(
  "plots/table_size_vs_no_index_time.png",
  width = 1200,
  height = 800,
  res = 140
)

plot(
  log(no_index$table_size),
  log(no_index$response_time_ms),
  pch = 19,
  col = "#E45756",
  main = "Table Size and No-Index Response Time",
  xlab = "log(table size)",
  ylab = "log(response time in milliseconds)"
)
abline(lm(log(response_time_ms) ~ log(table_size), data = no_index), lwd = 2)
dev.off()

cat("Syllabus mathematics finished successfully.\n")
cat("Created results/syllabus_expected_value_variance.csv\n")
cat("Created results/syllabus_empirical_probability.csv\n")
cat("Created results/syllabus_correlation.txt\n")
cat("Created plots/table_size_vs_no_index_time.png\n")
