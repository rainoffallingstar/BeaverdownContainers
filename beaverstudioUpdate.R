# 注意: 此脚本包含开发环境特定的路径映射
# 路径 /d/beaver 和 /d/fonts-main 是特定于开发环境的
# 在使用前，请根据你的实际路径修改 volume 参数

dockerR::container_update(containerid = "beaverstudio",
                          imageid = "fallingstar10/beaverstudio:latest",
                          force_rm_container = FALSE,
                          volume = "-v /d/beaver:/home/builduser -v /d/fonts-main:/etc/rstudio/fonts",
                          ports = "-p 8765:8787 -p 8675:8080",
                          ifD = TRUE,
                          restart = TRUE,
                          run_at_once = TRUE)
