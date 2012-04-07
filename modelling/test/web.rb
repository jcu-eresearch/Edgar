#!/usr/bin/ruby

# Author: Robert Pyke
#
# Test file
#
# This sinatra app is a mock-up of our HPC modelling API.
#
# It allows for early testing of the HPC scripts in a controlled
# environment.

require 'rubygems'
require 'sinatra'
require 'thread'
require 'monitor'

@@species = Queue.new
@@species.extend(MonitorMixin)

SLEEP_TIME = 10


# Request URI for the next job on the queue (what needs to be modelled)
get '/species/next_job' do
    content_type 'text/plain'
    @@species.synchronize do
        if @@species.empty?
            halt 503, {'Content-Type' => 'text/plain'}, "No species modelling required"
        else
            halt 200, {'Content-Type' => 'text/plain'}, @@species.pop()
        end
    end
end

# Thread to keep increasing the number of species in the queue.
# Generates random 8 character long species_id
Thread.new do
    while true
        @@species.synchronize do
            species_string = (0...8).map{65.+(rand(25)).chr}.join
            @@species.push(species_string)
        end
        sleep SLEEP_TIME
    end
end
