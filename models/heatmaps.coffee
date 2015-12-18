Heatmaps = new (Mongo.Collection)('heatmap')
Heatmap = Astro.Class(
  name: 'Heatmap'
  collection: Heatmaps
  transform: (doc) ->
    heatmap = new Heatmap(doc)
    # ignore the fields of the constructor
    ignore = Object.keys(heatmap.constructor.getFields())
    # the diff is a list of codes
    codes = _.difference(Object.keys(doc), ignore)
    airports = Airports.find({'_id':{'$in': codes}}, {transform: null}).fetch()
    # map the data
    heatmap.data = []
    _.each(doc, (value, key) ->
      airport = _.find(airports, (a) -> a._id == key)
      if _.isUndefined(airport)
        return
      heatmap.data.push([airport.loc.coordinates[1], airport.loc.coordinates[0], value, key])
    )
    return heatmap
  fields:
    'lastModified': 'date'
    'version': 'string'
    'simulatedPassengers': 'number'
    'data': 'array'
  events: { }
  methods: { }
)