module UsersHelper

  def display_user_cover_by_id(id, style)
    display_user_cover(User.find(id), style)
  end

  def get_default_user_cover(style)
    image_tag("default/user/#{style}/1.jpg")
  end

  def display_user_cover(user, style)
    mini_height = "36px"
    thumb_width = "72px"
    small_width = "126px"

    if user.facebook_user?
      case style
      when "mini"
        image = image_tag(user.fb_image_small, :height => mini_height)
      when "thumb"
        image = image_tag(user.fb_image, :width => thumb_width)
      when "small"
        image = image_tag(user.fb_image, :width => small_width)
      when "medium"
        image = image_tag(user.fb_image)
      when "large"
        image = image_tag(user.fb_image_big)
      else
        image = image_tag(user.fb_image)
      end
    else
      if style == "mini"
        image = image_tag("default/user/thumb/1.jpg", :height => mini_height)
        
      else
        image = image_tag("default/user/#{style}/1.jpg")
      end
    end
    if acquaintance_rights?(user)
      link_to(image, user)
    else
      if user.facebook_user?
        link_to(image, "http://www.facebook.com/people/#{user.first_name}-#{user.last_name}/#{user.fb_user_id}", :target => 'blank')
      else
        image
      end
    end
  end

  def get_user_name_or_pseudo_by_id(id)
    unless id.nil?
      get_user_name_or_pseudo(User.find(id))
    end
  end

  def get_user_name_or_pseudo(user)
    if user.facebook_user?
      return user.first_name + " " + user.last_name
    else
      return user.login
    end
  end

  def get_user_name_or_pseudo_link_by_id(id)
    user = User.find(id)
    link_to(get_user_name_or_pseudo(user), user)
  end

  def get_user_name_or_pseudo_link(user)
    link_to(get_user_name_or_pseudo(user), user)
  end

  #return an url for the user if logged in. Else return url to login page
  def url_for_user_show(user)
    if logged_in?
      return url_for user_path(user)
    else
      return url_for login_path
    end
  end

  def current_user_equal(user)
    if logged_in? && user
      if current_user.id == user.id
        return true
      end
    end
    return false
  end
  
  #
  # Use this to wrap view elements that the user can't access.
  # !! Note: this is an *interface*, not *security* feature !!
  # You need to do all access control at the controller level.
  #
  # Example:
  # <%= if_authorized?(:index,   User)  do link_to('List all users', users_path) end %> |
  # <%= if_authorized?(:edit,    @user) do link_to('Edit this user', edit_user_path) end %> |
  # <%= if_authorized?(:destroy, @user) do link_to 'Destroy', @user, :confirm => 'Are you sure?', :method => :delete end %> 
  #
  #
  def if_authorized?(action, resource, &block)
    if authorized?(action, resource)
      yield action, resource
    end
  end

  #
  # Link to user's page ('users/1')
  #
  # By default, their login is used as link text and link title (tooltip)
  #
  # Takes options
  # * :content_text => 'Content text in place of user.login', escaped with
  #   the standard h() function.
  # * :content_method => :user_instance_method_to_call_for_content_text
  # * :title_method => :user_instance_method_to_call_for_title_attribute
  # * as well as link_to()'s standard options
  #
  # Examples:
  #   link_to_user @user
  #   # => <a href="/users/3" title="barmy">barmy</a>
  #
  #   # if you've added a .name attribute:
  #  content_tag :span, :class => :vcard do
  #    (link_to_user user, :class => 'fn n', :title_method => :login, :content_method => :name) +
  #          ': ' + (content_tag :span, user.email, :class => 'email')
  #   end
  #   # => <span class="vcard"><a href="/users/3" title="barmy" class="fn n">Cyril Fotheringay-Phipps</a>: <span class="email">barmy@blandings.com</span></span>
  #
  #   link_to_user @user, :content_text => 'Your user page'
  #   # => <a href="/users/3" title="barmy" class="nickname">Your user page</a>
  #
  def link_to_user(user, options={})
    raise "Invalid user" unless user
    options.reverse_merge! :content_method => :login, :title_method => :login, :class => :nickname
    content_text      = options.delete(:content_text)
    content_text    ||= user.send(options.delete(:content_method))
    options[:title] ||= user.send(options.delete(:title_method))
    link_to h(content_text), user_path(user), options
  end

  #
  # Link to login page using remote ip address as link content
  #
  # The :title (and thus, tooltip) is set to the IP address 
  #
  # Examples:
  #   link_to_login_with_IP
  #   # => <a href="/login" title="169.69.69.69">169.69.69.69</a>
  #
  #   link_to_login_with_IP :content_text => 'not signed in'
  #   # => <a href="/login" title="169.69.69.69">not signed in</a>
  #
  def link_to_login_with_IP content_text=nil, options={}
    ip_addr           = request.remote_ip
    content_text    ||= ip_addr
    options.reverse_merge! :title => ip_addr
    if tag = options.delete(:tag)
      content_tag tag, h(content_text), options
    else
      link_to h(content_text), login_path, options
    end
  end

  #
  # Link to the current user's page (using link_to_user) or to the login page
  # (using link_to_login_with_IP).
  #
  def link_to_current_user(options={})
    if current_user
      link_to_user current_user, options
    else
      content_text = options.delete(:content_text) || 'not signed in'
      # kill ignored options from link_to_user
      [:content_method, :title_method].each{|opt| options.delete(opt)} 
      link_to_login_with_IP content_text, options
    end
  end

  #check if the logged in user is an acquaintance of the user to controll
  def acquaintance_rights?(user_to_display)
    allowed_to_view_profile = false

    if current_user
      if current_user.id==user_to_display.id || current_user.has_system_role('moderator')
        allowed_to_view_profile = true
      else
        #check if both current user and user to display are facebook users in order to use the friends system
        if current_user.facebook_user? && user_to_display.facebook_user?
          current_fb_user = Facebooker::User.new(current_user.fb_user_id)
          if current_fb_user.friends_with?(user_to_display.fb_user_id)
            allowed_to_view_profile = true
          end
        end
      end
    end

    return allowed_to_view_profile
  end

  def user_profile_link(user)
    if acquaintance_rights?(user)
      link_to(get_user_name_or_pseudo(user), user)
    else
      if user.facebook_user?
        link_to(get_user_name_or_pseudo(user), "http://www.facebook.com/people/#{user.first_name}-#{user.last_name}/#{user.fb_user_id}", :target => 'blank')
      else
        get_user_name_or_pseudo(user)
      end
    end
  end
end
