reset <- function(){
  config_paths <- .omicbot_config_paths()
  config_path <- config_paths$path
  env_path <- .omicbot_env_path(config_path)

  if (file.exists(config_path)) {
    file.remove(config_path)
  }
  if (file.exists(env_path)) {
    file.remove(env_path)
  }

  quickstart()
}
