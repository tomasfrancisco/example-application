log = require "./log"
r   = require 'rethinkdb'

connection = null

dbConfig = {
  host: 'localhost'
  port: 28015
  db: 'generator'
  tables: {
    'persons': 'id'
  }
}

# connect to database
onConnect = (callback) ->
  r.connect host: dbConfig.host, port: dbConfig.port, (err, connection) ->
    connection['_id'] = Math.floor Math.random() * 10001
    callback err, connection

# Create database and his tables
module.exports.setup = () ->
  r.connect host: dbConfig.host, port: dbConfig.port, (err, connection) ->
    r.dbCreate dbConfig.db
      .run connection, (err, result) ->
        if err
          log.debug "RethinkDB database '%s' already exists (%s:%s)\n%s", dbConfig.db, err.name, err.msg, err.message
        else
          log.info "RethinkDB database '%s' created", dbConfig.db

        for table, id of dbConfig.tables
          do (table) ->
            r.db dbConfig.db
              .tableCreate table, primaryKey: dbConfig.tables[table]
              .run connection, (err, result) ->
                if err
                  log.debug "RethinkDB table '%s' already exists (%s:%s)\n%s", table, err.name, err.msg, err.message
                else
                  log.info "RethinkDB table '%s' created", table

# save person json object
module.exports.savePerson = (person, callback) ->
  onConnect (err, connection) ->
    r.db dbConfig.db
      .table 'persons'
      .insert person
      .run connection, (err, result) ->
        if err
          log.error "[%s][savePerson] %s:%s\n%s", connection['_id'], err.name, err.msg, err.message
          callback err
        else
          if result.inserted is 1
            callback null, true
          else
            callback null, false
        connection.close()

# subscribe to person table changes with script
module.exports.personChanges = (filter, callback) ->
  onConnect (err, connection) ->
    log.error "Error on connection:", err if err
    r.db dbConfig.db
      .table 'persons'
      .changes()
      .filter(filter)
      .run connection, (err, cursor) ->
        callback(err, cursor)

# persons filter with default values
module.exports.personsFilter = (ageMin = 0, ageMax = Number.MAX_SAFE_INTEGER, gender = 'both') ->
  log.info "[NEW FILTER] ageMin: %s, ageMax: %s, gender: %s", ageMin, ageMax, gender
  return r.row("new_val")("age").lt(parseInt(ageMax)).and(r.row("new_val")("age").gt(parseInt(ageMin)).and(r.row("new_val")("gender").eq(if gender is 'both' then r.row("new_val")("gender") else gender)))
