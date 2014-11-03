#coding: utf-8

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)
  
require 'bundler'
require 'celluloid/io'

require 'consensus/health_checker'
require 'consensus/election'
require 'consensus/message_handler'
require 'consensus/node'
require 'consensus/base'
require 'consensus/state'

module Consensus
end