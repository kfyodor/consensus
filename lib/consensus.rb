#coding: utf-8

lib = File.dirname(__FILE__)
$:.unshift lib unless $:.include?(lib)

require 'consensus/node'
require 'consensus/base'
require 'consensus/cluster'

module Consensus
end