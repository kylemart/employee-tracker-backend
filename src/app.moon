package.path ..= ";./?/init.lua"

lapis = require "lapis"

class extends lapis.Application
	@include "Applications.EmployeeTracker"

	default_route: =>
		if @req.parsed_url.path\match("./$")
			return {
				redirect_to: @build_url(
					@req.parsed_url.path\match("^(.+)/+$"), {
						query: @req.parsed_url.query
					}
				)
				status: 301
			}
		else
			self.app.handle_404(self)

	handle_404: => {layout: false}, "Failed to find route: #{@req.cmd_url}"

	[index: "/"]: => "Hello World"