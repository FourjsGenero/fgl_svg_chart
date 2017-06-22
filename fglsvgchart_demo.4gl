IMPORT util

IMPORT FGL fglsvgcanvas
IMPORT FGL fglsvgchart

DEFINE rec RECORD
               chart_type STRING,
               ds_count SMALLINT,
               minpos SMALLINT,
               maxpos SMALLINT,
               grid_sx SMALLINT,
               minval SMALLINT,
               maxval SMALLINT,
               grid_sy SMALLINT,
               skip_gl SMALLINT,
               show_points BOOLEAN,
               show_legend BOOLEAN,
               show_origin BOOLEAN,
               curr_dataset SMALLINT,
               curr_item SMALLINT,
               curr_position DECIMAL,
               curr_value DECIMAL,
               curr_label STRING,
               canvas STRING,
               elem_selected STRING
           END RECORD

MAIN
    DEFINE rid, cid SMALLINT,
           root_svg om.DomNode,
           newpos DECIMAL

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

    LET rec.minpos =    0.0
    LET rec.maxpos = 2400.0
    LET rec.minval = -200.0
    LET rec.maxval = 1200.0

    LET cid = fglsvgchart.create("mychart","Export rate (2017)")
    CALL fglsvgchart.setBoundaries(cid, rec.minpos, rec.maxpos, rec.minval, rec.maxval)

    LET rec.grid_sx = 12
    LET rec.grid_sy = 14
    CALL fglsvgchart.defineGrid(cid, rec.grid_sx, rec.grid_sy)

    LET rec.skip_gl = 2

    LET rec.curr_dataset = 1
    LET rec.curr_item = 1
    LET rec.curr_position = 2400.0
    LET rec.curr_value = 500.0
    LET rec.curr_label = "Lab 1"

    CALL init_month_names(cid)
    CALL fglsvgchart.setGridLabelsFromStepsY(cid,rec.skip_gl,NULL)

    LET rec.show_points = TRUE
    CALL fglsvgchart.showPoints(cid, TRUE)

    LET rec.show_legend = TRUE
    CALL fglsvgchart.showDataSetLegend(cid, TRUE)

    LET rec.show_origin = TRUE
    CALL fglsvgchart.showOrigin(cid, TRUE)

                                  
    -- Must define a different width/height for the root svg viewBox to 
    CALL root_svg.setAttribute("viewBox","0 0 6000 4000")

    LET rec.chart_type = fglsvgchart.CHART_TYPE_LINES
    LET rec.ds_count = 2

    INPUT BY NAME rec.*
          ATTRIBUTES( WITHOUT DEFAULTS, UNBUFFERED )

        BEFORE INPUT
           CALL default_chart_data(cid,rec.ds_count)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE ds_count
           CALL default_chart_data(cid,rec.ds_count)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE chart_type
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE show_points
           CALL fglsvgchart.showPoints(cid, rec.show_points)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE show_legend
           CALL fglsvgchart.showDataSetLegend(cid, rec.show_legend)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE show_origin
           CALL fglsvgchart.showOrigin(cid, rec.show_origin)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE minpos
           IF rec.maxpos < rec.minpos THEN
              LET rec.maxpos = rec.minpos + 100
           END IF
           CALL fglsvgchart.setBoundaries(cid, rec.minpos, rec.maxpos, rec.minval, rec.maxval)
           --CALL fglsvgchart.setGridLabelsFromStepsX(cid,2,NULL)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE maxpos
           IF rec.minpos > rec.maxpos THEN
              LET rec.minpos = rec.maxpos - 100
           END IF
           CALL fglsvgchart.setBoundaries(cid, rec.minpos, rec.maxpos, rec.minval, rec.maxval)
           --CALL fglsvgchart.setGridLabelsFromStepsX(cid,2,NULL)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE minval
           IF rec.maxval < rec.minval THEN
              LET rec.maxval = rec.minval + 100
           END IF
           CALL fglsvgchart.setBoundaries(cid, rec.minpos, rec.maxpos, rec.minval, rec.maxval)
           CALL fglsvgchart.setGridLabelsFromStepsY(cid,rec.skip_gl,NULL)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE maxval
           IF rec.minval > rec.maxval THEN
              LET rec.minval = rec.maxval - 100
           END IF
           CALL fglsvgchart.setBoundaries(cid, rec.minpos, rec.maxpos, rec.minval, rec.maxval)
           CALL fglsvgchart.setGridLabelsFromStepsY(cid,rec.skip_gl,NULL)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE grid_sx
           CALL fglsvgchart.defineGrid(cid, rec.grid_sx, rec.grid_sy)
           --CALL fglsvgchart.setGridLabelsFromStepsX(cid,2,NULL)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE grid_sy
           CALL fglsvgchart.defineGrid(cid, rec.grid_sx, rec.grid_sy)
           CALL fglsvgchart.setGridLabelsFromStepsY(cid,rec.skip_gl,NULL)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE skip_gl
           CALL fglsvgchart.setGridLabelsFromStepsY(cid,rec.skip_gl,NULL)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON CHANGE curr_item
           IF rec.curr_item > fglsvgchart.getDataItemCount(cid) + 1 THEN
              CALL mbox_ok(SFMT("Data item %1 must be created before adding further items",rec.curr_item-1))
              LET rec.curr_item = rec.curr_item - 1
           END IF

        ON ACTION set_value
           IF rec.curr_dataset<=rec.ds_count THEN
              IF rec.curr_item > fglsvgchart.getDataItemCount(cid) THEN
                 PROMPT SFMT("This will add a new data item,\nEnter a position greater as %1",rec.curr_position) FOR newpos
                 IF NOT int_flag THEN
                    IF newpos > rec.curr_position THEN
                       LET rec.curr_position = newpos
                       CALL fglsvgchart.defineDataItem(cid, rec.curr_item, rec.curr_position, NULL)
                       CALL fglsvgchart.setDataItemValue(cid, rec.curr_item, rec.curr_dataset, rec.curr_value, rec.curr_label)
                    ELSE
                       CALL mbox_ok("Invalid position, data item not created.")
                    END IF
                 END IF
              END IF
           END IF
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON ACTION random
           CALL random_chart_data(cid,rec.ds_count,rec.minpos,rec.maxpos,rec.minval,rec.maxval,rec.curr_value)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON ACTION clear
           CALL clean_chart_data(cid,rec.ds_count)
           CALL draw_graph(rid,cid,root_svg,rec.chart_type)

        ON ACTION svg_selection ATTRIBUTES(DEFAULTVIEW = NO)
           LET rec.elem_selected = rec.canvas

    END INPUT

    CALL fglsvgchart.destroy(cid)
    CALL fglsvgchart.finalize()

    CALL fglsvgcanvas.destroy(rid)
    CALL fglsvgcanvas.finalize()

END MAIN

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

FUNCTION clean_chart_data(cid,ds)
    DEFINE cid, ds SMALLINT
    DEFINE x SMALLINT

    CALL fglsvgchart.clean(cid)

    IF ds>0 THEN CALL fglsvgchart.defineDataSet(cid, 1, "North",      "my_data_style_1") END IF
    IF ds>1 THEN CALL fglsvgchart.defineDataSet(cid, 2, "North-East", "my_data_style_2") END IF
    IF ds>2 THEN CALL fglsvgchart.defineDataSet(cid, 3, "North-West", "my_data_style_3") END IF
    IF ds>3 THEN CALL fglsvgchart.defineDataSet(cid, 4, "East",       "my_data_style_4") END IF

END FUNCTION

FUNCTION default_chart_data(cid,ds)
    DEFINE cid, ds SMALLINT
    DEFINE x SMALLINT

    CALL clean_chart_data(cid,ds)

    LET x=0
    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 200, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1, 150.50, "Jan1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2, 45.25,  "Jan1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3, 25.65,  "Jan1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4, 135.80, "Jan1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 400, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1, -150.30, "Feb1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  423.43, "Feb1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  625.15, "Feb1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  835.82, "Feb1.4") END IF

    -- Interim values
    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 500, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  -60.64, "Feb1.1.1") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  455.82, "Feb1.4.1") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 600, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1, 1000.50, "Mar1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  223.43, "Mar1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  125.15, "Mar1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  735.82, "Mar1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 800, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  800.00, "Apr1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  723.13, "Apr1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  425.25, "Apr1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  235.82, "Apr1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1000, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  423.59, "May1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  243.13, "May1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  145.15, "May1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  325.13, "May1.4") END IF

    -- Interim values
    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1100, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  353.49, "May1.1.1") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  250.13, "May1.4.1") END IF

    -- Interim values
    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1150, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  300.56, "May1.1.2") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  150.13, "May1.4.2") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1200, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1, -150.50, "Jun1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  723.13, "Jun1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  455.15, "Jun1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  923.13, "Jun1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1400, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  250.80, "Jul1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  123.13, "Jul1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  333.15, "Jul1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  423.13, "Jul1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1600, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  150.50, "Aug1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  423.13, "Aug1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  533.15, "Aug1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  823.13, "Aug1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 1800, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  250.00, "Sep1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  323.13, "Sep1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  433.15, "Sep1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  223.13, "Sep1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 2000, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  250.50, "Oct1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  523.43, "Oct1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  233.45, "Oct1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  123.63, "Oct1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 2200, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,  150.20, "Nov1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,  123.43, "Nov1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,  133.45, "Nov1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,  222.63, "Nov1.4") END IF

    CALL fglsvgchart.defineDataItem(cid, x:=x+1, 2400, NULL)
    IF ds>0 THEN CALL fglsvgchart.setDataItemValue(cid, x, 1,   50.89, "Dec1.1") END IF
    IF ds>1 THEN CALL fglsvgchart.setDataItemValue(cid, x, 2,   23.43, "Dec1.2") END IF
    IF ds>2 THEN CALL fglsvgchart.setDataItemValue(cid, x, 3,   33.45, "Dec1.3") END IF
    IF ds>3 THEN CALL fglsvgchart.setDataItemValue(cid, x, 4,   23.63, "Dec1.4") END IF

END FUNCTION

FUNCTION min_max_rand(min,max)
    DEFINE min, max DECIMAL
    DEFINE r DECIMAL
    LET r = util.Math.rand(100) / 100 -- %
    RETURN ( min + ((max-min) * r) )
END FUNCTION

FUNCTION random_chart_data(cid,ds,minpos,maxpos,minval,maxval,avgval)
    DEFINE cid, ds SMALLINT,
           minpos, maxpos, minval, maxval, avgval DECIMAL
    DEFINE d, i, totpos SMALLINT,
           pos, dpos, da, val DECIMAL

    CALL clean_chart_data(cid,ds)

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
    FOR i=1 TO totpos
        CALL fglsvgchart.defineDataItem(cid, i, pos, NULL)
        FOR d=1 TO ds
            LET val = min_max_rand(minval,maxval)
            CALL fglsvgchart.setDataItemValue(cid, i, d, val, SFMT("R%1.%2",i,d))
        END FOR
        LET pos = pos + dpos
    END FOR

END FUNCTION

FUNCTION draw_graph(rid,cid,root_svg,ct)
    DEFINE rid, cid SMALLINT,
           root_svg, n om.DomNode,
           ct SMALLINT
    DEFINE attr DYNAMIC ARRAY OF om.SaxAttributes,
           defs om.DomNode

    CALL fglsvgcanvas.clean(rid)

    LET attr[1] = om.SaxAttributes.create()
    CALL attr[1].addAttribute(SVGATT_STROKE,         "gray" )

    LET attr[2] = om.SaxAttributes.create()
    CALL attr[2].addAttribute(SVGATT_FONT_FAMILY,    "Arial" )
    CALL attr[2].addAttribute(SVGATT_FONT_SIZE,      "3em" )
    CALL attr[2].addAttribute(SVGATT_STROKE,         "gray" )
    CALL attr[2].addAttribute(SVGATT_STROKE_WIDTH,   "0.02em" )
    CALL attr[2].addAttribute(SVGATT_FILL,           "blue" )

    LET attr[3] = om.SaxAttributes.create()
    CALL attr[3].addAttribute(SVGATT_STROKE,         "red" )
    CALL attr[3].addAttribute(SVGATT_STROKE_WIDTH,   "3px" )

    LET attr[4] = om.SaxAttributes.create()
    CALL attr[4].addAttribute(SVGATT_FONT_FAMILY,    "Arial" )
    CALL attr[4].addAttribute(SVGATT_FONT_SIZE,      "3em" )

    LET attr[5] = om.SaxAttributes.create()
    CALL attr[5].addAttribute(SVGATT_FONT_FAMILY,    "Arial" )
    CALL attr[5].addAttribute(SVGATT_FONT_SIZE,      "3em" )

    LET attr[6] = om.SaxAttributes.create()
    CALL attr[6].addAttribute(SVGATT_STROKE,         "gray" )
    CALL attr[6].addAttribute(SVGATT_STROKE_WIDTH,   "1px" )
    CALL attr[6].addAttribute(SVGATT_FILL,           "lightYellow" )

    LET attr[7] = om.SaxAttributes.create()
    CALL attr[7].addAttribute(SVGATT_FONT_FAMILY,    "Arial" )
    CALL attr[7].addAttribute(SVGATT_FONT_SIZE,      "2em" )

    -- Dataset colors

    LET attr[11] = om.SaxAttributes.create()
    CALL attr[11].addAttribute(SVGATT_FILL,           "cyan" )
    CALL attr[11].addAttribute(SVGATT_FILL_OPACITY,   "0.3" )
    CALL attr[11].addAttribute(SVGATT_STROKE,         "blue" )
    CALL attr[11].addAttribute(SVGATT_STROKE_WIDTH,   "1px" )
    --CALL attr[11].addAttribute(SVGATT_STROKE_OPACITY, "0.7" )

    LET attr[12] = om.SaxAttributes.create()
    CALL attr[12].addAttribute(SVGATT_FILL,           "yellow" )
    CALL attr[12].addAttribute(SVGATT_FILL_OPACITY,   "0.3" )
    CALL attr[12].addAttribute(SVGATT_STROKE,         "orange" )
    CALL attr[12].addAttribute(SVGATT_STROKE_WIDTH,   "1px" )
    --CALL attr[12].addAttribute(SVGATT_STROKE_OPACITY, "0.7" )

    LET attr[13] = om.SaxAttributes.create()
    CALL attr[13].addAttribute(SVGATT_FILL,           "green" )
    CALL attr[13].addAttribute(SVGATT_FILL_OPACITY,   "0.3" )
    CALL attr[13].addAttribute(SVGATT_STROKE,         "darkGreen" )
    CALL attr[13].addAttribute(SVGATT_STROKE_WIDTH,   "1px" )
    --CALL attr[13].addAttribute(SVGATT_STROKE_OPACITY, "0.7" )

    LET attr[14] = om.SaxAttributes.create()
    CALL attr[14].addAttribute(SVGATT_FILL,           "orange" )
    CALL attr[14].addAttribute(SVGATT_FILL_OPACITY,   "0.3" )
    CALL attr[14].addAttribute(SVGATT_STROKE,         "red" )
    CALL attr[14].addAttribute(SVGATT_STROKE_WIDTH,   "1px" )
    --CALL attr[14].addAttribute(SVGATT_STROKE_OPACITY, "0.7" )


    LET defs = fglsvgcanvas.defs( NULL )
    CALL defs.appendChild( fglsvgcanvas.styleList(
                              fglsvgcanvas.styleDefinition(".grid",              attr[1])
                           || fglsvgcanvas.styleDefinition(".main_title",        attr[2])
                           || fglsvgcanvas.styleDefinition(".x_axis",            attr[3])
                           || fglsvgcanvas.styleDefinition(".y_axis",            attr[3])
                           || fglsvgcanvas.styleDefinition(".grid_x_label",      attr[4])
                           || fglsvgcanvas.styleDefinition(".grid_y_label",      attr[5])
                           || fglsvgcanvas.styleDefinition(".legend_box",        attr[6])
                           || fglsvgcanvas.styleDefinition(".legend_label",      attr[7])

                           || fglsvgcanvas.styleDefinition(".my_data_style_1",   attr[11])
                           || fglsvgcanvas.styleDefinition(".my_data_style_2",   attr[12])
                           || fglsvgcanvas.styleDefinition(".my_data_style_3",   attr[13])
                           || fglsvgcanvas.styleDefinition(".my_data_style_4",   attr[14])
                           )
                         )
    CALL root_svg.appendChild( defs )

    CALL fglsvgchart.render( cid, ct, root_svg, NULL,NULL,NULL,NULL )

--display root_svg.toString()

    CALL fglsvgcanvas.display(rid)

END FUNCTION
