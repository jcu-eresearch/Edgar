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

@@species = {}
@@species.extend(MonitorMixin)

SLEEP_TIME = 10


# Request URI for the next job on the queue (what needs to be modelled)
get '/species/next_job/?' do
    content_type 'text/plain'
    @@species.synchronize do
        sub_species = @@species.select { |key, val| val == "NOT_STARTED" }
        if sub_species.empty?
            halt 503, {'Content-Type' => 'text/plain'}, "No species modelling required"
        else
            halt 200, {'Content-Type' => 'text/plain'}, @@species.keys.first
        end
    end
end

# Report status URI for a job.
post '/species/job_status/:species_id/?' do
    content_type 'text/plain'
    species_id = params[:species_id]
    status = params[:status]

    @@species.synchronize do
        if @@species[species_id]
            @@species[species_id] = status
            halt 200, {'Content-Type' => 'text/plain'}, @@species[species_id].inspect
        else
            halt 400, {'Content-Type' => 'text/plain'}, "No such species"
        end
        puts @@species.inspect
    end
end

# Thread to keep increasing the number of species in the queue.
# Generates random 8 character long species_id
Thread.new do
    while true
        @@species.synchronize do
            species_string = (0...8).map{65.+(rand(25)).chr}.join
            @@species[species_string] = "NOT_STARTED"
            puts @@species.inspect
        end
        sleep SLEEP_TIME
    end
end
