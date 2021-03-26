##########################################################
# SHINY - FOOD HYGIENE RATINGS * PLOTS - ui.R (ui_plt.R) #
##########################################################

tabPanel('PLOTS', icon = icon('chart-area'),
         
    sidebarPanel(
        

        width = 3
        
    ),

    mainPanel(

        withSpinner( plotOutput('out_plt') )

    )

)
