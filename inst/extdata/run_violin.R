# Violin plot of gene expression data
library(ggplot2)

# Load data
gene_data <- read.csv("inst/extdata/gene_expression.csv", stringsAsFactors = FALSE)

# Violin plot: expression distribution per gene, split by group
p <- ggplot(gene_data, aes(x = Gene, y = Expression, fill = Group)) +
  geom_violin(position = position_dodge(width = 0.8), trim = FALSE, alpha = 0.8) +
  geom_boxplot(width = 0.15, position = position_dodge(width = 0.8),
               fill = "white", alpha = 0.6, outlier.shape = NA) +
  scale_fill_manual(values = c("Control" = "#4A90D9", "Treatment" = "#E74C3C")) +
  labs(
    title = "Gene Expression: Control vs Treatment",
    x = "Gene",
    y = "Expression Level",
    fill = "Group"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p)

