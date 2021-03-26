#######################################
# SHINY - FOOD HYGIENE RATINGS * ui.R #
#######################################

shinyUI(fluidPage(
    
    includeCSS(file.path(pub_path, 'styles', 'datamaps.css')),
#    includeScript(file.path(pub_path, 'scripts', 'scripts.js')),
    tags$head(
        tags$link(rel="shortcut icon", href="favicon.png")
    ),
    
    navbarPageWithText(
        
        header = '',
        title = HTML(
            '<div>
                <img src="logo.png" class="logo" height="18" width="18">
                <span class = "title">UK FOOD SHOPS</span>
            </div>'
        ),
        windowTitle = 'UK Food Shops', 
        id = 'mainNav',
        theme = shinytheme('united'), inverse = TRUE,
        
        source(file.path("ui", "ui_tbl.R"),  local = TRUE)$value,
        
        source(file.path("ui", "ui_plt.R"),  local = TRUE)$value,
        
        source(file.path("ui", "ui_dmp.R"),  local = TRUE)$value,
        
        source(file.path("ui", "ui_cmp.R"),  local = TRUE)$value,
        
#        source(file.path("ui", "ui_crd.R"),  local = TRUE)$value,
        
        text = paste('Last updated:', format(last_updated, '%d %b %Y') )
    
    ),

    useShinyjs()

))
