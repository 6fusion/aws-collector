desc 'Demo task'
task :demo do
  puts "Demo task is in progress"
  fail("Die")
end
