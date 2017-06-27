IMPORT util

IMPORT FGL fglsvgcanvas
IMPORT FGL fglsvgchart

DEFINE params RECORD
               chart_type SMALLINT,
               chart_mode SMALLINT,
               ds_count SMALLINT,
               minpos DECIMAL(10,4),
               maxpos DECIMAL(10,4),
               grid_sx SMALLINT,
               minval DECIMAL(10,4),
               maxval DECIMAL(10,4),
               grid_sy SMALLINT,
               rect_ratio DECIMAL(10,3),
               skip_glx SMALLINT,
               skip_gly SMALLINT,
               show_points BOOLEAN,
               points_style BOOLEAN,
               show_title BOOLEAN,
               show_legend BOOLEAN,
               show_origin BOOLEAN,
               show_plab BOOLEAN,
               show_vlab BOOLEAN,
               curr_dataset SMALLINT,
               curr_item SMALLINT,
               curr_position DECIMAL,
               curr_value DECIMAL,
               curr_label STRING,
               canvas STRING,
               elem_selected STRING
           END RECORD

CONSTANT MAX_DS = 4

MAIN
    DEFINE rid, cid SMALLINT,
           root_svg om.DomNode,
           pos DECIMAL

    OPEN FORM f1 FROM "fglsvgchart_demo"
    DISPLAY FORM f1

    OPTIONS FIELD ORDER FORM

    CALL fglsvgcanvas.initialize()
    LET rid = fglsvgcanvas.create("formonly.canvas")
    LET root_svg = fglsvgcanvas.setRootSVGAttributes( NULL,
                                   NULL, NULL,
                                   NULL, -- Note: viewBox is set later
                                   "xMidYMid meet"
                                )
    CALL root_svg.setAttribute(SVGATT_CLASS,"root_svg")

    CALL fglsvgchart.initialize()

    LET params.chart_type = fglsvgchart.CHART_TYPE_LINES
    LET params.chart_mode = 1
    LET params.ds_count = 2
    LET params.minpos =    0.0
    LET params.maxpos = 2400.0
    LET params.minval = -200.0
    LET params.maxval = 1200.0
    LET params.grid_sx = 12
    LET params.skip_glx = 2
    LET params.grid_sy = 14
    LET params.skip_gly = 1
    LET params.rect_ratio = 1.0
    LET params.show_title  = TRUE
    LET params.show_points = TRUE
    LET params.show_legend = TRUE
    LET params.show_origin = TRUE
    LET params.show_plab   = TRUE
    LET params.show_vlab   = TRUE

    LET params.curr_dataset = 1
    LET params.curr_item = 1
    LET params.curr_position = params.minpos
    LET params.curr_value = 500.0
    LET params.curr_label = "Lab 1"

    LET cid = fglsvgchart.create("mychart")

    -- Must define a different width/height for the root svg viewBox ...
    CALL root_svg.setAttribute("viewBox","0 0 2 1")


    INPUT BY NAME params.*
          ATTRIBUTES( WITHOUT DEFAULTS, UNBUFFERED )

        BEFORE INPUT
           CALL sample1_chart_data(cid)
           CALL set_params_and_render(rid,cid,root_svg,TRUE,TRUE)

        ON CHANGE chart_type
           CALL set_params_and_render(rid,cid,root_svg,TRUE,FALSE)
        ON CHANGE chart_mode
           CALL set_params_and_render(rid,cid,root_svg,TRUE,TRUE)
        ON CHANGE ds_count
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE show_title
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE show_points
           IF NOT params.show_points THEN
              LET params.points_style=FALSE
           END IF
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE points_style
           IF params.points_style THEN
              LET params.show_points=TRUE
           END IF
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE show_legend
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE show_origin
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE show_plab
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE show_vlab
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE minpos
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE maxpos
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE minval
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE maxval
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE grid_sx
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE grid_sy
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE skip_glx
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE skip_gly
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON CHANGE rect_ratio
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)

        ON ACTION minpos_minus
           LET params.minpos = params.minpos - (params.maxpos-params.minpos)*0.05
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON ACTION maxpos_plus
           LET params.maxpos = params.maxpos + (params.maxpos-params.minpos)*0.05
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON ACTION minval_minus
           LET params.minval = params.minval - (params.maxval-params.minval)*0.05
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON ACTION maxval_plus
           LET params.maxval = params.maxval + (params.maxval-params.minval)*0.05
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)
        ON ACTION ratio_plus
           LET params.rect_ratio = params.rect_ratio + params.rect_ratio*0.05
           CALL set_params_and_render(rid,cid,root_svg,FALSE,FALSE)

        ON CHANGE curr_item
           IF params.curr_item > fglsvgchart.getDataItemCount(cid) + 1 THEN
              CALL mbox_ok(SFMT("Data item %1 must be created before adding further items",params.curr_item-1))
              LET params.curr_item = params.curr_item - 1
           END IF

        ON ACTION set_value ATTRIBUTES(ACCELERATOR="CONTROL-S")
           IF params.curr_dataset<=params.ds_count THEN
              LET pos = NULL
              IF params.curr_item > fglsvgchart.getDataItemCount(cid) THEN
                 PROMPT SFMT("This will add a new data item,\nEnter a position greater as %1",params.curr_position) FOR pos
                 IF NOT int_flag THEN
                    IF pos > params.curr_position THEN
                       LET params.curr_position = pos
                       CALL fglsvgchart.defineDataItem(cid, params.curr_item, pos, NULL)
                    ELSE
                       CALL mbox_ok("Invalid position, data item not created.")
                       LET pos = NULL
                    END IF
                 END IF
              ELSE
                 LET pos = params.curr_position
              END IF
              IF pos IS NOT NULL THEN
                 CALL fglsvgchart.setDataItemValue(cid, params.curr_item, params.curr_dataset, params.curr_value, params.curr_label)
                 CALL draw_graph(rid,cid,root_svg,params.chart_type)
              END IF
           END IF

        ON ACTION render ATTRIBUTES(ACCELERATOR="CONTROL-R")
           CALL set_params_and_render(rid,cid,root_svg,FALSE,TRUE)

        ON ACTION clear ATTRIBUTES(ACCELERATOR="CONTROL-C")
           CALL fglsvgchart.clean(cid)
           CALL draw_graph(rid,cid,root_svg,params.chart_type)

        ON ACTION svg_selection ATTRIBUTES(DEFAULTVIEW = NO)
           LET params.elem_selected = params.canvas

    END INPUT

    CALL fglsvgchart.destroy(cid)
    CALL fglsvgchart.finalize()

    CALL fglsvgcanvas.destroy(rid)
    CALL fglsvgcanvas.finalize()

END MAIN

FUNCTION set_params_and_render(cid,rid,root_svg,ms,rc)
    DEFINE cid, rid SMALLINT,
           root_svg om.DomNode,
           ms, rc BOOLEAN

    CASE params.chart_mode
      WHEN 1 -- sample 1
           CALL fglsvgchart.setTitle(cid,IIF(params.show_title,"Export rates (2017)",NULL))
           IF ms THEN
              LET params.minpos =    0.0
              LET params.maxpos = 2400.0
              LET params.minval = -200.0
              LET params.maxval = 1200.0
              LET params.rect_ratio = 1.0
              LET params.grid_sx = 12
              LET params.grid_sy = 14
              LET params.skip_glx = 2
              LET params.skip_gly = 1
              LET params.curr_value = 500.0
              LET params.show_points = TRUE
           END IF
           CALL sample1_chart_data(cid)
      WHEN 2 -- random 1
           CALL fglsvgchart.setTitle(cid,IIF(params.show_title,"Random values 1",NULL))
           IF rc THEN
              LET params.curr_value = NULL
              CALL random_chart_data(cid,
                                     params.minpos,params.maxpos,
                                     params.minval,params.maxval,
                                     params.curr_value)
           END IF
      WHEN 3 -- random 2
           CALL fglsvgchart.setTitle(cid,IIF(params.show_title,"Random values 2",NULL))
           IF rc THEN
              IF ms THEN
                 LET params.minpos     = -100
                 LET params.maxpos     = +100
                 LET params.minval     =    0
                 LET params.maxval     =   +3
                 LET params.rect_ratio = 35.0
                 LET params.grid_sx    =   10
                 LET params.grid_sy    =    3
                 LET params.curr_value = NULL
                 LET params.show_points = TRUE
              END IF
              CALL random_chart_data(cid,
                                     params.minpos,params.maxpos,
                                     params.minval,params.maxval,
                                     params.curr_value)
           END IF
      WHEN 4 -- Trigo
           CALL fglsvgchart.setTitle(cid,IIF(params.show_title,"Trigo functions",NULL))
           IF rc THEN
              IF ms THEN
                 LET params.minpos     = -5.0
                 LET params.maxpos     = +5.0
                 LET params.minval     = -2.5
                 LET params.maxval     = +2.5
                 LET params.rect_ratio = 2.0
                 LET params.grid_sx    =   20
                 LET params.grid_sy    =   10
                 LET params.curr_value = NULL
                 LET params.show_points = FALSE
              END IF
              CALL trigo_chart_data( cid,
                                     params.minpos,params.maxpos,
                                     params.minval,params.maxval)
           END IF
    END CASE

    CALL fglsvgchart.showPoints(cid, params.show_points, IIF(params.points_style,"points",NULL))

    CALL fglsvgchart.showDataSetLegend(cid, params.show_legend)
    CALL fglsvgchart.showOrigin(cid, params.show_origin)
    CALL fglsvgchart.showGridPositionLabels(cid, params.show_plab)
    CALL fglsvgchart.showGridValueLabels(cid, params.show_vlab)

    IF params.maxpos<params.minpos THEN LET params.maxpos=params.minpos+100 END IF
    IF params.minpos>params.maxpos THEN LET params.minpos=params.maxpos-100 END IF
    IF params.maxval<params.minval THEN LET params.maxval=params.minval+100 END IF
    IF params.minval>params.maxval THEN LET params.minval=params.maxval-100 END IF
    CALL fglsvgchart.setBoundaries(cid, params.minpos, params.maxpos, params.minval, params.maxval)

    CALL fglsvgchart.setRectangularRatio(cid, params.rect_ratio)

    CALL fglsvgchart.defineGrid(cid, params.grid_sx, params.grid_sy)

    IF params.chart_mode!=1 THEN
       CALL fglsvgchart.setGridLabelsFromStepsX(cid,params.skip_glx,NULL)
    END IF
    CALL fglsvgchart.setGridLabelsFromStepsY(cid,params.skip_gly,NULL)

    CALL draw_graph(rid,cid,root_svg,params.chart_type)

END FUNCTION

FUNCTION mbox_ok(msg)
    DEFINE msg STRING
    MENU "SVG Chart Demo" ATTRIBUTES(STYLE="dialog",COMMENT=msg)
        COMMAND "Ok" EXIT MENU
    END MENU
END FUNCTION

FUNCTION init_month_names(cid)
    DEFINE cid SMALLINT
    DEFINE n SMALLINT
    FOR n=1 TO 48 STEP 12
        CALL fglsvgchart.setGridLabelX(cid, n +  1, "Jan" )
        CALL fglsvgchart.setGridLabelX(cid, n +  2, "Feb" )
        CALL fglsvgchart.setGridLabelX(cid, n +  3, "Mar" )
        CALL fglsvgchart.setGridLabelX(cid, n +  4, "Apr" )
        CALL fglsvgchart.setGridLabelX(cid, n +  5, "May" )
        CALL fglsvgchart.setGridLabelX(cid, n +  6, "Jun" )
        CALL fglsvgchart.setGridLabelX(cid, n +  7, "Jul" )
        CALL fglsvgchart.setGridLabelX(cid, n +  8, "Aug" )
        CALL fglsvgchart.setGridLabelX(cid, n +  9, "Sep" )
        CALL fglsvgchart.setGridLabelX(cid, n + 10, "Oct" )
        CALL fglsvgchart.setGridLabelX(cid, n + 11, "Nov" )
        CALL fglsvgchart.setGridLabelX(cid, n + 12, "Dec" )
    END FOR
END FUNCTION

FUNCTION sample1_chart_data(cid)
    DEFINE cid SMALLINT
    DEFINE x SMALLINT

    CALL fglsvgchart.reset(cid)

    CALL fglsvgchart.defineDataSet(cid, 1, "North",      "my_data_style_1")
    CALL fglsvgchart.defineDataSet(cid, 2, "North-East", "my_data_style_2")
    CALL fglsvgchart.defineDataSet(cid, 3, "North-West", "my_data_style_3")
    CALL fglsvgchart.defineDataSet(cid, 4, "East",       "my_data_style_4")

    CALL init_month_names(cid)

    LET x=0
    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 200, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  150.50, "Jan1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,   12.50, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,   45.25, "Jan1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,    7.50, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,   25.65, "Jan1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    2.50, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  135.80, "Jan1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,   11.50, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 400, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1, -150.30, "Feb1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,   10.23, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  423.43, "Feb1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,    3.50, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  625.15, "Feb1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    1.50, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  835.82, "Feb1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    6.50, NULL)

    -- Interim values
    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 500, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  -60.64, "Feb1.1.1")
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  455.82, "Feb1.4.1")

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 600, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1, 1000.50, "Mar1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,   -3.23, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  223.43, "Mar1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,    5.13, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  125.15, "Mar1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    8.23, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  735.82, "Mar1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,  -10.23, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 800, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  800.00, "Apr1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,    2.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  723.13, "Apr1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,   15.13, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  425.25, "Apr1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,   10.23, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  235.82, "Apr1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    3.43, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1000, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  423.59, "May1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,    8.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  243.13, "May1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,    6.83, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  145.15, "May1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    4.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  325.13, "May1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    1.43, NULL)

    -- Interim values
    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1100, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  353.49, "May1.1.1")
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  250.13, "May1.4.1")

    -- Interim values
    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1150, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  300.56, "May1.1.2")
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  150.13, "May1.4.2")

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1200, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1, -150.50, "Jun1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,   11.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  723.13, "Jun1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,    8.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  455.15, "Jun1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    5.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  923.13, "Jun1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    3.43, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1400, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  250.80, "Jul1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,    2.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  123.13, "Jul1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,   13.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  333.15, "Jul1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    8.73, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  423.13, "Jul1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,   11.23, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1600, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  150.50, "Aug1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,    5.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  423.13, "Aug1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,   10.13, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  533.15, "Aug1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    4.23, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  823.13, "Aug1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    2.63, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1800, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  250.00, "Sep1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,   12.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  323.13, "Sep1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,    2.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  433.15, "Sep1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    9.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  223.13, "Sep1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    7.63, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 2000, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  250.50, "Oct1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,   11.43, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  523.43, "Oct1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,    4.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  233.45, "Oct1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    2.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  123.63, "Oct1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    7.63, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 2200, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,  150.20, "Nov1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,   10.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,  123.43, "Nov1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,    3.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,  133.45, "Nov1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    8.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,  222.63, "Nov1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    4.63, NULL)

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 2400, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 1,   50.89, "Dec1.1")
    CALL fglsvgchart.setDataItemValue2(cid,x, 1,    2.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 2,   23.43, "Dec1.2")
    CALL fglsvgchart.setDataItemValue2(cid,x, 2,   10.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 3,   33.45, "Dec1.3")
    CALL fglsvgchart.setDataItemValue2(cid,x, 3,    9.63, NULL)
    CALL fglsvgchart.setDataItemValue(cid, x, 4,   23.63, "Dec1.4")
    CALL fglsvgchart.setDataItemValue2(cid,x, 4,    3.63, NULL)

END FUNCTION

FUNCTION min_max_rand(min,max)
    DEFINE min, max DECIMAL
    DEFINE r DECIMAL
    LET r = util.Math.rand(100) / 100 -- %
    RETURN ( min + ((max-min) * r) )
END FUNCTION

FUNCTION random_chart_data(cid,minpos,maxpos,minval,maxval,avgval)
    DEFINE cid SMALLINT,
           minpos, maxpos, minval, maxval, avgval DECIMAL
    DEFINE d, i, totpos SMALLINT,
           pos, dpos, da, val DECIMAL

    CALL fglsvgchart.reset(cid)

    CALL fglsvgchart.defineDataSet(cid, 1, "DataSet 1", "my_data_style_1")
    CALL fglsvgchart.defineDataSet(cid, 2, "DataSet 2", "my_data_style_2")
    CALL fglsvgchart.defineDataSet(cid, 3, "DataSet 3", "my_data_style_3")
    CALL fglsvgchart.defineDataSet(cid, 4, "DataSet 4", "my_data_style_4")

    CALL util.Math.srand()

    LET totpos = util.Math.rand(90) + 10

    IF avgval IS NOT NULL THEN
       LET da = IIF(avgval<0,-avgval,avgval) / 2
       IF da/2 < maxval-minval THEN
          LET minval = avgval - da
          LET maxval = avgval + da
       END IF
    END IF

    LET pos = minpos
    LET dpos =  (maxpos - minpos) / totpos
    FOR i=1 TO totpos+1
        CALL fglsvgchart.defineDataItem(cid, i, pos, NULL)
        FOR d=1 TO MAX_DS
            LET val = min_max_rand(minval,maxval)
            CALL fglsvgchart.setDataItemValue(cid, i, d, val, SFMT("R%1.%2",i,d))
            LET val = min_max_rand(minval,maxval) / 100
            CALL fglsvgchart.setDataItemValue2(cid, i, d, val, NULL)
        END FOR
        LET pos = pos + dpos
    END FOR

END FUNCTION

FUNCTION trigo_chart_data(cid,minpos,maxpos,minval,maxval)
    DEFINE cid SMALLINT,
           minpos, maxpos, minval, maxval DECIMAL
    DEFINE i, totpos SMALLINT,
           pos, dpos, val, piby2 DECIMAL

    CALL fglsvgchart.reset(cid)

    CALL fglsvgchart.defineDataSet(cid, 1, "Sine",    "my_data_style_1")
    CALL fglsvgchart.defineDataSet(cid, 2, "Cosine",  "my_data_style_2")
    CALL fglsvgchart.defineDataSet(cid, 3, "Tangent", "my_data_style_3")
    CALL fglsvgchart.defineDataSet(cid, 4, "Nat Log", "my_data_style_4")

    LET piby2 = util.Math.pi()/2.0
    LET pos = minpos
    LET dpos =  0.05
    LET i=1
    WHILE pos<=maxpos
        CALL fglsvgchart.defineDataItem(cid, i, pos, NULL)
        LET val = util.Math.sin( pos )
        CALL fglsvgchart.setDataItemValue(cid, i, 1, val, SFMT("sin(%1)=%2",pos,val))
        LET val = util.Math.cos( pos )
        CALL fglsvgchart.setDataItemValue(cid, i, 2, val, SFMT("cos(%1)=%2",pos,val))
        IF pos>=-piby2 AND pos<=piby2 THEN
           LET val = util.Math.tan( pos )
           CALL fglsvgchart.setDataItemValue(cid, i, 3, val, SFMT("tan(%1)=%2",pos,val))
        END IF
        IF pos>=0 THEN
           LET val = util.Math.log( pos )
           CALL fglsvgchart.setDataItemValue(cid, i, 4, val, SFMT("log(%1)=%2",pos,val))
        END IF
        LET pos = pos + dpos
        LET i=i+1
    END WHILE

END FUNCTION


FUNCTION compute_font_size_ratio()
    DEFINE br, tpos, tval DECIMAL
    LET br = 0.025  -- 2.5% of the max viewbox edge
    LET tpos = (params.maxpos-params.minpos)
    LET tpos = IIF(tpos<0,-tpos,tpos)
    LET tval = (params.maxval-params.minval)
    LET tval = IIF(tval<0,-tval,tval)
    IF tpos > tval THEN
       RETURN (tpos * br)
    ELSE
       RETURN (tval * br)
    END IF
END FUNCTION

FUNCTION create_styles(cid, root_svg)
    DEFINE cid SMALLINT,
           root_svg, n om.DomNode
    DEFINE attr om.SaxAttributes,
           buf base.StringBuffer,
           defs om.DomNode,
           fr DECIMAL,
           fs1, fs2, fs3 STRING

    -- It is in the hands of the caller to use the font size of its choice.
    LET fr = fglsvgchart.getFontSizeRatio(cid)
    LET fs1 = (2*fr) ||"%"
    LET fs2 = (5*fr) ||"%"
    LET fs3 = (8*fr) ||"%"

    LET attr = om.SaxAttributes.create()
    LET buf = base.StringBuffer.create()

    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_FILL,           "navy" )
    --CALL attr.addAttribute(SVGATT_FILL_OPACITY,   "0.3" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".grid",attr) )

    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_STROKE,         "gray" )
    CALL attr.addAttribute(SVGATT_STROKE_WIDTH,   "0.1%" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".grid_x_line",attr) )
    CALL buf.append( fglsvgcanvas.styleDefinition(".grid_y_line",attr) )

    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_STROKE,         "red" )
    CALL attr.addAttribute(SVGATT_STROKE_WIDTH,   "0.2%" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".grid_x_axis",attr) )
    CALL buf.append( fglsvgcanvas.styleDefinition(".grid_y_axis",attr) )

    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_FONT_FAMILY,    "Arial" )
    CALL attr.addAttribute(SVGATT_FONT_SIZE,      "1.8em" )
    --CALL attr.addAttribute(SVGATT_STROKE,         "gray" )
    --CALL attr.addAttribute(SVGATT_STROKE_WIDTH,   "0.1%" )
    CALL attr.addAttribute(SVGATT_FILL,           "blue" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".main_title",attr) )

    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_FONT_FAMILY,    "Arial" )
    CALL attr.addAttribute(SVGATT_FONT_SIZE,      fs2 )
    --CALL attr.addAttribute(SVGATT_STROKE,         "gray" )
    --CALL attr.addAttribute(SVGATT_STROKE_WIDTH,   "0.1%" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".grid_x_label",attr) )
    CALL buf.append( fglsvgcanvas.styleDefinition(".grid_y_label",attr) )

    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_STROKE,         "gray" )
    CALL attr.addAttribute(SVGATT_STROKE_WIDTH,   "0.2%" )
    CALL attr.addAttribute(SVGATT_FILL,           "lightYellow" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".legend_box",attr) )

    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_FONT_FAMILY,    "Arial" )
    CALL attr.addAttribute(SVGATT_FONT_SIZE,      "2em" )
    --CALL attr.addAttribute(SVGATT_STROKE,         "gray" )
    --CALL attr.addAttribute(SVGATT_STROKE_WIDTH,   "0.1%" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".legend_label",attr) )

    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_FILL,           "red" )
    CALL attr.addAttribute(SVGATT_FILL_OPACITY,   "0.3" )
    CALL attr.addAttribute(SVGATT_STROKE,         "black" )
    CALL attr.addAttribute(SVGATT_STROKE_WIDTH,   "0.05%" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".points",attr) )

    -- Dataset colors
    CALL attr.clear()
    CALL attr.addAttribute(SVGATT_FILL_OPACITY,   "0.3" )
    CALL attr.addAttribute(SVGATT_STROKE_WIDTH,   "0.1%" )

    CALL attr.addAttribute(SVGATT_FILL,   "cyan" )
    CALL attr.addAttribute(SVGATT_STROKE, "blue" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".my_data_style_1",attr) )

    CALL attr.addAttribute(SVGATT_FILL,   "yellow" )
    CALL attr.addAttribute(SVGATT_STROKE, "orange" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".my_data_style_2",attr) )

    CALL attr.addAttribute(SVGATT_FILL,   "green" )
    CALL attr.addAttribute(SVGATT_STROKE, "darkGreen" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".my_data_style_3",attr) )

    CALL attr.addAttribute(SVGATT_FILL,   "orange" )
    CALL attr.addAttribute(SVGATT_STROKE, "red" )
    CALL buf.append( fglsvgcanvas.styleDefinition(".my_data_style_4",attr) )

    LET defs = fglsvgcanvas.defs( NULL )
    CALL defs.appendChild( fglsvgcanvas.styleList(buf.toString()) )
    CALL root_svg.appendChild( defs )

END FUNCTION

FUNCTION draw_graph(rid,cid,root_svg,ct)
    DEFINE rid, cid SMALLINT,
           root_svg om.DomNode,
           ct SMALLINT

    CALL fglsvgchart.showDataSet(cid, 1, (params.ds_count>0) )
    CALL fglsvgchart.showDataSet(cid, 2, (params.ds_count>1) )
    CALL fglsvgchart.showDataSet(cid, 3, (params.ds_count>2) )
    CALL fglsvgchart.showDataSet(cid, 4, (params.ds_count>3) )

    CALL fglsvgcanvas.clean(rid)
    CALL create_styles(cid, root_svg)
    CALL fglsvgchart.render( cid, ct, root_svg, NULL,NULL,NULL,NULL )
--display root_svg.toString()
    CALL fglsvgcanvas.display(rid)

END FUNCTION
