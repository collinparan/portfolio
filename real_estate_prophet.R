install.packages("DBI", "RMySQL","prophet","plotly","anytime", "jsonlite")

library(DBI)
library(RMySQL)
library(plotly)
library(anytime)
library(prophet)
library(jsonlite)
library(RPostgreSQL)

############################################################################################

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")

#Estabalishes the connection
conn = dbConnect(drv, user='<user>', password='<pass>', dbname='<db>', host='<host>')

sqlString <- "SELECT
	*
FROM
public.vw_denver_university_hood
WHERE EXTRACT(YEAR FROM to_date(year_month,'YYYY-MM')) > 2017"

#Sends the query to get the columns and rows
rs = dbSendQuery(conn,sqlString)

#Compiles the data and removes the header
df = fetch(rs, n=-1)

#Disconnects with the database
dbDisconnect(conn)

#########################################################
#Using Facebook Prophet
##########################################################

alldata <- df

alldata$ds <- anytime(alldata$year_month)
alldata$data <- df$med_val_per_sqft

stats <- alldata %>% 
  select(ds, data) 

colnames(stats) <- c("ds", "y")

m <- prophet(weekly.seasonality=FALSE)
m <- add_seasonality(m, name='monthly', period=30.5, fourier.order=5)
m <- fit.prophet(m, df)
future <- make_future_dataframe(m, periods = 200)

forecast <- predict(m, future)

plot(m, forecast, main="Zillow & FB Prophet", sub="analysis by Collin Paran", xlab="time", ylab="USD value")


tail(forecast[c('ds', 'yhat', 'yhat_lower', 'yhat_upper')])

tail(forecast)

prophet_plot_components(m, forecast)

#############################################
##Plotly
############################################
p <- plot_ly(forecast, x = forecast$ds, y = forecast$yhat_upper, type = 'scatter', mode = 'lines',
             line = list(color = 'transparent'),
             showlegend = FALSE, name = 'High') %>%
  add_trace(y = forecast$yhat_lower, type = 'scatter', mode = 'lines',
            fill = 'tonexty', fillcolor='rgba(168, 216, 234,0.5)', line = list(color = 'transparent'),
            showlegend = FALSE, name = 'Low') %>%
  add_trace(x = forecast$ds, y = forecast$yhat, type = 'scatter', mode = 'lines',
            line = list(color='rgb(168, 216, 234)'),
            name = 'Average') %>%
  add_trace(x = alldata$ds, y = alldata$data, type = 'scatter', mode = 'markers',
            line = list(color=I('black')),
            name = 'Actual') %>%
  layout(title = "Zillow: Mean Value Per Sqft of Denver University Neighborhood",
         paper_bgcolor='rgb(255,255,255)', plot_bgcolor='rgb(229,229,229)',
         xaxis = list(title = "Date Time",
                      gridcolor = 'rgb(255,255,255)',
                      showgrid = TRUE,
                      showline = FALSE,
                      showticklabels = TRUE,
                      tickcolor = 'rgb(127,127,127)',
                      ticks = 'outside',
                      zeroline = FALSE),
         yaxis = list(title = "USD",
                      gridcolor = 'rgb(255,255,255)',
                      showgrid = TRUE,
                      showline = FALSE,
                      showticklabels = TRUE,
                      tickcolor = 'rgb(127,127,127)',
                      ticks = 'outside',
                      zeroline = FALSE))

p

htmlwidgets::saveWidget(as_widget(p), "real_estate.html")
