###############################################################
# SHINY - FOOD HYGIENE RATINGS * CHOROPLETH - ui.R (ui_cmp.R) #
###############################################################

tabPanel('CHOROPLETH', icon = icon('globe', lib = 'glyphicon'),
         
    sidebarPanel(
        
        pickerInput('cbo_cmp_geo', 'GEOGRAPHY:', lst.geo),

        width = 3
        
    ),

    mainPanel(

        withSpinner( leafletOutput('out_cmp') )

    )

)
