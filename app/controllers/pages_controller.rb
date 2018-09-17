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

			return
		end

		if params[:mode].to_s == "verify"
			@merkle_hash = params["merkle_hash"].to_s
			@audit_proof_merkle = params["merkle_audit_proof"].to_s
			@root_node_merkle = ""

			if (@merkle_hash.to_s != "" && @audit_proof_merkle.to_s != "")
	            node = Digest::SHA256.digest("\0" + @merkle_hash)
	            ap = @audit_proof_merkle.split(", ")
	            ap.each do |item|
	                if item[0] == "+"
	                    item[0] = ""
	                    left_node = [item].pack("H*")
	                    right_node = node
	                else
	                    item[0] = ""
	                    left_node = node
	                    right_node = [item].pack("H*")
	                end
	                node = Digest::SHA256.digest("\x01" + left_node + right_node)
	            end
	            @root_node_merkle = node.unpack('H*')[0]
	        end
		end

	end

	def submit
		hash = params[:hash_field].to_s
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

	def merkle
		@my_hash = params[:hash_field_merkle].to_s
		@my_audit_proof = params[:audit_proof_merkle].to_s
		
		redirect_to root_path(merkle_hash: @my_hash, merkle_audit_proof: @my_audit_proof, mode: "verify")
	end

	def faq
	end

	def favicon
		send_file 'public/favicon.ico', type: 'image/x-icon', disposition: 'inline'
	end
end