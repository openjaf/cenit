/**
 * Created by dhbahr on 5/10/16.
 * = require jquery
 */

$(function(){
    $(".soc-btn").on("click", function(ev){
        $(this).addClass("selected");
        $(this).siblings().addClass("unused");

        var parent = $(this).parent().parent().parent();
        console.log($(parent));

        var forms = $(parent).find('form');
        $(forms).each(function() {
            $(this).find("input, button")
                .prop("disabled", true);
        });

        var links = $(parent).find('a');
        console.log($(links));
        $(links).each(function(){
            $(this).on('click', function(ev){
                ev.preventDefault();
            });
        });
    });
});