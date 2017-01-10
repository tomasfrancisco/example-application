log   = require './log'
http  = require 'http'
consul = require('consul')()
ipify = require 'ipify'

serviceName = 'person-generator'

personGeneratorService = (callback) ->
  consul.catalog.service.nodes serviceName, (err, result) ->
    throw err if err
    data = {
      address:  result[0].ServiceAddress
      port:     result[0].ServicePort
    }
    callback data

module.exports = personGeneratorService
