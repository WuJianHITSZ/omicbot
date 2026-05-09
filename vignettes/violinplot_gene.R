library(ggplot2)
library(tidyr)

# Load gene expression data
df <- read.csv("inst/extdata/tiny_gene_counts.csv", check.names = FALSE)

# Pivot to long format for ggplot: gene_id | cell | count
long_df <- pivot_longer(df, -gene_id, names_to = "cell", values_to = "count")

# Violin plot of gene expression across cells
p <- ggplot(long_df, aes(x = gene_id, y = count, fill = gene_id)) +
  geom_violin(trim = FALSE, show.legend = FALSE) +
  geom_jitter(width = 0.1, alpha = 0.4, size = 1, show.legend = FALSE) +
  labs(title = "Gene Expression Across Cells",
       x = "Gene", y = "Expression Count") +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p)

