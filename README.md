# Omicbot

Omicbot is an RStudio-native AI assistant package for interactive R programming, exploratory data analysis, and omics-oriented workflows.

It is designed for people who already work inside RStudio and want AI help without constantly switching to a browser chat window. Omicbot brings lightweight assistant-style interaction into the IDE through an addin, quick prompting flow, and model/provider configuration tools.

## Why Omicbot exists

A lot of bioinformatics and data-analysis work in R is iterative: write a small block of code, inspect an object, fix an error, reshape a data frame, sketch a plot, repeat. Omicbot is meant to shorten that loop.

Instead of leaving RStudio to ask for help elsewhere, you can trigger Omicbot from inside the console and use it as a nearby assistant for coding, troubleshooting, and analysis support.

## What it can help with

Omicbot is useful for tasks such as:

- explaining and troubleshooting console errors
- drafting or refining R code
- helping with exploratory data analysis steps
- assisting with plots and visualization code
- speeding up repetitive analysis iteration
- making LLM access easier to configure inside RStudio

For bioinformaticians, that can mean help with workflows like:

- wrangling expression matrices and sample metadata
- debugging RNA-seq, bulk omics, or single-cell analysis scripts
- sketching PCA, clustering, heatmap, volcano plot, or violin plot code
- interpreting intermediate objects and package behavior
- turning an analysis question into a runnable R snippet more quickly

## Features

Current repository structure and documentation indicate support for:

- **Inline AI assistance without interrupting normal coding flow**  
  Omicbot is designed to fit around ordinary R console work rather than forcing a separate “chat mode.” You can keep coding, inspecting objects, and running commands as usual, then invoke the assistant only when needed.

- **Shortcut-first interaction inside RStudio**  
  Instead of bouncing between the IDE and a browser tab, Omicbot is triggered from a convenient keyboard shortcut through the RStudio addin system, making AI interaction feel lightweight and immediate.

- **Console-aware troubleshooting**  
  Omicbot can help interpret and troubleshoot errors based on console context, which is especially useful during fast iterative analysis work.

- **Git patch / diff-oriented tooling**  
  The project structure suggests support for working with code changes in a patch-oriented way, which opens the door to more structured review and editing workflows inside an R-centered environment.

- **Support for multiple API-based LLM backends**  
  Omicbot is being built to work with multiple model providers, giving users flexibility in how they configure and access LLMs from RStudio.

- **Multi-line prompt support**  
  Longer prompts can be passed through clipboard-based flows, which is handy when working with copied code, stack traces, or analysis notes.

- **Configuration and setup utilities**  
  The package includes helper flows for configuration, setup, reset, and related environment management.

## Installation

Install from GitHub:

```r
# install.packages("remotes")
remotes::install_github("WuJianHITSZ/omicbot")
```

Package metadata currently lists these imports:

- `ellmer`
- `getPass`
- `rstudioapi`
- `shiny`

If `remotes` is not installed yet:

```r
install.packages("remotes")
remotes::install_github("WuJianHITSZ/omicbot")
```

## Quick start

After installation:

1. Open **RStudio**.
2. Go to **Tools -> Modify Keyboard Shortcuts**.
3. Search for the addin named **omicbot**.
4. Assign a shortcut key.
5. `Shift+Enter` is recommended by the current package docs.

Then:

- type a prompt into the **Console** as if it were a regular R command
- trigger the Omicbot shortcut instead of pressing Enter
- Omicbot will capture the prompt and generate a response

## Error diagnosis workflow

If you hit an error in the R console:

1. Type `??`
2. Trigger the Omicbot shortcut
3. Omicbot will use the console context to help diagnose the issue

This is one of the most practical use cases for day-to-day R analysis work.

## Multi-line prompts

If your prompt spans multiple lines:

1. Copy the full prompt to the clipboard
2. Return to the RStudio Console
3. Make sure the console caret is active
4. Trigger the Omicbot shortcut

According to the current implementation/docs, Omicbot can pick up the clipboard content for this workflow.

## Who this is for

Omicbot is especially relevant for:

- bioinformaticians
- computational biologists
- omics data analysts
- R users doing iterative exploratory analysis
- researchers who want AI assistance closer to their normal IDE workflow

## Coming soon

Planned or desired future directions include:

- **Agent skills**  
  Reusable capability modules could make Omicbot more specialized, extensible, and task-aware for different analysis scenarios.

- **Background sub-agents**  
  A sub-agent model would make it possible to hand off longer-running tasks while the main R session remains focused on interactive work.

- **Support for ChatGPT / Codex subscription-backed models**  
  Broader model-access options could make Omicbot more convenient for users already subscribed to OpenAI-hosted products.

## Current status

This repository looks like an actively developed R package prototype. It already includes package metadata, tests, addin integration, prompt assets, and several workflow-oriented helper modules.

That makes it a promising foundation for an IDE-native AI assistant focused on practical analysis work in R.

## Development

Typical local package-development commands:

```bash
R CMD build .
R CMD INSTALL .
R CMD check .
Rscript -e 'testthat::test_dir("tests/testthat")'
```

## Contact

Support contact listed in the existing project materials:

- `wujianhitsz@gmail.com`
