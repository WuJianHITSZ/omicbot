# Load libraries
library(ggplot2)

# Load gene expression data
df <- read.csv("./inst/extdata/gene_expression.csv")

# Create violin plot: gene expression by Gene, colored by Group
p <- ggplot(df, aes(x = Gene, y = Expression, fill = Group)) +
  geom_violin(trim = FALSE, alpha = 0.8, position = position_dodge(0.9)) +
  geom_boxplot(width = 0.15, position = position_dodge(0.9), alpha = 0.9, outlier.shape = NA) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Gene Expression Distribution by Group",
    subtitle = "Violin + Boxplot comparison: Control vs Treatment",
    x = "Gene",
    y = "Expression Level",
    fill = "Group"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5, color = "grey40"),
    axis.text.x = element_text(angle = 30, hjust = 1, face = "bold"),
    legend.position = "top"
  )

# Render to RStudio Plots panel
print(p)

