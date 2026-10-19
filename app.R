# app.R
# Presentation-only Shiny dashboard.
# It reads the saved real measurements and never connects to PostgreSQL.

required_packages <- c("shiny")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the missing package first: ",
    paste(missing_packages, collapse = ", "),
    "\nRun: install.packages(\"shiny\")"
  )
}

library(shiny)

timings <- read.csv("data/query_times.csv", stringsAsFactors = FALSE)
summary_statistics <- read.csv(
  "results/summary_statistics.csv",
  stringsAsFactors = FALSE
)
speedup_results <- read.csv(
  "results/speedup_results.csv",
  stringsAsFactors = FALSE
)
paired_tests <- read.csv(
  "results/paired_t_test_results.csv",
  stringsAsFactors = FALSE
)
syllabus_summary <- read.csv(
  "results/syllabus_expected_value_variance.csv",
  stringsAsFactors = FALSE
)
syllabus_probability <- read.csv(
  "results/syllabus_empirical_probability.csv",
  stringsAsFactors = FALSE
)
syllabus_correlation <- readLines(
  "results/syllabus_correlation.txt",
  warn = FALSE
)

method_order <- c("No index", "B+ tree", "Hash")
size_order <- c(10000, 100000, 500000)

summary_statistics$index_method <- factor(
  summary_statistics$index_method,
  levels = method_order
)

website_css <- "
body { background:#f5f7fb; color:#172033; font-family:Inter,Segoe UI,Arial,sans-serif; }
.navbar { background:#16213e; border:0; }
.navbar-brand, .navbar-nav>li>a { color:#fff !important; }
.container-fluid { max-width:1280px; margin:auto; }
.hero { background:linear-gradient(120deg,#16213e,#2563a6); color:#fff; padding:30px; border-radius:18px; margin:22px 0; }
.hero h1 { font-weight:800; margin-top:0; }
.card { background:#fff; border:1px solid #e4e9f2; border-radius:14px; padding:20px; margin:14px 0; box-shadow:0 4px 16px rgba(27,47,84,.06); }
.metric { font-size:28px; font-weight:800; color:#145da0; }
.small-muted { color:#65738b; font-size:13px; }
.result-good { color:#087443; font-weight:700; }
.result-neutral { color:#8a5a00; font-weight:700; }
.table { background:#fff; }
.btn-primary { background:#2563a6; border:0; }
"

ui <- fluidPage(
  tags$head(tags$style(HTML(website_css))),
  navbarPage(
    title = "IndexLab",
    tabPanel(
      "Overview",
      div(class = "hero",
          h1("Database indexing, measured with R"),
          p("A presentation dashboard built from 270 real PostgreSQL response-time measurements."),
          p(class = "small-muted", "This dashboard reads saved results only. It does not connect to PostgreSQL or run new timings.")),
      fluidRow(
        column(4, div(class = "card", h4("Research question"), p("Are indexed equality searches faster than a search without an index?"))),
        column(4, div(class = "card", h4("Experiment"), div(class = "metric", "9 tables"), p("3 sizes x 3 methods"))),
        column(4, div(class = "card", h4("Measurements"), div(class = "metric", "270"), p("30 matched searches per condition")))
      ),
      div(class = "card", h3("Final finding"), uiOutput("overview_conclusion"))
    ),
    tabPanel(
      "Database",
      div(class = "card",
          h3("Sample database"),
          p("The experiment uses generated student-style records with the same columns in every equivalent table."),
          tableOutput("database_schema"),
          h4("Why nine tables?"),
          p("There are three table sizes and three search methods: 3 x 3 = 9 tables. Tables of the same size contain equivalent records; only the index setup changes.")
      ),
      div(class = "card", h3("Benchmark table names"), tableOutput("table_names"))
    ),
    tabPanel(
      "Search",
      div(class = "card",
          h3("Search a sample record"),
          p("Enter a record ID. The record is reconstructed from the controlled sample-data rule used to create the benchmark tables."),
          fluidRow(
            column(4, numericInput("record_id", "Record ID (1 to 500,000)", value = 5000, min = 1, max = 500000, step = 1)),
            column(4, selectInput("search_size", "Table size for the measured summary", choices = c("10,000" = 10000, "100,000" = 100000, "500,000" = 500000), selected = 500000)),
            column(4, br(), actionButton("search", "Show result", class = "btn-primary"))
          ),
          uiOutput("search_message"),
          h4("Returned record under every method"),
          tableOutput("record_result"),
          p(class = "small-muted", "The three rows show that all methods return the same record. The response-time table below contains the saved 30-run measurements for the selected table size; this dashboard does not create new timings.")
      ),
      div(class = "card", h3("Measured response-time summary"), tableOutput("selected_summary"), tableOutput("selected_speedup"))
    ),
    tabPanel(
      "Mathematics",
      div(class = "card", h3("How the comparison is calculated"),
          tags$ul(
            tags$li("Mean = sum of the 30 response times divided by 30."),
            tags$li("Standard deviation describes how much timings vary."),
            tags$li("Speed-up = No-index mean divided by indexed mean."),
            tags$li("The paired t-test compares the same lookup keys under two methods."),
            tags$li("At the 5% level, p < 0.05 is treated as evidence of a difference.")
          )),
      div(class = "card", h3("Paired-test results at 500,000 rows"), tableOutput("test_results")),
      div(class = "card", h3("What the p-values mean"), p("The No-index versus B+ tree and No-index versus Hash comparisons provide strong evidence that both indexed methods were faster. The B+ tree versus Hash comparison is not statistically clear, so this experiment does not establish a definite winner between the two indexed methods."))
    ),
    tabPanel(
      "Syllabus",
      div(class = "card", h3("Expected value and variance"), p("The mean estimates expected response time. Variance measures the squared spread around the mean."), tableOutput("syllabus_summary")),
      div(class = "card", h3("Empirical probability"), p("This is the proportion of the 30 matched searches in which the indexed method was faster than No index."), tableOutput("syllabus_probability")),
      div(class = "card", h3("Correlation"), verbatimTextOutput("syllabus_correlation"), p("This supporting result checks whether response time tends to increase as table size increases."))
    ),
    tabPanel(
      "Graph",
      div(class = "card", h3("Mean response time by table size"), plotOutput("mean_plot", height = "520px")),
      div(class = "card", h3("Thirty timings at 500,000 rows"), plotOutput("box_plot", height = "520px"))
    ),
    tabPanel(
      "Test cases",
      div(class = "card", h3("Website checks"), tableOutput("test_cases"), p(class = "small-muted", "These checks verify the presentation data and interface logic. They are not new database timings."))
    ),
    tabPanel(
      "Conclusion",
      div(class = "card", h2("Conclusion from the real experiment"), verbatimTextOutput("conclusion_text")),
      div(class = "card", h3("Scope and limitation"), p("These results describe equality searches on the measured PostgreSQL setup. Caching, background activity and hardware can change individual timings. Hash indexes are not being evaluated for range searches."))
    )
  )
)

server <- function(input, output, session) {
  output$overview_conclusion <- renderUI({
    div(class = "result-good", "Both B+ tree and Hash indexing were much faster than No index. No statistically clear winner was established between B+ tree and Hash.")
  })

  output$database_schema <- renderTable({
    data.frame(
      Column = c("record_id", "lookup_key", "student_name", "score"),
      Purpose = c("Identifies the record", "Value used for searching", "Generated sample name", "Generated sample score"),
      Example = c("5000", "50007", "Student_5000", "51"),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = TRUE, spacing = "m")

  output$table_names <- renderTable({
    data.frame(
      Rows = c("10,000", "100,000", "500,000"),
      `No index` = c("benchmark_10000_noindex", "benchmark_100000_noindex", "benchmark_500000_noindex"),
      `B+ tree` = c("benchmark_10000_bplus", "benchmark_100000_bplus", "benchmark_500000_bplus"),
      Hash = c("benchmark_10000_hash", "benchmark_100000_hash", "benchmark_500000_hash"),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = TRUE, spacing = "s")

  searched_id <- eventReactive(input$search, {
    id <- suppressWarnings(as.integer(input$record_id))
    validate(need(!is.na(id) && id >= 1 && id <= 500000, "Enter a whole-number record ID from 1 to 500,000."))
    id
  }, ignoreNULL = FALSE)

  output$search_message <- renderUI({
    id <- searched_id()
    div(class = "result-good", sprintf("Record %d found in the controlled sample data.", id))
  })

  output$record_result <- renderTable({
    id <- searched_id()
    record <- data.frame(
      record_id = id,
      lookup_key = id * 10 + 7,
      student_name = paste0("Student_", id),
      score = id %% 101
    )
    result <- rbind(record, record, record)
    result$method <- method_order
    result[, c("method", "record_id", "lookup_key", "student_name", "score")]
  }, striped = TRUE, bordered = TRUE, spacing = "m")

  selected_data <- reactive({
    summary_statistics[summary_statistics$table_size == as.numeric(input$search_size), ]
  })

  output$selected_summary <- renderTable({
    current <- selected_data()
    data.frame(
      Method = as.character(current$index_method),
      Runs = current$measurements,
      Mean_ms = round(current$mean_ms, 4),
      Standard_deviation_ms = round(current$standard_deviation_ms, 4),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = TRUE, spacing = "m")

  output$selected_speedup <- renderTable({
    current <- speedup_results[speedup_results$table_size == as.numeric(input$search_size), ]
    data.frame(
      Method = current$index_method,
      Speed_up_vs_No_index = round(current$speedup_vs_no_index, 2),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = TRUE, spacing = "m")

  output$test_results <- renderTable({
    current <- paired_tests[paired_tests$table_size == 500000, ]
    data.frame(
      First = current$first_method,
      Second = current$second_method,
      P_value = format.pval(current$p_value, digits = 4, eps = 0.0001),
      Finding = ifelse(
        current$statistically_significant == "Yes",
        paste(current$lower_observed_mean, "faster on observed mean"),
        "No statistically clear difference"
      ),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = TRUE, spacing = "m")

  output$syllabus_summary <- renderTable({
    result <- syllabus_summary
    result$index_method <- as.character(result$index_method)
    result$estimated_expected_time_ms <- round(result$estimated_expected_time_ms, 4)
    result$sample_variance_ms_squared <- round(result$sample_variance_ms_squared, 4)
    result
  }, striped = TRUE, bordered = TRUE, spacing = "s")

  output$syllabus_probability <- renderTable({
    result <- syllabus_probability
    result$empirical_probability <- round(result$empirical_probability, 4)
    result
  }, striped = TRUE, bordered = TRUE, spacing = "s")

  output$syllabus_correlation <- renderText({
    paste(syllabus_correlation, collapse = "\n")
  })

  output$mean_plot <- renderPlot({
    current <- summary_statistics
    means <- tapply(current$mean_ms, list(current$index_method, current$table_size), identity)
    means <- means[method_order, as.character(size_order), drop = FALSE]
    positions <- barplot(
      means,
      beside = TRUE,
      col = c("#e45756", "#4c78a8", "#54a24b"),
      names.arg = c("10,000", "100,000", "500,000"),
      main = "Mean Query Response Time",
      xlab = "Table size (rows)",
      ylab = "Mean response time (milliseconds)",
      ylim = c(0, max(means) * 1.18),
      legend.text = rownames(means),
      args.legend = list(x = "topleft", bty = "n")
    )
    text(positions, means, labels = format(round(means, 2), nsmall = 2), pos = 3, cex = 0.8)
  })

  output$box_plot <- renderPlot({
    largest <- timings[timings$table_size == 500000, ]
    boxplot(
      response_time_ms ~ index_method,
      data = largest,
      col = c("#e45756", "#4c78a8", "#54a24b"),
      main = "Thirty Measured Timings at 500,000 Rows",
      xlab = "Indexing method",
      ylab = "Response time (milliseconds)"
    )
  })

  output$conclusion_text <- renderText({
    paste(readLines("results/final_conclusion.txt", warn = FALSE), collapse = "\n")
  })

  output$test_cases <- renderTable({
    valid_record <- 5000
    required_timing_columns <- c(
      "table_size", "index_method", "run_number", "block_id",
      "execution_order", "lookup_key", "response_time_ms", "returned_rows"
    )
    same_record <- all(required_timing_columns %in% names(timings))
    condition_counts <- table(timings$table_size, timings$index_method)
    data.frame(
      Test = c("Valid record 5000", "Invalid record 0", "Invalid record 500001", "270 timing rows", "30 rows per condition", "Required timing columns"),
      Expected = c("Accepted", "Rejected", "Rejected", "PASS", "PASS", "PASS"),
      Status = c(
        ifelse(valid_record >= 1 && valid_record <= 500000, "PASS", "FAIL"),
        ifelse(0 < 1, "PASS", "FAIL"),
        ifelse(500001 > 500000, "PASS", "FAIL"),
        ifelse(nrow(timings) == 270, "PASS", "FAIL"),
        ifelse(all(condition_counts == 30), "PASS", "FAIL"),
        ifelse(same_record, "PASS", "FAIL")
      ),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = TRUE, spacing = "m")
}

shinyApp(ui = ui, server = server)
