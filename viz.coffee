# visualization

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

# fetch data and draw

getSites().then ->
    soFetch = getStats "stackoverflow"
    suFetch = getStats "superuser"
    sfFetch = getStats "serverfault"

    $.when(soFetch, suFetch, sfFetch).then drawChart

drawChart = (so, su, sf) ->
    d3.select("#viz").append("ul")
        .selectAll("li").data([so, su, sf])
        .enter().append("li")
        .text (site) -> "#{site.site}: #{site.total_unanswered}/#{site.total_questions}"
