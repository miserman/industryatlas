library(community)

# use `page_` functions to add parts of a page

## `page_head` adds to the page's meta data, and can be a place to import script and style sheets
page_head(title = "Industry Atlas", description = "Industry Atlas", icon = "icon.svg")

## `page_header` adds to the top bar (navbar) of the page
page_navbar(
  title = "Industry Atlas",
  logo = "icon.svg",
  input_button("Reset", "reset_selection", "reset.selection", class = "btn-link", note = "Reset the menu inputs to their defaults."),
  input_button("Filter", "filter", "open.filter", class = "btn-link"),
  list(
    name = "Settings",
    backdrop = "false",
    class = "menu-compact",
    items = list(
      input_switch("Dark Theme", id = "settings.theme_dark"),
      input_select("Color Palette", options = "palettes", id = "settings.palette", floating_label = FALSE),
      input_switch(
        "Color by Rank",
        id = "settings.color_by_order",
        note = paste(
          "Switch from coloring by value to coloring by sorted index.",
          "This may help differentiate regions with similar values."
        )
      ),
      input_switch("Hide URL Settings", id = "settings.hide_url_parameters"),
      input_switch("Hide Tooltips", id = "settings.hide_tooltips"),
      input_switch("Show Missing Years", id = "settings.show_empty_times"),
      input_select(
        "Color Scale Center",
        options = c("none", "median", "mean"), default = "none",
        display = c("None", "Median", "Mean"), id = "settings.color_scale_center",
        floating_label = FALSE,
        note = "Determines whether and on what the color scale should be centered."
      ),
      '<p class="section-heading">Map Options</p>',
      input_number(
        "Outline Weight", "settings.polygon_outline",
        default = 1, step = .5, floating_label = FALSE,
        note = "Thickness of the outline around region shapes."
      ),
      '<p class="section-heading">Plot Options</p>',
      input_select("Plot Type", c("scatter", "scattergl", "bar"), "scatter", id = "plot_type", floating_label = FALSE),
      input_switch("Box Plots", default_on = TRUE, id = "settings.boxplots"),
      input_switch(
        "Use IQR Whiskers",
        default_on = TRUE, id = "settings.iqr_box",
        note = "Define the extreme fences of the box plots by 1.5 * interquartile range (true) or min and max (false)."
      ),
      input_number(
        "Trace Limit", "settings.trace_limit",
        default = 20, floating_label = FALSE,
        note = "Limit the number of plot traces that can be drawn, split between extremes of the variable."
      ),
      '<p class="section-heading">Table Options</p>',
      input_switch("Auto-Sort", default_on = TRUE, id = "settings.table_autosort"),
      input_switch("Auto-Scroll", default_on = TRUE, id = "settings.table_autoscroll"),
      input_select(
        "Scroll Behavior", c("instant", "smooth", "auto"), "auto",
        id = "settings.table_scroll_behavior", floating_label = FALSE
      )
    ),
    foot = list(
      input_button("Clear Settings", "reset_storage", "clear_storage", class = "btn-danger")
    )
  ),
  list(
    name = "About",
    items = list(
      page_text(c(
        "This site is a rework of [industryatlas.org](https://github.com/kenny101/industryatlas).",
        paste0(
          "It is built around the same [County Business Patterns Database]",
          "(https://www.fpeckert.me/cbp/) as of 2025-04, which was created as part of the ",
          "[Imputing Missing Values in the US Census Bureau&apos;s County Business Patterns]",
          "(https://www.nber.org/papers/w26632) paper."
        ),
        paste0(
          "This site was made by the Yale [Data-Intensive Social Science Center]",
          "(https://dissc.yale.edu)."
        ),
        input_button("Download All Data", "export", query = list(
          features = list(geoid = "id", name = "name")
        ), class = "btn-full"),
        "Credits",
        paste(
          "Built in [R](https://www.r-project.org) with the",
          "[community](https://uva-bi-sdad.github.io/community) package, using these resources:"
        )
      ), class = c("", "", "", "", "h5")),
      output_credits()
    )
  )
)


## `input_dataview` can collect multiple inputs as filters for a shared data view
input_dataview(
  "primary_view",
  y = "selected_variable",
  x = "selected_year",
  dataset = "county",
  time_agg = "selected_year",
  ids = "filter.county",
)

output_info(
  title = "features.name",
  body = c(
    "variables.long_name" = "selected_variable",
    "variables.statement"
  ),
  row_style = c("stack", "table"),
  dataview = "primary_view",
  subto = c("main_map", "main_plot", "rank_table", "main_legend"),
  variable_info = FALSE,
  floating = TRUE
)

# use `page_section` to build the page's layout
output_info(
  title = "variables.short_name",
  dataview = "primary_view",
  id = "variable_info_pane",
)
page_section(
  page_section(
    type = "col side-panel",
    input_combobox(
      "Sector",
      options = "variables",
      id = "selected_variable", note = paste(
        "Determines which sector is shown on the plot's y-axis, in the rank table,",
        "and info fields, and used to color map polygons and plot elements."
      )
    ),
    input_number(
      "Selected Year", min = "filter.time_min", max = "filter.time_max", default = 2016,
      id = "selected_year", buttons = TRUE, show_range = TRUE, note = paste(
        "Year of the selected variable to color the map shapes and plot elements by, and to show on hover."
      )
    ),
    output_legend(
      "settings.palette",
      dataview = "primary_view", click = "region_select",
      subto = c("main_map", "main_plot", "rank_table"), id = "main_legend"
    ),
    output_info(body = "summary", dataview = "primary_view"),
    output_info("Filters", "filter", dataview = "primary_view"),
    page_section(
      type = "mt-auto w-100",
      page_popup(
        "Export",
        page_section(
          wraps = "col",
          input_select("Table Format", c("tall", "mixed", "wide"), "mixed", id = "export_table_format"),
          input_select("File Format", c("csv", "tsv"), "csv", c("CSV", "TSV"), id = "export_file_format")
        ),
        input_button(
          "Download", "export",
          dataview = "primary_view", query = list(
            include = "selected_variable",
            features = list(geoid = "id", name = "name"),
            table_format = "export_table_format", file_format = "export_file_format"
          )
        )
      )
    )
  ),
  page_section(
    type = "col",
    output_map(
      list(
        name = "county",
        url = "counties_2010.geojson",
        id_property = "geoid"
      ),
      dataview = "primary_view",
      id = "main_map",
      subto = c("main_plot", "rank_table", "main_legend"),
      options = list(
        attributionControl = FALSE,
        scrollWheelZoom = FALSE,
        center = c(38, -96),
        zoom = 5,
        height = "720px",
        zoomAnimation = "settings.map_zoom_animation",
        setView = FALSE
      ),
      tiles = list(
        light = list(url = "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"),
        dark = list(url = "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png")
      ),
      attribution = list(
        list(
          name = "CARTO",
          url = "https://carto.com/attributions",
          description = "Map tiles by CARTO"
        ),
        list(
          name = "OpenStreetMap",
          url = "https://www.openstreetmap.org/copyright"
        )
      )
    )
  )
)
page_section(
  wraps = "col",
  sizes = c(5, 7),
  output_table("selected_variable", dataview = "primary_view", options = list(
    info = FALSE,
    searching = FALSE,
    scrollY = 420,
    scrollX = "100%",
    dom = "<'row't>"
  ), id = "rank_table", click = "region_select", subto = c("main_map", "main_plot", "main_legend")),
  output_plot(
    x = "time", y = "selected_variable", dataview = "primary_view",
    click = "region_select", subto = c("main_map", "rank_table", "main_legend"), id = "main_plot",
    options = list(
      layout = list(
        xaxis = list(title = FALSE, fixedrange = TRUE),
        yaxis = list(fixedrange = TRUE, zeroline = FALSE)
      ),
      data = data.frame(
        type = c("plot_type", "box"), fillcolor = c(NA, "transparent"),
        hoverinfo = c("text", NA), mode = "lines+markers", showlegend = FALSE,
        name = c(NA, "Summary"), marker.line.color = "#767676", marker.line.width = 1
      ),
      config = list(modeBarButtonsToRemove = c("select2d", "lasso2d", "sendDataToCloud"))
    )
  )
)