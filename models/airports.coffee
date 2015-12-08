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
  methods: {
    # return an object that can be used to determine typeahead matches
    typeaheadMatcher: () ->
      WAC: {weight: 0, regexOptions: 'ig', display: 'WAC'}
      notes: {weight: 1, regexOptions: 'ig', display: 'Notes'}
      globalRegion: {weight: 2, regexOptions: 'ig', display: 'Global Region'}
      countryName: {weight: 3, regexOptions: 'ig', display: 'Country Name'}
      country: {weight: 4, regexOptions: 'ig', display: 'Country'}
      stateName: {weight: 5, regexOptions: 'ig', display: 'State Name'}
      state: {weight: 6, regexOptions: 'ig', display: 'State'}
      city: {weight: 7, regexOptions: 'ig', display: 'City'}
      name: {weight: 8, regexOptions: 'i', display: null}
      _id: {weight: 9, regexOptions: 'i', display: null}    
  })