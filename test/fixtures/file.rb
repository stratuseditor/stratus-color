# TODO
# * Make before_filter :setup_dropdowns
#   not run unless necessary 
#   (layout being rendered || searching with AJAX).
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :setup_dropdowns
  
  # Dont render the layout for AJAX requests.
  layout(Proc.new { |c| c.request.xhr? ? false : "application" })
  
  ALL_CATEGORIES = "All"
  
  # An Array of all of the fields that can be searched by
  # using the dropdown search. This *must* be in the order
  # that it is on the search form.
  # 
  # If a field is added to this that needs autocomplete functionality
  # in the search but does not use +DROPDOWN_DEFAULTS+, public/search.js
  # needs to be updated in +Bikes.Search.init+ the ensure that the key events
  # make the right AJAX calls.
  SEARCH_FIELDS = [:category, :year, :cc_adv, :cyls, :subcategory, :brand, :model, :avocom]
  # An Array of fields that are ranges in the dropdown search.
  RANGE_SEARCH_FIELDS = [:year, :cc_adv, :avocom]
  # Default values for the dropdown search, by field.
  DROPDOWN_DEFAULTS = {
    :category => ["Street", "Scooter", "Dual", "Dirt", "Mini", ALL_CATEGORIES],
    :year => ["2010-2019", "2000-2009", "1990-1999",
              "1980-1989", "1970-1979", "1960-1969",
              "1950-1959", "1940-1949", "1930-1939",
              "1920-1929", "1910-1919", "1900-1909",
              "1880-1899"],
    :cc_adv => ["1-50", "51-125", "126-250", "251-400", "401-500",
                "501-650", "651-750", "751-1000", "1001-1200",
                "1201-1600", "1601-1750", "1751-2000",
                "2001-9000"],
    :cyls => (1..10).to_a.join(",").split(","),
    :avocom => ["1-2000", "2001-4000", "4001-6000", "6001-8000",
                "8001-10000", "10001-12000", "12001-14000",
                "14001-16000", "16001-18000", "18001-20000",
                "20001-25000", "25001-30000", "30000-100000"]
  }
  # The maximum number of results returned to fill the combobox.
  ITEMS_PER_DROPDOWN = 40
  
  # When a user selects a bike, that bike's fields
  # are filled into the dropdown search. This is
  # an Array of fields that should not be filled in.
  # 
  # It should include all of the advanced fields, otherwise
  # the advanced search will always start out expanded.
  DONT_AUTOFILL = [:model, :cyls, :avocom]
  
  private
  
  # FILTERS
  
  # The user must have at least one current bike,
  # otherwise they are redirected to the home page.
  # This is a +before_filter+.
  # 
  # The current bike(s) are stored in +session+,
  # so the user doesn't actually need to be logged in.
  def need_bike!
    if !session[:bikes] || session[:bikes].empty?
      flash[:error] = "You need to select a bike to do that"
      redirect_to "/"
    else
      @current_bikes = Array.new
      session[:bikes].each do |bike_id|
        @current_bikes << Bike.find(bike_id)
      end
      @current_bike = @current_bikes.first
    end
  end
  
  # Redirect the user if the item requested
  # does not belong to the user.
  # Apply as a +before_filter+:
  #   before_filter(:only => [:edit, :update, :destroy]) { |c| belongs_to_user(Model) }
  # 
  # Params:
  # * redir
  #   +nil+ to redirect to root. Otherwise, an argument for +redirect_to+.
  # * user
  #   Something.send(user) must be equal to the current user.
  #   If +nil+, uses :user.
  #   
  #   For mail, this should be :from or :to.
  def belongs_to_user(model_class, redir = nil, user = nil)
    if model_class.find(params[:id]).send(user || :user) != current_user
      flash[:error] = "That isn't yours!"
      redirect_to(redir || '/')
    end
  end
  
  # Override render to call +selected_from_current_bike+
  # when appropriate.
  def render(*args)
    if !params[:search] && session[:bikes] && !session[:bikes].empty?
      selected_from_current_bike
    end
    super
  end
  
  ###############################################################
  # Bike search stuff                                           #
  ###############################################################
  
  # Convert a field to a range for use in the search
  # Example:
  #   >> to_range(1992, :year)
  #   => '1990-1999'
  # The field must be in +DROPDOWN_DEFAULTS+.
  def to_range(number, field)
    DROPDOWN_DEFAULTS[field].each do |range|
      if range.split('-')[0].to_f <= number.to_f && number.to_f <= range.split('-')[1].to_f
        return range
      end
    end
    return number
  end
  
  # Use the current bike to choose the
  # +@selected+ values.
  def selected_from_current_bike
    bike = Bike.find(session[:bikes].first)
    @selected ||= {}
    # Set everything.
    SEARCH_FIELDS.each do |field|
      # Don't set model or advanced fields.
      if DONT_AUTOFILL.include?(field)
        @selected[field] = ""
      else
        if RANGE_SEARCH_FIELDS.include? field
          @selected[field] = to_range(bike[field].to_s, field)
        else
          @selected[field] = bike[field].to_s
        end
      end
    end
    # Set the category
    if DROPDOWN_DEFAULTS[:category].include? bike.category.split("-")[0]
      @original_category = bike.category.split("-")[0]
    else
      @original_category = ALL_CATEGORIES
    end
  end
  
  # Set +@selected+ using the most recent search,
  # as stored in the +params+ hash.
  def selected_from_search_params
    @original_category = params[:search][:category] || "Street"
    # The other fields.
    SEARCH_FIELDS.each do |field|
      # All should be "".
      params[:search][field] = "" if params[:search][field] == ALL_CATEGORIES
      @selected[field] = params[:search][field] || ""
    end
  end
  
  # Set +@selected+ using the user's past search
  # that was stored in the cookie.
  def selected_from_cookies
    last_search = JSON.parse cookies[:bike_search]
    # Change the keys to symbols and put them in @selected.
    last_search.each do |field, query|
      @selected[field.to_sym] = query || ""
    end
  end
  
  # Create the +@selected+ hash.
  # It assigns +@selected+ some default values, and then
  # overrides them by calling 1 or 0 of the following:
  # - +selected_from_search_params+
  # - +selected_from_current_bike+
  # - +selected_from_cookies+
  def setup_selected
    # If nothing else works, it will be as if they selected blanks..
    @selected = { :category => "",
                  :year => "",
                  :brand => "",
                  :model => "",
                  :cc_adv => "",
                  :cyls => "",
                  :subcategory => "",
                  :avocom => "" }
    # Set the selected items from the drop down.
    if params[:search]
      selected_from_search_params
    elsif session[:bikes] && !session[:bikes].empty?
      selected_from_current_bike
    # Try to get the last search from cookies.
    elsif cookies[:bike_search]
      selected_from_cookies
    end
    # Set the user's cookies to remember the selected bike.
    cookies[:bike_search] = @selected.to_json
  end
  
  
  # Create the +@dropdown+ hash.
  # +@dropdown+ contains the values that should
  # be returned to the user in the search form.
  def setup_dropdowns
    setup_selected
    
    # The field to search fuzzily.
    like_field = (params[:search] && params[:search][:like]) ? params[:search][:like].to_sym : nil
    
    @dropdown = {}
    # If like_field return results for like_field and the next field.
    fields_in_dropdowns = if like_field && SEARCH_FIELDS.include?(like_field.to_sym)
        fields = [like_field]
        fields << (nxt = SEARCH_FIELDS.index(like_field) + 1) if nxt
        fields
      else
        SEARCH_FIELDS
      end
    
    # Change the fields which the user selected as a range
    # to a start and end for the BETWEEN clause.
    (RANGE_SEARCH_FIELDS).each do |field|
      if @selected[field].include? "-"
        # The keys are :year_s and :year_e for start and end.
        @selected[(field.to_s + "_s").to_sym] = @selected[field].split("-")[0].to_s
        @selected[(field.to_s + "_e").to_sym] = @selected[field].split("-")[1].to_s
      elsif @selected[field] == ''
        @selected[(field.to_s + "_s").to_sym] = ""
        @selected[(field.to_s + "_e").to_sym] = ""
      else
        @selected[(field.to_s + "_s").to_sym] = @selected[field]
        @selected[(field.to_s + "_e").to_sym] = @selected[field]
      end
    end
    
    fields_in_dropdowns.each do |field|
      # Fuzzy search
      where = (like_field and like_field == field) ? ["#{ field } LIKE :#{ field }_like"] : []
      # General conditions
      conditions = BikesController.conditions(SEARCH_FIELDS[0, SEARCH_FIELDS.index(field)], where)
      @selected[(field.to_s + "_like").to_sym] = @selected[field] + "%"
      
      @dropdown[field] = DROPDOWN_DEFAULTS[field] || Bike.find(:all,
        :select => "DISTINCT #{ field.to_s }",
        :order => "#{ field.to_s } ASC",
        :conditions => [conditions, @selected],
        :limit => ITEMS_PER_DROPDOWN
      ).collect {|bike| bike.send(field) }
      
      @selected.delete((field.to_s + "_like").to_sym)
      
      # Add "All", except for categoy.
      @dropdown[field] = [ALL_CATEGORIES] | @dropdown[field] unless field == :category
      
      # Tell the user to refine their search if the results hit the limit.
      # >= is used because of "Any being added to the beginning"
      if @dropdown[field].length >= ITEMS_PER_DROPDOWN
        @dropdown[field].push "Refine your search to see more results"
      end
    end
  end
  
  # Return the order that the query should be sorted by.
  # This is determined by accessing +params[:order]+ and +params[:dir]+.
  def sort_order
    # Check for params.
    valid_sort   = params[:order] && params[:dir]
    # Validate the direction.
    valid_sort &&= %w(asc desc).include?(params[:dir])
    # Validate the order column.
    valid_sort &&= params[:order].match(/^[a-zA-Z0-9_]*$/)
    if valid_sort
      "`#{ params[:order] }` #{ params[:dir] }"
    else
      ""
    end
  end
  # Same as +sort_order+, but with the syntax thinking_sphinx needs.
  # 'year' is changed to '_year' (as found in the bike model)
  # because 'year' is a reserved word for Sphinx.
  def sort_order_sphinx
    if %w(asc desc).include?(params[:dir]) && params[:order].match(/^[a-zA-Z0-9_]*$/)
      order = params[:order].clone if  params[:order]
      order = "_year" if params[:order] == "year"
      (params[:order] && params[:dir]) ? "#{ order } #{ params[:dir] }" : nil
    end
  end
  
end
