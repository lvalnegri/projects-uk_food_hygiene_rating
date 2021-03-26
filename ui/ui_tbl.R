##########################################################
# SHINY - FOOD HYGIENE RATINGS * TABLE - ui.R (ui_tbl.R) #
##########################################################

tabPanel('TABLE', icon = icon('th'),
         
    sidebarPanel(
        

        width = 3
        
    ),

    mainPanel(

        withSpinner( DTOutput('out_tbl') )

    )

)
