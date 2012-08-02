require 'data_mapper'

# A way to keep a todo list of tasks for the AM Liaison
class Task

  include DataMapper::Resource

  # An auto-increment integer 
  property :id,		    Serial
  property :resource_uuid,  UUID
  property :AM_URN,	    String
  property :AM_URI,	    URI
  # The time that this task should start in "YYYY-MM-DD HH:MM:SS"
  property :date_time,	    DateTime
  # The type of the task (e.g. create, release...)
  property :type,	    String

end
