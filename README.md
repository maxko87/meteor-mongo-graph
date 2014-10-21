====
meteor-mongo-graph
===

Quickly create Highcharts.js powered graphs directly from your Mongo collections. 

Atmopshere project is available [here](https://atmospherejs.com/maxko87/mongo-graph).

## Setup

Initialize MongoGraph with the collection you'll be creating graphs from. All other commands are
executed on the client.

  server.coffee
  ```coffeescript
if Meteor.isServer
  MongoGraph.initialize('collection_name')
  ```

## Examples

  main.html
  ```html
<!-- create divs to hold the graphs -->
<div class="ordersPerPerson"></div>
<div class="dollarsSpent"></div>
<div class="ordersPerDay"></div>
  ```

  client.coffee
  ```coffeescript

MongoGraph.create 'ordersPerPerson',
  keys: ['request.last_name'] # x-axis values -- dot notation works for keying on nested values 
  values: [
    {
      name: "Orders Placed" # name of the line graph
      accumulator: "$sum" # any mongo accumulator (http://docs.mongodb.org/manual/reference/operator/aggregation-group/)
      field: 1 # the value to sum -- in this case, we just do a count
    }
  ]
  limit: 10 # max number of points to plot
  query: {'request.last_name': {'$exists': 1}} # only use documents that fit a certain schema
  sortValues: {'Orders Placed': -1} # sorting on values
  highchartsOptions: # options to override the Highcharts initialization options
    chart:
      type: "column"
    title:
      text: "Orders / User This Month"

MongoGraph.create 'dollarsSpent',
  keys: ['request.first_name', 'request.last_name'] # key on both first and last name this time
  values: [
    {
      name: "Dollars Spent"
      accumulator: "$sum"
      field: "price_components.subtotal" # sum a field this time
      postProcess: (num) -> parseInt(num/100) # post-process calculation to convert all cent to dollar values
    }
  ]

MongoGraph.create 'ordersPerDay',
  query: {'request': {'$exists': 1}, '_created_at': {'$gt': new Date(Date.now() - 1000 * 60 * 60 * 24 * 30)}}
  keys: { month: {$month: "$_created_at"}, day: {$dayOfMonth: "$_created_at"} } # use $ for mongo style keys
  keyFormat: (o) ->
    return o.month + "/" + o.day # special formatting for displaying the keys (e.g. 05/10 for May 10th)
  values: [
    {
      name: "Orders"
      accumulator: "$sum"
      field: 1
    }
  ]
  sortKeys: {month: 1, day: 1} # sorting on keys: first by month, then by day
  ```