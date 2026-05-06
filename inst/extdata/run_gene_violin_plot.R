## Gene Expression Violin Plot
## Loads inst/extdata/gene_expression.csv and renders a violin plot per gene,
## split by Control vs Treatment group.

# Dependencies
library(ggplot2)

# ── 1. Load data ──────────────────────────────────────────────────────────────
gene_data <- read.csv("inst/extdata/gene_expression.csv", stringsAsFactors = FALSE)

cat("Dimensions:", dim(gene_data), "\n")
cat("Genes     :", paste(unique(gene_data$Gene), collapse = ", "), "\n")
cat("Groups    :", paste(unique(gene_data$Group), collapse = ", "), "\n")
cat("Samples   :", length(unique(gene_data$Sample)), "\n")

# ── 2. Violin plot ────────────────────────────────────────────────────────────
p <- ggplot(gene_data, aes(x = Gene, y = Expression, fill = Group)) +
  geom_violin(
    alpha        = 0.7,
    position     = position_dodge(0.9),
    trim         = FALSE,
    color        = "grey30",
    linewidth    = 0.4
  ) +
  geom_boxplot(
    width        = 0.15,
    position     = position_dodge(0.9),
    outlier.shape = NA,
    fill         = "white",
    alpha        = 0.8
  ) +
  geom_jitter(
    position = position_jitterdodge(jitter.width = 0.08, dodge.width = 0.9),
    size     = 0.9,
    alpha    = 0.4
  ) +
  scale_fill_manual(values = c(Control = "#1976D2", Treatment = "#E64A19")) +
  labs(
    title = "Gene Expression Distribution by Group",
    x     = NULL,
    y     = "Expression Level",
    fill  = "Group"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title          = element_text(face = "bold", hjust = 0.5, size = 15),
    axis.text.x         = element_text(face = "italic", size = 12),
    legend.position     = "top",
    panel.grid.major.x  = element_blank()
  )

# ── 3. Display ────────────────────────────────────────────────────────────────
print(p)

