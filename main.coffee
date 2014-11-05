MongoGraph = {}
MongoGraph.GRAPHS = {}

if Meteor.isServer
  
  Meteor.startup ->
    console.log "mongo-graph running on " + process.env.MONGO_URL

  path = Npm.require("path")
  Future = Npm.require(path.join("fibers", "future"))
  
  createCollection = (name) ->
  for globalVal of global
    return global[globalVal]  if global[globalVal]._name is name  if global[globalVal] instanceof Mongo.Collection
  new Mongo.Collection(name)

  MongoGraph.initialize = (collectionName) ->
    MongoGraph.COLLECTION = createCollection(collectionName)

    MongoGraph.COLLECTION.aggregate = (pipeline) ->
      self = this
      future = new Future()
      self.find()._mongo._withDb (db) -> 
        db.createCollection self._name, (err, collection) ->
          if err
            console.log err
            future.throw(err);
            return
          collection.aggregate pipeline, (err, result) ->
            if err
              console.log err
              future.throw(err);
              return
            future.return [true, result]

      result = future.wait()
      throw result[1] unless result[0]
      return result[1]

  Meteor.methods
    'aggregate': (pipeline) -> 
      return MongoGraph.COLLECTION.aggregate(pipeline);


if Meteor.isClient

  enc = (str) ->
    str.replace(/\ /g, '__')

  dec = (str) ->
    str.replace(/__/g, ' ')

  MongoGraph.create = (className, options) ->

    # set defaults
    options = {} if not options
    keys = options.keys || []
    values = options.values ||  [{name: "# of documents", accumulator: "$sum", field: 1}]
    query = options.query || {}
    sortKeys = options.sortKeys
    sortValues = options.sortValues
    limit = options.limit || null
    highchartsOptions = options.highchartsOptions || {}
    keyFormat = options.keyFormat

    # remove nesting and format keys for aggregation
    key_expr = {}
    if _.isArray(keys)
      for key in keys
        key_expr[key.replace(/\./g, '_')] = "$"+key
    else
      key_expr = keys

    group_expr = {_id: key_expr}
    
    # format values (either a string property or the number "1") for aggregation
    for v in values
      o = {}
      if _.isString(v.field)
        v.field = "$"+v.field
      o[v.accumulator] = v.field
      group_expr[enc(v.name)] = o

    # setup to sort by either key or value
    sort = {}
    if sortValues
      for k, v of sortValues
        k = enc(k)
        sort[k] = v
    else if sortKeys
      for k, v of sortKeys
        k = "_id." + k
        sort[k] = v
    else
      sort = {"_id": 1}

    pipeline = [{$match: query}, {$group: group_expr}, {$sort: sort}]

    if limit
      pipeline.push {$limit: limit}

    Meteor.call "aggregate", pipeline, (err, points) ->
      if err
        console.error('Mongo aggregation error: ' + err)
        return

      # post-process values
      for value in values
        if value.postProcess
          for point in points
            val = point[enc(value.name)]
            processedVal = value.postProcess(val)
            point[enc(value.name)] = processedVal

      xSeries = _.map points, (f) ->
        if _.isObject(f['_id'])
          if keyFormat
            return keyFormat(f['_id'])
          else
            label = _.values f['_id']
            return label.join(', ')
        else
          return f['_id'].toString()

      series = []
      for seriesName of points[0]
        if seriesName != '_id'
          series.push {name: dec(seriesName), data: _.pluck(points, seriesName)}

      highchartsData = 
        xAxis:
          categories: xSeries
        series: series

      # some sensible defaults
      highchartsDefaults =
        title:
          text: "Data"
          x: -20
        yAxis:
          title:
            text: ""

      _.extend(highchartsData, highchartsDefaults, highchartsOptions)

      $(document).ready ->
        $('.'+className).highcharts(highchartsData)
        
