#+ Genero SVG Chart Library
#+
#+ This library provides a set of functions to produce SVG charts.
#+ Before using this library, you need to know how to use fglsvgcanvas.4gl.
#+

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
                 style STRING,
                 visible BOOLEAN
             END RECORD

PRIVATE TYPE t_chart RECORD
               name STRING,
               type SMALLINT,
               title STRING,
               points BOOLEAN,
               points_style STRING,
               legend_pos SMALLINT,
               origin BOOLEAN,
               minpos DECIMAL,
               maxpos DECIMAL,
               width DECIMAL,
               minval DECIMAL,
               maxval DECIMAL,
               height DECIMAL,
               xyratio DECIMAL,
               grid_np DECIMAL,
               grid_pl BOOLEAN,
               grid_lx DYNAMIC ARRAY OF STRING,
               grid_nv DECIMAL,
               grid_vl BOOLEAN,
               grid_ly DYNAMIC ARRAY OF STRING,
               value_lb BOOLEAN,
               datasets DYNAMIC ARRAY OF t_dataset,
               items DYNAMIC ARRAY OF t_data_item
             END RECORD
-- options: background color, x-grid line/coord, y-grid line/coord, ...

PRIVATE DEFINE initCount SMALLINT
PRIVATE DEFINE charts DYNAMIC ARRAY OF t_chart

PUBLIC CONSTANT
  CHART_TYPE_BARS    = 1,
  CHART_TYPE_POINTS  = 2,
  CHART_TYPE_LINES   = 3,
  CHART_TYPE_SPLINES = 4,
  CHART_TYPE_STACKS  = 5

PUBLIC CONSTANT
  LEGEND_POS_TOP    = 1,
  LEGEND_POS_LEFT   = 2,
  LEGEND_POS_BOTTOM = 3,
  LEGEND_POS_RIGHT  = 4

PRIVATE DEFINE debug_level SMALLINT

#+ Library initialization function.
#+
#+ This function has to be called before using other functions of this module.
#+
PUBLIC FUNCTION initialize()
    WHENEVER ERROR RAISE
    IF initCount == 0 THEN
       -- prepare resources
       LET debug_level = fgl_getenv("FGLSVGCHART_DEBUG")
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
#+ LET id = fglsvgchart.create("mychart")
#+
#+ @param name The name of the chart.
#+
#+ @returnType SMALLINT
#+ @return The chart object ID
#+
PUBLIC FUNCTION create(name)
    DEFINE name STRING
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
    INITIALIZE charts[id].* TO NULL
    LET charts[id].name = name
    LET charts[id].title = SFMT("Chart #%1",id)
    CALL reset(id)
    RETURN id
END FUNCTION

#+ Defines the chart main title
#+
#+ @code
#+ CALL fglsvgchart.setTitle(cid, "My chart")
#+
#+ @param id      The chart id
#+ @param title   The lower limit for positions (X-axis)
#+
PUBLIC FUNCTION setTitle(id,title)
    DEFINE id SMALLINT,
           title STRING
    CALL _check_id(id)
    LET charts[id].title = title
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
    DEFINE id SMALLINT,
           minpos, maxpos DECIMAL,
           minval, maxval DECIMAL
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

#+ Defines the rectangular ratio of the chart
#+
#+ When the positions and values ranges differe too much, use this
#+ funciton to apply an aspect ration, and produce a readable chart.
#+ The ratio will be applied to values to determine the coordinate
#+ of the value item in the chart grid.
#+ For example, if the positions go from -100 to 100 and the values
#+ fo from -1 to 1, you can apply a ratio of 20.0, so that value 0.5
#+ will be displayed at 0.5*50.0 = 25.0 ...
#+
#+ @code
#+ CALL fglsvgchart.setRectangularRatio(cid, 35.0)
#+
#+ @param id      The chart id
#+ @param ratio   The ratio to apply for this chart
#+
PUBLIC FUNCTION setRectangularRatio(id,ratio)
    DEFINE id SMALLINT,
           ratio DECIMAL
    CALL _check_id(id)
    LET charts[id].xyratio = ratio
END FUNCTION

PRIVATE FUNCTION isodec(v)
    DEFINE v DECIMAL(32,10) -- Warning: must not produce exponent notation!
    -- FIXME: Need a utility function (FGL-4196)
    RETURN util.JSON.stringify(v)
END FUNCTION

PRIVATE FUNCTION _get_y(id, value)
    DEFINE id SMALLINT,
           value DECIMAL
    RETURN (charts[id].xyratio * value)
END FUNCTION

PRIVATE FUNCTION _min(v1,v2)
    DEFINE v1, v2 DECIMAL
    RETURN IIF(v1 < v2, v1, v2)
END FUNCTION

PRIVATE FUNCTION _max(v1,v2)
    DEFINE v1, v2 DECIMAL
    RETURN IIF(v1 > v2, v1, v2)
END FUNCTION

#+ Display points
#+
#+ @param id      The chart id
#+ @param enable  TRUE to display points
#+ @param style   SVG style for points, NULL= use dataset style.
#+
PUBLIC FUNCTION showPoints(id,enable,style)
    DEFINE id SMALLINT,
           enable BOOLEAN,
           style STRING
    CALL _check_id(id)
    LET charts[id].points = enable
    LET charts[id].points_style = style
END FUNCTION

#+ Display dataset legend
#+
#+ Defines the position of the legend box.
#+
#+ @param id        The chart id
#+ @param position  NULL or LEGEND_POS_{TOP|LEFT|BOTTOM|RIGHT}
#+
PUBLIC FUNCTION showDataSetLegend(id,position)
    DEFINE id SMALLINT,
           position SMALLINT
    CALL _check_id(id)
    LET charts[id].legend_pos = position
END FUNCTION

#+ Display value-axis labels
#+
#+ @param id      The chart id
#+ @param enable  TRUE to display the labels
#+
PUBLIC FUNCTION showGridValueLabels(id,enable)
    DEFINE id SMALLINT,
           enable BOOLEAN
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
           enable BOOLEAN
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
           enable BOOLEAN
    CALL _check_id(id)
    LET charts[id].origin = enable
END FUNCTION

#+ Display value labels
#+
#+ @param id      The chart id
#+ @param enable  TRUE to display the value labels
#+
PUBLIC FUNCTION showValueLabels(id,enable)
    DEFINE id SMALLINT,
           enable BOOLEAN
    CALL _check_id(id)
    LET charts[id].value_lb = enable
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
    CALL _check_id(id)
    IF index<1 OR index>charts[id].items.getLength() THEN
       OPEN FORM _dummy_ FROM NULL
    END IF
END FUNCTION

PRIVATE FUNCTION _check_dataset_index(id, index)
    DEFINE id, index SMALLINT
    CALL _check_id(id)
    IF index<1 OR index>charts[id].datasets.getLength() THEN
       OPEN FORM _dummy_ FROM NULL
    END IF
END FUNCTION

#+ Set the number of horizontal and vertical grid lines to display.
#+
#+ The style of the grid can be defined with "grid", the line styles
#+ can be defined with "grid_x_line_x" and "grid_y_line", the style
#+ for X/Y axises can be defined with "grid_x_axis" and "grid_y_axis".
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

PRIVATE FUNCTION _num_format(fmt)
    DEFINE fmt STRING
    RETURN NVL(fmt,"-<<<<<<<<&.&&")
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
    IF skip <= 0 THEN OPEN FORM _dummy_ FROM NULL END IF
    LET dy = (charts[id].maxpos - charts[id].minpos) / charts[id].grid_np
    CALL charts[id].grid_lx.clear()
    FOR n=1 TO charts[id].grid_np+1 STEP skip
        LET v = charts[id].minpos + (dy * (n-1))
        LET charts[id].grid_lx[n] = (v USING _num_format(format))
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
    IF skip <= 0 THEN OPEN FORM _dummy_ FROM NULL END IF
    LET dx = (charts[id].maxval - charts[id].minval) / charts[id].grid_nv
    CALL charts[id].grid_ly.clear()
    FOR n=1 TO charts[id].grid_nv+1 STEP skip
        LET v = charts[id].minval + (dx * (n-1))
        LET charts[id].grid_ly[n] = (v USING _num_format(format))
    END FOR
END FUNCTION

#+ Remove all data items from the chart.
#+
#+ Call this function to clean the data of the chart.
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

#+ Reset chart datasets.
#+
#+ Call this function to reset the chart by deleting all datasets.
#+
#+ @code
#+ CALL fglsvgchart.reset(id)
#+
#+ @param id     The chart id
#+
PUBLIC FUNCTION reset(id)
    DEFINE id SMALLINT
    CALL _check_id(id)
    CALL clean(id)
    CALL charts[id].grid_lx.clear()
    CALL charts[id].grid_ly.clear()
    CALL charts[id].datasets.clear()
END FUNCTION

#+ Define a new data set.
#+
#+ @code
#+ CALL fglsvgchart.defineDataSet(id, 1, "North",      "style_1")
#+ CALL fglsvgchart.defineDataSet(id, 2, "North-East", "style_2")
#+ CALL fglsvgchart.defineDataSet(id, 3, "North-West", "style_3")
#+
#+ @param id         The chart id
#+ @param index      The index of the data set
#+ @param label      The text to display at the base of the item
#+ @param style      The general style to render data items
#+
PUBLIC FUNCTION defineDataSet(id,index,label,style)
    DEFINE id SMALLINT,
           index SMALLINT,
           label STRING,
           style STRING

    CALL _check_id(id)
    LET charts[id].datasets[index].label = label
    LET charts[id].datasets[index].style = style
    LET charts[id].datasets[index].visible = TRUE

END FUNCTION

#+ Display dataset
#+
#+ @param id      The chart id
#+ @param index   The dataset index
#+ @param enable  TRUE to display the dataset
#+
PUBLIC FUNCTION showDataSet(id,index,enable)
    DEFINE id SMALLINT,
           index SMALLINT,
           enable STRING
    CALL _check_dataset_index(id, index)
    LET charts[id].datasets[index].visible = enable
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
    IF itemidx<=0 THEN
       OPEN FORM _dummy_ FROM NULL
    END IF
    LET charts[id].items[itemidx].position = position
    LET charts[id].items[itemidx].title = title
    CALL charts[id].items[itemidx].values.clear()

END FUNCTION

#+ Set the main value and label of an existing data item.
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
    CALL _check_dataset_index(id, dataidx)
    LET charts[id].items[itemidx].values[dataidx].value = value
    LET charts[id].items[itemidx].values[dataidx].label = label

END FUNCTION

#+ Set the secondary value and label of an existing data item.
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

#+ Get the main value from an existing data item.
#+
#+ @code
#+ DISPLAY fglsvgchart.getDataItemValue(id, 5, 1)
#+
#+ @param id         The chart id
#+ @param itemidx    The index of the item.
#+ @param dataidx    The index of the data set.
#+
PUBLIC FUNCTION getDataItemValue(id,itemidx,dataidx)
    DEFINE id SMALLINT,
           itemidx SMALLINT,
           dataidx SMALLINT

    CALL _check_data_item_index(id, itemidx)
    CALL _check_dataset_index(id, dataidx)
    RETURN charts[id].items[itemidx].values[dataidx].value

END FUNCTION

#+ Get the secondary value from an existing data item.
#+
#+ @code
#+ DISPLAY fglsvgchart.getDataItemValue2(id, 5, 1)
#+
#+ @param id         The chart id
#+ @param itemidx    The index of the item.
#+ @param dataidx    The index of the data set.
#+
PUBLIC FUNCTION getDataItemValue2(id,itemidx,dataidx)
    DEFINE id SMALLINT,
           itemidx SMALLINT,
           dataidx SMALLINT

    CALL _check_data_item_index(id, itemidx)
    CALL _check_dataset_index(id, dataidx)
    RETURN charts[id].items[itemidx].values[dataidx].value2

END FUNCTION

#+ Get the data item position.
#+
#+ @code
#+ DISPLAY fglsvgchart.getDataItemPosition(id, 1)
#+
#+ @param id         The chart id
#+ @param itemidx    The index of the item.
#+
PUBLIC FUNCTION getDataItemPosition(id,itemidx)
    DEFINE id SMALLINT,
           itemidx SMALLINT

    CALL _check_data_item_index(id, itemidx)
    RETURN charts[id].items[itemidx].position

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

#+ Returns the current number of datasets in the chart.
#+
#+ @param id      The chart id
#+
#+ @returnType INTEGER
#+ @return The number of datasets.
#+
PUBLIC FUNCTION getDataSetCount(id)
    DEFINE id SMALLINT
    CALL _check_id(id)
    RETURN charts[id].datasets.getLength()
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
    DEFINE b, s om.DomNode

    CALL _check_id(id)
    LET charts[id].type = type

    CALL _create_base_svg(id, parent, x, y, width, height) RETURNING b, s

    CASE type
      WHEN CHART_TYPE_BARS     CALL _render_bars(id,s)
      WHEN CHART_TYPE_POINTS   CALL _render_points(id,s)
      WHEN CHART_TYPE_LINES    CALL _render_lines(id,s)
      WHEN CHART_TYPE_SPLINES  CALL _render_splines(id,s)
      WHEN CHART_TYPE_STACKS   CALL _render_stacks(id,s)
    END CASE

END FUNCTION

PRIVATE FUNCTION _create_legend_box(id, pw, ph, tdy)
    CONSTANT CHAR_WIDTH DECIMAL = 0.18
    DEFINE id SMALLINT,
           pw, ph, tdy DECIMAL
    DEFINE b, g, n, r, t om.DomNode,
           x, y DECIMAL, w, h STRING,
           vb STRING,
           mc, cw, ch INTEGER,  -- (1) Using INTEGER avoids isodec() if box size = 100
           tw, th INTEGER,      -- (1)
           ldxl, ldxr DECIMAL,
           ldyt, ldyb DECIMAL,
           l, ml SMALLINT,
           vv BOOLEAN

    LET cw = 100
    LET ch = 100

    LET ml = charts[id].datasets.getLength()

    LET mc=3
    FOR l=1 TO ml
        IF mc < charts[id].datasets[l].label.getLength() THEN
           LET mc = charts[id].datasets[l].label.getLength()
        END IF
    END FOR

    LET vv = (   charts[id].legend_pos==LEGEND_POS_TOP
              OR charts[id].legend_pos==LEGEND_POS_BOTTOM )

    LET g = fglsvgcanvas.g(NULL)
    LET tw = 0
    LET th = 0
    FOR l=1 TO ml
        IF NOT charts[id].datasets[l].visible THEN CONTINUE FOR END IF
        LET n = fglsvgcanvas.g(NULL)
        CALL n.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM,
                             SFMT("translate(%1,%2)", tw, th)
                           )
        CALL g.appendChild(n)
        LET r = fglsvgcanvas.rect(20,20,60,60,NULL,NULL)
        CALL r.setAttribute(fglsvgcanvas.SVGATT_CLASS,charts[id].datasets[l].style)
        CALL r.setAttribute(fglsvgcanvas.SVGATT_STYLE, SFMT("%1:%2",fglsvgcanvas.SVGATT_FILL_OPACITY,0.8))
        CALL n.appendChild(r)
        LET t = fglsvgcanvas.text(90, (ch*0.60),
                                  charts[id].datasets[l].label, "legend_label")
        CALL t.setAttribute(fglsvgcanvas.SVGATT_FONT_SIZE,"2em")
        CALL t.setAttribute("text-anchor","left")
        CALL n.appendChild(t)
        IF vv THEN
           LET tw = tw + ( cw * (1 + (charts[id].datasets[l].label.getLength() * CHAR_WIDTH)) )
        ELSE
           LET th = th + ch
        END IF
    END FOR

    LET ldxl = 0
    LET ldxr = 0
    LET ldyt = 0
    LET ldyb = 0

    IF vv THEN -- top/bottom
       LET th = ch
       LET x = 0
       LET w = NULL
       LET h = "7%"
    ELSE       -- left/right
       LET tw = (cw * (1 + (mc * CHAR_WIDTH)))
       LET y = 0
       LET w = "12%"
       LET h = NULL
    END IF

    CASE charts[id].legend_pos
      WHEN LEGEND_POS_TOP
        LET y = tdy + (ph * 0.03)
        LET ldyt = (ph * 0.10)
      WHEN LEGEND_POS_BOTTOM
        LET y = (ph * 0.91)
        LET ldyb = (ph * 0.10)
      WHEN LEGEND_POS_LEFT
        LET x = 0
        LET ldxl = (pw * 0.12)
      WHEN LEGEND_POS_RIGHT
        LET x = (pw * 0.88)
        LET ldxr = (pw * 0.12)
    END CASE

    LET vb = SFMT("0 0 %1 %2", tw, th)
    LET b = fglsvgcanvas.svg(SFMT("legend_%1",id),
                             isodec(x), isodec(y), w, h,
                             vb, "xMidYMid meet")

    LET r = fglsvgcanvas.rect( 3, 3, tw-6, th-6, NULL, NULL)
    CALL r.setAttribute(fglsvgcanvas.SVGATT_CLASS,"legend_box")
    CALL b.appendChild(r)

    CALL b.appendChild(g)

--display b.toString()

    RETURN b, ldxl, ldxr, ldyt, ldyb

END FUNCTION

PRIVATE FUNCTION _create_base_svg(id, parent, x, y, width, height)
    CONSTANT BASE_SVG_SIZE DECIMAL = 1000.0
    DEFINE id SMALLINT,
           parent om.DomNode,
           x,y,width,height STRING
    DEFINE b, s, t, lb om.DomNode,
           hwratio DECIMAL,
           sheet_x, sheet_y, sheet_w, sheet_h DECIMAL,
           bdx, bdy DECIMAL,
           tdy DECIMAL,
           ldxl, ldxr DECIMAL,
           ldyt, ldyb DECIMAL,
           x1, y1, w1, h1 DECIMAL,
           vb STRING

    LET hwratio = _get_y(id,charts[id].height) / charts[id].width

    LET x1 = 0
    LET y1 = 0
    LET w1 = BASE_SVG_SIZE
    LET h1 = BASE_SVG_SIZE * hwratio
    LET vb = SFMT("%1 %2 %3 %4", isodec(x1), isodec(y1), isodec(w1), isodec(h1) )

    IF charts[id].title IS NOT NULL THEN
       LET tdy = (BASE_SVG_SIZE * 0.05) * hwratio
    ELSE
       LET tdy = 0.0
    END IF

    IF charts[id].legend_pos IS NOT NULL THEN
       CALL _create_legend_box(id, w1, h1, tdy) RETURNING lb, ldxl, ldxr, ldyt, ldyb
    ELSE
       LET ldxl = 0.0
       LET ldxr = 0.0
       LET ldyt = 0.0
       LET ldyb = 0.0
    END IF

    LET bdx = 0
    LET bdy = (BASE_SVG_SIZE * 0.01) * hwratio

    LET sheet_x = bdx + ldxl
    LET sheet_y = bdy + tdy + ldyt
    LET sheet_w = (BASE_SVG_SIZE)           - (bdx + ldxl + ldxr)
    LET sheet_h = (BASE_SVG_SIZE * hwratio) - (tdy + ldyt + ldyb)

-- For debug only
--let y = "10%"
--let height = "80%"

    LET b = fglsvgcanvas.svg(SFMT("svgchart_%1",id),
                             x,y,width,height, -- no need for isodec(): these a strings
                             vb, "xMidYMid meet" )
    CALL parent.appendChild(b)

    IF charts[id].title IS NOT NULL THEN
       LET t = fglsvgcanvas.text( (w1/2), tdy,
                                  charts[id].title, "main_title" )
       CALL t.setAttribute(fglsvgcanvas.SVGATT_FONT_SIZE,"1.8em")
       CALL t.setAttribute("text-anchor","middle")
       CALL b.appendChild(t)
    END IF

    IF charts[id].legend_pos IS NOT NULL THEN
       CALL b.appendChild(lb)
    END IF

    IF debug_level>0 THEN
       CALL b.appendChild( add_debug_rect(x1,y1,w1,h1) )
       CALL b.appendChild( add_debug_rect(0,0,1000,tdy) )
    END IF

    LET s = _create_sheet_1(id, b, sheet_x, sheet_y, sheet_w, sheet_h)

    RETURN b, s

END FUNCTION

PRIVATE FUNCTION add_debug_rect(x,y,w,h)
    DEFINE x,y,w,h DECIMAL
    DEFINE n om.DomNode
    LET n = fglsvgcanvas.rect(isodec(x),isodec(y),isodec(w),isodec(h),NULL,NULL)
    CALL n.setAttribute(fglsvgcanvas.SVGATT_FILL,"yellow")
    CALL n.setAttribute(fglsvgcanvas.SVGATT_FILL_OPACITY,"0.2")
    CALL n.setAttribute(fglsvgcanvas.SVGATT_STROKE,"red")
    CALL n.setAttribute(fglsvgcanvas.SVGATT_STROKE_WIDTH,"0.4%")
    RETURN n
END FUNCTION

PRIVATE FUNCTION _flip_transform(id, y)
    DEFINE id SMALLINT,
           y DECIMAL
    RETURN SFMT("translate(0,%1) scale(1,-1)", isodec( _get_y(id,y) ) )
END FUNCTION

PRIVATE FUNCTION _create_sheet_1(id, base, x,y,width,height)
    DEFINE id SMALLINT,
           base om.DomNode,
           x,y,width,height DECIMAL
    DEFINE bdxl, bdxr DECIMAL,
           bdyt, bdyb DECIMAL,
           x1, y1, w1, h1 DECIMAL,
           s, g, d, cr om.DomNode,
           fy DECIMAL,
           vb STRING

    LET bdxl = charts[id].width  * IIF(charts[id].grid_vl,0.10,0.03)
    LET bdxr = charts[id].width  * 0.03
    LET bdyt = charts[id].height * 0.03
    LET bdyb = charts[id].height * IIF(charts[id].grid_pl,0.07,0.03)
    LET x1 = charts[id].minpos - bdxl
    LET y1 = charts[id].minval - bdyt
    LET w1 = charts[id].width  + (bdxl+bdxr)
    LET h1 = charts[id].height + (bdyt+bdyb)
    LET vb = SFMT("%1 %2 %3 %4", isodec(x1), _get_y(id,y1), isodec(w1), _get_y(id,h1) )

    LET s = fglsvgcanvas.svg(SFMT("sheet_%1",id),
                             isodec(x), isodec(y), isodec(width), isodec(height),
                             vb, "xMidYMid meet")
    CALL base.appendChild(s)
    IF debug_level>0 THEN
       CALL s.appendChild( add_debug_rect(x1,_get_y(id,y1),w1,_get_y(id,h1)) )
    END IF

    LET d = fglsvgcanvas.defs( NULL )
    CALL s.appendChild(d)
    LET cr = fglsvgcanvas.clipPath_rect("grid_clip",
                                        charts[id].minpos,
                                        _get_y(id,charts[id].minval),
                                        charts[id].width,
                                        _get_y(id,charts[id].height)
                                       )
    CALL d.appendChild(cr)

    LET g = fglsvgcanvas.g(SFMT("mg_%1",id))
    CALL s.appendChild(g)
    LET fy = charts[id].maxval + charts[id].minval
    CALL g.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM, _flip_transform(id,fy) )
    IF charts[id].grid_np IS NOT NULL
    OR charts[id].grid_nv IS NOT NULL
    THEN
       CALL _create_grid_1(id, g)
    END IF
    RETURN g
END FUNCTION

PRIVATE FUNCTION _grid_needs_pos_shift(id)
    DEFINE id SMALLINT
    RETURN (charts[id].type == CHART_TYPE_BARS)
        OR (charts[id].type == CHART_TYPE_STACKS)
END FUNCTION

PRIVATE FUNCTION _font_size_ratio(id)
    DEFINE id SMALLINT
    RETURN ( _min( charts[id].width, _get_y(id,charts[id].height) ) * 0.04 )
END FUNCTION

PRIVATE FUNCTION _create_grid_1(id, base)
    DEFINE id SMALLINT,
           base om.DomNode
    DEFINE n, t, g om.DomNode,
           dx, dy DECIMAL,
           ix, iy DECIMAL,
           lx, ly DECIMAL,
           ox DECIMAL,
           i, m SMALLINT,
           fs STRING

    LET g = fglsvgcanvas.g("grid")
    CALL g.setAttribute(fglsvgcanvas.SVGATT_CLASS,"grid")
    CALL base.appendChild(g)

    LET fs = (5.5 * _font_size_ratio(id)) || "%"

    IF charts[id].grid_np > 0 THEN
       LET dx = charts[id].width / charts[id].grid_np
       IF _grid_needs_pos_shift(id) THEN
          LET ox = dx/2
          LET m = charts[id].grid_np
       ELSE
          LET ox = 0.0
          LET m = charts[id].grid_np+1
       END IF
       LET ly = charts[id].minval - (charts[id].height * 0.04)
       LET ix = charts[id].minpos
       FOR i=1 TO m
           LET n = fglsvgcanvas.line((ix+ox), _get_y(id,charts[id].minval),
                                     (ix+ox), _get_y(id,charts[id].maxval))
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS,"grid_x_line")
           CALL g.appendChild(n)
           IF charts[id].grid_pl AND charts[id].grid_lx[i] IS NOT NULL THEN
              LET t = fglsvgcanvas.text( ix, _get_y(id,ly),
                                         charts[id].grid_lx[i], "grid_x_label" )
              CALL t.setAttribute(fglsvgcanvas.SVGATT_FONT_SIZE,fs)
              CALL t.setAttribute("text-anchor","middle")
              CALL t.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM, _flip_transform(id,ly*2) )
              CALL g.appendChild(t)
           END IF
           LET ix = ix + dx
       END FOR
    END IF

    IF charts[id].grid_nv > 0 THEN
       LET dy = charts[id].height / charts[id].grid_nv
       LET lx = charts[id].minpos - (charts[id].width * 0.01)
       LET iy = charts[id].minval
       FOR i=1 TO charts[id].grid_nv+1
           LET n = fglsvgcanvas.line(charts[id].minpos, _get_y(id,iy),
                                     charts[id].maxpos, _get_y(id,iy))
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS,"grid_y_line")
           CALL g.appendChild(n)
           IF charts[id].grid_vl AND charts[id].grid_ly[i] IS NOT NULL THEN
              LET t = fglsvgcanvas.text( lx, _get_y(id,iy),
                                         charts[id].grid_ly[i], "grid_y_label" )
              CALL t.setAttribute(fglsvgcanvas.SVGATT_FONT_SIZE,fs)
              CALL t.setAttribute("text-anchor","end")
              CALL t.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM, _flip_transform(id,iy*2) )
              CALL g.appendChild(t)
           END IF
           LET iy = iy + dy
       END FOR
    END IF

    IF charts[id].origin THEN
       IF charts[id].minval <= 0 THEN
          LET n = fglsvgcanvas.line(charts[id].minpos, 0,
                                    charts[id].maxpos, 0)
          CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS,"grid_x_axis")
          CALL g.appendChild(n)
       END IF
       IF charts[id].minpos <= 0 THEN
          LET n = fglsvgcanvas.line(0, _get_y(id,charts[id].minval),
                                    0, _get_y(id,charts[id].maxval))
          CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS,"grid_y_axis")
          CALL g.appendChild(n)
       END IF
    END IF

END FUNCTION

PRIVATE FUNCTION _position_in_grid_range(id,i,tx)
    DEFINE id, i SMALLINT,
           tx DECIMAL
    LET tx = (charts[id].width * tx)
    RETURN ( charts[id].items[i].position >= (charts[id].minpos - tx)
         AND charts[id].items[i].position <= (charts[id].maxpos + tx) )
END FUNCTION

PRIVATE FUNCTION _items_in_grid_range(id,tx)
    DEFINE id SMALLINT,
           tx DECIMAL
    DEFINE i, m, n SMALLINT,
           minpos, maxpos DECIMAL
    LET m = charts[id].items.getLength()
    LET minpos = NULL
    LET maxpos = NULL
    FOR i=1 TO m
        IF _position_in_grid_range(id,i,tx) THEN
           LET n = n + 1
           IF minpos IS NULL THEN
              LET minpos=charts[id].items[i].position
           END IF
           LET maxpos = charts[id].items[i].position
        END IF
    END FOR
    RETURN n, minpos, maxpos
END FUNCTION

PRIVATE FUNCTION _dataset_id(l)
    DEFINE l SMALLINT
    RETURN SFMT("dataset_%1",l)
END FUNCTION

PRIVATE FUNCTION _data_id(l, i)
    DEFINE l, i SMALLINT
    RETURN SFMT("data_%1_%2",l,i)
END FUNCTION

PRIVATE FUNCTION _define_clickable_element(n,id)
    DEFINE n om.DomNode,
           id STRING
    CALL n.setAttribute("id",id)
    CALL n.setAttribute("onclick","elem_clicked(this)")
END FUNCTION

PRIVATE FUNCTION _render_bars(id, sheet)
    DEFINE id SMALLINT,
           sheet om.DomNode
    DEFINE n, g, gi om.DomNode,
           vi INTEGER,
           i, m INTEGER,
           l, ml INTEGER,
           s STRING,
           ipmin, ipmax DECIMAL,
           wi, dx, bx DECIMAL,
           x,y,w,h DECIMAL

    LET g = fglsvgcanvas.g("data_bars")
    CALL g.setAttribute("clip-path", fglsvgcanvas.url("grid_clip"))
    CALL sheet.appendChild(g)

    LET m = charts[id].items.getLength()
    LET ml = charts[id].datasets.getLength()

    CALL _items_in_grid_range(id,0.10) RETURNING vi, ipmin, ipmax

    LET wi = (ipmax - ipmin)
    LET dx = (wi / (ml*vi)) * 0.85
    LET w = dx * 0.90
    LET bx = (-(ml/2) * dx) + ((dx-w)/2)

    FOR l=1 TO ml
        IF NOT charts[id].datasets[l].visible THEN CONTINUE FOR END IF
        LET s = charts[id].datasets[l].style
        FOR i=1 TO m
            IF NOT _position_in_grid_range(id,i,0.10) THEN CONTINUE FOR END IF
            LET h = charts[id].items[i].values[l].value
            IF h IS NULL THEN CONTINUE FOR END IF
            IF h<0 THEN
               LET y = h
               LET h = -h
            ELSE
               LET y = 0
            END IF
            LET x = charts[id].items[i].position + bx + (dx*(l-1))
            LET gi = fglsvgcanvas.g(NULL)
            CALL _define_clickable_element(gi,_data_id(l,i))
            CALL g.appendChild(gi)
            LET n = fglsvgcanvas.rect(x, _get_y(id,y), w, _get_y(id,h), NULL, NULL)
            IF s IS NOT NULL THEN
               CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
            END IF
            CALL gi.appendChild(n)
        END FOR
        IF charts[id].value_lb THEN
           CALL _create_data_labels(id, g, l, bx+(dx*(l-1)), NULL)
        END IF
    END FOR

END FUNCTION

PRIVATE FUNCTION _render_stacks(id, sheet)
    DEFINE id SMALLINT,
           sheet om.DomNode
    DEFINE n, g, gi om.DomNode,
           vi INTEGER,
           i, m INTEGER,
           l, ml INTEGER,
           s STRING,
           ipmin, ipmax DECIMAL,
           wi, dx, bx DECIMAL,
           x,y,w,h,y1,h1 DECIMAL

    LET g = fglsvgcanvas.g("data_stacks")
    CALL g.setAttribute("clip-path", fglsvgcanvas.url("grid_clip"))
    CALL sheet.appendChild(g)

    LET m = charts[id].items.getLength()
    LET ml = charts[id].datasets.getLength()

    CALL _items_in_grid_range(id,0.10) RETURNING vi, ipmin, ipmax

    LET wi = (ipmax - ipmin)
    LET dx = (wi / vi)
    LET w = dx * 0.85
    LET bx = -(w / 2.0)

    FOR i=1 TO m
        IF NOT _position_in_grid_range(id,i,0.10) THEN CONTINUE FOR END IF
        LET y = 0
        FOR l=1 TO ml
            IF NOT charts[id].datasets[l].visible THEN CONTINUE FOR END IF
            LET s = charts[id].datasets[l].style
            LET h = charts[id].items[i].values[l].value
            IF h IS NULL THEN CONTINUE FOR END IF
            LET x = charts[id].items[i].position + bx
            IF h < 0 THEN
               LET y1 = y + h
               LET h1 = -h
            ELSE
               LET y1 = y
               LET h1 = h
            END IF
            LET gi = fglsvgcanvas.g(NULL)
            CALL _define_clickable_element(gi,_data_id(l,i))
            CALL g.appendChild(gi)
            LET n = fglsvgcanvas.rect(x, _get_y(id,y1), w, _get_y(id,h1), NULL, NULL)
            IF s IS NOT NULL THEN
               CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
            END IF
            CALL gi.appendChild(n)
            IF charts[id].value_lb THEN
               CALL _create_data_label(id, gi, l, i, (x+(w*0.05)), (y1+(h*0.60)), NULL, NULL)
            END IF
            LET y = y + h
        END FOR
    END FOR

END FUNCTION

PRIVATE FUNCTION _render_points(id, sheet)
    DEFINE id SMALLINT,
           sheet om.DomNode
    DEFINE g om.DomNode,
           l, ml INTEGER

    LET g = fglsvgcanvas.g("data_points")
    CALL g.setAttribute("clip-path", fglsvgcanvas.url("grid_clip"))
    CALL sheet.appendChild(g)

    LET ml = charts[id].datasets.getLength()

    FOR l=1 TO ml
        IF NOT charts[id].datasets[l].visible THEN CONTINUE FOR END IF
        CALL _create_data_points(id, g, l, TRUE, charts[id].datasets[l].style)
        IF charts[id].value_lb THEN
           CALL _create_data_labels(id, g, l, NULL, NULL)
        END IF
    END FOR

END FUNCTION

PRIVATE FUNCTION _min_max_value2(id)
    DEFINE id SMALLINT
    DEFINE i, m SMALLINT,
           l, ml SMALLINT,
           minv2, maxv2 DECIMAL
    LET m = charts[id].items.getLength()
    LET ml = charts[id].datasets.getLength()
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
    DEFINE n, gi om.DomNode,
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
        IF NOT _position_in_grid_range(id,i,0.10) THEN CONTINUE FOR END IF
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
        LET gi = fglsvgcanvas.g(NULL)
        CALL _define_clickable_element(gi,_data_id(l,i))
        CALL g.appendChild(gi)
        LET n = fglsvgcanvas.circle(cx, _get_y(id,cy), cr)
        IF s IS NOT NULL THEN
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
        END IF
        IF NOT r THEN
           CALL n.setAttribute(fglsvgcanvas.SVGATT_STYLE, SFMT("%1:%2",fglsvgcanvas.SVGATT_FILL_OPACITY,1.0))
        END IF
        CALL gi.appendChild(n)
    END FOR

END FUNCTION

PRIVATE FUNCTION _create_data_label(id, g, l, i, tx, ty, dx, dy)
    DEFINE id SMALLINT,
           g om.DomNode,
           l, i SMALLINT,
           tx, ty DECIMAL,
           dx, dy DECIMAL
    DEFINE t om.DomNode,
           fsr DECIMAL,
           fs STRING

    IF charts[id].items[i].values[l].value IS NULL
    OR NOT _position_in_grid_range(id,i,0.10) THEN
       RETURN
    END IF

    LET fsr = (5.0 * _font_size_ratio(id))
    LET fs = fsr || "%"

    IF tx IS NULL THEN
       LET tx = (charts[id].items[i].position + NVL(dx,0))
    END IF
    IF ty IS NULL THEN
       LET ty = (charts[id].items[i].values[l].value + NVL(dy,0))
    END IF

    LET t = fglsvgcanvas.text( tx, _get_y(id,ty),
                               charts[id].items[i].values[l].label, "value_label" )
    CALL t.setAttribute(fglsvgcanvas.SVGATT_FONT_SIZE,fs)
    CALL t.setAttribute("text-anchor","left")
    CALL t.setAttribute( fglsvgcanvas.SVGATT_TRANSFORM, _flip_transform(id,ty*2) )
    CALL g.appendChild(t)

END FUNCTION

PRIVATE FUNCTION _create_data_labels(id, g, l, dx, dy)
    DEFINE id SMALLINT,
           g om.DomNode,
           l SMALLINT,
           dx, dy DECIMAL
    DEFINE i, m INTEGER

    IF dx IS NULL THEN
       LET dx = (charts[id].width * 0.01)
    END IF
    IF dy IS NULL THEN
       LET dy = (charts[id].height * 0.01)
    END IF

    LET m = charts[id].items.getLength()
    FOR i=1 TO m
        CALL _create_data_label(id, g, l, i, NULL, NULL, dx, dy)
    END FOR

END FUNCTION

PRIVATE FUNCTION _render_lines(id, sheet)
    DEFINE id SMALLINT,
           sheet om.DomNode
    DEFINE n, g om.DomNode,
           i, m INTEGER,
           l, ml INTEGER,
           s, p STRING,
           dx DECIMAL,
           x,y DECIMAL

    LET g = fglsvgcanvas.g("data_lines")
    CALL g.setAttribute("clip-path", fglsvgcanvas.url("grid_clip"))
    CALL sheet.appendChild(g)

    LET m = charts[id].items.getLength()
    LET dx = ( charts[id].width / m ) * 0.10

    LET ml = charts[id].datasets.getLength()

    FOR l=1 TO ml
        IF NOT charts[id].datasets[l].visible THEN CONTINUE FOR END IF
        LET p = NULL
        FOR i=1 TO m
            IF NOT _position_in_grid_range(id,i,0.10) THEN CONTINUE FOR END IF
            LET y = charts[id].items[i].values[l].value
            IF y IS NULL THEN CONTINUE FOR END IF
            IF p IS NULL THEN
               LET p = " M"||isodec(charts[id].items[i].position)||",0"
            END IF
            LET x = charts[id].items[i].position
            LET p = p||" L"||isodec(x)||","||isodec(_get_y(id,y))
        END FOR
        LET p = p||" L"||isodec(x)||",0"
        LET p = p||" Z"
        LET n = fglsvgcanvas.path(p)
        CALL _define_clickable_element(n,_dataset_id(l))
        LET s = charts[id].datasets[l].style
        IF s IS NOT NULL THEN
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
        END IF
        CALL g.appendChild(n)
        IF charts[id].points THEN
           CALL _create_data_points(id, g, l, FALSE, NVL(charts[id].points_style,s))
        END IF
        IF charts[id].value_lb THEN
           CALL _create_data_labels(id, g, l, NULL, NULL)
        END IF
    END FOR

END FUNCTION

PRIVATE FUNCTION _render_splines(id, sheet)
    DEFINE id SMALLINT,
           sheet om.DomNode
    DEFINE n, g om.DomNode,
           m INTEGER,
           l, ml INTEGER,
           s, p STRING

    LET g = fglsvgcanvas.g("data_splines")
    CALL g.setAttribute("clip-path", fglsvgcanvas.url("grid_clip"))
    CALL sheet.appendChild(g)

    LET m = charts[id].items.getLength()
    LET ml = charts[id].datasets.getLength()

    FOR l=1 TO ml
        IF NOT charts[id].datasets[l].visible THEN CONTINUE FOR END IF
        LET p = _spline_path(id, l)
        LET n = fglsvgcanvas.path(p)
        CALL _define_clickable_element(n,_dataset_id(l))
        LET s = charts[id].datasets[l].style
        IF s IS NOT NULL THEN
           CALL n.setAttribute(fglsvgcanvas.SVGATT_CLASS, s)
        END IF
        CALL g.appendChild(n)
        IF charts[id].points THEN
           CALL _create_data_points(id, g, l, FALSE, NVL(charts[id].points_style,s))
        END IF
        IF charts[id].value_lb THEN
           CALL _create_data_labels(id, g, l, NULL, NULL)
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
        IF charts[id].items[i].values[l].value IS NOT NULL
        AND _position_in_grid_range(id,i,0.10) THEN
           LET n = n+1
           LET x[n] = charts[id].items[i].position
           LET y[n] = _get_y(id,charts[id].items[i].values[l].value)
        END IF
    END FOR
    LET x[1] = x[2] - (x[3]-x[2])
    LET y[1] = 0
    LET x[n+1] = x[n] + (x[n]-x[n-1])
    LET y[n+1] = 0

    CALL _spline_control_points(x, px)
    CALL _spline_control_points(y, py)

    LET path = base.StringBuffer.create()
    CALL path.append(SFMT(" M%1,%2", isodec(x[2]), isodec(y[2])))
    FOR i=2 TO n-1
        CALL path.append(
                  SFMT(" C%1,%2 %3,%4 %5,%6",
                       isodec(px[i].p1), isodec(py[i].p1),
                       isodec(px[i].p2), isodec(py[i].p2),
                       isodec(x[i+1])  , isodec(  y[i+1])
                      )
             )
    END FOR
    CALL path.append(SFMT(" L%1,%2", isodec(x[n]), 0))
    CALL path.append(SFMT(" L%1,%2", isodec(x[2]), 0))
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
