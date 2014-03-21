require_relative 'icmp'

@icmp = Ping::ICMP.new('192.168.1.101')
repeat = 5
puts 'starting to ping'
(1..repeat).each do

  if @icmp.ping
    puts "host replied in #{@icmp.duration}"
  else
    puts "timeout"
  end
end
