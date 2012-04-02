class MainController < ApplicationController
	require "open-uri"
	skip_before_filter :only => [:fetch_mail, :get_analytics_image, :ajax_create_comment, :ajax_get_comments]

   #do an auth filter
	#welcome you, or a visitor
	def welcome
   		#so I'm going to go ahead and explain what I'm doing here, since it involves a few steps of code kung-fu
   		#so, first, I'm obtaining some xml from the dino comix rss feed and converting it to a hash, via rails' convenient Active Record xml methods
   		#I then access the specific element I want (namely the html of the latest post entry)
   		#.html_safe is a handy sanitizer to make sure there's no bad stuff going on
   		#the resulting string of all this is assigned to the @dino_comix local, to be passed to the view
   		@dino_comix=(Hash.from_xml open("http://www.rsspect.com/rss/qwantz.xml").read)["rss"]["channel"]["item"][0]["description"].html_safe
   		#but, you might ask, how are you displaying just the image?  You can see the answer to that in the script of the view
   		#I could have manipulated the string in the ruby view here, but I decided that it would be easier (and more maintainable) to take advantage
   		#of jquery to pull out only the element I wanted (right tool for the right job and all that)

   		#so, this is pulling from the weather underground api (i registered for an api key for this assignment)
   		#it's currently hardcoded to williamsburg, because that's where I live
   		#in an actual app, I'd let a use select their own area code
   		#This is broadly similar to the above dino_comix rss call, except that it's accessing an api, which requires authorization and that the returned result is json instead of xml 
   		begin
            params[:weather_zip] = (ActiveSupport::JSON.decode open("http://api.ipinfodb.com/v3/ip-city?key=4d593c67638b66a938250797272d35d842b72eb1287435308be1932770929912&ip=" + request.remote_ip + "&format=json").read)["zipCode"]
         rescue
            params[:weather_zip] = "00000"
         end
         @brooklyn_weather = (ActiveSupport::JSON.decode open("http://api.wunderground.com/api/eb654ed434bd3526/conditions/q/"+params[:weather_zip]+".json").read)["current_observation"]
   		
   		#fetching all of my unread emails
   		@emails = []
   		Gmail.connect("michael.magner", "qwantz999").inbox.find(:unread).reverse.each do |g|
   			@emails << [g.message.from, g.message.subject]
   			#without this hte emails are marked as read, which is not what we want
   			g.unread!
   		end

   		@new_comment = Comment.new
         @comments = Comment.last 9
   		#The twitter nickname I want (@magz) is unfortunately taken, but inactive
   		#I threw together this little check to monitor whether it's been deleted yet
   		#Trying to access the twitter api for an invalid screen name throws a 404 error, hence the begin/rescue structure

   		begin
   			open("http://api.twitter.com/1/users/show.xml?screen_name=magz")
   			@twitter_check	= true
   		rescue
   			@twitter_check = false
   		end
	end

	def fetch_mail
		
		#so all this is doing is pulling in all of my unread emails...pretty self explanotry i think?
   		@emails = []
   		Gmail.connect("michael.magner", "qwantz999").inbox.find(:unread).each do |g|
   			@emails << [g.message.from, g.message.subject]
   			g.unread!
   		end

		
         render :json => {emails: @emails}

	end
	def ajax_create_comment
		#check to make sure body isn't blank
		if params[:comment][:body]
			@comment = Comment.new
			@comment.body  = params[:comment][:body]
			@comment.save
			
			#gather most recent comments, render the comments partial as a string...
		  @comments = Comment.last(5)
	     @comments_html = render_to_string(:partial=>'comments.html.erb', :layout => false, :locals => {:comments => @comments}).html_safe

	        #pass back success, along with the new most recent comments
	        #if I was doing this for real, I would have the success handler in the view just fire off the comments periodic updater (keeping to Don't Repeat Yourself)
	        #but i decided to make life slightly easier for myself in this exercise by passing this along
        	render :json => { :success => true, :comments_html => @comments_html  }
		else
			render :json => {success: false}

		end


	end

	def ajax_get_comments
		#this is the call hit 
		@comments = Comment.last(5)
		
		template_format = :html
		#gotta write this partial..nbd
        @comments_html = render_to_string(:partial=>'comments.html.erb', :layout => false, :locals => {:comments => @comments}).html_safe
        render :json => { :success => true, :comments_html => @comments_html  }

	end

	def get_analytics_image
		stats = []
      

      # so, really, you'd probably want to measure uniques (which could be accomplished via a slight modification of the query below....
      #OR by doing a scope validation at the model validation level to only insert a model into the DB if it's unique for the current day
      #but i thought i'd keep it simple and make sure the graph actually has some variation/data points on it

      g = Gruff::Line.new

      stats = []
      (0..6).each {|d| stats << Hit.where(:created_at => (Time.now.midnight - d.day)..(Time.now.midnight) - (d-1).day).count}
      g.data("Visits", stats.reverse)

      stats = []
      (0..6).each {|d| stats << Hit.where(:created_at => (Time.now.midnight - d.day)..(Time.now.midnight) - (d-1).day).count("ip_address", :distinct=>true)}
      g.data("Uniques", stats.reverse)


      
      g.title = "Visits"
      g.labels = {6 => 'Today', 5 => 'Yesterday'} #Labels for Each of the Graph
      [4,3,2,1,0].each {|d| g.labels[d]=(Time.now.midnight - d.day).strftime("%A")}




      send_data g.to_blob, :type => 'image/png', :disposition => 'inline'
	end

end