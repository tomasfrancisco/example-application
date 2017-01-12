class ControlsView extends Marionette.ItemView

	template: require "../templates/controls.jade"

	modelEvents:
    "change": "render"

	events:
    "click button.pause": "pauseButtonClicked"
    "click button.filter-age": "setAgeFilter"
    "change input#age-min-input": "resetAgeFilter"
    "click input#age-min-checkbox": "setMinAge"
    "change input#age-max-input": "resetAgeFilter"
    "click input#age-max-checkbox": "setMaxAge"
    "change input[name=genre]": "setGenre"

  filter: {}

	pauseButtonClicked: ->
    @model.set "pause", !@model.get "pause"


  emitFilter: ->
    socket.emit "persons:filter", @filter

  setMinAge: (evt) ->
    if evt.target.checked
      @filter.ageMin = document.getElementById("age-min-input").value
    else
      delete @filter.ageMin
    @emitFilter()

  setMaxAge: (evt) ->
    if evt.target.checked
      @filter.ageMax = document.getElementById("age-max-input").value
    else
      delete @filter.ageMax
    @emitFilter()

  setGenre: (evt) ->
    switch evt.target.value
      when 'female' then @filter.gender = 'Female'
      when 'male' then @filter.gender = 'Male'
      else delete @filter.gender
    @emitFilter()

  # setGenreFilter: (evt) ->
  #   switch evt.target.value
  #     when 'female' then socket.emit "persons:genre:create", 'female'
  #     when 'male' then socket.emit "persons:genre:create", 'male'
  #     else delete socket.emit "persons:genre:remove"
	#
  # setFilterAgeGreater: (evt) ->
  #   if evt.target.checked
  #     ageValue = document.getElementById("age-min-input").value
  #     socket.emit "persons:age:greater:create", ageValue
  #   else
  #     socket.emit "persons:age:greater:remove"
	#
  # setFilterAgemin: (evt) ->
  #   if evt.target.checked
  #     ageValue = document.getElementById("age-min-input").value
  #     socket.emit "persons:age:min:create", ageValue
  #   else
  #     socket.emit "persons:age:min:remove"

module.exports = ControlsView
