# GOTT

Use this skill when the user asks about GOTT, GOTTA, HyperView, spatial mesh construction, spatial transcriptomics cartograms, or workflows from the `gotta` R package.

`gotta` means Geometric Optimal Transport Tableau & Alignment. It is an R package for spatial transcriptomics analysis using geometric optimal transport methods. It supports GOTT cartogram layouts, GOTTA alignment between assay layouts, spatial mesh construction, trajectory analysis, HyperView analysis, and mesh-based visualization.

## When To Use

- Run a quick-start GOTT workflow on the packaged toy Seurat object.
- Explain or scaffold code using `VertexJob()`, `GOTTJob()`, `FindSpatialNeighbors()`, `ComputeCellArea()`, `RunGOTT()`, or `RunHyperView()`.
- Help users choose cartogram shapes: `free_boundary`, `disk`, or `rect`.
- Build visualization code with `MeshFeaturePlot()`, `SurfFeaturePlot()`, `CartFeaturePlot()`, `ArrowFeaturePlot()`, `HyperMeshFeaturePlot()`, or `HyperSurfFeaturePlot()`.

## Installation Context

If `gotta` is not installed, recommend installing from the local development repository when available:

```r
devtools::install("E:/gotta", upgrade = "never")
```

For source installs, users need R >= 4.1.0 and a C++17-capable build toolchain. On Windows, use a matching Rtools installation.

## Quick Workflow

```r
library(gotta)
library(Matrix)
library(patchwork)

toy_path <- system.file(
  "extdata",
  "example-object-sma-mouse-heart-3-toy.rds",
  package = "gotta"
)
object <- readRDS(toy_path)

vertex.job <- VertexJob(reduction = "rnapca", n.components = 10)
gott.job <- GOTTJob(vertex.job = vertex.job, shape = "free_boundary")

object <- FindSpatialNeighbors(object, col.names = c("original_y", "original_x"))
object <- ComputeCellArea(object, vertex.job = vertex.job)

print(
  MeshFeaturePlot(object, layout.name = "spatial_coords", features = "RegionLoupe") +
    SurfFeaturePlot(object, layout.name = "spatial_coords", features = "area.rnapca")
)

object <- RunGOTT(object, gott.job = gott.job, is.pseudo.initial = TRUE)

print(
  MeshFeaturePlot(object, layout.name = "rnapca.free_boundary", features = "RegionLoupe") +
    SurfFeaturePlot(object, layout.name = "rnapca.free_boundary")
)

object <- RunHyperView(object, vertex.job = vertex.job, layout.name = "rnapca.free_boundary")
print(HyperMeshFeaturePlot(object, layout.name = "rnapca.free_boundary", features = "RegionLoupe"))
```

## Tool

This skill provides `gott_workflow`, which can run selected steps of the quick workflow. Use `step = "all"` for the full quick start, or one of `load_data`, `setup`, `plot`, `gott`, `plot_gott`, `hyperview`, or `plot_hyperview`.
