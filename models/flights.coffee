Flights = new (Mongo.Collection)('legs')
Flight = Astro.Class(
  name: 'Flight'
  collection: Flights
  transform: true
  fields:
    # _id is md5 hash of (effectiveDate, carrier, flightNumber)
    'carrier' : 'string'
    'flightNumber' : 'number'
    'serviceType' : 'string'
    'effectiveDate' : 'date'
    'discontinuedDate' : 'date'
    'day1' : 'boolean'
    'day2' : 'boolean'
    'day3' : 'boolean'
    'day4' : 'boolean'
    'day5' : 'boolean'
    'day6' : 'boolean'
    'day7' : 'boolean'
    'departureAirport' : 'object'
    #'departureCity' : 'string'
    #'departureState' : 'string'
    #'departureCountry' : 'string'
    #'departureTimePub' : 'date'
    #'departureTimeActual' : 'date'
    #'departureUTCVariance' : 'number'
    #'departureTerminal' : 'string'
    'arrivalAirport' : 'object'
    #'arrivalCity' : 'string'
    #'arrivalState' : 'string'
    #'arrivalCountry' : 'string'
    #'arrivalTimePub' : 'date'
    #'arrivalTimeActual' : 'date'
    #'arrivalUTCVariance' : 'number'
    #'arrivalTerminal' : 'string'
    #'subAircraftCode' : 'string'
    #'groupAircraftCode' : 'string'
    #'classes' : 'string'
    #'classesFull' : 'string'
    #'trafficRestriction' : 'string'
    #'flightArrivalDayIndicator' : 'string'
    #'stops' : 'number'
    #'stopCodes' : 'array'
    #'stopRestrictions' : 'string'
    #'stopsubAircraftCodes' : 'number'
    #'aircraftChangeIndicator' : 'string'
    #'meals' : 'string'
    #'flightDistance' : 'number'
    #'elapsedTime' : 'number'
    #'layoverTime' : 'number'
    #'inFlightService' : 'string'
    #'SSIMcodeShareStatus' : 'string'
    #'SSIMcodeShareCarrier' : 'string'
    #'codeshareIndicator' : 'boolean'
    #'wetleaseIndicator' : 'boolean'
    #'codeshareInfo' : 'array'
    #'wetleaseInfo' : 'string'
    #'operationalSuffix' : 'string'
    #'ivi' : 'number'
    #'leg' : 'number'
    #'recordId' : 'number'
    #'daysOfOperation' : 'string'
    #'totalFrequency' : 'number'
    'weeklyFrequency' : 'number'
    #'availSeatMi' : 'number'
    #'availSeatKm' : 'number'
    #'intStopArrivaltime' : 'array'
    #'intStopDepartureTime' : 'array'
    #'intStopNextDay' : 'array'
    #'physicalLegKey' : 'array'
    #'departureAirportName' : 'string'
    #'departureCityName' : 'string'
    #'departureCountryName' : 'string'
    #'arrivalAirportName' : 'string'
    #'arrivalCityName' : 'string'
    #'arrivalCountryName' : 'string'
    #'aircraftType' : 'string'
    #'carrierName' : 'string'
    'totalSeats' : 'number'
    #'firstClassSeats' : 'number'
    #'businessClassSeats' : 'number'
    #'premiumEconomyClassSeats' : 'number'
    #'economyClassSeats' : 'number'
    #'aircraftTonnage' : 'number'
  events: {}
  methods: {})
