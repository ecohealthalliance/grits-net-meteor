Simulations = new (Mongo.Collection)('simulations')
Simulation = Astro.Class(
  name: 'Simulation'
  collection: Simulations
  transform: true
  fields:
    'simId': 'string'
    'departureNode': 'string'
    'numberPassengers': 'number'
    'startDate': 'date'
    'endDate': 'date'
    'submittedBy': 'string'
    'submittedTime': 'date'
  events: {}
  methods: {})
