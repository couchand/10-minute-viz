# visualization

# chart helpers

format = d3.format "1,000"

margin =
  top: 40
  right: 20
  bottom: 20
  left: 50
width = 960 - margin.left - margin.right
height = 600 - margin.top - margin.bottom

color =
  answered: "#75845C"
  accepted: "#46B525"
  unanswered: "#9A4444"

xScale = d3.scale.ordinal()
    .rangeRoundBands [0, width], 0.1

yScale = d3.scale.linear()
    .range [height, 0]

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

tagSite = (site) ->
    (response) -> response.site = allSites[site]; response

getSites = () ->
    $.getJSON("https://api.stackexchange.com/2.1/sites?key=#{key}&filter=#{filter.sites}")
        .then(getItems)
        .then saveSites

getStats = (site) ->
    $.getJSON("https://api.stackexchange.com/2.1/info?site=#{site}&key=#{key}&filter=#{filter.stats}")
        .then(getItems)
        .then(getFirst)
        .then tagSite(site)

flatten = (sites) ->
    stats = []
    for site in sites
        stats.push
            site: site
            type: "accepted"
            count: site.total_accepted
        stats.push
            site: site
            type: "unanswered"
            count: site.total_unanswered
        stats.push
            site: site
            type: "answered"
            count: site.total_questions - site.total_accepted - site.total_unanswered
    stats

# fetch data and draw

getSites().then ->
    soFetch = getStats "stackoverflow"
    suFetch = getStats "superuser"
    sfFetch = getStats "serverfault"

    $.when(soFetch, suFetch, sfFetch).then drawChart

drawChart = (so, su, sf) ->
#    console.log stack bySite.entries(flatten [so, su, sf]).map (d) -> d.values
    xScale.domain [so, sf, su].map (d) -> d.site.name
    yScale.domain d3.extent [so, sf, su], (d) -> d.total_questions

    d3.select("#viz").append("ul")
        .selectAll("li").data([so, su, sf])
        .enter().append("li")
        .text (site) -> "#{site.site.name}: #{format site.total_unanswered}/#{format site.total_questions}"

    svg = d3.select("#viz").append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", "translate(#{margin.left},#{margin.top})")

    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0,#{height})")
        .call(xAxis)

    svg.append("g")
        .attr("class", "y axis")
        .call(yAxis)

    svg.selectAll(".site")
        .data([so, su, sf])
        .enter().append("rect")
        .attr("class", "site")
        .attr("fill", "#ccc")
        .attr("x", xBySite)
        .attr("y", yByTotal)
        .attr("width", xScale.rangeBand())
        .attr("height", (d) -> height - yByTotal(d))
