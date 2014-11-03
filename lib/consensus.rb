#coding: utf-8

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)
  
require 'bundler'
require 'celluloid/io'

module Consensus
  module BaseActors
    def self.included(base)
      base.class_eval %q{
        def state;    Celluloid::Actor[:state];    end
        def election; Celluloid::Actor[:election]; end
        def health;   Celluloid::Actor[:health];   end
        def handler;  Celluloid::Actor[:handler];  end
      }
    end
  end
end

require 'consensus/health_checker'
require 'consensus/election'
require 'consensus/message_handler'
require 'consensus/node'
require 'consensus/base'
require 'consensus/state'