# app/controllers/events_controller.rb
class EventsController < ApplicationController
  before_action :authenticate_user!, only: [:going, :my_events]

  def index
    @events = Event.all
    if params[:query].present?
      query = "%#{params[:query]}%"
      @events = @events.joins(:user).where(
        "events.title ILIKE :query OR users.first_name ILIKE :query OR users.last_name ILIKE :query",
        query: query
      )
    end
  end

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    @event.user = current_user

    if @event.save
      if current_user.events.count >= 1
        current_user.award_badge('First Event Create')
        current_user.check_winter_survival_badge
        flash[:notice] = "Congratulations! You've received the 'Event Create' badge."
      elsif current_user.badges.where(name: ['First Article', 'Attend Your First Event', 'First Event Create']).count >= 3
        flash[:notice] = "Congratulations! You've also received the 'Survive Your First Winter' badge."
      end
      redirect_to events_path, notice: "Event created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def going
    @event = Event.find(params[:id])
    unless current_user.events.include?(@event)
      current_user.events << @event
      if current_user.events.count >= 1
        current_user.award_badge('Attend Your First Event')
        current_user.check_winter_survival_badge
      end
    end
    redirect_to my_events_path
  end

  def my_events
    @events = current_user.events
  end

  private

  def event_params
    params.require(:event).permit(:title, :description, :location, :event_date, :number_of_people, images: [])
  end
end
