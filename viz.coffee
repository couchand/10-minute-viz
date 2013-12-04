# visualization

# chart helpers

format = d3.format "1,000"
tooltipPie = (d) -> "#{format d.data.count} #{d.data.type} questions"
tooltipBar = (d) -> "#{format d.total_questions} questions"

margin =
  top: 20
  right: 20
  bottom: 20
  left: 80
width = 960 - margin.left - margin.right
height = 600 - margin.top - margin.bottom

thickness = 0.4
padding = 0.2

color =
  answered: "#75845C"
  accepted: "#46B525"
  unanswered: "#9A4444"

xScale = d3.scale.ordinal()
    .rangeRoundBands [0, width], 0.2

yScale = d3.scale.linear()

xAxis = d3.svg.axis()
    .scale(xScale)
    .tickSize(0)
    .orient "bottom"

yAxis = d3.svg.axis()
    .scale(yScale)
    .tickFormat(format)
    .orient "left"

xBySite = (d) -> xScale d.site.name
yByCount = (d) -> yScale d.count
yByTotal = (d) -> yScale d.total_questions
colorByType = (d) -> color[d.type]
colorBySite = (d) -> d.site.styling.tag_foreground_color

calculateRadius = ->
    radius = xScale.rangeBand() * 0.5
    paddingSize = radius * padding
    radius -= paddingSize
    [radius,  radius - radius * thickness, paddingSize]

arc = d3.svg.arc()
pie = d3.layout.pie()
    .sort(null)
    .value (d) -> d.count

# stack api

key = "YOUR_API_KEY_HERE"
filter =
    sites: "!2--dQ)lBeYF_nW9vSSb3m"
    stats: "!tRKJ12V4q)fdK4mizgMuEQWjsOeXIou"

getItems = (response) -> response.items
getFirst = (response) -> response[0]

siteList = []
siteMap = {}
saveSites = (sites) ->
    siteList = []
    for site in sites.filter((d) -> d.site_type is "main_site")
        site.name = $("<span>").html(site.name).text()
        siteMap[site.api_site_parameter] = site
        siteList.push site

getSites = () ->
    $.getJSON("https://api.stackexchange.com/2.1/sites?key=#{key}&filter=#{filter.sites}&pagesize=999")
        .then(getItems)
        .then(saveSites)

getStats = (site) ->
    $.getJSON("https://api.stackexchange.com/2.1/info?site=#{site}&key=#{key}&filter=#{filter.stats}")
        .then(getItems)
        .then(getFirst)

extractTypes = (sites) ->
    for site in sites
        site.site = siteMap[site.site.api_site_parameter]
        site.questions = ["unanswered", "answered", "accepted"].map (type) ->
            if type is "answered"
                type: type
                count: site.total_questions - site.total_accepted - site.total_unanswered
            else
                type: type
                count: site["total_#{type}"]

# fetch data and draw

createBars = (bars) ->
    bars.append("rect")
        .attr("class", "site")
        .attr("title", tooltipBar)
        .call(updateBars)

updateBars = (bars) ->
    bars.attr("x", xBySite)
        .attr("y", yByTotal)
        .attr("fill", colorBySite)
        .attr("width", xScale.rangeBand())
        .attr("height", (d) -> height - yByTotal(d))

createPies = (radius, paddingSize) -> (pies) ->
    pies = pies.append("g")
        .attr("class", "pie")

    pies.append("image")
        .attr("class", "logo")
        .attr("title", (d) -> d.site.name)
        .attr("xlink:href", (d) -> d.site.icon_url)
        .attr("preserveAspectRatio", "xMidYMid")

    pies.call(updatePies(radius, paddingSize))

updatePies = (radius, paddingSize) -> (pies) ->
    pies.attr("transform", (d) -> "translate(#{radius + xBySite(d) + paddingSize},#{radius})")

    pies.select(".logo")
        .attr("width", radius)
        .attr("height", radius)
        .attr("transform", "translate(#{-radius*0.5},#{-radius*0.5})")

createArcs = (arcs) ->
    arcs.append("path")
        .attr("class", "arc")
        .attr("stroke", "#ccc")
        .call(updateArcs)

updateArcs = (arcs) ->
    arcs.attr("title", tooltipPie)
        .attr("d", arc)
        .style("fill", (d) -> colorByType d.data)

svg = no

createChart = ->
    svg = d3.select("#viz").append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", "translate(#{margin.left},#{margin.top})")

    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0,#{height})")
    svg.append("g")
        .attr("class", "y axis")

drawChart = (sites) ->
    createChart() if not svg

    xScale.domain sites.map (d) -> d.site.name
    yScale.domain [0, d3.max sites, (d) -> d.total_questions]

    [radius, innerRadius, paddingSize] = calculateRadius()
    arc.outerRadius(radius)
        .innerRadius(innerRadius)

    yScale.nice().range [height, radius*2 + paddingSize]

    bars = svg.selectAll(".site")
        .data(sites, (d) -> d.site.name)

    bars.enter()
        .call(createBars)

    bars.exit()
        .remove()

    bars.transition(40)
        .call(updateBars)

    pies = svg.selectAll(".pie")
        .data(sites, (d) -> d.site.name)

    pies.enter()
        .call(createPies(radius, paddingSize))

    pies.exit()
        .remove()

    pies.transition(40)
        .call(updatePies(radius, paddingSize))

    arcs = pies.selectAll(".arc")
        .data((d) -> pie d.questions)

    arcs.enter()
        .call(createArcs)

    arcs.transition(40)
        .call(updateArcs)

    svg.select(".x.axis")
        .transition(40)
        .call(xAxis)
    svg.select(".y.axis")
        .transition(40)
        .call(yAxis)

drawSelect = (sites) ->
    $p = $("#pick").autocomplete
        source: sites.map (d) ->
            label: d.name
            value: d.api_site_parameter
        select: ->
            site = siteMap[$p.val()]
            site.selected = !site.selected
            setTimeout (-> $p.val(""); draw()), 0

draw = ->
    fetches = siteList.filter((d) -> d.selected)
        .map((d) -> d.api_site_parameter)
        .map getStats

    $.when.apply($, fetches).then ->
        sites = Array.prototype.slice.call arguments
        extractTypes sites
        drawChart sites

getSites().then () ->
    drawSelect siteList

    siteMap["stackoverflow"].selected = yes
    siteMap["superuser"].selected = yes
    siteMap["serverfault"].selected = yes

    draw()
