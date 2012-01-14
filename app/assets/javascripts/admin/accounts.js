// mise en forme des tables de lignes
jQuery(function() {
    if ($('.accounts .data_table').length != 0) {
        var oTable= $('.accounts .data_table').dataTable(
        {
            "oLanguage": {
                "sUrl": "/frenchdatatable.txt"
            },
 "aoColumns": [
            { "sType": "string" },
            null,
            null,
           {"bSortable": false}
            ]

        });
        
        var nCells=$('tbody tr:nth-child(1) td').length;
        $('td', oTable.fnGetNodes()).hover( function() {

            var iCol = $('td', this.parentNode).index(this) % nCells;
            var nTrs = oTable.fnGetNodes();
            $('td:nth-child('+(iCol+1)+')', nTrs).addClass( 'highlighted' );
        }, function() {
            $('td.highlighted', oTable.fnGetNodes()).removeClass('highlighted');
        } );
    }
});

// fonction permettant de selectionner les classes 6 ou 7 selon le type de nature choisi
//
//
// fonction qui permet de déselctionner les classe 6
//function toggle_classe(classe, aff){
//    // on trouve les id des options du select account
//    var myregexp = new RegExp('\^'+classe);
//    jQuery.each($('#account_nature_ids option'), function(index, val){
//         if ($(val).text().match(myregexp)) {
//             if (aff==false) {
//                 $(val).attr('disabled', 'disabled');
//             }
//              if (aff==true) {
//                  $(val).attr('disabled', false);
//              }
//         }
//    });
//}
//
//function change_classe(){
// //   _test2.attr("checked") != "undefined" && _test2.attr("checked") == "checked");
// var rec_dep= $('#account_number').val();
//  var myregexp = new RegExp('\^'+ '6');
// var dep = $('#nature_income_outcome_false');
//    if (rec_dep.match(myregexp)) {toggle_classe('7',false); toggle_classe('6', true);}
//    if (!rec_dep.match(myregexp)) {toggle_classe('7',true); toggle_classe('6', false);}
//
//
//}



//jQuery(function() {
//
//change_radio(); // gestion des comptes sélectionnables à l'affichage'
//$('[type=radio]').click(function() {
//    change_radio(); // gestion en cas de changement
//});
//
//});


