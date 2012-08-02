require 'omf_am'
require 'task'
require 'eventmachine'
require 'omf_common'


# This entity is being used for resource allocation.
# It is responsible to contact the AMs through XMPP before a 
# reservation of a resource starts. It sends a command to the 
# AMs to create this resource, in order to be ready for use 
# by the corresponding reservation.
# 
# @attr [Hash<String, AbstractAM>] am_list
# @attr [Hash<Fixnum, EventMachine::Timer>] timers_list
class AMLiaison

  # A list for keeping AMs objects
  @am_list
  
  # A list for keeping the timers for the upcoming tasks
  @timers_list


  # Create the database in order to be ready to serve requests
  #
  # @param [String] database the path to the AM Liaison's database
  def initialize(database)
    # TODO: load configuration from YAML file

    @am_list ||= {}
    @timers_list ||= {}

    initialize_database(database)
  end

  # returns the list with the available AMs
  #
  # @return [Hash<String, AbstractAM>]
  def am_list
    @am_list
  end

  # add an AM to the AMs list
  #
  # @param [AbstractAM] am The reference to the AM object
  def add_am(am)
    @am_list[am.urn] = am
  end
  
  # get the list with the timers of the future tasks
  #
  # @return [Hash<Fixnum, EventMachine::Timer>]
  def timers_list
    @timers_list
  end

  # add a timer for a future task
  #
  # @param [Fixnum] id The task's unique id for distinguishing the timers. 
  # @param [EventMachine::Timer] timer The reference to the task's timer
  def add_timer(id, timer)
    @timers_list[id] = timer
  end

  # release an AM by disconnecting from it and
  # removing its reference
  #
  # @param [AbstractAM] am The reference to the AM object
  def remove_am(am)
    @am_list[am.urn].disconnect
    @am_list.delete(am.urn)
  end

  # cancel the timer and remove its reference from the timers_list 
  # and the task from the database
  #
  # @param [Task] task The reference to the task object
  def clear_task(task)
    @timers_list[task.id].cancel
    @timers_list.delete(task.id)
    logger.debug "#{task} cancelled!"
    raise "Error while deleting task: #{task}" unless task.destroy
  rescue => ex
    logger.error ex.message
    logger.error ex.backtrace.join("\n")
  end

  # create a timer that will be fired in a specified time in the future
  #
  # @param (see #clear_task)
  def schedule_task(task)
    # convert DateTime to Time
    task_time = task.date_time.to_time
    logger.debug "Creating a new timer for #{task} at #{task_time}"

    raise "I can't travel in the past!" unless task_time >= Time.now

    timer = EventMachine::Timer.new(task_time - Time.now) do
      do_task(task)
      logger.debug "I am running a scheduled task for #{task_time}"
      clear_task(task)
      logger.debug "timers: #{@timers_list.inspect}"
    end

    id = task.id
    add_timer(id, timer)
  rescue => ex
    logger.error ex.message
    logger.error ex.backtrace.join("\n")
  end
  
  # Add a task to the database table
  #
  # @param [UUID] res_uuid The resource's uuid
  # @param [AbstractAM] am The reference to the AM
  # @param [DateTime] date_time The day and time that this task should be start
  # @param [String] type The type of the task
  #
  # @return [Task]
  def add_task(res_uuid, am, date_time, type)
    @task = Task.create(:resource_uuid => res_uuid,
			:AM_URN => am.urn,
			:AM_URI => am.uri,
			:date_time => date_time,
			:type => type)
    raise "failed to save the task: #{@task.inspect}" unless @task.saved?
    @task
  rescue => ex
    logger.error ex.message
    logger.error ex.backtrace.join("\n")
  end

  # Execute the task by sending the corresponding message to the AM
  #
  # @param (see #clear_task)
  def do_task(task)
    case task.type
    when 'create'
     logger.info "create message to #{task.AM_URN}" 
     @am_list[task.AM_URN].create_resource(task.resource_uuid)
    when 'release' then logger.info 'release message'
    end
  end

  # Database related stuff
  #
  # @param [String] database The path to the database
  def initialize_database(database)

    DataMapper.setup(:default, database)
    DataMapper.finalize

    # Deletes any previous records in the database
    DataMapper.auto_migrate!
    # Doesn't omit the data of the tables
    #DataMapper.auto_upgrade!
  end

end
