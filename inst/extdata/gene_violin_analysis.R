# Gene Expression Violin Plot Analysis
# This script loads gene expression data and creates violin plots
# Author: Databot
# Date: Generated automatically

# Load required libraries
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("dplyr")) install.packages("dplyr")
if (!require("readr")) install.packages("readr")

library(ggplot2)
library(dplyr)
library(readr)

# ==============================================================================
# DATA LOADING
# ==============================================================================

# Define file path
data_file <- "inst/extdata/gene_expression.csv"

# Load the data
cat("Loading gene expression data from:", data_file, "\n")
gene_data <- read_csv(data_file)

# Display basic information about the data
cat("\nDataset Summary:\n")
cat("Dimensions:", dim(gene_data), "\n")
cat("Columns:", names(gene_data), "\n\n")

# Preview the first few rows
cat("First 10 rows:\n")
print(head(gene_data, 10))

# Summary statistics
cat("\nExpression Value Summary:\n")
print(summary(gene_data$Expression))

cat("\nNumber of unique genes:", length(unique(gene_data$Gene)), "\n")
cat("Genes:", paste(unique(gene_data$Gene), collapse = ", "), "\n")
cat("\nGroups:", paste(unique(gene_data$Group), collapse = ", "), "\n")
cat("Number of samples per gene-group combination:\n")
print(table(gene_data$Gene, gene_data$Group))

# ==============================================================================
# VIOLIN PLOT CREATION
# ==============================================================================

cat("\nCreating violin plot...\n")

# Create violin plot with jittered points
violin_plot <- ggplot(gene_data, 
                      aes(x = Gene, 
                          y = Expression, 
                          fill = Group,
                          color = Group)) +
  # Violin layer
  geom_violin(alpha = 0.6, 
              position = position_dodge(0.9),
              trim = FALSE) +
  # Add boxplot inside violin
  geom_boxplot(width = 0.15, 
               position = position_dodge(0.9),
               alpha = 0.8,
               outlier.shape = NA) +
  # Add individual points
  geom_jitter(position = position_jitterdodge(jitter.width = 0.1,
                                               dodge.width = 0.9),
              size = 1.5,
              alpha = 0.5) +
  # Custom colors
  scale_fill_manual(values = c("Control" = "#2196F3", 
                                "Treatment" = "#FF5722")) +
  scale_color_manual(values = c("Control" = "#1565C0", 
                                 "Treatment" = "#D84315")) +
  # Labels and theme
  labs(title = "Gene Expression Distribution by Treatment Group",
       subtitle = "Violin plots showing expression levels for key genes",
       x = "Gene",
       y = "Expression Level (log2)",
       fill = "Treatment Group",
       color = "Treatment Group") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "grey50"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 11),
    axis.text.y = element_text(size = 11),
    legend.position = "top",
    legend.title = element_text(size = 12, face = "bold"),
    panel.grid.major = element_line(color = "grey90"),
    panel.grid.minor = element_blank()
  )

# Display the plot
print(violin_plot)

# ==============================================================================
# SAVE PLOT (Optional)
# ==============================================================================

# Save to file
output_file <- "inst/extdata/gene_violin_plot.png"
cat("\nSaving plot to:", output_file, "\n")
ggsave(output_file, 
       plot = violin_plot, 
       width = 12, 
       height = 8, 
       dpi = 300)

cat("\n✓ Analysis complete!\n")
cat("✓ Violin plot generated and displayed in RStudio Plots panel\n")
cat("✓ Plot also saved to:", output_file, "\n")

