require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                          :path => '/',
                          :secret => 'my_super_secret_string1988$&**'

BLACKJACK = 21
DEALER_MIN = 17

helpers do
  def calculate_total(cards)
    total = 0
    aces = 0
    cards.each do |card|
      if card[1] == 'ace'
        aces += 1
      elsif card[1].to_i == 0
        total += 10
      else
        total += card[1].to_i
      end#if
    end#do

    if aces > 0
      for i in 1..aces do
        if total + (11 * (aces - i +1)) > BLACKJACK
          total += 1
        else
          total += 11
        end#if
      end#for
    end#if
      total
  end#def calculate_total

  def card_image(card)
    suit = card[0]
    value = card[1]
    "<img src='/images/cards/#{suit}_#{value}.jpg' alt='#{value} of #{suit}' class='card_image'/>"
  end

  def winner!(msg)
    session[:bank] += session[:current_bet] * 2
    @success = "#{session[:username]}, you win! #{msg}"
  end

  def tie!
    session[:bank] += session[:current_bet] #return bet back to player
    @success = "It's a tie! #{calculate_total session[:player_cards]} to #{calculate_total session[:dealer_cards]}."
  end

  def loser!(msg)
    #bet was removed at the beginning of the hand
    @error = "Dealer wins! #{msg}"
  end
end#do helper

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

post '/bet' do
  bet                     = params[:bet].to_i
  session[:current_bet]   = bet.to_i
  redirect '/bet'         if bet > session[:bank] || bet <= 0
  session[:bank]         -= session[:current_bet]
  session[:turn]          = "player_turn" #initialize player's turn
  session[:player_status] = "hit" #initialize hit status; gives player option to hit or stay
  session[:winner]        = false
  #Setup Deck
  suits = ['hearts', 'diamonds', 'clubs', 'spades']
  values = ['2','3','4','5','6','7','8','9','10','jack','queen','king','ace']
  session[:deck] = suits.product(values).shuffle!
  #Deal Cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  #Calculate current score
  session[:dealer_score]  = calculate_total session[:dealer_cards] #Calculate score
  session[:player_score]  = calculate_total session[:player_cards]#Calculate score
  if session[:player_score] == BLACKJACK
    redirect '/end_hand'
  else
    redirect '/play_game'
  end
end

get '/play_game' do
  erb :play_game
end

post '/deal_to_player' do
  #deal card to player
  session[:player_cards] << session[:deck].pop
  session[:player_score] = calculate_total session[:player_cards] #calculate player score
  if    session[:player_score] == BLACKJACK
    redirect '/end_hand'
  elsif session[:player_score] < BLACKJACK
    redirect '/play_game'
  else #Over BLACKJACK amount
    redirect '/end_hand'
  end

end

post '/deal_to_dealer' do
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_score] = calculate_total session[:dealer_cards]
  if session[:dealer_score] < DEALER_MIN
    redirect '/play_game'
  else
    redirect '/end_hand'
  end
end

post '/player_stay' do
  session[:player_status] = "stay"
  if session[:dealer_score] < DEALER_MIN
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
    winner! "BLACKJACK! Automatic win."
    # session[:bank]   += session[:current_bet] * 2
    # session[:winner]  = "#{session[:username]}, you hit BLACKJACK!!! You automatically win!"
  elsif score1 >  21
    loser! "You busted with #{calculate_total session[:player_cards]}."
    # session[:winner]  = "Dealer wins; you busted with #{session[:player_score]}"
  elsif (score2<=21 && score1 < score2)
    loser! "#{calculate_total session[:dealer_cards]} to #{calculate_total session[:player_cards]}."
    # session[:winner]  = "Dealer wins #{session[:dealer_score]} to #{session[:player_score]}"
  elsif score2 >  21 || (score1 > score2)
    winner! "#{calculate_total session[:player_cards]} to #{calculate_total session[:dealer_cards]}"
    # session[:bank]   += session[:current_bet] * 2
    # session[:winner]  = "#{session[:username]}, you win!!! #{session[:player_score]} to {session[:dealer_score]}."
  elsif score1 == score2
    tie!
    # session[:winner]  = "It's a tie: #{session[:dealer_score]} to #{session[:player_score]}"
    # session[:bank] += session[:current_bet] #give player money back
  else
    @info = "Cannot determine winner. Conditions to win are broken."
    # session[:winner]  = "Check winning conditions in end_hand get method."
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





