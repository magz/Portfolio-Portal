desc "Cron task to update the visitor stats image"
task :cron => :environment do
	
	if Time.now.hour == 23 # run at midnight
		require 'gruff'

		stats = []
		

		# so, really, you'd probably want to measure uniques (which could be accomplished via a slight modification of the query below....
		#OR by doing a scope validation at the model validation level to only insert a model into the DB if it's unique for the current day
		#but i thought i'd keep it simple and make sure the graph actually has some variation/data points on it
		(1..7).each {|d| stats << Hit.where(:created_at => (Time.now.midnight - d.day)..(Time.now.midnight) - (d-1).day).count}

		g = Gruff::Line.new
		
		g.title = "Visits"
		g.data("Visits", stats)
		#put in labels for days of week
		
		#remove the old file to make sure we're gettin a fresh one
		# `` executes the included string at the commandline
		`rm public/visitor_stats.png`
		g.write("public/visitor_stats.png")
 


	end
end



