# Load gene expression data and create violin plot

library(ggplot2)

# Load data
gene_data <- read.csv("inst/extdata/gene_expression.csv", stringsAsFactors = FALSE)

# Create violin plot with boxplot overlay
p <- ggplot(gene_data, aes(x = Gene, y = Expression, fill = Group)) +
  geom_violin(trim = FALSE, alpha = 0.7, position = position_dodge(0.9)) +
  geom_boxplot(width = 0.15, position = position_dodge(0.9), outlier.shape = NA, alpha = 0.8) +
  scale_fill_manual(values = c("Control" = "#2196F3", "Treatment" = "#FF5722")) +
  labs(
    title = "Gene Expression Distribution by Group",
    x = "Gene",
    y = "Expression Level",
    fill = "Group"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 12),
    axis.text.y = element_text(size = 12),
    legend.position = "top",
    panel.grid.minor = element_blank()
  )

# Print the plot (renders in RStudio Plots panel)
print(p)

