require_relative 'class_jobs.rb'

job_inf = Jobs.new("infojobs")
job_fdw = Jobs.new("forosdelweb")

job_inf.new_file("base")
job_fdw.new_file("base")

while true do
	job_inf.new_file("refresh")
	job_fdw.new_file("refresh")

	if !job_inf.compare_files() then
		job_inf.twitter("NEW JOB - @jvlob!")
		job_inf.update_files()
	end

	if !job_fdw.compare_files() then
		job_fdw.twitter("NEW JOB - @jvlob!")
		job_fdw.update_files()
	end

	sleep 30
end