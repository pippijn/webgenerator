jQuery(function ($) {

   function load (href) {
      $('#content').load(href + ".frag #content-frag", function () {
         $('#menubar').load(href + ".frag #menubar-frag", function () {
            $('#updated').load(href + ".frag #updated-frag", function () {
               install();
            });
         });
      });
   }

   function install () {
      $('#menubar a:not(#actmenu)').click(function (event) {
         event.preventDefault();

         var a = $(event.target);
         var href = a.attr('href');

         $.get(href + '.frag')
         .done(function () {
            load(href);
         })
         .fail(function () {
            load(href + '/index');
         });
      });
   }

   install();
});
