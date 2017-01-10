ApplicationLayoutView = require "./views/ApplicationLayoutView"
NavigationView        = require "./views/NavigationView"
LinkCollection        = require "./collections/LinkCollection"

Application = new Marionette.Application
	container: "#application"

Application.triggerRoute = (route, args...) ->
	@trigger "route", route, args...
	@trigger "route:#{route}", args...

Application.addInitializer ->
	@addRegions
		applicationRegion: "#application"

	@layoutView = new ApplicationLayoutView

	@navigationView = new NavigationView
		collection: new LinkCollection [
			{ url: "/#persons", route: "persons", name: "Persons", active: false }
			{ url: "/#todos",   route: "todos",   name: "ToDos",   active: false }
		]

	@applicationRegion.show @layoutView

	@layoutView.navigation.show @navigationView

module.exports = Application
