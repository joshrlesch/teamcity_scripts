require 'teamcity'
require 'json'
require 'date'
require 'command_line_reporter'
require 'time_difference'
require 'io/console'

class BuildDuration
	include CommandLineReporter

	def initialize
		self.formatter = 'progress'
	end

	def run
		secret = File.read('secret.json')
		secret_hash = JSON.parse(secret)

		def get_password(prompt="Password: ")
				print prompt
				STDIN.noecho(&:gets).chomp
		end

		TeamCity.configure do |config|
			config.endpoint = "#{secret_hash['teamcity_url']}/httpAuth/app/rest"
			config.http_user = secret_hash['username']
			if secret_hash.has_key?("password")
				config.http_password = secret_hash['password']
			else
				config.http_password = get_password("Enter your TeamCity Password: ")
			end
		end

		build_configs = secret_hash['build_configs']
		today = DateTime.now
		week_ago = today - 7

	  report do
		header :title => 'Gathering the average build times per app, this takes a couple minutes'
		table :border => true do
			  row :header => true, :color => 'red'  do
			    column 'BUILD CONFIG', :width => 30, :align => 'center'
			    column 'BUILD DURATION', :width => 30, :padding => 5
				column 'TIME IN QUEUE', :width => 30, :padding => 5
			  end

			  for build_config in build_configs
				vertical_spacing
				aligned("App Build Config: #{build_config}")

					build_duration = Array.new
					time_in_queue = Array.new

					# Get all build ids in the last 7 days for specific build config
					builds = TeamCity.builds(buildType: build_config, branch: 'unspecified:any', status: 'success')
					builds.each do |build|
						stats = TeamCity.build_statistics(build.id)
						stats.each do |stat|
							if stat.name.eql? "BuildDurationNetTime"
								build_duration.push(stat.value.to_i)
							end
							if stat.name.eql? "TimeSpentInQueue"
								time_in_queue.push(stat.value.to_i)
							end
						end

						progress
					end

					if not build_duration.empty?
						build_average_sec = (build_duration.sum.to_f / build_duration.size) / 1000
						build_duration = Time.at(build_average_sec).utc.strftime("%Hh:%Mm:%Ss")
					else
						build_duration = 'N/A'
					end

					if not time_in_queue.empty?
						queue_average_sec = (time_in_queue.sum.to_f / time_in_queue.size) / 1000
						queue_duration =  Time.at(queue_average_sec).utc.strftime("%Hh:%Mm:%Ss")
					else
						queue_duration = 'N/A'
					end
				
					row do
						column build_config
						column build_duration
						column queue_duration
					end

				end
				vertical_spacing
			end
		end
	end
end

BuildDuration.new.run

# 			Get stats for each build instead of calculating them.
#       This gets net time which doesn't include checkout/artifact upload
#       for id in build_ids
# 				stats = TeamCity.build_statistics(id)
# 				stats.each do |stat|
# 					if stat.name.eql? "BuildDurationNetTime"
# 						build_duration.push(stat.value.to_i)
# 					end
# 				end
# 				progress
# 			end
