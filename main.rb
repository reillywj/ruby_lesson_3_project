require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                          :path => '/',
                          :secret => 'my_super_secret_string1988$&**'


get '/' do
  erb :set_name
end

post '/set_name' do
  session[:username] = params[:username]
  session[:bank] = 1000
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/set_current_bet' do
  redirect '/bet' if params[:bet].to_i > session[:bank] || params[:bet].to_i.to_s != params[:bet]
  session[:current_bet] = params[:bet].to_i
  session[:turn] = "User"
  redirect '/game'
end

get '/game' do
  "User Turn" #if session[:turn] == "User"
  # "Something else" if false
  # (session[:turn] == "User").to_s
#   erb :user_turn if session[:turn] == "User"
#   erb :dealer_turn if session[:turn] == "Dealer"
#   redirect '/game_over' if false
end

post '/set_dealer_turn' do
  session[:turn] = "Dealer"
  redirect '/game'
end

post '/finalize_hand' do
  #calculate score
  #calculate if player lost and out of money
  redirect '/hand_over'
end

get '/game_over' do
  erb :game_over
end

get '/bankrupt' do
  erb :bankrupt
end

post '/new_game' do
  session[:bank] = 1000
  redirect '/bet'
end

post '/say_goodbye' do
  redirect :say_goodbye
end

get '/goodbye' do

end







