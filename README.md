# Omicbot

Omicbot is an RStudio-native AI assistant package for interactive R programming, exploratory data analysis, and omics-oriented workflows.

It is designed for people who already work inside RStudio and want AI help without constantly switching to a browser chat window. Omicbot brings lightweight assistant-style interaction into the IDE through an addin, quick prompting flow, and model/provider configuration tools.

## Release 0.2.0

This release adds folder-based agent skills, a bundled GOTT/GOTTA skill, skill scaffolding and installation helpers, saved chat sessions, Xiaomi MiMo provider support, packaged gene-expression violin plot examples, and ready-to-use editor keybinding templates for VS Code and Positron.

## Why Omicbot exists

A lot of bioinformatics and data-analysis work in R is iterative: write a small block of code, inspect an object, fix an error, reshape a data frame, sketch a plot, repeat. Omicbot is meant to shorten that loop.

Instead of leaving RStudio to ask for help elsewhere, you can trigger Omicbot from inside the console and use it as a nearby assistant for coding, troubleshooting, and analysis support.

## Demo video

Watch a short usage demo on YouTube:

- https://www.youtube.com/watch?v=_4L2wHKZcRI

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
  Omicbot works with OpenAI, Google Gemini, DeepSeek, Alibaba Qwen through an OpenAI-compatible endpoint, Xiaomi MiMo through an OpenAI-compatible endpoint, and local Ollama models.

- **Saved and resumable chat sessions**  
  Use `save_chat()` to persist the active Omicbot conversation as an RDS file under the Omicbot config directory, then use `resume_chat()` to restore it later with the current package tools re-attached.

- **Folder-based agent skills**  
  Omicbot can discover reusable agent skills from simple folders. Each skill is a directory with a `SKILL.md` instruction file and, optionally, a `tools.R` file that exposes executable `ellmer` tools. User-installed skills live under the Omicbot config directory beside `.env`, so installing a skill is just copying or installing a folder.

- **Skill authoring helpers**  
  Use `create_skill()` to scaffold a new skill folder, `install_skill()` to copy it into the Omicbot config directory, `list_skills()` to inspect available skills, and `read_skill()` to view a skill's instructions.

- **Bundled GOTT/GOTTA skill**  
  The package includes a `gott` skill for spatial omics workflows using the GOTTA package. The skill documents the expected workflow and provides an executable helper tool when GOTTA and its plotting dependencies are installed.

- **Multi-line prompt support**  
  Longer prompts can be passed through clipboard-based flows, which is handy when working with copied code, stack traces, or analysis notes.

- **Configuration and setup utilities**  
  The package includes helper flows for configuration, setup, reset, and related environment management.

- **Example omics visualization workflow**  
  The repository includes example gene expression data and R scripts that load the data and render grouped violin plots in the RStudio Plots panel.

- **Editor keybinding templates**  
  The `config/` directory includes VS Code and Positron keybinding examples for quick access to `quickchat()` and `settings()`.

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

## Provider setup

Run `settings()` to choose a provider and model. Omicbot currently supports:

- OpenAI: `OPENAI_API_KEY`
- Google Gemini: `GOOGLE_API_KEY`
- DeepSeek: `DEEPSEEK_API_KEY`
- Alibaba Qwen: `DASHSCOPE_API_KEY`
- Xiaomi MiMo: `MIMO_API_KEY`
- Ollama: local models from `ollama list`

Alibaba and Xiaomi use OpenAI-compatible endpoints. You can override their defaults with `DASHSCOPE_BASE_URL` and `XIAOMI_MIMO_BASE_URL`.

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

## Save and resume chats

After starting an Omicbot session, save the current conversation:

```r
save_chat()
```

To resume a saved conversation, pass the UUID or saved `.rds` path:

```r
resume_chat("your-chat-uuid")
```

When a resumed session is saved again, Omicbot asks whether to update the existing saved chat or create a new UUID.

## Agent skills

Omicbot skills follow a folder layout inspired by Claude Code and Codex-style local skills:

```text
my-skill/
  SKILL.md
  tools.R      # optional
```

Create a new skill scaffold:

```r
create_skill(
  name = "my-skill",
  title = "My Skill",
  description = "Use this skill for a specific workflow.",
  tools = TRUE
)
```

Install a skill by copying it into the Omicbot config directory:

```r
install_skill("my-skill")
```

List and inspect installed skills:

```r
list_skills()
read_skill("my-skill")
```

By default, user skills are stored under:

```text
~/.config/rstudio/omicbot/skills/
```

Skill folders can be copied directly into that directory. User-installed skills override bundled skills with the same folder name.

Executable skill tools are optional. If a skill includes `tools.R`, it should define:

```r
omicbot_skill_tools <- function(skill) {
  list(
    ellmer::tool(
      function() "ok",
      name = "my_skill_ok",
      description = "Return ok from this skill tool."
    )
  )
}
```

Omicbot automatically advertises installed skills in the agent system prompt and provides a `read_skill(name)` tool so the agent can load full skill instructions before applying a skill-specific workflow.

## Example gene violin plot

The package includes a small example gene-expression dataset at `inst/extdata/gene_expression.csv` plus R scripts that render violin plots for Control and Treatment groups. For example:

```r
source("inst/extdata/run_gene_violin_plot.R")
```

The plot is displayed in the RStudio Plots panel.

## Who this is for

Omicbot is especially relevant for:

- bioinformaticians
- computational biologists
- omics data analysts
- R users doing iterative exploratory analysis
- researchers who want AI assistance closer to their normal IDE workflow

## Coming soon

Planned or desired future directions include:

- **Background sub-agents**  
  A sub-agent model would make it possible to hand off longer-running tasks while the main R session remains focused on interactive work.

- **Additional model-access options**  
  Broader access paths could make Omicbot more convenient for users with existing hosted AI subscriptions or local model environments.

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
