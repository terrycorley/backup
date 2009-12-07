# Gems
require 'net/ssh'
require 'net/scp'
require 'net/ftp'
require 'net/sftp'
require 'aws/s3'

# Environments
require 'backup/environment/base'
require 'backup/environment/unix'
require 'backup/environment/rails'

# Configuration
require 'backup/configuration/base'
require 'backup/configuration/adapter'
require 'backup/configuration/adapter_options'
require 'backup/configuration/storage'
require 'backup/configuration/helpers'

include Backup::Configuration::Helpers
include Backup::Environment::Base

case current_environment
  when :unix  then include Backup::Environment::Unix
  when :rails then include Backup::Environment::Rails
end

if File.exist?(File.join(BACKUP_PATH, 'config', 'backup.rb'))
  require File.join(BACKUP_PATH, 'config', 'backup.rb')
end

# Adapters
require 'backup/adapters/base'
require 'backup/adapters/mysql'
require 'backup/adapters/postgresql'
require 'backup/adapters/archive'
require 'backup/adapters/custom'

# Connectors
require 'backup/connection/s3'

# Storage
require 'backup/storage/s3'
require 'backup/storage/scp'
require 'backup/storage/ftp'
require 'backup/storage/sftp'

# Backup Recorders
require 'backup/record/s3'
require 'backup/record/scp'
require 'backup/record/ftp'
require 'backup/record/sftp'


# Backup Module
module Backup
  class Setup
  
    attr_accessor :trigger, :procedures, :procedure
    
    # Sets the Trigger and All Available Procedures.
    # Will not find a specific procedure if the "trigger" argument is set to false.
    def initialize(trigger, procedures)
      self.trigger    = trigger
      self.procedures = procedures
      self.procedure  = find_triggered_procedure unless trigger.eql?(false)
    end
    
    # Initializes one of the few adapters and start the backup process
    def initialize_adapter
      case procedure.adapter_name.to_sym
        when :mysql       then Backup::Adapters::MySQL.new      trigger, procedure
        when :postgresql  then Backup::Adapters::PostgreSQL.new trigger, procedure
        when :archive     then Backup::Adapters::Archive.new    trigger, procedure
        when :custom      then Backup::Adapters::Custom.new     trigger, procedure
        else raise "Unknown Adapter: \"#{procedure.adapter_name}\"."
      end
    end
  
    # Scans through all the backup settings and returns the backup setting
    # that was specified in the "trigger" argument.
    # If an non-existing trigger is specified, it will raise an error and display
    # all the available triggers.
    def find_triggered_procedure
      procedures.each do |procedure|
        if procedure.trigger.eql?(trigger)
          return procedure
        end
      end
      available_triggers = procedures.each.map {|procedure| "- #{procedure.trigger}\n" }
      raise "Could not find a backup procedure with the trigger \"#{trigger}\". \nHere's a list of available triggers:\n#{available_triggers}"
    end

  end
end