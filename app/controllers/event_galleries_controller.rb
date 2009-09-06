class EventGalleriesController < ApplicationController

  # store the current location in case of an atempt to login, for redirecting back
  before_filter :store_location, :only => [:show, :index]

  # GET /galleries
  # GET /galleries.xml
  def index
    @event = Event.find(params[:event_id])
    @galleries = @event.search_galleries(params[:search], params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @galleries }
      format.js {
        render :update do |page|
          page.replace_html 'results', :partial => '/galleries/galleries_list'
        end
      }
    end
  end
  
end