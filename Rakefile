task :deploy do
  system "git push heroku master"
end

task :start do
  system "foreman start"
end

task :rescale do
  system "heroku scale web=1"
end

task :test do
  system "bundle exec bacon test/**/*_test.rb"
end

task default: :test