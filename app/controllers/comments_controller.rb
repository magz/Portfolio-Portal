class CommentsController < ApplicationController

	def ajax_create
		if params[:body]
			@comment = Comment.new
			@comment.body
			@comment.save
			render :json => {success: true}
		else
			render :json => {success: false}

		end


	end

	def ajax_get
		params[:size] ||= 5
		@comments = Comment.last(params[:size])
		
		template_format = :html
		#gotta write this partial..nbd
        @comments_html = render_to_string(:partial=>'comments.html.erb', :layout => false, :locals => {:comments => @comments}).html_safe
        render :json => { :success => true, :comment_html => @comment_html  }

	end













end