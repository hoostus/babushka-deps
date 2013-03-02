dep 'bitbucket team', :team, :bitbucket_username, :bitbucket_password do
	bitbucket_username.default(ENV['USER'] + '_atlassian')
	bitbucket_password.ask('What is your bitbucket password?')

	require 'net/http'
	require 'json'

	bitbucket_url ='https://api.bitbucket.org/1.0/user/privileges'
	uri = URI(bitbucket_url)
	http = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https')

	met? {
		request = Net::HTTP::Get.new(uri.request_uri)
		request.basic_auth(bitbucket_username, bitbucket_password)
		response = http.request(request)
		teams = JSON.parse(response.body)

		teams.has_key?(team)
	}
end

dep 'bitbucket ssh key', :bitbucket_username, :bitbucket_password, :ssh_key do
	bitbucket_username.default(ENV['USER'] + '_atlassian')
	bitbucket_password.ask('What is your bitbucket password?')
	ssh_key.default('~/.ssh/id_dsa')

	require 'net/http'
	require 'json'

	requires 'public ssh key'.with(ssh_key: ssh_key)

	public_key = ssh_key.p.to_s + '.pub'
	key_value = public_key.p.read.strip

	bitbucket_url ='https://api.bitbucket.org/1.0/users/' + bitbucket_username + '/ssh-keys'
	uri = URI(bitbucket_url)
	http = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https')

	met? {
		request = Net::HTTP::Get.new(uri.request_uri)
		request.basic_auth(bitbucket_username, bitbucket_password)
		response = http.request(request)
		keys = JSON.parse(response.body)

		keys.find { |value|
			value['key'].chomp == key_value
		}
	}

	meet {
		request = Net::HTTP::Post.new(uri.request_uri, inithead = {'Content-Type' => 'application/json'})
		request.basic_auth(bitbucket_username, bitbucket_password)
		request.body = {"key" => key_value, "label" => 'My Atlassian public key'}.to_json

		response = http.request(request)
		log response.message
		response.code == '201'

	}
end
