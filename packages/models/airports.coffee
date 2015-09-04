Airports = new (Mongo.Collection)('airports')
Airport = Astro.Class(
  name: 'Airport'
  collection: Airports
  transform: true
  fields:
    'Code': 'string'
    'Name': 'string'
    'City': 'string'
    'State': 'string'
    'State Name': 'string'
    'loc': 'object' 
    'loc.type': 'string'
    'loc.coordinates': 'array'
    'Country': 'number'
    'Country Name': 'string'
    'Global Region': 'string'
    'WAC': 'number'
    'Notes': 'string'
  events: {}
  methods: {})
if Meteor.isClient
else
if Meteor.isServer
else