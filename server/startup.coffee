_warmupMongoFlights = (done) ->
  query = {"departureAirport._id":{"$in":["BOS"]}}
  console.log('warmup flights')
  async.eachSeries([0..9],
    (x, callback) ->
      Meteor.call('flightsByQuery', query, 100, x*100, (err, res) ->
        callback()
      )
    (err) ->
      done()
  )
  return
_warmupMongoAirports = (done) ->
  letters = ['b','o','s']
  console.log('warmup airports')
  async.eachSeries([0..9],
    (x, callback) ->
      Meteor.call('typeaheadAirport', letters[x], x*10, (err, res) ->
        callback()
      )
    (err) ->
      done()
  )
  return
warmupMongo = () ->
  start = new Date()
  console.log('starting warmup')
  async.auto({
    'warmupMongoFlights': (callback, result) ->
      _warmupMongoFlights(callback)
    'warmupMongoAirports': (callback, result) ->
      _warmupMongoAirports(callback)
  }, (err, result) ->
    console.log('warmup done(ms): ', new Date() - start)
  )

Meteor.startup ->
  # if we're not in a test environment, warmup mongodb
  Meteor.call('isTestEnvironment', (err, res) ->
    if res == false
      warmupMongo()
  )
  # setup i18n
  i18n.addLanguage('en', 'English')
