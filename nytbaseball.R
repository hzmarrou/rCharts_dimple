require(Lahman)  
require(plyr)
require(ggplot2)

dat = Teams[,c('yearID', 'name', 'lgID', 'G', 'SO')]
team_data = na.omit(transform(dat, SOG = round(SO/G, 2)))
team_data$yearID = paste0(team_data$yearID, "-01-01")

ggplot(data = team_data, aes(x=yearID, y=SOG, colour=name)) +
  geom_point() +
  stat_summary(fun.y=mean,geom="line",aes(group=1))

ggplot(team_data,aes(x=as.Date(yearID),y=SOG)) +
  geom_point() +
  geom_smooth(groups=1)

require(rCharts)
p1 <- dPlot(
  SOG ~ yearID,
  groups = "average",
  data = team_data,
  type = 'line' 
)
p1$xAxis(
  type = "addTimeAxis",
  inputFormat = "%Y-%m-%d",
  outputFormat = "%Y"
)

p1$setTemplate(
  afterScript = sprintf(
    '<script>
    //delete some of the ticks
    {{chartId}}.forEach(function(cht){
      cht.axes[0].timePeriod = d3.time.years;
      cht.axes[0].timeInterval = 20;
      cht.draw();
    })
    </script>'
  )
)
p1



#test out some facets
p1_facets <- p1$copy()
p1_facets$params$facet <- list(
  x = "lgID", y = NULL
)
p1_facets

p1_facets$facet(removeAxes=T)
p1_facets


p1$layer(
  y="SOG",
  x="yearID",
  groups = "name",
  data = NULL,
  type = 'bubble' 
)
p1$xAxis(
  type = "addTimeAxis",
  inputFormat = "%Y-%m-%d",
  outputFormat = "%Y",
  overrideMin = sprintf("#!new Date('%s')!#",min(team_data$yearID)),
  overrideMax = sprintf("#!new Date('%s')!#",max(team_data$yearID))
)
p1$yAxis(
  outputFormat = ".2f",
  #axes are not linked, so dimple doesn't handle well
  #overrideMin and overrideMax are inherited though
  #if not specified in additional layers
  overrideMax = round(max(team_data$SOG))
)
myteam = "Boston Red Sox"
p1$layer(
  SOG ~ yearID,
  data = team_data[team_data$name == myteam,],
  groups = "name",
  type = 'line'
)

#now clean it up a bit with new rCharts functionality
p1$setTemplate(
  afterScript = sprintf(
    '<script>
    //delete some of the ticks
    {{chartId}}.forEach(function(cht){
      cht.axes[0].timePeriod = d3.time.years;
      cht.axes[0].timeInterval = 20;
      cht.draw();
    })

    var svg = {{chartId}}[0].svg;
    svg.selectAll("path")
        .transition()
        .delay(200)
        .style("pointer-events","none")
    //do a delayed transition to make the circles smaller
    //since dimple drawing has a transition; wait for it
    svg.selectAll("circle").transition().attr("r",1).delay(200)

    //fix scale for additional layers
    //does not work cross browser
    //use overrideMin/Max instead
    /*d3.selectAll("circle.series1.bubble")
      .transition()
      .attr("cy",function(d){
        return myChart.axes[1]._draw.scale()(d.y)
      })
      .delay(200);
    */
    //#remove the hover effect for the lines
    svg.selectAll("circle  + .dimple-series-2 + [id*=%s]").transition().remove()
    svg.selectAll("circle + [id*=%s]").transition().remove()
    </script>',
    paste0("'",myteam,"'"),
    paste0("'",p1$params$groups[1],"'")
  )
)
p1


#test out some facets
p1_facets <- p1$copy()
p1_facets$params$facet <- list(
  x = "lgID", y = NULL
)
p1_facets

p1_facets$facet(removeAxes=T)
p1_facets

p1_facets$params$layers <- list()
p1_facets


#test to see that r mean matches dimple.aggregateMethod.avg
p2 <- dPlot(
  SOG ~ yearID,
  groups = "average",
  data = team_data,
  type = 'line' 
)
p2$xAxis(
  type = "addTimeAxis",
  inputFormat = "%Y-%m-%d",
  outputFormat = "%Y"
)
p2$yAxis(
  outputFormat = ".2f",
  #axes are not linked, so dimple doesn't handle well
  #overrideMin and overrideMax are inherited though
  #if not specified in additional layers
  overrideMax = round(max(team_data$SOG))
)
year_data_mean = ddply(
  team_data,
  .(yearID),
  summarize,
  mean = mean(SOG)
)
p2$layer(
  mean~yearID,
  groups="rAvg",
  data = year_data_mean,
  type = "area"
)
p2$layer(
  mean~yearID,
  groups="rAvg",
  data = year_data_mean,
  type = "bubble"
)
p2



#color axis is not working as expected
# I think this is really nice functionality
# in next version make sure to solve this
p1$copy()$colorAxis(
  type = "addColorAxis",
  colorSeries = "SOG",
  palette = c("red","yellow","green")
)
p1