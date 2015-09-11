Flights = new (Mongo.Collection)('flights')
Flight = Astro.Class(
  name: 'Flight'
  collection: Flights
  transform: true
  fields:
    'key': 'string'
    'Date': 'date'
    'Mktg Al': 'string'
    'Alliance': 'string'
    'Op Al': 'string'
    'Orig': 'object'
    'Dest': 'object'
    'Miles': 'number'
    'Flight': 'number'
    'Stops': 'number'
    'Equip': 'string'
    'Seats': 'number'
    'Dep Term': 'string'
    'Arr Term': 'string'
    'Dep Time': 'number'
    'Arr Time': 'number'
    'Block Mins': 'number'
    'Arr Flag': 'boolean'
    'Orig WAC': 'number'
    'Dest WAC': 'number'
    'Op Days': 'string'
    'Ops/Week': 'number'
    'Seats/Week': 'number'
  events: {}
  methods: {})
if Meteor.isClient
else
if Meteor.isServer
else