# visualization

# stack api

key = "YOUR_API_KEY_HERE"

cleanResponse = (site) ->
    (response) ->
        items = response.items[0]
        items.site = site
        items

getStats = (site) ->
    $.getJSON("https://api.stackexchange.com/2.1/info?site=#{site}&key=#{key}")
        .then cleanResponse(site)

# fetch data and draw

soFetch = getStats "stackoverflow"
suFetch = getStats "superuser"
sfFetch = getStats "serverfault"

$.when(soFetch, suFetch, sfFetch).then (so, su, sf) ->
    d3.select("#viz").append("ul")
        .selectAll("li").data([so, su, sf])
        .enter().append("li")
        .text (site) -> "#{site.site}: #{site.total_unanswered}/#{site.total_questions}"
