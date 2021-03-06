class TermsController < ApplicationController

  # store the current location in case of an atempt to login, for redirecting back
  before_filter :store_location, :only => [:show, :index]

  before_filter :ensure_event_parameter?, :except => [:show, :index, :destroy]

  # Protect these actions behind a moderator login
  before_filter :is_granted_to_edit?, :except => [:show, :index, :destroy]

  before_filter :is_granted_to_destroy?, :only => [:destroy]

  # GET /terms
  # GET /terms.xml
  def index

    if params[:period] == "past"
      @period_link_param = "futur"
      @terms = Term.search_has_publisher_past(params[:search], params[:page])
    else
      @period_link_param = "past"
      @terms = Term.search_has_publisher_futur(params[:search], params[:page])
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @terms }
      format.js {
        render :update do |page|
          page.replace_html 'results', :partial => 'terms_list'
        end
      }
    end
  end

  # GET /terms/1
  # GET /terms/1.xml
  def show
    #@event = Event.find(params[:event_id])
    @term = Term.find(params[:id])
    @current_object = @event = @term.event unless @term.nil?
    @comment = Comment.new
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @term }
    end
  end

  # GET /terms/new
  # GET /terms/new.xml
  def new
    @event = Event.find(params[:event_id])
    @term = Term.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @term }
    end
  end

  # GET /terms/1/edit
  def edit
    @event = Event.find(params[:event_id])
    @term = Term.find(params[:id])
  end

  # POST /terms
  # POST /terms.xml
  def create
    
    @term = Term.new(params[:term])

    @term.start = Time.parse(params[:term][:start])
    @term.end = Time.parse(params[:term][:end])
    #@term.start = Date.strptime(params[:term][:start], "%d/%m/%Y %H:%M")
    

    @term.event_id = params[:event_id]

    #create associations between terms and categories via categories_terms table
    @event = Event.find(params[:event_id])
    @event.terms << @term
    
    respond_to do |format|
      if @term.save
        flash[:notice] = 'Term was successfully created.'
        format.html { redirect_to(@event) }
        format.xml  { head :ok }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @term.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /terms/1
  # PUT /terms/1.xml
  def update
    @term = Term.find(params[:id])
    @event = Event.find(params[:event_id])

    params[:term][:start] = Time.parse(params[:term][:start])
    params[:term][:end] = Time.parse(params[:term][:end])

    respond_to do |format|
      if @term.update_attributes(params[:term])
        flash[:notice] = 'Term was successfully updated.'
        format.html { redirect_to(@event) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @term.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /terms/1
  # DELETE /terms/1.xml
  def destroy
    term = Term.find(params[:id])
    event = term.event
    term.destroy

    respond_to do |format|
      format.html { redirect_to(event) }
      format.xml  { head :ok }
    end
  end


  
  protected

  def ensure_event_parameter?
    no_event_param_redirection unless !params[:event_id].nil? && !Event.find(params[:event_id]).nil?
  end

  def no_event_param_redirection
		flash[:error] = "Event parameter is missing or not correct."
		redirect_to root_path
	end

 def is_granted_to_edit?
    event = Event.find(params[:event_id])
    not_granted_redirection unless current_user && event.is_granted_to_edit?(current_user)
  end

 def is_granted_to_destroy?
    term = Term.find(params[:id])
    event = term.event
    not_granted_redirection unless current_user && event.is_granted_to_edit?(current_user)
  end

  def not_granted_redirection
    flash[:error] = "Not allowed to do this"
    redirect_to root_path
  end

  
end
