class EventsController < ApplicationController
  before_action :authenticate_user!, :except => [:index, :show]
  before_action :require_permission, :only => [:edit, :update, :destroy]

  def index
    @events = Event.all.order(:date, :time)
  end

  def new
    @event = Event.new
    if params[:project_id]
      @project = Project.find([params[:project_id]])
    end
  end

  def create
    @event = Event.new(event_params)
    @event.tag_list = event_params[:tag_list]
    @event.owner = current_user
    if @event.save
      if params[:project_id]
        EventsProject.create(event_id: @event.id, project_id: params[:project_id].to_i)
      end
      if Rails.env == 'production'
        $twitter.update("Check out #{@event.title}, a new Bootcampr event: http://bootcampr.herokuapp.com/events/#{@event.id}")
      end
      flash[:success] = "You created a new event."
      redirect_to @event
    else
      render :new, status: 422
    end
  end

  def show
    @event = Event.find(params[:id])
  end

  def edit
    @event = Event.find(params[:id])
  end

  def update
    @event = Event.find(params[:id])
    if @event.update_attributes(event_params)
      flash[:success] = "You updated your event."
      redirect_to @event
    else
      render :edit
    end
  end

  def destroy
    Event.find(params[:id]).destroy
    flash[:success] = "You removed your event."
    redirect_to events_path
  end

  private

  def event_params
    params.require(:event).permit(:title, :date, :time, :location, :summary, :tag_list, :image)
  end

  def require_permission
    if current_user != Event.find(params[:id]).owner
      redirect_to root_path
    end
  end

end
