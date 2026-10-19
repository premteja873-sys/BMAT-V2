# database_setup.R
# Recreates the local PostgreSQL database and all nine benchmark tables.
# The password is requested interactively and is never written to a file.

required_packages <- c("DBI", "RPostgres", "rstudioapi")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the missing packages first: ",
    paste(missing_packages, collapse = ", "),
    "\nRun: install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    "))"
  )
}

if (!file.exists("sql/01_create_benchmark_tables.sql")) {
  stop("Run this script from the project root folder.")
}

password <- rstudioapi::askForPassword("PostgreSQL password")
admin_connection <- NULL
project_connection <- NULL

cleanup_connections <- function() {
  if (!is.null(project_connection) && DBI::dbIsValid(project_connection)) {
    DBI::dbDisconnect(project_connection)
  }
  if (!is.null(admin_connection) && DBI::dbIsValid(admin_connection)) {
    DBI::dbDisconnect(admin_connection)
  }
  if (exists("password", inherits = TRUE)) {
    password <<- NULL
  }
}

tryCatch({
  admin_connection <- DBI::dbConnect(
    RPostgres::Postgres(),
    dbname = "postgres",
    host = "localhost",
    port = 5432,
    user = "postgres",
    password = password
  )

  database_exists <- DBI::dbGetQuery(
    admin_connection,
    "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'indexing_project') AS present"
  )$present[[1]]

  if (!isTRUE(database_exists)) {
    DBI::dbExecute(admin_connection, "CREATE DATABASE indexing_project")
    cat("Created PostgreSQL database: indexing_project\n")
  } else {
    cat("PostgreSQL database indexing_project already exists.\n")
  }

  DBI::dbDisconnect(admin_connection)
  admin_connection <- NULL

  project_connection <- DBI::dbConnect(
    RPostgres::Postgres(),
    dbname = "indexing_project",
    host = "localhost",
    port = 5432,
    user = "postgres",
    password = password
  )

  setup_sql <- paste(
    readLines("sql/01_create_benchmark_tables.sql", warn = FALSE),
    collapse = "\n"
  )

  DBI::dbExecute(project_connection, setup_sql, immediate = TRUE)

  expected_tables <- c(
    "benchmark_10000_noindex", "benchmark_10000_bplus", "benchmark_10000_hash",
    "benchmark_100000_noindex", "benchmark_100000_bplus", "benchmark_100000_hash",
    "benchmark_500000_noindex", "benchmark_500000_bplus", "benchmark_500000_hash"
  )

  available_tables <- DBI::dbListTables(project_connection)
  missing_tables <- setdiff(expected_tables, available_tables)

  if (length(missing_tables) > 0) {
    stop("Database setup finished but these tables are missing: ", paste(missing_tables, collapse = ", "))
  }

  counts <- vapply(expected_tables, function(table_name) {
    query <- paste0("SELECT COUNT(*) AS n FROM ", DBI::dbQuoteIdentifier(project_connection, table_name))
    as.numeric(DBI::dbGetQuery(project_connection, query)$n[[1]])
  }, numeric(1))

  verification <- data.frame(
    table_name = expected_tables,
    row_count = counts,
    stringsAsFactors = FALSE
  )

  print(verification, row.names = FALSE)
  cat("\nDatabase setup complete: all nine benchmark tables are available.\n")
}, finally = {
  cleanup_connections()
})
