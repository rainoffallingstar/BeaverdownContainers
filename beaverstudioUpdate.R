dockerR::container_update(containerid = "beaverstudio",
                          imageid = "fallingstar10/beaverstudio:latest",
                          force_rm_container = FALSE,
                          volume = "-v /d/beaver:/home/builduser",
                          ports = "-p 8765:8787 -p 8675:8080",
                          ifD = TRUE,
                          restart = TRUE,
                          run_at_once = TRUE)
