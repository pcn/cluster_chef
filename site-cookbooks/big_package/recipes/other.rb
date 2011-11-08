packages_list = %w[
  ifstat
  iotop
  gt5
  # elinks
]

if node[:lsb][:release].to_f > 9.0
  packages_list += %w[ ec2-api-tools ec2-ami-tools ]
end

# Don't need the below, we have no 9.x installed ubuntu hosts.
# if node[:lsb][:release].to_f > 9.0
#   packages_list += %w[ jardiff ]
# end
if node[:lsb][:release].to_f > 10.0
  packages_list += %w[  ]
end

packages_list.each do |pkg|
  package pkg
end
