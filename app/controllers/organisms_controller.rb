class OrganismsController < ApplicationController

  # store the current location in case of an atempt to login, for redirecting back
  before_filter :store_location, :only => [:show, :index]

  # Protect these actions behind an admin login
  before_filter :is_organism_admin?, :only => [:update, :edit, :destroy, :purge, :suspend, :unsuspend]

  # GET /organisms
  # GET /organisms.xml
  def index
    @organisms = Organism.search(params[:search], params[:page])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @organisms }
      format.js {
        render :update do |page|
          page.replace_html 'results', :partial => 'organisms_list'
        end
      }
    end
  end

  # GET /organisms/1
  # GET /organisms/1.xml
  def show
    @current_object = @organism = Organism.find(params[:id])

    #the object comment is needed for displaying the form of new comment
    @comment = Comment.new

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organism }
    end
  end

  # GET /organisms/new
  # GET /organisms/new.xml
  def new
    @organism = Organism.new
    set_session_parent_parameters(@organism)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organism }
    end
  end

  # GET /organisms/1/edit
  def edit
    @organism = Organism.find(params[:id])
    set_session_parent_parameters(@organism)
  end

  # POST /organisms
  # POST /organisms.xml
  def create
    @organism = Organism.new(params[:organism])
    set_session_parent_parameters(@organism)

    respond_to do |format|
      @organism.register! if @organism && @organism.valid?
      success = @organism && @organism.valid?
      
      if success && @organism.errors.empty?
        flash[:notice] = 'Organism was successfully created. A moderator will look at it for activation ASAP'
        format.html { redirect_to(@organism) }
        format.xml  { render :xml => @organism, :status => :created, :location => @organism }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /organisms/1
  # PUT /organisms/1.xml
  def update
    @organism = Organism.find(params[:id])
    set_session_parent_parameters(@organism)
    
    respond_to do |format|
      if @organism.update_attributes(params[:organism])
        flash[:notice] = 'Organism was successfully updated.'
        format.html { redirect_to(@organism) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /organisms/1
  # DELETE /organisms/1.xml
  def destroy
    @organism = Organism.find(params[:id])
    @organism.destroy

    respond_to do |format|
      format.html { redirect_to(organisms_url) }
      format.xml  { head :ok }
    end
  end

  def activate
    organism = Organism.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && organism && !organism.active?
      organism.activate!
      flash[:notice] = "Organism activated! You can start to use it."
       redirect_to(organism)
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else
      flash[:error]  = "We couldn't find an organism with that activation code -- check your email? Or maybe you've already activated -- try using it."
      redirect_back_or_default('/')
    end
  end

  # PUT /users/1/suspend
  def suspend
    @organism = Organism.find(params[:id])
    @organism.suspend!
    redirect_to(organisms_url)
  end

  # PUT /users/1/unsuspend
  def unsuspend
    @organism = Organism.find(params[:id])
    @organism.unsuspend!
    redirect_to(organisms_url)
  end

  # DELETE /users/1
  def destroy
    @organism = Organism.find(params[:id])
    @organism.delete!
    redirect_to(organisms_url)
  end

  # DELETE /users/1/purge
  def purge
    @organism = Organism.find(params[:id])
    @organism.destroy
    redirect_to(organisms_url)
  end

  # Check if logged in user has organism_admin or organism_moderator rights
  #
  # will return true if the logged in user is equal as the controlled user (or admin or moderator)
	def organism_admin_or_moderator?
    return true
    #TODO: implement organism_moderator and organism_admin
    #no_permission_redirection unless self.current_user && (self.current_user.id==find_user.id || self.current_user.has_system_role('moderator'))
  end

  def is_organism_moderator?
    organism = Organism.find(params[:id])
    not_granted_redirection unless current_user && organism.is_user_moderator?(current_user)
  end

  def is_organism_admin?
    organism = Organism.find(params[:id])
    not_granted_redirection unless current_user && organism.is_user_admin?(current_user)
  end

  def not_granted_redirection
    flash[:error] = "Not allowed to do this"
    redirect_to root_path
  end

end