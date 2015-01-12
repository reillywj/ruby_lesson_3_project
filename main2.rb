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
      @error = "$#{bet} is not a denomination of $#{BET_DENOMINATIONS}."
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
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
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
  #WILL: Fill in this portion when starting here.
  erb :play_game
end











