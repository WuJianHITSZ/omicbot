omicbot_skill_tools <- function(skill) {
  gott_workflow <- function(step = "all",
                            data_path = "",
                            reduction = "rnapca",
                            n_components = 10,
                            shape = "free_boundary",
                            layout_name = "spatial_coords",
                            feature = "RegionLoupe") {
    if (!requireNamespace("gotta", quietly = TRUE)) {
      return("Error: package 'gotta' is not installed. Try devtools::install('E:/gotta', upgrade = 'never').")
    }
    if (!requireNamespace("patchwork", quietly = TRUE)) {
      return("Error: package 'patchwork' is not installed.")
    }

    step <- tolower(trimws(step))
    if (!nzchar(step)) step <- "all"
    reduction <- if (nzchar(trimws(reduction))) reduction else "rnapca"
    n_components <- suppressWarnings(as.integer(n_components))
    if (is.na(n_components) || n_components <= 0L) n_components <- 10L
    shape <- if (nzchar(trimws(shape))) shape else "free_boundary"
    layout_name <- if (nzchar(trimws(layout_name))) layout_name else "spatial_coords"
    feature <- if (nzchar(trimws(feature))) feature else "RegionLoupe"

    object <- NULL
    vertex_job <- NULL
    gott_job <- NULL
    result <- list()

    if (step %in% c("load_data", "all")) {
      if (nzchar(data_path) && file.exists(data_path)) {
        object <- readRDS(data_path)
      } else {
        toy_path <- system.file(
          "extdata",
          "example-object-sma-mouse-heart-3-toy.rds",
          package = "gotta"
        )
        if (!nzchar(toy_path) || !file.exists(toy_path)) {
          return("Error: GOTTA toy data not found. Provide data_path.")
        }
        object <- readRDS(toy_path)
      }
      result$load_data <- sprintf("Loaded object: %d cells x %d features", ncol(object), nrow(object))
    }

    if (step %in% c("setup", "all")) {
      if (is.null(object)) return("Error: run load_data first or use step = 'all'.")
      vertex_job <- gotta::VertexJob(reduction = reduction, n.components = n_components)
      gott_job <- gotta::GOTTJob(vertex.job = vertex_job, shape = shape)
      object <- gotta::FindSpatialNeighbors(object, col.names = c("original_y", "original_x"))
      object <- gotta::ComputeCellArea(object, vertex.job = vertex_job)
      result$setup <- "Spatial neighbors found, cell area computed."
    }

    if (step %in% c("plot", "all")) {
      if (is.null(object)) return("Error: run load_data first or use step = 'all'.")
      p <- gotta::MeshFeaturePlot(object, layout.name = layout_name, features = feature) +
        gotta::SurfFeaturePlot(object, layout.name = layout_name, features = paste0("area.", reduction))
      print(p)
      result$plot <- "Spatial plot rendered."
    }

    cart_layout <- paste0(reduction, ".", shape)

    if (step %in% c("gott", "all")) {
      if (is.null(object)) return("Error: run load_data first or use step = 'all'.")
      if (is.null(gott_job)) {
        vertex_job <- gotta::VertexJob(reduction = reduction, n.components = n_components)
        gott_job <- gotta::GOTTJob(vertex.job = vertex_job, shape = shape)
      }
      object <- gotta::RunGOTT(object, gott.job = gott_job, is.pseudo.initial = TRUE)
      result$gott <- sprintf("GOTT complete. Cartogram layout: %s", cart_layout)
    }

    if (step %in% c("plot_gott", "all")) {
      if (is.null(object)) return("Error: run load_data and gott first or use step = 'all'.")
      p <- gotta::MeshFeaturePlot(object, layout.name = cart_layout, features = feature) +
        gotta::SurfFeaturePlot(object, layout.name = cart_layout)
      print(p)
      result$plot_gott <- "GOTT plot rendered."
    }

    if (step %in% c("hyperview", "all")) {
      if (is.null(object)) return("Error: run load_data and gott first or use step = 'all'.")
      if (is.null(vertex_job)) {
        vertex_job <- gotta::VertexJob(reduction = reduction, n.components = n_components)
      }
      object <- gotta::RunHyperView(object, vertex.job = vertex_job, layout.name = cart_layout)
      result$hyperview <- "HyperView complete."
    }

    if (step %in% c("plot_hyperview", "all")) {
      if (is.null(object)) return("Error: run hyperview first or use step = 'all'.")
      p <- gotta::HyperMeshFeaturePlot(object, layout.name = cart_layout, features = feature)
      print(p)
      result$plot_hyperview <- "HyperView plot rendered."
    }

    if (!length(result)) {
      return(sprintf(
        "Unknown step: %s. Use load_data, setup, plot, gott, plot_gott, hyperview, plot_hyperview, or all.",
        step
      ))
    }

    paste(unlist(result, use.names = FALSE), collapse = "\n")
  }

  list(
    ellmer::tool(
      gott_workflow,
      name = "gott_workflow",
      description = "Run steps of the GOTTA/GOTT spatial transcriptomics quick-start workflow.",
      arguments = list(
        step = ellmer::type_string("Workflow step: load_data, setup, plot, gott, plot_gott, hyperview, plot_hyperview, or all."),
        data_path = ellmer::type_string("Optional path to an RDS Seurat object. Empty uses GOTTA toy data."),
        reduction = ellmer::type_string("Reduction name, default rnapca."),
        n_components = ellmer::type_number("Number of components, default 10."),
        shape = ellmer::type_string("GOTT boundary shape: free_boundary, disk, or rect."),
        layout_name = ellmer::type_string("Spatial layout name for the initial plot."),
        feature = ellmer::type_string("Feature to plot, default RegionLoupe.")
      )
    )
  )
}
