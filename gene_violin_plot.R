## Script: gene_violin_plot.R
## Generates a violin plot of gene expression by Group (Control vs Treatment)
## with facets for each Gene.

# Load required packages
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}
if (!requireNamespace("tidyr", quietly = TRUE)) {
  install.packages("tidyr")
}

library(ggplot2)
library(dplyr)
library(tidyr)

# 1. Load the data
data_path <- "inst/extdata/gene_expression.csv"
gene_data <- read.csv(data_path, stringsAsFactors = FALSE)

# 2. Quick look at the data structure
str(gene_data)
head(gene_data)

# 3. Create violin plot
# Using facet_wrap to separate each gene, and color by Group
p <- ggplot(gene_data, aes(x = Group, y = Expression, fill = Group)) +
  geom_violin(trim = FALSE, alpha = 0.7, draw_quantiles = c(0.25, 0.5, 0.75)) +
  geom_jitter(width = 0.1, alpha = 0.5, size = 1) +
  facet_wrap(~ Gene, scales = "free_y", ncol = 4) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Gene Expression Distribution by Group",
    x = "Group",
    y = "Expression Level",
    fill = "Group"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "top"
  )

# 4. Print the plot
print(p)

