log   = require './log'
http  = require 'http'
consul = require('consul')()
ipify = require 'ipify'

serviceName = 'person-generator'

getServiceAddress = (callback) ->
  consul.catalog.service.nodes serviceName, (err, result) ->
    callback err if err
    if result and result[0]
      data = {
        address:  result[0].ServiceAddress
        port:     result[0].ServicePort
      }
      callback null, data

module.exports = {
  getServiceAddress
}
