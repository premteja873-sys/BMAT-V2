# 00_setup.R
# Creates the folders used by the simplified project.

folders <- c("data", "results", "plots", "docs", "sql")

for (folder in folders) {
  dir.create(folder, showWarnings = FALSE)
}

# Packages are needed only when creating/reconnecting to PostgreSQL or
# collecting a new timing dataset. The saved analysis itself uses base R.
database_packages <- c("DBI", "RPostgres", "microbenchmark", "rstudioapi")
missing_packages <- database_packages[
  !vapply(database_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  cat("Missing optional database packages:\n")
  cat(paste("-", missing_packages), sep = "\n")
  cat("\nInstall them with:\n")
  cat(
    "install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    "))\n",
    sep = ""
  )
}

cat("Project folders are ready.\n")
cat("Working directory:", getwd(), "\n")
