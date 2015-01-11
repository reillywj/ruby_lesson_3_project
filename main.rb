require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                          :path => '/',
                          :secret => 'my_super_secret_string1988$&**'


get '/' do
    redirect '/set_name'
end

get '/set_name' do
  erb :set_name
end

post '/reset_name' do
  session[:username] = nil
  redirect '/set_name'
end

post '/set_name' do
  session[:username] = params[:username]
  redirect '/named'
end

post '/named' do
  session[:bank]        = 1000
  session[:current_bet] = 5
  redirect '/bet'
end

get '/named' do
  session[:bank]        = 1000
  session[:current_bet] = 5
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/set_current_bet' do
  bet                     = params[:bet].to_i
  session[:current_bet]   = bet.to_i
  redirect '/bet'         if bet > session[:bank] || bet <= 0
  session[:bank]         -= session[:current_bet]
  session[:turn]          = "player_turn" #initialize player's turn
  session[:player_status] = "hit" #initialize hit status; gives player option to hit or stay
  session[:winner]        = false
  #Will deal cards here
  session[:dealer_score]  = rand(17) + 4 #Calculate score
  session[:player_score]  = rand(17) + 4 #Calculate score
  redirect '/play_game'
end

get '/play_game' do
  erb :play_game
end

post '/deal_to_player' do
  #deal card to player
  session[:player_score] += rand(10) + 1 #calculate player score
  if    session[:player_score] == 21
    redirect '/end_hand'
  elsif session[:player_score] <= 21
    redirect '/play_game'
  else
    redirect '/end_hand'
  end

end

post '/deal_to_dealer' do
  session[:dealer_score] += rand(10) + 1
  if session[:dealer_score] < 17
    redirect '/play_game'
  else
    redirect '/end_hand'
  end
end

post '/player_stay' do
  session[:player_status] = "stay"
  if session[:dealer_score] < 17
    session[:turn] = "dealer_turn"
    redirect 'play_game'
  else
    redirect '/end_hand'
  end
end

get '/end_hand' do
  score1          = session[:player_score]
  score2          = session[:dealer_score]
  session[:turn]  = "hand_over"
  if    score1 == 21
    session[:bank]   += session[:current_bet] * 2
    session[:winner]  = "#{session[:username]}, you hit BLACKJACK!!! You win automatically!"
  elsif score1 >  21
    session[:winner]  = "Dealer wins; you busted with #{session[:player_score]}"
  elsif (score2<=21 && score1 < score2)
    session[:winner]  = "Dealer wins #{session[:dealer_score]} to #{session[:player_score]}"
  elsif score2 >  21 || (score1 > score2)
    session[:bank]   += session[:current_bet] * 2
    session[:winner]  = "#{session[:username]}, you win!!! #{session[:player_score]} to #{session[:dealer_score]}."
  elsif score1 == score2
    session[:winner]  = "It's a tie: #{session[:dealer_score]} to #{session[:player_score]}"
    session[:bank] += session[:current_bet] #give player money back
  else
    session[:winner]  = "Check winning conditions in end_hand get method."
  end

  session[:current_bet] = 0
  redirect '/play_game'
end

post '/play_new_game' do
  redirect '/named'
end

post '/play_again' do
  session[:current_bet] = 5
  redirect '/bet'
end

post '/end_game' do
  redirect '/gameover'
end

get '/gameover' do 
  erb :gameover
end

post '/go_to_google' do
  redirect 'https://www.google.com'
end





