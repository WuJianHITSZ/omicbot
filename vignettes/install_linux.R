# rm(hi)
 install.packages("devtools")

devtools::install(upgrade = FALSE, dependencies = TRUE)
# devtools::install(upgrade = "never", dependencies = TRUE)
devtools::build()
#rstudioapi::restartSession()








