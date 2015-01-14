$(document).ready(function(){
  $(document).on('click','#hit_form input', function(){


    //simulate submission of form by using ajax
    $.ajax({
      type: 'POST',
      url: '/game/player_turn'
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });


    return false //don't want the execution to continue
  });

});