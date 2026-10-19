# Starts the saved-results presentation website.
# It does not connect to PostgreSQL and does not run new timings.

if (!requireNamespace("shiny", quietly = TRUE)) {
  install.packages("shiny")
}

if (!file.exists("results/syllabus_expected_value_variance.csv")) {
  stop("Run source('04_syllabus_math.R') before starting the website.")
}

shiny::runApp("app.R", launch.browser = TRUE)
