Rails.application.routes.draw do
	scope "(:locale)", :locale => /en|de/ do
		root  'pages#index'
		get   'favicon',    to: 'pages#favicon'
		match '/submit',    to: 'pages#submit', via: 'post'
		match '/merkle',    to: 'pages#merkle', via: 'post'
		match 'faq',        to: 'pages#faq',    via: 'get'
		match 'tsr',        to: 'pages#tsr',    via: 'get'
	end
end
