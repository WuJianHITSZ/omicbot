#!/usr/bin/env Rscript
# Save or recreate `plot_l1demo` and write it to a PNG file.
# - If `plot_l1demo` exists in the environment it is saved directly.
# - Otherwise, if `df_l1demo` exists, the script fits OLS and L1 (median) models,
#   recreates the plot and saves it.

suppressPackageStartupMessages({
  library(ggplot2)
})

out_file <- "plot_l1demo.png"
width <- 6
height <- 4
dpi <- 300

if (exists("plot_l1demo", inherits = TRUE)) {
  ggsave(filename = out_file, plot = plot_l1demo, width = width, height = height, dpi = dpi)
  cat("Saved", normalizePath(out_file), "\n")
} else if (exists("df_l1demo", inherits = TRUE)) {
  # Recreate OLS and L1 fits and the plot
  ols <- lm(y ~ x, data = df_l1demo)
  if (!requireNamespace("quantreg", quietly = TRUE)) {
    stop("Package 'quantreg' is required to recreate L1 fit. Install with: install.packages('quantreg')")
  }
  l1 <- quantreg::rq(y ~ x, tau = 0.5, data = df_l1demo)

  newx <- data.frame(x = seq(min(df_l1demo$x, na.rm = TRUE),
                             max(df_l1demo$x, na.rm = TRUE),
                             length.out = 200))
  newx$ols <- predict(ols, newdata = newx)
  newx$l1  <- predict(l1,  newdata = newx)

  plot_l1demo <- ggplot(df_l1demo, aes(x = x, y = y)) +
    geom_point() +
    geom_line(data = newx, aes(x = x, y = ols), color = "blue", size = 0.8) +
    geom_line(data = newx, aes(x = x, y = l1),  color = "red",  size = 0.8) +
    theme_minimal()

  ggsave(filename = out_file, plot = plot_l1demo, width = width, height = height, dpi = dpi)
  cat("Recreated and saved", normalizePath(out_file), "\n")
} else {
  stop("Neither 'plot_l1demo' nor 'df_l1demo' exist in the environment. Load data or run in the interactive session where the objects are available.")
}
