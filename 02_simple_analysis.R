# 02_simple_analysis.R
# Simplified statistical analysis of the 270 real PostgreSQL timings.
# This script does not connect to PostgreSQL and does not rerun the benchmark.

dir.create("results", showWarnings = FALSE)
dir.create("plots", showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Read and check the real timing data
# -----------------------------------------------------------------------------

timings <- read.csv("data/query_times.csv", stringsAsFactors = FALSE)

required_columns <- c(
  "table_size", "index_method", "run_number", "block_id",
  "lookup_key", "response_time_ms"
)

if (!all(required_columns %in% names(timings))) {
  stop("The timing CSV is missing one or more required columns.")
}

if (nrow(timings) != 270) {
  stop("Expected 270 timing rows, but found ", nrow(timings), ".")
}

method_order <- c("No index", "B+ tree", "Hash")
size_order <- c(10000, 100000, 500000)

timings$index_method <- factor(
  timings$index_method,
  levels = method_order
)

# -----------------------------------------------------------------------------
# 2. Mean, median and standard deviation
# -----------------------------------------------------------------------------

groups <- split(
  timings$response_time_ms,
  list(timings$table_size, timings$index_method),
  drop = TRUE
)

summary_rows <- lapply(names(groups), function(group_name) {
  parts <- strsplit(group_name, "\\.", fixed = FALSE)[[1]]
  values <- groups[[group_name]]

  data.frame(
    table_size = as.numeric(parts[1]),
    index_method = paste(parts[-1], collapse = "."),
    measurements = length(values),
    mean_ms = mean(values),
    median_ms = median(values),
    standard_deviation_ms = sd(values),
    stringsAsFactors = FALSE
  )
})

summary_statistics <- do.call(rbind, summary_rows)
summary_statistics$index_method <- factor(
  summary_statistics$index_method,
  levels = method_order
)
summary_statistics <- summary_statistics[
  order(summary_statistics$table_size, summary_statistics$index_method),
]
summary_statistics$index_method <- as.character(summary_statistics$index_method)

write.csv(
  summary_statistics,
  "results/summary_statistics.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 3. Speed-up compared with No index
# -----------------------------------------------------------------------------

speedup_rows <- lapply(size_order, function(current_size) {
  current <- subset(summary_statistics, table_size == current_size)
  no_index_mean <- current$mean_ms[current$index_method == "No index"]

  data.frame(
    table_size = current_size,
    index_method = current$index_method,
    mean_ms = current$mean_ms,
    speedup_vs_no_index = no_index_mean / current$mean_ms,
    stringsAsFactors = FALSE
  )
})

speedup_results <- do.call(rbind, speedup_rows)

write.csv(
  speedup_results,
  "results/speedup_results.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 4. Paired t-tests
# The same block_id and lookup_key are matched before each test.
# -----------------------------------------------------------------------------

paired_comparison <- function(current_size, first_method, second_method) {
  first <- subset(
    timings,
    table_size == current_size & index_method == first_method,
    select = c("block_id", "lookup_key", "response_time_ms")
  )

  second <- subset(
    timings,
    table_size == current_size & index_method == second_method,
    select = c("block_id", "lookup_key", "response_time_ms")
  )

  names(first)[3] <- "first_time_ms"
  names(second)[3] <- "second_time_ms"

  matched <- merge(
    first,
    second,
    by = c("block_id", "lookup_key"),
    sort = TRUE
  )

  if (nrow(matched) != 30) {
    stop("Expected 30 matched observations for ", current_size, ".")
  }

  test <- t.test(
    matched$first_time_ms,
    matched$second_time_ms,
    paired = TRUE,
    alternative = "two.sided",
    conf.level = 0.95
  )

  first_mean <- mean(matched$first_time_ms)
  second_mean <- mean(matched$second_time_ms)

  data.frame(
    table_size = current_size,
    first_method = first_method,
    second_method = second_method,
    pairs = nrow(matched),
    first_mean_ms = first_mean,
    second_mean_ms = second_mean,
    mean_difference_ms = first_mean - second_mean,
    confidence_interval_low_ms = unname(test$conf.int[1]),
    confidence_interval_high_ms = unname(test$conf.int[2]),
    p_value = test$p.value,
    statistically_significant = ifelse(test$p.value < 0.05, "Yes", "No"),
    lower_observed_mean = ifelse(
      first_mean < second_mean,
      first_method,
      second_method
    ),
    stringsAsFactors = FALSE
  )
}

comparisons <- list()
comparison_number <- 1L

for (current_size in size_order) {
  method_pairs <- list(
    c("No index", "B+ tree"),
    c("No index", "Hash"),
    c("B+ tree", "Hash")
  )

  for (pair in method_pairs) {
    comparisons[[comparison_number]] <- paired_comparison(
      current_size,
      pair[1],
      pair[2]
    )
    comparison_number <- comparison_number + 1L
  }
}

paired_test_results <- do.call(rbind, comparisons)

write.csv(
  paired_test_results,
  "results/paired_t_test_results.csv",
  row.names = FALSE
)

# -----------------------------------------------------------------------------
# 5. Graph of the average response times
# -----------------------------------------------------------------------------

mean_matrix <- matrix(
  NA_real_,
  nrow = length(method_order),
  ncol = length(size_order),
  dimnames = list(method_order, as.character(size_order))
)

for (row_number in seq_len(nrow(summary_statistics))) {
  result_row <- summary_statistics[row_number, ]
  mean_matrix[
    result_row$index_method,
    as.character(result_row$table_size)
  ] <- result_row$mean_ms
}

png(
  "plots/mean_response_times.png",
  width = 1400,
  height = 850,
  res = 150
)

bar_positions <- barplot(
  mean_matrix,
  beside = TRUE,
  col = c("#E45756", "#4C78A8", "#59A14F"),
  main = "Mean Query Response Time by Table Size",
  xlab = "Number of rows",
  ylab = "Mean response time (milliseconds)",
  names.arg = format(
    size_order,
    big.mark = ",",
    scientific = FALSE,
    trim = TRUE
  ),
  legend.text = TRUE,
  args.legend = list(x = "topleft", bty = "n"),
  ylim = c(0, max(mean_matrix) * 1.15)
)

text(
  bar_positions,
  mean_matrix,
  labels = format(round(mean_matrix, 2), nsmall = 2),
  pos = 3,
  cex = 0.8
)

dev.off()

# -----------------------------------------------------------------------------
# 6. Boxplot for the largest table size
# -----------------------------------------------------------------------------

largest <- subset(timings, table_size == 500000)

png(
  "plots/boxplot_500000_rows.png",
  width = 1200,
  height = 800,
  res = 150
)

boxplot(
  response_time_ms ~ index_method,
  data = largest,
  col = c("#E45756", "#4C78A8", "#59A14F"),
  main = "Query Response Times for 500,000 Rows",
  xlab = "Indexing method",
  ylab = "Response time (milliseconds)"
)

dev.off()

# -----------------------------------------------------------------------------
# 7. Write a plain-English conclusion using the real results
# -----------------------------------------------------------------------------

largest_summary <- subset(summary_statistics, table_size == 500000)
largest_speedup <- subset(speedup_results, table_size == 500000)

mean_no_index <- largest_summary$mean_ms[
  largest_summary$index_method == "No index"
]
mean_bplus <- largest_summary$mean_ms[
  largest_summary$index_method == "B+ tree"
]
mean_hash <- largest_summary$mean_ms[
  largest_summary$index_method == "Hash"
]

speedup_bplus <- largest_speedup$speedup_vs_no_index[
  largest_speedup$index_method == "B+ tree"
]
speedup_hash <- largest_speedup$speedup_vs_no_index[
  largest_speedup$index_method == "Hash"
]

largest_tests <- subset(paired_test_results, table_size == 500000)
p_no_bplus <- largest_tests$p_value[
  largest_tests$first_method == "No index" &
    largest_tests$second_method == "B+ tree"
]
p_no_hash <- largest_tests$p_value[
  largest_tests$first_method == "No index" &
    largest_tests$second_method == "Hash"
]
p_bplus_hash <- largest_tests$p_value[
  largest_tests$first_method == "B+ tree" &
    largest_tests$second_method == "Hash"
]

conclusion <- c(
  "SIMPLIFIED PROJECT CONCLUSION",
  "=============================",
  "",
  "The experiment used 270 real PostgreSQL response-time measurements:",
  "3 table sizes x 3 methods x 30 matched searches.",
  "",
  sprintf("At 500,000 rows, No index averaged %.2f ms.", mean_no_index),
  sprintf("At 500,000 rows, B+ tree averaged %.2f ms.", mean_bplus),
  sprintf("At 500,000 rows, Hash averaged %.2f ms.", mean_hash),
  sprintf("B+ tree was approximately %.2f times faster than No index.", speedup_bplus),
  sprintf("Hash was approximately %.2f times faster than No index.", speedup_hash),
  "",
  sprintf("No index versus B+ tree paired-test p-value: %.4g", p_no_bplus),
  sprintf("No index versus Hash paired-test p-value: %.4g", p_no_hash),
  sprintf("B+ tree versus Hash paired-test p-value: %.4g", p_bplus_hash),
  "",
  paste(
    "Both indexed methods were significantly faster than No index under the",
    "tested conditions. Hash had a slightly lower observed mean than B+ tree",
    "at 500,000 rows, but their difference was not statistically significant."
  ),
  "",
  paste(
    "These conclusions apply to equality searches on this PostgreSQL database",
    "and this computer. Individual timings can change because of caching and",
    "background system activity."
  )
)

writeLines(conclusion, "results/final_conclusion.txt")

cat("\nSimplified analysis finished successfully.\n")
cat("Created results/summary_statistics.csv\n")
cat("Created results/speedup_results.csv\n")
cat("Created results/paired_t_test_results.csv\n")
cat("Created results/final_conclusion.txt\n")
cat("Created plots/mean_response_times.png\n")
cat("Created plots/boxplot_500000_rows.png\n")
