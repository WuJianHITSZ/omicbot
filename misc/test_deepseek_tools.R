library(ellmer)

readRenviron("/Users/jianwu/.config/rstudio/omicbot/.env")

agent <- chat_deepseek(model = "deepseek-chat")
agent <- .omicbot_attach_tools(agent, omicbot_tools())
options(omicbot.agent = agent)