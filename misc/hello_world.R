# Hello World R Script
# This is a simple R script that prints a greeting

# Print a simple message
print("Hello, World!")

# Print a message with the current date and time
cat("\nCurrent date and time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")

# Print R version information
cat("\nR version:", R.version.string, "\n")

# Create a simple vector and print it
numbers <- c(1, 2, 3, 4, 5)
cat("\nA simple vector:", numbers, "\n")

# Calculate and print the sum
cat("Sum of numbers:", sum(numbers), "\n")

# Create a simple data frame
simple_df <- data.frame(
  Name = c("Alice", "Bob", "Charlie"),
  Age = c(25, 30, 35),
  Score = c(85, 92, 88)
)

cat("\nA simple data frame:\n")
print(simple_df)

# End of script
cat("\nScript completed successfully!\n")
