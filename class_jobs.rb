require 'net/http'
require 'net/https'
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
        @hash_jobs = Array.new
    end

    def looking_for_jobs()
        @web == "infojobs" ? infojobs() : foros_del_web()
    end

    def new_file(name)
        name == "base" ? filename = @base_file : filename = @refresh_file
        file = File.new("#{filename}", "w")
        file.sync = true #flush buffer automated = http://www.ruby-doc.org/core-2.0.0/IO.html#method-i-sync-3D
        file.write(looking_for_jobs())
        file.close
    end

    def twitter(msg)
        if @hash_jobs.class == Array then
			begin
				client.update("#{msg} - #{@hash_jobs.first[:name]} - #{@hash_jobs.first[:url]}")
			rescue Twitter::Error
				puts "Hey Loser, Twitter says you cannot post same twice"
			rescue Exception
				puts "some other error happened!"
			end 
        end
        #puts "#{msg} - #{hash_jobs.first[:name]} - #{hash_jobs.first[:url]}"
    end

    def compare_files()
        FileUtils.compare_file("#{@base_file}", "#{refresh_file}")
    end

    def update_files()
        FileUtils.copy_file("#{refresh_file}", "#{@base_file}")
    end

    private
        def getFW(uri)
	        uri = URI.parse("#{uri}")

	        begin
                response = Net::HTTP.get_response(uri)
            rescue StandardError
                puts "Network error"
                sleep 60
                retry
            end

            if !response.nil? then 
	           Nokogiri::HTML(response.body)
           end
        end

        def getIJ(uri)
            uri = URI.parse("#{uri}")

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE

            request = Net::HTTP::Get.new(uri.request_uri)

            begin
                response = http.request(request)
            rescue StandardError
                puts "Network error"
                sleep 60
                retry
            end

            if !response.nil? then 
               Nokogiri::HTML(response.body)
           end
        end

        def infojobs()
            jobs = getIJ("https://freelance.infojobs.net/proyectos/informatica").css("ul#resultdata > li")

            @hash_jobs.clear

            jobs.count.times{ |i|
                jobs_name = jobs[i].css(".name") #seleccionamos los <a href> con la clase "name"
                jobs_list_details = jobs[i].css(".list-details") #seleccionamos el <ul> con la clase "name"

                hash_single_job = Hash.new
                hash_single_job[:name] = jobs_name.css("span").text
                hash_single_job[:url] =  "https://freelance.infojobs.net" + jobs_name[0]["href"]
                hash_single_job[:date] = jobs_list_details.css(".date > span").text

                @hash_jobs << hash_single_job
            }
            @hash_jobs
        end

        def foros_del_web()
            jobs = getFW("http://www.forosdelweb.com/f65/").css("tbody#threadbits_forum_65 > tr > .tdtitle")

            @hash_jobs.clear

            jobs.count.times{ |i|
                jobs_name = jobs[i].css("div > a") #seleccionamos los td con la clase "tdtitle"
                
                hash_single_job = Hash.new
                hash_single_job[:name] = jobs_name.text
                hash_single_job[:url] =  jobs_name[0]["href"]

                @hash_jobs << hash_single_job
            }
            @hash_jobs
        end        
end
