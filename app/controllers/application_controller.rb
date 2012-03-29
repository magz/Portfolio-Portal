class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :get_ip_for_analytics

  #as is this is placed in the application controller, it will go off any time anyone accesses any controller action, unless it's specifically skipped
  #as it will be in, for example, ajax calls (since this would lead to duplicate results)
  def get_ip_for_analytics
  	#this is just going to keep a db log of ip addresses that hit the site
  	#you coudl accomplish similar things via filtering your logs (via regex), but I decided to go this route in order to show off a few things
  	#there's a cron job set up to update (on a daily basis, though easily chnageable) a graph of the number of uniques in the past week
  	#fortunately, the free heroku slice I'm throwing this on let's me set up a daily cron job for free

  	a=Access.new(ip: request.remote_ip)
  	begin
  		a.save
  	rescue
  	end



  end





end
