#!/usr/bin/env ruby

require 'am_liaison'

HOSTNAME = %x{'hostname'}.chomp

def shutdown(am_liaison, omf_am)
  am_liaison.remove_am(omf_am)
  exit
end

EM.run do
  # create an AM_Liaison
  am_liaison = AMLiaison.new('sqlite:///tmp/am_liaison.db')

  # create an OMF AM
  omf_am = OmfAM.new('omf_am', "xmpp://#{HOSTNAME}:9090")

  # list the AMs of Liaison
  puts "AMs List: #{am_liaison.am_list}"

  # add the OMF AM to the list of the AM Liaison
  am_liaison.add_am(omf_am)

  # create another one OMF AM and add it to the AM Liaison as well
  #omf_am2 = OmfAM.new('boo_AM', "urn:local+boo+AM", 'localhost')
  #am_liaison.add_am(omf_am2)

  # list the AMs of Liaison
  puts "AMs List: #{am_liaison.am_list}"

  # create 2 tasks in am_liaison's database
  uuid = '984265dc-4200-4f02-ae70-fe4f48964159'
  task = am_liaison.add_task(uuid, omf_am, Time.now + 10, 'create') 
  task2 = am_liaison.add_task(uuid, omf_am, Time.now + 15, 'release') 

  # schedule these 2 tasks
  am_liaison.schedule_task(task)
  am_liaison.schedule_task(task2)

  # cancel the 2nd task
  am_liaison.clear_task(task2)

  puts "timers list: #{am_liaison.timers_list}"


  trap(:INT) { shutdown(am_liaison, omf_am) }
  trap(:TERM) { shutdown(am_liaison, omf_am) }
end
