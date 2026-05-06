# Load libraries
library(ggplot2)

# Load data
data <- read.csv("inst/extdata/gene_expression.csv")

# Create violin plot with boxplot overlay
p <- ggplot(data, aes(x = Gene, y = Expression, fill = Group)) +
  geom_violin(position = position_dodge(width = 0.9), alpha = 0.7) +
  geom_boxplot(width = 0.15, position = position_dodge(width = 0.9), alpha = 0.9) +
  labs(
    title = "Gene Expression Distribution by Group",
    x = "Gene",
    y = "Expression Level"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Display in RStudio Plots panel
print(p)

