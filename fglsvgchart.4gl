IMPORT util
IMPORT FGL fglsvgcanvas

PUBLIC TYPE t_value RECORD
                 value DECIMAL,
                 label STRING,
                 value2 DECIMAL,
                 label2 STRING
             END RECORD

PUBLIC TYPE t_data_item RECORD
                 position DECIMAL,
                 title STRING,
                 values DYNAMIC ARRAY OF t_value
             END RECORD

PUBLIC TYPE t_dataset RECORD
                 label STRING,
                 style STRING
             END RECORD

PRIVATE TYPE t_chart RECORD
               name STRING,
               title STRING,
               points BOOLEAN,
               points_style STRING,
               legend BOOLEAN,
               origin BOOLEAN,
               minpos DECIMAL,
               maxpos DECIMAL,
               width DECIMAL,
               minval DECIMAL,
               maxval DECIMAL,
               height DECIMAL,
               grid_np DECIMAL,
               grid_pl BOOLEAN,
               grid_lx DYNAMIC ARRAY OF STRING,
               grid_nv DECIMAL,
               grid_vl BOOLEAN,
               grid_ly DYNAMIC ARRAY OF STRING,
               datasets DYNAMIC ARRAY OF t_dataset,
               items DYNAMIC ARRAY OF t_data_item
             END RECORD
-- options: background color, x-grid line/coord, y-grid line/coord, ...

PRIVATE DEFINE initCount SMALLINT
PRIVATE DEFINE charts DYNAMIC ARRAY OF t_chart

PUBLIC CONSTANT
  CHART_TYPE_BARS = 1,
  CHART_TYPE_POINTS = 2,
  CHART_TYPE_LINES = 3,
  CHART_TYPE_SPLINES = 4

#+ Library initialization function.
#+
#+ This function has to be called before using other functions of this module.
#+
PUBLIC FUNCTION initialize()
    WHENEVER ERROR RAISE
    IF initCount == 0 THEN
       -- prepare resources
    END IF
    LET initCount = initCount + 1
END FUNCTION


#+ Library finalization function.
#+
#+ This function has to be called when the library is not longer used.
#+
PUBLIC FUNCTION finalize()
    LET initCount = initCount - 1
    IF initCount == 0 THEN
       CALL charts.clear()
    END IF
END FUNCTION

#+ Create a new chart and return an ID
#+
#+ This function creates a new chart object and returns its ID.
#+ The chart ID will be used in other functions to identify a
#+ chart object.
#+
#+ @code
#+ DEFINE id SMALLINT
#+ LET id = fglsvgchart.create("mychart","Apple sales")
#+
#+ @param name The name of the chart.
#+ @param title The main title of the chart.
#+
#+ @returnType SMALLINT
#+ @return The chart object ID
#+
PUBLIC FUNCTION create(name,title)
    DEFINE name,title STRING
    DEFINE id, i SMALLINT
    IF LENGTH(name)==0 THEN
       OPEN FORM _dummy_ FROM NULL
    END IF
    FOR i=1 TO charts.getLength()
        IF charts[i].name IS NULL THEN
           LET id = i
        END IF
    END FOR
    IF id==0 THEN
       LET id = charts.getLength() + 1
    END IF
    LET charts[id].name = name
    LET charts[id].title = title
    LET charts[id].points = FALSE
    LET charts[id].points_style = NULL
    LET charts[id].legend = FALSE
    LET charts[id].grid_np = NULL
    LET charts[id].grid_nv = NULL
    CALL setBoundaries(id, 0, 1000, 0, 1000)
    CALL charts[id].items.clear()
    RETURN id
END FUNCTION

#+ Defines the coordinate limits of the chart
#+
#+ Sets the lower and upper limits of the chart coordinate system.
#+
#+ @code
#+ CALL fglsvgchart.setBoundaries(cid, -400, 1200, 0, 5000)
#+
#+ @param id      The chart id
#+ @param minpos  The lower limit for positions (X-axis)
#+ @param maxpos  The upper limit for positions (X-axis)
#+ @param minval  The lower limit for values (Y-axis)
#+ @param maxval  The upper limit for values (Y-axis)
#+
PUBLIC FUNCTION setBoundaries(id,minpos,maxpos,minval,maxval)
    DEFINE name,title STRING,
           minpos, maxpos DECIMAL,
           minval, maxval DECIMAL
    DEFINE id, i SMALLINT
    CALL _check_id(id)
    IF minpos>=maxpos OR minval>=maxval THEN
       OPEN FORM _dummy_ FROM NULL
    END IF
    LET charts[id].minpos = minpos
    LET charts[id].maxpos = maxpos
    LET charts[id].width = maxpos - minpos
    LET charts[id].minval = minval
    LET charts[id].maxval = maxval
    LET charts[id].height = maxval - minval
END FUNCTION

#+ Display points
#+
#+ @param id      The chart id
#+ @param enable  TRUE to display points
#+ @param style   SVG style for points, NULL= use dataset style.
#+
PUBLIC FUNCTION showPoints(id,enable,style)
    DEFINE id SMALLINT,
           enable STRING,
           style STRING
    CALL _check_id(id)
    LET charts[id].points = enable
    LET charts[id].points_style = style
END FUNCTION

#+ Display dataset legend
#+
#+ @param id      The chart id
#+ @param enable  TRUE to display the legend
#+
PUBLIC FUNCTION showDataSetLegend(id,enable)
    DEFINE id SMALLINT,
           enable STRING
    CALL _check_id(id)
    LET charts[id].legend = enable
END FUNCTION

#+ Display value-axis labels
#+
#+ @param id      The chart id
#+ @param enable  TRUE to display the labels
#+
PUBLIC FUNCTION showGridValueLabels(id,enable)
    DEFINE id SMALLINT,
           enable STRING
    CALL _check_id(id)
    LET charts[id].grid_vl = enable
END FUNCTION

#+ Display position-axis labels
#+
#+ @param id      The chart id
#+ @param enable  TRUE to display the labels
#+
PUBLIC FUNCTION showGridPositionLabels(id,enable)
    DEFINE id SMALLINT,
           enable STRING
    CALL _check_id(id)
    LET charts[id].grid_pl = enable
END FUNCTION

#+ Display X/Y axis
#+
#+ @param id      The chart id
#+ @param enable  TRUE to display the axis
#+
PUBLIC FUNCTION showOrigin(id,enable)
    DEFINE id SMALLINT,
           enable STRING
    CALL _check_id(id)
    LET charts[id].origin = enable
END FUNCTION

#+ Destroy a chart object
#+
#+ This function releases all resources allocated for the chart.
#+
#+ @param id      The chart id
#+
PUBLIC FUNCTION destroy(id)
    DEFINE id SMALLINT
    CALL _check_id(id)
    INITIALIZE charts[id].* TO NULL
END FUNCTION

-- Raises an error that can be trapped in callers because of WHENEVER ERROR RAISE
PRIVATE FUNCTION _check_id(id)
    DEFINE id SMALLINT
    IF id>=1 AND id<=charts.getLength() THEN
       IF charts[id].name IS NOT NULL THEN
          RETURN
       END IF
    END IF
    OPEN FORM _dummy_ FROM NULL
END FUNCTION

PRIVATE FUNCTION _check_data_item_index(id, index)
    DEFINE id, index SMALLINT
    IF index<1 OR index>charts[id].items.getLength() THEN
       OPEN FORM _dummy_ FROM NULL
    END IF
END FUNCTION

#+ Set the number of horizontal and vertical grid lines to display.
#+
#+ The style of the grid can be defined with "grid", the line styles
#+ can be defined with "grid_line_x" and "grid_line_y", the style
#+ for X/Y axises can be defined with "x_axis" and "y_axis".
#+
#+ @code
#+ CALL fglsvgchart.defineGrid(id, 12, 40)
#+
#+ @param id     The chart id
#+ @param nx     The number of horizontal lines.
#+ @param ny     The number of vertival lines.
#+
PUBLIC FUNCTION defineGrid(id,nx,ny)
    DEFINE id, nx, ny SMALLINT
    CALL _check_id(id)
    LET charts[id].grid_np = nx
    LET charts[id].grid_nv = ny
END FUNCTION

#+ Set grid labels for X axis.
#+
#+ @code
#+ CALL fglsvgchart.setGridLabelX(id, 12, "December")
#+
#+ @param id       The chart id
#+ @param index  The position of the label
#+ @param label    The text of the label
#+
PUBLIC FUNCTION setGridLabelX(id,index,label)
    DEFINE id SMALLINT,
           index SMALLINT,
           label STRING
    CALL _check_id(id)
    LET charts[id].grid_lx[index] = label
END FUNCTION

#+ Set grid labels for Y axis.
#+
#+ @code
#+ CALL fglsvgchart.setGridLabelY(id, 5, "50%")
#+
#+ @param id       The chart id
#+ @param index  The position of the label
#+ @param label    The text of the label
#+
PUBLIC FUNCTION setGridLabelY(id,index,label)
    DEFINE id SMALLINT,
           index SMALLINT,
           label STRING
    CALL _check_id(id)
    LET charts[id].grid_ly[index] = label
END FUNCTION

#+ Set grid labels for X axis from grid steps.
#+
#+ @code
#+ CALL fglsvgchart.setGridLabelsFromStepsX(id,2,"---&.&&%")
#+
#+ @param id      The chart id
#+ @param skip    The number of steps to skip
#+ @param format  The USING format to create the text
#+
PUBLIC FUNCTION setGridLabelsFromStepsX(id,skip,format)
    DEFINE id SMALLINT,
           skip SMALLINT,
           format STRING
    DEFINE n SMALLINT,
           v, dy DECIMAL
    CALL _check_id(id)
    LET dy = (charts[id].maxpos - charts[id].minpos) / charts[id].grid_np
    CALL charts[id].grid_lx.clear()
    IF format IS NULL THEN
       LET format = "----&.&&"
    END IF
    FOR n=1 TO charts[id].grid_np+1 STEP skip
        LET v = charts[id].minpos + (dy * (n-1))
        LET charts[id].grid_lx[n] = (v USING format)
    END FOR
END FUNCTION

#+ Set grid labels for Y axis from grid steps.
#+
#+ @code
#+ CALL fglsvgchart.setGridLabelsFromStepsY(id,2,"---&.&&%")
#+
#+ @param id      The chart id
#+ @param skip    The number of steps to skip
#+ @param format  The USING format to create the text
#+
PUBLIC FUNCTION setGridLabelsFromStepsY(id,skip,format)
    DEFINE id SMALLINT,
           skip SMALLINT,
           format STRING
    DEFINE n SMALLINT,
           v, dx DECIMAL
    CALL _check_id(id)
    LET dx = (charts[id].maxval - charts[id].minval) / charts[id].grid_nv
    CALL charts[id].grid_ly.clear()
    IF format IS NULL THEN
       LET format = "----&.&&"
    END IF
    FOR n=1 TO charts[id].grid_nv+1 STEP skip
        LET v = charts[id].minval + (dx * (n-1))
        LET charts[id].grid_ly[n] = (v USING format)
    END FOR
END FUNCTION


#+ Remove all data items from the chart.
#+
#+ Call this function to clean the chart.
#+
#+ @code
#+ CALL fglsvgchart.clean(id)
#+
#+ @param id     The chart id
#+
PUBLIC FUNCTION clean(id)
    DEFINE id SMALLINT
    CALL _check_id(id)
    CALL charts[id].items.clear()
END FUNCTION

#+ Define a new data set.
#+
#+ @code
#+ CALL fglsvgchart.defineDataSet(id, 1, "North",      "style_1")
#+ CALL fglsvgchart.defineDataSet(id, 2, "North-East", "style_2")
#+ CALL fglsvgchart.defineDataSet(id, 3, "North-West", "style_3")
#+
#+ @param id         The chart id
#+ @param dsidx      The index of the data set
#+ @param label      The text to display at the base of the item
#+ @param style      The general style to render data items
#+
PUBLIC FUNCTION defineDataSet(id,dsidx,label,style)
    DEFINE id SMALLINT,
           dsidx SMALLINT,
           label STRING,
           style STRING

    CALL _check_id(id)
    LET charts[id].datasets[dsidx].label = label
    LET charts[id].datasets[dsidx].style = style

END FUNCTION

#+ Define a new data item to the chart with a single value.
#+
#+ @code
#+ CALL fglsvgchart.defineDataItem(id, 10, 15.34, "January")
#+
#+ @param id         The chart id
#+ @param itemidx    The index of the data item
#+ @param position   The data position (X-axis)
#+ @param title      The text to display at the base of the item
#+
PUBLIC FUNCTION defineDataItem(id,itemidx,position,title)
    DEFINE id SMALLINT,
           itemidx SMALLINT,
           position DECIMAL,
           title STRING

    CALL _check_id(id)
    LET charts[id].items[itemidx].position = position
    LET charts[id].items[itemidx].title = title
    CALL charts[id].items[itemidx].values.clear()

END FUNCTION

#+ Set a value to an existing data item.
#+
#+ The data item must have been created with the defineDataItem() function.
#+
#+ @code
#+ DEFINE x SMALLINT
#+ LET x = 0
#+ CALL fglsvgchart.defineDataItem(id, x:=x+1, 15.34, "January")
#+ CALL fglsvgchart.setDataItemValue(id, x, 1, 30.15, "Jan1")
#+ CALL fglsvgchart.setDataItemValue(id, x, 2, 45.25, "Jan2")
#+ CALL fglsvgchart.setDataItemValue(id, x, 3, 15.57, "Jan3")
#+ CALL fglsvgchart.setDataItemValue(id, x, 4, 40.15, "Jan4")
#+
#+ @param id         The chart id
#+ @param itemidx    The index of the item.
#+ @param dataidx    The index of the data set.
#+ @param value      The data value (Y-axis)
#+ @param label      The test to display at the value / point
#+
PUBLIC FUNCTION setDataItemValue(id,itemidx,dataidx,value,label)
    DEFINE id SMALLINT,
           itemidx SMALLINT,
           dataidx SMALLINT,
           value DECIMAL,
           label STRING

    CALL _check_data_item_index(id, itemidx)
    LET charts[id].items[itemidx].values[dataidx].value = value
    LET charts[id].items[itemidx].values[dataidx].label = label

END FUNCTION

#+ Set the secondary value to an existing data item.
#+
#+ The data item must have been created with the defineDataItem() function.
#+
#+ @code
#+ DEFINE x SMALLINT
#+ LET x = 0
#+ CALL fglsvgchart.defineDataItem(id, x:=x+1, 15.34, "January")
#+ CALL fglsvgchart.setDataItemValue2(id, x, 1, 30.15, "Jan1")
#+ CALL fglsvgchart.setDataItemValue2(id, x, 2, 45.25, "Jan2")
#+ CALL fglsvgchart.setDataItemValue2(id, x, 3, 15.57, "Jan3")
#+ CALL fglsvgchart.setDataItemValue2(id, x, 4, 40.15, "Jan4")
#+
#+ @param id         The chart id
#+ @param itemidx    The index of the item.
#+ @param dataidx    The index of the data set.
#+ @param value      The data value (Y-axis)
#+ @param label      The test to display at the value / point
#+
PUBLIC FUNCTION setDataItemValue2(id,itemidx,dataidx,value,label)
    DEFINE id SMALLINT,
           itemidx SMALLINT,
           dataidx SMALLINT,
           value DECIMAL,
           label STRING

    CALL _check_data_item_index(id, itemidx)
    LET charts[id].items[itemidx].values[dataidx].value2 = value
    LET charts[id].items[itemidx].values[dataidx].label2 = label

END FUNCTION

#+ Returns the current number of data items in the chart.
#+
#+ @param id      The chart id
#+
#+ @returnType INTEGER
#+ @return The number of data items.
#+
PUBLIC FUNCTION getDataItemCount(id)
    DEFINE id SMALLINT

    CALL _check_id(id)
    RETURN charts[id].items.getLength()

END FUNCTION

PRIVATE FUNCTION isodec(v)
    DEFINE v DECIMAL(32,10) -- Warning: must not produce exponent notation!
    -- FIXME: Need a utility function (FGL-4196)
    RETURN util.JSON.stringify(v)
END FUNCTION

#+ Render the chart in your web component.
#+
#+ @code
#+ CALL fglsvgchart.render(id, CHART_TYPE_BARS, svg_root_node, NULL,NULL,"10em","10em" )
#+
#+ @param id     The chart id
#+ @param type   The type of chart, can be: CHART_TYPE_BARS, CHART_TYPE_POINTS, CHART_TYPE_LINES
#+ @param parent The parent svg om.DomNode where the chart svg node must be created.
#+ @param x      The X position (in the parent svg node).
#+ @param y      The Y position (in the parent svg node).
#+ @param width  The width (in the parent svg node).
#+ @param height The height (in the parent svg node).
#+
PUBLIC FUNCTION render(id, type, parent, x, y, width, height)
    DEFINE id SMALLINT,
           type SMALLINT,
           parent om.DomNode,
           x,y,width,height STRING
    DEFINE b om.DomNode

    CALL _check_id(id)

    LET b = _render_base_svg(id, parent, x, y, width, height)

    CASE type
      WHEN CHART_TYPE_BARS     CALL _render_bars(id,b)
      WHEN CHART_TYPE_POINTS   CALL _render_points(id,b)
      WHEN CHART_TYPE_LINES    CALL _render_lines(id,b)
      WHEN CHART_TYPE_SPLINES  CALL _render_splines(id,b)
    END CASE

END FUNCTION

-- TODO: Vertical / Horizontal legend...
PRIVATE FUNCTION _create_legend_box(id, h)
    DEFINE id SMALLINT,
           h DECIMAL
    DEFINE b, r, n, t om.DomNode,
           vb STRING,
           cw,ch DECIMAL,
           w DECIMAL,
           l, ml SMALLINT

    LET ml = _max_value_count(id)

    LET w = (h * 1.10) * ml

    LET cw = 270
    LET ch = 100
    LET vb = SFMT("0 0 %1 %2", (cw*ml), ch)

    LET b = fglsvgcanvas.svg(SFMT("legend_%1",id), NULL,NULL,w,h, vb, "xMidYMid meet" )

    LET r = fglsvgcanvas.rect(3,3,(cw*ml)-6,ch-6,NULL,NULL)
    CALL r.setAttribute(fglsvgcanvas.SVGATT_CLASS,"legend_box")
    CALL b.appendChild(r)

    FOR l=1 TO ml
        LET n = fglsvgcanvas.g(NULL)
        CALL n.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM, SFMT("translate(%1,0)",(cw*(l-1))) )
        CALL b.appendChild(n)
        LET r = fglsvgcanvas.rect(15,15,70,70,NULL,NULL)
        CALL r.setAttribute(fglsvgcanvas.SVGATT_CLASS,charts[id].datasets[l].style)
        CALL n.appendChild(r)
        LET t = fglsvgcanvas.text( 100, (ch*0.60), charts[id].datasets[l].label, "legend_label")
        CALL n.appendChild(t)
    END FOR

    RETURN b

END FUNCTION

PRIVATE FUNCTION _render_base_svg(id, parent, x, y, width, height)
    DEFINE id SMALLINT,
           parent om.DomNode,
           x,y,width,height STRING
    DEFINE b, t, n om.DomNode,
           bdx, bdy DECIMAL,
           tdy DECIMAL,
           ldy DECIMAL,
           x1, y1, w1, h1 DECIMAL,
           vb STRING,
           ml SMALLINT

    LET bdx = (charts[id].width  * IIF(charts[id].grid_vl,0.10,0.02) )
    LET bdy = (charts[id].height * IIF(charts[id].grid_pl,0.05,0.02) )

    IF charts[id].title IS NOT NULL THEN
       LET tdy = (charts[id].height * 0.10)
    ELSE
       LET tdy = 0.0
    END IF

    IF charts[id].legend THEN
       LET ldy = (charts[id].height * 0.15)
    ELSE
       LET ldy = 0.0
    END IF

    LET x1 = charts[id].minpos - (bdx)
    LET y1 = charts[id].minval - (bdy+tdy) 
    LET w1 = charts[id].width + (bdx*2)
    LET h1 = charts[id].height + tdy + ldy + (bdy*2)
    LET vb = SFMT("%1 %2 %3 %4", x1, y1, w1, h1 )

    LET b = fglsvgcanvas.svg(SFMT("svgchart_%1",id), x,y,width,height, vb, "xMidYMid meet" )
    CALL parent.appendChild(b)

    IF charts[id].title IS NOT NULL THEN
       LET t = fglsvgcanvas.text( charts[id].minpos + (charts[id].width/2),
                                  charts[id].minval + bdy - tdy,
                                  charts[id].title, "main_title" )
       CALL t.setAttribute("text-anchor","middle")
       CALL b.appendChild(t)
    END IF

    IF charts[id].legend THEN
       LET ml = _max_value_count(id)
       LET n = _create_legend_box(id, ldy)
       CALL n.setAttribute("x", charts[id].minpos + (charts[id].width/2) - (ldy*(ml-1)) )
       CALL n.setAttribute("y", charts[id].maxval + (ldy * 0.4) )
       CALL b.appendChild(n)
    END IF

--CALL b.appendChild( add_debug_rect( x1, y1, w1, h1 ) )

    RETURN b

END FUNCTION

PRIVATE FUNCTION add_debug_rect(x,y,w,h)
    DEFINE x,y,w,h DECIMAL
    DEFINE n om.DomNode
    LET n = fglsvgcanvas.rect(isodec(x),isodec(y),isodec(w),isodec(h),NULL,NULL)
    CALL n.setAttribute(fglsvgcanvas.SVGATT_FILL,"yellow")
    CALL n.setAttribute(fglsvgcanvas.SVGATT_FILL_OPACITY,"0.2")
    CALL n.setAttribute(fglsvgcanvas.SVGATT_STROKE,"red")
    CALL n.setAttribute(fglsvgcanvas.SVGATT_STROKE_WIDTH,"0.4em")
    RETURN n
END FUNCTION

PRIVATE FUNCTION _render_sheet_1(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n om.DomNode,
           dy DECIMAL
    LET n = fglsvgcanvas.g("sheet_1")
    LET dy = charts[id].maxval + charts[id].minval
    CALL n.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM,
                         SFMT("translate(0,%1) scale(1,-1)",dy) )
    CALL base.appendChild(n)
    IF charts[id].grid_np IS NOT NULL
    OR charts[id].grid_nv IS NOT NULL
    THEN
       CALL _render_grid_1(id, n)
    END IF
    RETURN n
END FUNCTION

PRIVATE FUNCTION _render_grid_1(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n, t, g om.DomNode,
           dx, dy DECIMAL,
           ldx, ldy DECIMAL,
           ix, iy DECIMAL,
           lx, ly DECIMAL,
           i SMALLINT

    LET g = fglsvgcanvas.g("grid")
    CALL g.setAttribute(fglsvgcanvas.SVGATT_CLASS,"grid")
    CALL base.appendChild(g)

    IF charts[id].grid_np > 0 THEN
       LET dx = charts[id].width / charts[id].grid_np
       LET ldy = charts[id].height * 0.04
       LET ly = charts[id].minval - ldy
       LET ix = charts[id].minpos
       FOR i=1 TO charts[id].grid_np+1
           LET n = fglsvgcanvas.line(ix, charts[id].minval, ix, charts[id].maxval)
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS,"grid_line_x")
           CALL g.appendChild(n)
           IF charts[id].grid_pl AND charts[id].grid_lx[i] IS NOT NULL THEN
              LET t = fglsvgcanvas.text( ix, ly, charts[id].grid_lx[i], "grid_x_label" )
              CALL t.setAttribute("text-anchor","middle")
              CALL t.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM,
                                   SFMT("translate(0,%1) scale(1,-1)",ly*2) )
              CALL g.appendChild(t)
           END IF
           LET ix = ix + dx
       END FOR
    END IF

    IF charts[id].grid_nv > 0 THEN
       LET dy = charts[id].height / charts[id].grid_nv
       LET ldx = charts[id].width * 0.01
       LET lx = charts[id].minpos - ldx
       LET iy = charts[id].minval
       FOR i=1 TO charts[id].grid_nv+1
           LET n = fglsvgcanvas.line(charts[id].minpos, iy, charts[id].maxpos, iy)
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS,"grid_line_y")
           CALL g.appendChild(n)
           IF charts[id].grid_vl AND charts[id].grid_ly[i] IS NOT NULL THEN
              LET t = fglsvgcanvas.text( lx, iy, charts[id].grid_ly[i], "grid_y_label" )
              CALL t.setAttribute("text-anchor","end")
              CALL t.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM,
                                   SFMT("translate(0,%1) scale(1,-1)",iy*2) )
              CALL g.appendChild(t)
           END IF
           LET iy = iy + dy
       END FOR
    END IF

    IF charts[id].origin THEN
       LET n = fglsvgcanvas.line(charts[id].minpos, 0, charts[id].maxpos, 0)
       CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS,"x_axis")
       CALL g.appendChild(n)
       LET n = fglsvgcanvas.line(0, charts[id].minval, 0, charts[id].maxval)
       CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS,"y_axis")
       CALL g.appendChild(n)
    END IF

END FUNCTION

PRIVATE FUNCTION _render_bars(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n om.DomNode
    LET n = _render_sheet_1(id, base)
    CALL _render_data_bars(id, n)
END FUNCTION

PRIVATE FUNCTION _render_data_bars(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n, g om.DomNode,
           i, m INTEGER,
           l, ml INTEGER,
           s STRING,
           dx, sdx DECIMAL,
           x,y,w,h DECIMAL

    LET g = fglsvgcanvas.g("data_bars")
    CALL base.appendChild(g)

    LET m = charts[id].items.getLength()
    LET dx = (charts[id].width / m) * 0.8
    LET ml = _max_value_count(id)
    LET sdx = dx / ml

    FOR l=1 TO ml
        LET s = charts[id].datasets[l].style
        FOR i=1 TO m
            LET h = charts[id].items[i].values[l].value
            IF h IS NULL THEN CONTINUE FOR END IF
            IF h<0 THEN
               LET y = h
               LET h = -h
            ELSE
               LET y = 0
            END IF
            LET x = charts[id].items[i].position - (dx/2) + (sdx*(l-1))
            LET w = (sdx * 0.95)
            LET n = fglsvgcanvas.rect(x, y, w, h, NULL, NULL)
            IF s IS NOT NULL THEN
               CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
            END IF
            CALL g.appendChild(n)
        END FOR
    END FOR

END FUNCTION

PRIVATE FUNCTION _render_points(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n om.DomNode
    LET n = _render_sheet_1(id, base)
    CALL _render_data_points(id, n)
END FUNCTION

PRIVATE FUNCTION _render_data_points(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE g om.DomNode,
           l, ml INTEGER

    LET g = fglsvgcanvas.g("data_points")
    CALL base.appendChild(g)

    LET ml = _max_value_count(id)

    FOR l=1 TO ml
        CALL _create_data_points(id, g, l, TRUE, charts[id].datasets[l].style)
    END FOR

END FUNCTION

PRIVATE FUNCTION _min_max_value2(id)
    DEFINE id SMALLINT
    DEFINE i, m SMALLINT,
           l, ml SMALLINT,
           minv2, maxv2 DECIMAL
    LET m = charts[id].items.getLength()
    LET ml = _max_value_count(id)
    LET minv2 = NULL
    LET maxv2 = NULL
    FOR i=1 TO m
        FOR l=1 TO ml
           IF charts[id].items[i].values[l].value2 IS NOT NULL THEN
              IF minv2 IS NULL
              OR minv2 > charts[id].items[i].values[l].value2 THEN
                 LET minv2 = charts[id].items[i].values[l].value2
              END IF
              IF maxv2 IS NULL
              OR maxv2 < charts[id].items[i].values[l].value2 THEN
                 LET maxv2 = charts[id].items[i].values[l].value2
              END IF
           END IF
        END FOR
    END FOR
    RETURN minv2, maxv2
END FUNCTION

PRIVATE FUNCTION _abs_min_max(min,max)
    DEFINE min, max DECIMAL
    LET min = IIF(min<0,-min,min)
    LET max = IIF(max<0,-max,max)
    IF min>max THEN
       RETURN max,min
    ELSE
       RETURN min,max
    END IF
END FUNCTION

PRIVATE FUNCTION _create_data_points(id, g, l, r, s)
    DEFINE id SMALLINT,
           g om.DomNode,
           l SMALLINT,
           r BOOLEAN,
           s STRING
    DEFINE n om.DomNode,
           i, m INTEGER,
           minv2, maxv2 DECIMAL,
           br,rr,vr DECIMAL,
           cx,cy,cr DECIMAL

    LET br = charts[id].width * 0.005
    IF r THEN
       CALL _min_max_value2(id) RETURNING minv2, maxv2
       CALL _abs_min_max(minv2,maxv2) RETURNING minv2, maxv2
       LET rr = 4 * br / (maxv2-minv2)
    END IF

    LET m = charts[id].items.getLength()
    FOR i=1 TO m
        LET cy = charts[id].items[i].values[l].value
        IF cy IS NULL THEN CONTINUE FOR END IF
        LET cx = charts[id].items[i].position
        LET vr = charts[id].items[i].values[l].value2
        IF rr IS NOT NULL AND vr IS NOT NULL THEN
           LET vr = IIF(vr<0,-vr,vr)
           LET cr = vr * rr
        ELSE
           LET cr = br
        END IF
        LET n = fglsvgcanvas.circle(cx, cy, cr)
        IF s IS NOT NULL THEN
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
        END IF
        CALL g.appendChild(n)
    END FOR

END FUNCTION

PRIVATE FUNCTION _render_lines(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n om.DomNode
    LET n = _render_sheet_1(id, base)
    CALL _render_data_lines(id, n)
END FUNCTION

PRIVATE FUNCTION _render_data_lines(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n, g om.DomNode,
           i, m INTEGER,
           l, ml INTEGER,
           s, p STRING,
           dx DECIMAL,
           x,y DECIMAL

    LET g = fglsvgcanvas.g("data_lines")
    CALL base.appendChild(g)

    LET m = charts[id].items.getLength()
    LET dx = ( charts[id].width / m ) * 0.10

    LET ml = _max_value_count(id)

    FOR l=1 TO ml
        LET p = " M"||isodec(charts[id].items[1].position)||","||isodec(0)
        FOR i=1 TO m
            LET y = charts[id].items[i].values[l].value
            IF y IS NULL THEN CONTINUE FOR END IF
            LET x = charts[id].items[i].position
            LET p = p||" L"||isodec(x)||","||isodec(y)
        END FOR
        LET p = p||" L"||isodec(x)||","||isodec(0)
        LET p = p||" Z"
        LET n = fglsvgcanvas.path(p)
        LET s = charts[id].datasets[l].style
        IF s IS NOT NULL THEN
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
        END IF
        CALL g.appendChild(n)
        IF charts[id].points THEN
           CALL _create_data_points(id, g, l, FALSE, NVL(charts[id].points_style,s))
        END IF
    END FOR

END FUNCTION

PRIVATE FUNCTION _max_value_count(id)
    DEFINE id SMALLINT
    DEFINE i, m, ml SMALLINT
    LET m = charts[id].items.getLength()
    LET ml = 0
    FOR i=1 TO m
        IF ml < charts[id].items[i].values.getLength() THEN
           LET ml = charts[id].items[i].values.getLength()
        END IF
    END FOR
    RETURN ml
END FUNCTION

PRIVATE FUNCTION _render_splines(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n om.DomNode
    LET n = _render_sheet_1(id, base)
    CALL _render_data_splines(id, n)
END FUNCTION

PRIVATE FUNCTION _render_data_splines(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n, g om.DomNode,
           m INTEGER,
           l, ml INTEGER,
           s, p STRING

    LET g = fglsvgcanvas.g("data_splines")
    CALL base.appendChild(g)

    LET m = charts[id].items.getLength()
    LET ml = _max_value_count(id)

    FOR l=1 TO ml
        LET p = _spline_path(id, l)
        LET n = fglsvgcanvas.path(p)
        LET s = charts[id].datasets[l].style
        IF s IS NOT NULL THEN
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
        END IF
        CALL g.appendChild(n)
        IF charts[id].points THEN
           CALL _create_data_points(id, g, l, FALSE, NVL(charts[id].points_style,s))
        END IF
    END FOR

END FUNCTION


PRIVATE FUNCTION _spline_path(id, l)
    DEFINE id, l SMALLINT
    DEFINE i, m, n SMALLINT,
           x, y DYNAMIC ARRAY OF DECIMAL,
           px, py DYNAMIC ARRAY OF RECORD
                  p1 DECIMAL,
                  p2 DECIMAL
           END RECORD,
           path base.StringBuffer

    LET m = charts[id].items.getLength()

    IF m < 2 THEN
       RETURN NULL
    END IF

    LET n = 1
    FOR i=1 TO m
        IF charts[id].items[i].values[l].value IS NOT NULL THEN
           LET n = n+1
           LET x[n] = charts[id].items[i].position
           LET y[n] = charts[id].items[i].values[l].value
        END IF
    END FOR
    LET x[1] = x[2] - (x[3]-x[2])
    LET y[1] = 0
    LET x[n+1] = x[n] + (x[n]-x[n-1])
    LET y[n+1] = 0

    CALL _spline_control_points(x, px)
    CALL _spline_control_points(y, py)

    LET path = base.StringBuffer.create()
    CALL path.append(SFMT(" M%1,%2", x[2], y[2]))
    FOR i=2 TO n-1
        CALL path.append(
                  SFMT(" C%1,%2 %3,%4 %5,%6",
                       px[i].p1, py[i].p1,
                       px[i].p2, py[i].p2,
                       x[i+1],   y[i+1]
                      )
             )
    END FOR
    CALL path.append(SFMT(" L%1,%2", x[n], 0))
    CALL path.append(SFMT(" L%1,%2", x[2], 0))
    CALL path.append(" Z")

    RETURN path.toString()

END FUNCTION

PRIVATE FUNCTION _spline_control_points(k, cp)
    DEFINE k DYNAMIC ARRAY OF DECIMAL,
           cp DYNAMIC ARRAY OF RECORD
                  p1 DECIMAL,
                  p2 DECIMAL
              END RECORD,
           i, n SMALLINT,
           m DECIMAL,
           a,b,c,r DYNAMIC ARRAY OF DECIMAL

    CALL cp.clear()
    LET n = k.getLength() - 1

    LET a[1] = 0
    LET b[1] = 2
    LET c[1] = 1
    LET r[1] = k[1] + 2 * k[2]

    FOR i=2 TO n-1
        LET a[i] = 1
        LET b[i] = 4
        LET c[i] = 1
        LET r[i] = 4 * k[i] + 2 * k[i+1]
    END FOR

    LET a[n] = 2
    LET b[n] = 7
    LET c[n] = 0
    LET r[n] = 8 * k[n] + k[n+1]

    FOR i=2 TO n
        LET m = a[i] / b[i-1]
        LET b[i] = b[i] - m * c[i-1]
        LET r[i] = r[i] - m * r[i-1]
    END FOR

    LET cp[n].p1 = r[n] / b[n]

    FOR i=n-1 TO 1 STEP -1
        LET cp[i].p1 = (r[i] - c[i] * cp[i+1].p1) / b[i]
    END FOR

    FOR i=1 TO n-1
        LET cp[i].p2 = 2 * k[i+1] - cp[i+1].p1
    END FOR

    LET cp[n].p2 = 0.5 * (k[n+1] + cp[n].p1)

END FUNCTION
