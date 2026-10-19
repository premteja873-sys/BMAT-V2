# 03_validate_project.R
# Checks the simplified project without modifying the timing data.

required_files <- c(
  "00_setup.R",
  "01_collect_timings.R",
  "database_setup.R",
  "02_simple_analysis.R",
  "README.md",
  "docs/ABSTRACT.md",
  "docs/METHODOLOGY.md",
  "docs/PRESENTATION_GUIDE.md",
  "docs/FRIEND_SETUP.md",
  "data/query_times.csv",
  "data/run_information.txt",
  "sql/01_create_benchmark_tables.sql",
  "sql/02_verify_execution_plans.sql",
  "results/summary_statistics.csv",
  "results/speedup_results.csv",
  "results/paired_t_test_results.csv",
  "results/final_conclusion.txt",
  "plots/mean_response_times.png",
  "plots/boxplot_500000_rows.png"
)

file_check <- data.frame(
  file = required_files,
  exists = file.exists(required_files),
  stringsAsFactors = FALSE
)

timings <- read.csv("data/query_times.csv", stringsAsFactors = FALSE)

condition_counts <- aggregate(
  response_time_ms ~ table_size + index_method,
  data = timings,
  FUN = length
)
names(condition_counts)[3] <- "measurements"

checks <- c(
  all(file_check$exists),
  nrow(timings) == 270,
  nrow(condition_counts) == 9,
  all(condition_counts$measurements == 30),
  all(is.finite(timings$response_time_ms)),
  all(timings$response_time_ms > 0),
  all(timings$returned_rows == 1)
)

validation_text <- c(
  "SIMPLIFIED PROJECT VALIDATION",
  "=============================",
  "",
  paste("Required files:", ifelse(checks[1], "PASS", "FAIL")),
  paste("Exactly 270 measurements:", ifelse(checks[2], "PASS", "FAIL")),
  paste("Exactly 9 conditions:", ifelse(checks[3], "PASS", "FAIL")),
  paste("30 measurements per condition:", ifelse(checks[4], "PASS", "FAIL")),
  paste("All timings are finite:", ifelse(checks[5], "PASS", "FAIL")),
  paste("All timings are positive:", ifelse(checks[6], "PASS", "FAIL")),
  paste("Every query returned one row:", ifelse(checks[7], "PASS", "FAIL")),
  "",
  "Condition counts:",
  capture.output(print(condition_counts, row.names = FALSE)),
  "",
  "File check:",
  capture.output(print(file_check, row.names = FALSE)),
  "",
  paste("Overall status:", ifelse(all(checks), "PASS", "FAIL"))
)

writeLines(validation_text, "results/project_validation.txt")

cat("Project validation:", ifelse(all(checks), "PASS", "FAIL"), "\n")

if (!all(checks)) {
  stop("One or more validation checks failed. See results/project_validation.txt")
}
