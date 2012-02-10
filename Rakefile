desc "Deploy to Heroku"
task :deploy do
  system "git push heroku master"
end

desc "Start webserver"
task :start do
  system "foreman start"
end

task :rescale do
  system "heroku scale web=1"
end

desc "Run tests"
task :test do
  system "bundle exec bacon test/**/*_test.rb"
end

desc "Start the local test database server"
task "database:start" do
  mkdir_p "data/db/"
  system "mongod --dbpath ./data/db/"
end

task default: :test