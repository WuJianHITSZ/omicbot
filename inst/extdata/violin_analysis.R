# Violin plot of gene expression data
# Loads gene_expression.csv and displays a grouped violin plot

library(ggplot2)

# Load the gene expression data
gene_data <- read.csv("inst/extdata/gene_expression.csv", stringsAsFactors = FALSE)

# Ensure Gene is a factor with a sensible order (by median expression)
gene_order <- names(sort(tapply(gene_data$Expression, gene_data$Gene, median)))
gene_data$Gene <- factor(gene_data$Gene, levels = gene_order)

# Create the violin plot: expression by Gene, faceted/split by Group
p <- ggplot(gene_data, aes(x = Gene, y = Expression, fill = Group)) +
  geom_violin(trim = FALSE, alpha = 0.7, position = position_dodge(0.9)) +
  geom_boxplot(width = 0.15, position = position_dodge(0.9),
               outlier.shape = NA, alpha = 0.8) +
  scale_fill_manual(values = c("Control" = "#5DADE2", "Treatment" = "#E74C3C")) +
  labs(
    title = "Gene Expression Distribution: Control vs Treatment",
    subtitle = "Violin + boxplot across 30 samples per group",
    x = "Gene",
    y = "Expression Level",
    fill = "Group"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    legend.position = "top"
  )

print(p)
cat("Violin plot displayed successfully.\n")

