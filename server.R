###########################################
# SHINY - FOOD HYGIENE RATINGS * server.R #
###########################################

shinyServer(function(input, output, session) {
    
    source(file.path("server", "srv_tbl.R"),  local = TRUE)$value

    source(file.path("server", "srv_plt.R"),  local = TRUE)$value

    source(file.path("server", "srv_dmp.R"),  local = TRUE)$value

    source(file.path("server", "srv_cmp.R"),  local = TRUE)$value
    
})
