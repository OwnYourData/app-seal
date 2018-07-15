class PagesController < ApplicationController
	include ApplicationHelper

	def index
		@show_response = false
		if !params[:hash].nil?
			@show_response = true
			@hash =        params[:hash].to_s
			if DateTime.now.utc.hour > 5
				my_time = DateTime.now.utc.end_of_day + 6.hours
			else
				my_time = DateTime.now.utc.beginning_of_day + 6.hours
			end
			@wait = (my_time.utc.to_i - Time.now.utc.to_i)/3600
			
			api_url = "https://blockchain.ownyourdata.eu/api/doc"
			response = HTTParty.post(api_url,
		        headers: { 'Content-Type' => 'application/json' },
		        body: { hash: params[:hash] }.to_json ).parsed_response
			@id =          response["id"]
			@address =     response["address"]
			@root_node =   response["root-node"]
			@audit_proof = response["audit-proof"]
			@ether_ts =    response["ether-timestamp"]
			@oyd_ts =      response["oyd-timestamp"]
		end

	end

	def submit
		hash = params[:hash_field].to_s
		puts "hash: " + hash.to_s
		api_url = "https://blockchain.ownyourdata.eu/api/doc"
		response = HTTParty.post(api_url,
            headers: { 'Content-Type' => 'application/json' },
            body: { hash: hash }.to_json )
		if response.code.to_s == "200"
			flash[:success] = t('general.success')
		else
			flash[:warning] = t('general.hash_error')
		end
		if params[:mode].to_s == "advanced"
			redirect_to root_path(hash: hash, mode: "advanced")
		else
			redirect_to root_path(hash: hash)
		end
	end

	def faq
	end

	def favicon
		send_file 'public/favicon.ico', type: 'image/x-icon', disposition: 'inline'
	end
end