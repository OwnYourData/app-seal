class PagesController < ApplicationController
	include ApplicationHelper
	
	require 'open3'
	
	def index
		@show_response = false
		@verify_only = false
		if !params[:hash].nil?
			@show_response = true
			@hash = params[:hash].to_s.strip
			if DateTime.now.utc.hour > 5
				my_time = DateTime.now.utc.end_of_day + 6.hours
			else
				my_time = DateTime.now.utc.beginning_of_day + 6.hours
			end
			@wait = (my_time.utc.to_i - Time.now.utc.to_i)/3600
			
			api_url = "https://blockchain.ownyourdata.eu/api/doc"
			timeout = false
			begin
				if params[:operation].to_s == "verify"
					response = HTTParty.post(api_url,
						timeout: 25,
				        headers: { 'Content-Type' => 'application/json' },
				        body: { hash: @hash,
				        		mode: "verify" }.to_json ).parsed_response
				else
					response = HTTParty.post(api_url,
						timeout: 25,
				        headers: { 'Content-Type' => 'application/json' },
				        body: { hash: @hash }.to_json ).parsed_response
				end
			rescue
				timeout = true
			end
			if timeout
				flash[:warning] = t('general.service_unavailable')

			else
				if response["status"] == "unknown"
					@verify_only = true
					return
				else
					@id =          response["id"].to_s
					@address =     response["address"].to_s
					@root_node =   response["root-node"].to_s
					@audit_proof = response["audit-proof"].to_s
					@ether_ts =    response["ether-timestamp"].to_s
					@oyd_ts =      response["oyd-timestamp"].to_s
					@tsr_ts =      response["tsr-timestamp"].to_s
					@tsr =         response["tsr"].to_s
				end
			end
		end

		if params[:mode].to_s == "verify"
			@merkle_hash = params["merkle_hash"].to_s.strip
			@audit_proof_merkle = params["merkle_audit_proof"].to_s
			@root_node_merkle = ""

			if (@merkle_hash != "" && @audit_proof_merkle.to_s != "")
	            node = Digest::SHA256.digest("\0" + @merkle_hash)
	            ap = @audit_proof_merkle.split(", ")
	            ap.each do |item|
	            	item = item.strip
	                if item[0] == "+"
	                    item[0] = ""
	                    left_node = [item.strip].pack("H*")
	                    right_node = node
	                else
	                    item[0] = ""
	                    left_node = node
	                    right_node = [item.strip].pack("H*")
	                end
	                node = Digest::SHA256.digest("\x01" + left_node + right_node)
	            end
	            @root_node_merkle = node.unpack('H*')[0]
	        end
		end

	end

	def submit
		hash = params[:hash_field].to_s.strip
		if hash == ""
			hash = params[:hash_advanced].to_s.strip
		end
		if hash != ""
			api_url = "https://blockchain.ownyourdata.eu/api/doc"
			response = HTTParty.post(api_url,
				timeout: 25,
	            headers: { 'Content-Type' => 'application/json' },
	            body: { hash: hash,
	                    mode: params[:api_mode] }.to_json )
			if response.code.to_s == "200"
				if response.parsed_response["status"].to_s == "unknown"
					flash[:success] = t('general.verification_success')
				else
					if params[:mode].to_s == "advanced"
						flash[:success] = t('general.success')
					else
						flash[:success] = t('general.success_basic')
					end
				end
			else
				flash[:warning] = t('general.hash_error')
			end
			if params[:mode].to_s == "advanced"
				redirect_to root_path(hash: hash, mode: "advanced", operation: params[:api_mode])
			else
				redirect_to root_path(hash: hash)
			end
		else
			if params[:mode].to_s == "advanced"
				redirect_to root_path(mode: "advanced")
			else
				redirect_to root_path
			end
		end
	end

	def merkle
		@my_hash = params[:hash_field_merkle].to_s.strip
		@my_audit_proof = params[:audit_proof_merkle].to_s
		
		redirect_to root_path(merkle_hash: @my_hash, merkle_audit_proof: @my_audit_proof, mode: "verify")
	end

	def faq
	end

	def tsr
		hash = params[:hash].to_s.strip
		if hash != ""
			api_url = "https://blockchain.ownyourdata.eu/api/doc"
			response = HTTParty.post(api_url,
				timeout: 25,
	            headers: { 'Content-Type' => 'application/json' },
	            body: { hash: hash,
	                    mode: params[:api_mode] }.to_json )
			if response.code.to_s == "200"
				data = Base64.decode64(response.parsed_response["tsr"].to_s)
				file = "file.tsr"
				File.open(file, "wb"){ |f| f << data }
				send_file( file )
			else
				redirect_to root_path(hash: hash)
			end
		else
			redirect_to root_path(hash: hash)
		end
	end

	def read_tsr
		hash = params[:hash].to_s.strip
		if hash != ""
			api_url = "https://blockchain.ownyourdata.eu/api/doc"
			response = HTTParty.post(api_url,
				timeout: 25,
	            headers: { 'Content-Type' => 'application/json' },
	            body: { hash: hash,
	                    mode: params[:api_mode] }.to_json )
			if response.code.to_s == "200"
				out, err, status = Open3.capture3("bash", "-c", 
                    'openssl ts -reply -in <(echo -n "' + response.parsed_response["tsr"].to_s + '" | base64 --decode) -text')
				render plain: out.to_s,
					   status: 200
			else
				redirect_to root_path(hash: hash)
			end
		else
			redirect_to root_path(hash: hash)
		end
	end

	def favicon
		send_file 'public/favicon.ico', type: 'image/x-icon', disposition: 'inline'
	end
end