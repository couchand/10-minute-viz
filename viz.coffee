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

bySite = d3.nest().key (d) -> d.site.site.name
stack = d3.layout.stack()

# stack api

key = "YOUR_API_KEY_HERE"
filter =
    sites: "!SmOA0zL2EfpNhn1ZEq"
    stats: "!.HwmyBFZVc789XV8bpU9Aa1g0GdoP"

getItems = (response) -> response.items
getFirst = (response) -> response[0]

allSites = {}
saveSites = (sites) ->
    allSites[site.api_site_parameter] = site for site in sites

getSites = () ->
    $.getJSON("https://api.stackexchange.com/2.1/sites?key=#{key}&filter=#{filter.sites}")
        .then(getItems)
        .then saveSites

getStats = (site) ->
    $.getJSON("https://api.stackexchange.com/2.1/info?site=#{site}&key=#{key}&filter=#{filter.stats}")
        .then(getItems)
        .then(getFirst)

extractTypes = (sites) ->
    for site in sites
        site.questions = ["unanswered", "answered", "accepted"].map (type) ->
            if type is "answered"
                type: type
                count: site.total_questions - site.total_accepted - site.total_unanswered
            else
                type: type
                count: site["total_#{type}"]

# fetch data and draw

getSites().then ->
    soFetch = getStats "stackoverflow"
    suFetch = getStats "superuser"
    sfFetch = getStats "serverfault"

    $.when(soFetch, suFetch, sfFetch).then drawChart

drawChart = (so, su, sf) ->
#    console.log stack bySite.entries(flatten [so, su, sf]).map (d) -> d.values
    sites = [so, sf, su]
    extractTypes sites

    xScale.domain sites.map (d) -> d.site.name
    yScale.domain [0, d3.max sites, (d) -> d.total_questions]

    [radius, innerRadius, paddingSize] = calculateRadius()
    arc.outerRadius(radius)
        .innerRadius(innerRadius)

    yScale.range [height, radius*2 + paddingSize]

    d3.select("#viz").append("ul")
        .selectAll("li").data([so, su, sf])
        .enter().append("li")
        .text (site) -> "#{site.site.name}: #{format site.total_unanswered}/#{format site.total_questions}"

    svg = d3.select("#viz").append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", "translate(#{margin.left},#{margin.top})")

    svg.selectAll(".site")
        .data(sites)
        .enter().append("rect")
        .attr("class", "site")
        .attr("title", tooltipBar)
        .attr("fill", "#ccc")
        .attr("x", xBySite)
        .attr("y", yByTotal)
        .attr("fill", colorBySite)
        .attr("width", xScale.rangeBand())
        .attr("height", (d) -> height - yByTotal(d))

    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0,#{height})")
        .call(xAxis)

    svg.append("g")
        .attr("class", "y axis")
        .call(yAxis)

    pies = svg.selectAll(".pie")
        .data(sites)
        .enter().append("g")
        .attr("class", "pie")
        .attr("transform", (d) -> "translate(#{radius + xBySite(d) + paddingSize},#{radius})")

    pies.selectAll(".arc")
        .data((d) -> pie d.questions)
        .enter().append("path")
        .attr("class", "arc")
        .attr("title", tooltipPie)
        .attr("d", arc)
        .style("fill", (d) -> colorByType d.data)
