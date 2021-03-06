
def system!(str)
  raise "Command Failed: #{str}" unless system(str)
end

Given /^the temp directory is clean$/ do
  system!("rm -rf /tmp/lobot-test")
  system!("mkdir -p /tmp/lobot-test")
end

Given /^I am in the temp directory$/ do
  Dir.chdir('/tmp/lobot-test')
end

When /^I create a new Rails project using a Rails template$/ do
  system!("echo -e '\nyes\nno\nno\nno\nno\nno\nno' | rails new testapp -m https://github.com/pivotal/guiderails/raw/master/main.rb")
end

When /^I vendor Lobot$/ do
  lobot_dir = File.expand_path('../../', File.dirname(__FILE__))
  system! "cd #{lobot_dir} && rake build"
  system! "mkdir -p testapp/vendor/cache/"
  system! "cp #{lobot_dir}/pkg/lobot-#{Lobot::VERSION}.gem testapp/vendor/cache/"
end

When /^I put Lobot in the Gemfile$/ do
  lobot_path = File.expand_path('../../', File.dirname(__FILE__))
  system!(%{echo "gem 'lobot'" >> testapp/Gemfile})
end

When /^I run bundle install$/ do
  system("cd testapp && gem uninstall lobot")
  system!("cd testapp && bundle install")
  system!('cd testapp && bundle exec gem list | grep lobot')
end

When /^I run the Lobot generator$/ do
  system!('cd testapp && rails generate lobot:install')
  system!('ls testapp | grep -s soloistrc')
end

When /^I enter my info into the ci\.yml file$/ do
  secrets = YAML.load_file(File.expand_path('../config/secrets.yml', File.dirname(__FILE__)))
  
  ci_conf_location = 'testapp/config/ci.yml'
  ci_yml = YAML.load_file(ci_conf_location)
  ci_yml.merge!(
  'app_name' => 'testapp',
  'app_user' => 'testapp-user',
  'git_location' => 'git@github.com:pivotalprivate/ci-smoke.git',
  'basic_auth' => [{ 'username' => 'testapp', 'password' => 'testpass' }],
  'credentials' => { 'aws_access_key_id' => secrets['aws_access_key_id'], 'aws_secret_access_key' => secrets['aws_secret_access_key'], 'provider' => 'AWS' },
  'ec2_server_access' => {'key_pair_name' => 'lobot_cucumber_key_pair', 'id_rsa_path' => '~/.ssh/id_rsa'},
  'id_rsa_for_github_access' => secrets['id_rsa_for_github_access']
  )
  # ci_yml['server']['name]  = '' # This can be used to merge in a server which is already running if you want to skip the setup steps while iterating on a test
  File.open(ci_conf_location, "w") do |f|
    YAML.dump(ci_yml, f)
  end
end

When /^I push to git$/ do
  system! "echo 'config/ci.yml' >> testapp/.gitignore"
  system! "cd testapp && git add ."
  system! "cd testapp && git commit -m'initial commit'"
  system "cd testapp && git remote rm origin"
  system! "cd testapp && git remote add origin git@github.com:pivotalprivate/ci-smoke.git"
  system! "cd testapp && git push --force -u origin master"
end

When /^I run the server setup$/ do
  system! "cd testapp && rake ci:server_start"
end

When /^I bootstrap$/ do
  server_is_available = false
  iterations = 0
  until server_is_available
    server_is_available = system("cd testapp && cap ci check_for_server_availability")
    puts "Sleeping for 3 seconds"
    sleep 3
    iterations += 1
    raise "server is not available" if iterations > 10
  end
  system! "cd testapp && cap ci bootstrap"
end

When /^I deploy$/ do
  system! "cd testapp && cap ci chef"
end

Then /^CI is green$/ do
  Timeout::timeout(300) do
    until system("cd testapp && rake ci:status")
      sleep 5
    end
  end
end
