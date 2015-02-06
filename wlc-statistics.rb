#!/usr/bin/ruby

require 'snmp'
require 'pp'

client_base_id = "1.3.6.1.4.1.14179.2.1.4.1"
bsnMobileStationMacAddress = "1.3.6.1.4.1.14179.2.1.4.1.1"

ap_base_id = "1.3.6.1.4.1.14179.2.2.1.1"
bsnAPDot3MacAddress = "1.3.6.1.4.1.14179.2.2.1.1.1"
bsnMobileStationAPMacAddr = "1.3.6.1.4.1.14179.2.1.4.1.4"

clients = {}

protocol = {
1 =>"dot11a",
2 =>"dot11b",
3 =>"dot11g",
4 =>"unknown",
5 =>"mobile",
6 =>"dot11n24",
7 =>"dot11n5",
}

aps = {}

SNMP::Manager.open(:Host => ARGV[0], :Version => :SNMPv2c, :Community => 'public') do |manager|

	manager.walk(bsnAPDot3MacAddress) do |i|
		mac = ""
		i.value.encode.to_s.byteslice(2,10).each_char do |c|
			mac += c.ord.to_s(16) + ":"
		end
		mac = mac[0,mac.length-1]
		client_id = i.name.to_str[bsnAPDot3MacAddress.length + 1, 1024]

		aps[mac] = {
			:mac => mac,
			:bsnAPName => manager.get_value(["1.3.6.1.4.1.14179.2.2.1.1.3" + "." + client_id]).first.to_s,
			:bsnAPModel => manager.get_value(["1.3.6.1.4.1.14179.2.2.1.1.22" + "." + client_id]).first.to_s,
		}

		#pp aps[mac]
	end

	manager.walk(bsnMobileStationMacAddress) do |i|
		mac = ""
		i.value.encode.to_s.byteslice(2,10).each_char do |c|
			mac += c.ord.to_s(16) + ":"
		end
		mac = mac[0,mac.length-1]
		client_id = i.name.to_str[bsnMobileStationMacAddress.length + 1, 1024] 

		apmac = ""
		manager.get_value(["1.3.6.1.4.1.14179.2.1.4.1.4" + "." + client_id]).first.encode.to_s.byteslice(2,10).each_char do |c|
			apmac += c.ord.to_s(16) + ":"
		end
		apmac = apmac[0,apmac.length-1]

                clients[mac] = {
                        :mac => mac,
			:bsnMobileStationSsid => manager.get_value(["1.3.6.1.4.1.14179.2.1.4.1.7" + "." + client_id]).first.to_s,
			:bsnMobileStationIpAddress => manager.get_value(["1.3.6.1.4.1.14179.2.1.4.1.2" + "." + client_id]).first.to_s,
			:bsnMobileStationRSSI => manager.get_value(["1.3.6.1.4.1.14179.2.1.6.1.1" + "." + client_id]).first.to_s,
                        :bsnMobileStationSNR => manager.get_value(["1.3.6.1.4.1.14179.2.1.6.1.26" + "." + client_id]).first.to_s,
			:bsnMobileStationProtocol => manager.get_value(["1.3.6.1.4.1.14179.2.1.4.1.25" + "." + client_id]).first.to_i,
			:bsnMobileStationAPMacAddr => apmac, 
                }
		#pp clients[mac]
	end	

end

format = "%-20s %-15s %-18s %-10s %-10s %-10s\n"
i = 0
clients.each do |mac, data|
	if i % 40 == 0
		printf(format, "CLIENT MAC", "SSID", "IP", "RSSI", "SNR", "ACCESS POINT")
	end
	i = i + 1
	ap = aps[data[:bsnMobileStationAPMacAddr]]
	printf(format, mac, data[:bsnMobileStationSsid], data[:bsnMobileStationIpAddress], data[:bsnMobileStationRSSI], data[:bsnMobileStationSNR], ap[:bsnAPName])
end


