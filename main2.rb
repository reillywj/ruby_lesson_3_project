require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                          :path => '/',
                          :secret => 'my_super_secret_string1988$&**'

BLACKJACK = 21
DEALER_MIN = 17
INITIAL_BANK = 1000
BET_DENOMINATIONS = 10
MINIMUM_BET = BET_DENOMINATIONS

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

  def winner!(msg = "")
    session[:bank] += session[:current_bet]
    @success = "You won! #{msg} #{tell_bank}"
    hand_over
  end

  def tie!
    session[:bank] += 0 #return bet back to player
    @success = "It's a tie! #{calculate_total session[:player_cards]} to #{calculate_total session[:dealer_cards]}. You still have $#{session[:bank]} to play with."
    hand_over
  end

  def loser!(msg = "")
    #bet was removed at the beginning of the hand
    session[:bank] -= session[:current_bet]
    @error = "Dealer wins! #{msg} #{tell_bank}"
    hand_over
  end

  def tell_bank
    if session[:bank] <= 0
      tell_bankrupt
    else
    "#{session[:username]}, you have $#{session[:bank]} in the bank." if session[:bank] > 0
    end
  end

  def tell_bankrupt
    "#{session[:username]}, you are out of money!!!"
  end

  def hand_over
    session[:turn] = "hand_over"
    session[:current_bet] = 0
  end

  def reset_bank
    session[:bank] = INITIAL_BANK
  end

  def initialize_bet
    session[:current_bet] = MINIMUM_BET
  end

  def good_bet?(bet)
    bank = session[:bank]
    if bet.to_i.to_s != bet
      @error = "#{bet} is an invalid entry."
    elsif bet.to_i > bank
      @error = "You bet of $#{bet} is more than you have in the bank --- $#{bank}."
      false
    elsif bet.to_i % BET_DENOMINATIONS != 0
      @error = "$#{bet} is not a multiple of $#{BET_DENOMINATIONS}."
      false
    elsif bet.to_i <= 0
      @error = "Bet must be greater than $0."
      false
    else
      @success = "You bet $#{bet}."
      true
    end
  end

  def give_bet_info
    @info = "You have $#{session[:bank]}. Your bet must be in $#{BET_DENOMINATIONS} denominations, such as $#{BET_DENOMINATIONS * 7}."
  end

  def info_hit_stay
    @info = "#{session[:username]}, do you want to hit or stay?" unless calculate_total(session[:player_cards]) > 21
  end

  def deal_to(player_cards)
    session[player_cards] << session[:deck].pop
  end

  def initialize_game
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
    deal_to :player_cards
    deal_to :dealer_cards
    deal_to :player_cards
    deal_to :dealer_cards
    info_hit_stay if calculate_total(session[:player_cards]) < BLACKJACK
  end

  def tell_card_dealt(card)
    "#{card[1].capitalize} of #{card[0].capitalize} was dealt."
  end
end#do helper


get '/' do
  erb :set_name
end

post '/set_name' do
  session[:username] = params[:username]
  reset_bank
  redirect :bet
end

post '/named' do
  reset_bank
  redirect :bet
end

post '/reset_name' do
  session[:username] = nil
  redirect '/'
end

get '/bet' do
  initialize_bet
  give_bet_info
  erb :bet
end

post '/bet' do
  bet = params[:bet]
  if good_bet?(bet)
    session[:current_bet] = bet.to_i
    redirect '/game'
  else
    give_bet_info
    erb :bet
  end
end

get '/game' do
  initialize_game
  if calculate_total(session[:player_cards]) == BLACKJACK
    winner! "BLACKJACK!"
  end
  erb :play_game
end

post '/game/player_turn' do
  deal_to :player_cards if session[:turn] == "player_turn"
  total = calculate_total session[:player_cards]
  if total < BLACKJACK
    @info = "#{tell_card_dealt(session[:player_cards].last)} "
  elsif total == BLACKJACK
    winner! "BLACKJACK!"
  else
    loser! "You busted."
  end

  erb :play_game
end

post '/game/dealer_turn' do
  session[:player_status] = "stay"
  
  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])
  if dealer_total < DEALER_MIN && session[:turn] == "dealer_turn"
    deal_to :dealer_cards
    @info = tell_card_dealt(session[:dealer_cards].last)
  end
  session[:turn] = "dealer_turn" if session[:turn] = "player_turn"
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total < DEALER_MIN
    @info = "#{tell_card_dealt(session[:dealer_cards].last)} Total is still less than #{DEALER_MIN}, deal another card to dealer."
  elsif dealer_total > BLACKJACK
    winner!("Dealer busted.")
  elsif dealer_total == player_total
    tie!
  elsif dealer_total > player_total
    loser!
  else
    winner!
  end

  erb :play_game
end

post '/play_again' do
  redirect '/bet'
end

post '/gameover' do
  erb :gameover
end

post '/play_new_game' do
  redirect '/'
end











