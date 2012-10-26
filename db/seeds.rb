# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# Seed Data for the Roles table

#Role data
#Clear existing data
Role.delete_all
#Re-seed the data
["contentAccessTeam", "staff", "student", "committeeSection", "engineering", "guest", "admin"].each {|r| Role.create(:name => r, :description => r) } 
