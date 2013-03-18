"use strict";
/*jslint browser: true */
/*global $, jQuery, jc_spinner_opts, Spinner */

// crée le spinner lorsque l'on appuie sur le bouton de création d'un organisme
// jc_spinner_opts est défini globalement dans application.js
// tandis que Spinner est défini dans spin.js (plugin de jQuery)
jQuery(function () {
    $('#new_organism input.btn').click(function () {
        var target = document.getElementById('new_organism');
        new Spinner(jc_spinner_opts).spin(target);
    });
});

