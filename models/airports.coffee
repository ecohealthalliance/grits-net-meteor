Airports = new (Mongo.Collection)('airports')
Airport = Astro.Class(
  name: 'Airport'
  collection: Airports
  transform: true
  fields:
    'name': 'string'
    'city': 'string'
    'state': 'string'
    'stateName': 'string'
    'loc': 'object' 
    'loc.type': 'string'
    'loc.coordinates': 'array'
    'country': 'number'
    'countryName': 'string'
    'globalRegion': 'string'
    'WAC': 'number'
    'notes': 'string'
  events: {}
  methods: {})