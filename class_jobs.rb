require 'net/http'
require 'nokogiri'
require 'fileutils'
require 'twitter'
require_relative 'twitter_config'

class Jobs
	attr_accessor :hash_jobs, :web, :base_file, :refresh_file
 
	def initialize(web)
		@web = web
		@base_file = "base_#{@web}.dat"
		@refresh_file = "refresh_#{@web}.dat"
	end

	def looking_for_jobs()
		@web == "infojobs" ? infojobs() : foros_del_web()
	end

	def new_file(name)
		name == "base" ? filename = @base_file : filename = @refresh_file
		file = File.new("#{filename}", "w")
		file.write(looking_for_jobs())
		file.close
	end

	def twitter(msg)
		Twitter.update("#{msg} - #{hash_jobs[0][:name]} - #{hash_jobs[0][:url]}")
	end

	def compare_files()
		FileUtils.compare_file("#{@base_file}", "#{refresh_file}")
	end

	def update_files()
		FileUtils.copy_file("#{refresh_file}", "#{@base_file}")
	end

	private
		def get(uri)
		  uri = URI.parse("#{uri}")
		  response = Net::HTTP.get_response(uri)
		  if response.code.to_i == 404
		    raise RuntimeError, "The api returned status code #{response.code} for #{uri}"
		  end
		  
		  Nokogiri::HTML(response.body)
		end

		def infojobs()
			jobs = get("https://freelance.infojobs.net/proyectos/informatica").css("ul#resultdata > li")

			hash_jobs = Array.new

			jobs.count.times{ |i|
				jobs_name = jobs[i].css(".name") #seleccionamos los <a href> con la clase "name"
				jobs_list_details = jobs[i].css(".list-details") #seleccionamos el <ul> con la clase "name"

				hash_single_job = Hash.new
				hash_single_job[:name] = jobs_name.css("span").text
				hash_single_job[:url] =  "https://freelance.infojobs.net" + jobs_name[0]["href"]
				hash_single_job[:date] = jobs_list_details.css(".date > span").text

				hash_jobs << hash_single_job
			}

			@hash_jobs = hash_jobs
		end

		def foros_del_web()
			jobs = get("http://www.forosdelweb.com/f65/").css("tbody#threadbits_forum_65 > tr > .tdtitle")

			hash_jobs = Array.new

			jobs.count.times{ |i|
				jobs_name = jobs[i].css("div > a") #seleccionamos los td con la clase "tdtitle"
				
				hash_single_job = Hash.new
				hash_single_job[:name] = jobs_name.text
				hash_single_job[:url] =  jobs_name[0]["href"]

				hash_jobs << hash_single_job
			}

			@hash_jobs = hash_jobs	
		end	
end