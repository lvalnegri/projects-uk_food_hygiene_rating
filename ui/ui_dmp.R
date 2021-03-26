############################################################
# SHINY - FOOD HYGIENE RATINGS * DOTSMAP - ui.R (ui_dmp.R) #
############################################################

tabPanel('DOTSMAP', icon = icon('map-marked-alt'),
         
    sidebarPanel(
        
        # GEOGRAPHY -----------------------------
        a(id = 'tgl_dmp_geo', 'Show/Hide GEOGRAPHY', class = 'toggle-choices'),  
        div(id = 'hdn_dmp_geo', class = 'toggle-choices-content',
            p(),

            pickerInput('cbo_dmp_geo_rgn', 'REGION:', lst.rgn),
            uiOutput('ui_dmp_geo_lad')

        # End Controls GEOGRAPHY --------------
        ), br(),
        
        # VALUES -----------------------------
        a(id = 'tgl_dmp_vls', 'Show/Hide VALUES', class = 'toggle-choices'),  
        div(id = 'hdn_dmp_vls', class = 'toggle-choices-content',
            p(),

            pickerInput('cbo_dmp_vls_shw', 'SHOW:', lst.shw),

            radioGroupButtons('chk_dmp_vls_grp', 'GROUP BY:', 
                choices = c('Ratings', 'Groups'), 
                individual = TRUE,
                checkIcon = list( 
                    yes = tags$i(class = "fa fa-circle", style = "color: steelblue"),
                    no = tags$i(class = "fa fa-circle-o", style = "color: steelblue")
                ),
                direction = 'vertical'
            )

        # End Controls VALUES --------------
        ), br(),
        
        # FILTERS -----------------------------
        a(id = 'tgl_dmp_flt', 'Show/Hide FILTERS', class = 'toggle-choices'),  
        div(id = 'hdn_dmp_flt', class = 'toggle-choices-content',
            p(),

            pickerInput('cbo_dmp_flt_rtg', 'RATING(S):', lst.rtg),

            pickerInput('cbo_dmp_flt_sch', 'SCORE(S) HYGIENE:', lst.rtg),

            pickerInput('cbo_dmp_flt_scs', 'SCORE(S) STRUCTURAL:', lst.rtg),

            pickerInput('cbo_dmp_flt_scc', 'SCORE(S) CONFIDENCE:', lst.rtg),

            pickerInput('cbo_dmp_flt_sct', 'SECTOR(S):', lst.sct)
            
        # End Controls FILTERS --------------
        ), br(),
        
        # OPTIONS -----------------------------
        a(id = 'tgl_dmp_opt', 'Show/Hide OPTIONS', class = 'toggle-choices'),  
        div(id = 'hdn_dmp_opt', class = 'toggle-choices-content',
            p(),

            radioGroupButtons('chk_dmp_grp', 'GROUP BY:', 
                choices = c('Ratings', 'Groups'), 
                individual = TRUE,
                checkIcon = list( 
                    yes = tags$i(class = "fa fa-circle", style = "color: steelblue"),
                    no = tags$i(class = "fa fa-circle-o", style = "color: steelblue")
                ),
                direction = 'vertical'
            )

        # End Controls OPTIONS --------------
        ), br(),
        
        # DOWNLOAD -----------------------------
        a(id = 'tgl_dmp_dwn', 'Show/Hide DOWNLOAD', class = 'toggle-choices'),  
        div(id = 'hdn_dmp_dwn', class = 'toggle-choices-content',
            p()


        # End Controls DOWNLOAD --------------
        ), br(),
        
        width = 3
        
    ),

    mainPanel(

        withSpinner( leafletOutput('out_dmp') )

    )

)
