// 
//  jQuery Validate example script
//
//  Prepared by David Cochran
//  
//  Free for your use -- No warranties, no guarantees!
//
function actualizarLog(){
  var dateFrom = $("#from").datepicker('getDate');
    var tiempoInicio =dateFrom.getFullYear()+"-"+ ((dateFrom.getMonth()+1) < 10 ? "0"+(dateFrom.getMonth()+1) : (dateFrom.getMonth()+1)) +"-"+((dateFrom.getDate()) < 10 ? "0"+(dateFrom.getDate()) : (dateFrom.getDate()))+" "+$("#tp1").val();
    var dateTo = $("#to").datepicker('getDate');
    var tiempoFin =dateTo.getFullYear()+"-"+ ((dateTo.getMonth()+1) < 10 ? "0"+(dateTo.getMonth()+1) : (dateTo.getMonth()+1)) +"-"+((dateTo.getDate()) < 10 ? "0"+(dateTo.getDate()) : (dateTo.getDate()))+" "+$("#tp2").val();
    var user = $("#select01").val();

      $.ajax({
          url: "ajax_log",
          data: {'from':tiempoInicio,'to':tiempoFin,usuario:user},
          type: "POST",
          success: function(data){
            $("#tabla").html(data);
          },
          error: function(error){
            alert("ERROR");
            alert(error);
            console.log(error);
          }
      });
      return false; // prevents normal behaviour
}
function actualizarGaleria(){
  var dateFrom = $("#from").datepicker('getDate');
  var tiempoInicio =dateFrom.getFullYear()+"-"+ ((dateFrom.getMonth()+1) < 10 ? "0"+(dateFrom.getMonth()+1) : (dateFrom.getMonth()+1)) +"-"+((dateFrom.getDate()) < 10 ? "0"+(dateFrom.getDate()) : (dateFrom.getDate()))+" "+$("#tp1").val();
  var dateTo = $("#to").datepicker('getDate');
  var tiempoFin =dateTo.getFullYear()+"-"+ ((dateTo.getMonth()+1) < 10 ? "0"+(dateTo.getMonth()+1) : (dateTo.getMonth()+1)) +"-"+((dateTo.getDate()) < 10 ? "0"+(dateTo.getDate()) : (dateTo.getDate()))+" "+$("#tp2").val();
  var camara = $("#select09").val();
  var deteccion_movimiento= $("#deteccion_movimiento").val();
 
   
    $.ajax({
        url: "ajax_galeria",
        data: {'from':tiempoInicio,'to':tiempoFin,camara:camara,deteccion_movimiento:deteccion_movimiento},
        type: "POST",
        success: function(data){
          $("#tabla").html(data);
        },
        error: function(error){
          alert("ERROR");
        }
    });
    return false; // prevents normal behaviour
}
function actualizarImagen(direccion){
    $(".velo").fadeIn("fast");
    $.ajax({
        url: "/principal/mover_camara",
        data: {'direccion':direccion,id_camara:$("#id_camara").val()},
        type: "POST",
        success: function(data){
          $("#fotoNueva").html(data);
          $(".velo").fadeOut("fast");
        },
        error: function(error){
          alert("Error cambiando la imagen");
        }
    });
    return false; // prevents normal behaviour
}
function actualizarFtp(){
    $(".velo").fadeIn("fast");
    $.ajax({
        url: "/principal/actualizar_ftp",
        data: {id_camara:$("#id_camara").val()},
        type: "POST",
        success: function(data){
          alert(" LISTO ");
          console.log(data);
        },
        error: function(error){
          alert("Error cambiando la imagen");
        }
    });
    return false; // prevents normal behaviour
}
function obtenerFoto(){
    $(".velo").fadeIn("fast");
    $.ajax({
        url: "/principal/mover_camara",
        data: {id_camara:$("#id_camara").val()},
        type: "POST",
        success: function(data){
          $("#fotoNueva").html(data);
          $(".velo").fadeOut("fast");
        },
        error: function(error){
          alert("Error cambiando la imagen");
        }
    });
    return false; // prevents normal behaviour
}
$(document).ajaxSend(function(e, xhr, options) {
  var token = $("meta[name='csrf-token']").attr("content");
  xhr.setRequestHeader("X-CSRF-Token", token);
});
$(document).ready(function(){

  // Validate
  // http://bassistance.de/jquery-plugins/jquery-plugin-validation/
  // http://docs.jquery.com/Plugins/Validation/
  // http://docs.jquery.com/Plugins/Validation/validate#toptions
  
    $('#signin').validate({
      rules: {
       
        "usuario_clave": {
          minlength: 6,
          required: true
        },

         "usuario_email": {
          email: true,
          required: true
        },
    
     
      },

      messages:{
        "usuario_clave":{
        required:"Introduzca su contraseña",
        minlength:"La contraseña debe tener al menos 6 caracteres"},
        "usuario_email":{
        required:"Introduzca su email"},
        
      },
    
      highlight: function(label) {
        $(label).closest('.control-group').addClass('error');
      },
      success: function(label) {
        label
          .text('').addClass('valid')
          .closest('.control-group').addClass('success');
      }
    });


    $('#signup').validate({
        rules: {
         
          "contrasena2": {
            minlength: 6,
            required: true
          },

          "nombre": {
            minlength: 3,
            required: true
          },
    
          "contrasena3": {
            required: true,
            equalTo: "#contrasena2"

          },

          "email": {
            email:true,
            required: true
          },

       
        },

        messages:{
        "contrasena2":{
        required:"Introduzca su contraseña",
        minlength:"Debe tener al menos 6 caracteres"},
        "nombre":{
        required:"Introduzca su nombre",
        minlength:"Debe tener al menos 3 caracteres"},
        "contrasena3":{
        required:"Introduzca la confirmación de su contraseña",
        equalTo:"La contraseña no coincide"},
        "email":{
        required:"Introduzca su email"},
        
      },
      
        highlight: function(label) {
        $(label).closest('.control-group').addClass('error');
        },
        success: function(label) {
          label
            .text('').addClass('valid')
            .closest('.control-group').addClass('success');
        }
     });

   

   $('#nuevaCamara-form').validate({
        rules: {
         
          "dirIP": {
            required: true
          },

           "numPuerto": {
            required: true
          },

          "nombre": {
            minlength: 4,
            required: true
          },

          "usuario": {
            minlength: 3,
            required: true
          },

          "contrasena": {
            minlength: 3,
            required: true
          },

          "coordenada_x": {
            
            required: true
          },

          "coordenada_y": {
            
            required: true
          },
       
        },

        messages:{
        "dirIP":{
        required:"Indique la dirección IP"},
        "numPuerto":{
        required:"Indique el número de puerto"},
        "nombre":{
        required:"Indique el nombre de la cámara",
        minlength:"El nombre de la cámara debe tener al menos 6 caracteres"},
        "usuario":{
        required:"Introduzca el nombre de usuario",
        minlength:"El usuario debe tener al menos 6 caracteres"},
        "contrasena":{
        required:"Introduzca su contraseña",
        minlength:"La contraseña debe tener al menos 6 caracteres"},
        "coordenada_x":{
        required:""},
        "coordenada_y":{
        required:""},
        
        },
      
        highlight: function(label) {
        $(label).closest('.control-group').addClass('error');
        },
        success: function(label) {
          label
            .text('').addClass('valid')
            .closest('.control-group').addClass('success');
        }
     });

  


  $('#contrasena2').keyup(function(){
        $('#result').html(checkStrength($('#contrasena2').val()))
    })  
 
    function checkStrength(contrasena2){
 
    //initial strength
    var strength = 0
  
    //length is ok, lets continue.
 
    //if length is 8 characters or more, increase strength value
    if (contrasena2.length > 7) strength += 1
 
    //if contrasena2 contains both lower and uppercase characters, increase strength value
    if (contrasena2.match(/([a-z].*[A-Z])|([A-Z].*[a-z])/))  strength += 1
 
    //if it has numbers and characters, increase strength value
    if (contrasena2.match(/([a-zA-Z])/) && contrasena2.match(/([0-9])/))  strength += 1 
 
    //if it has one special character, increase strength value
    if (contrasena2.match(/([!,%,&,@,#,$,^,*,?,_,~])/))  strength += 1
 
    //if it has two special characters, increase strength value
    if (contrasena2.match(/(.*[!,%,&,@,#,$,^,*,?,_,~].*[!,",%,&,@,#,$,^,*,?,_,~])/)) strength += 1
 
    //now we have calculated strength value, we can return messages
 
    //if value is less than 2
    if (strength < 2 ) {
        $('#result').removeClass()
        $('#result').addClass('debil')
        return 'Débil'
    } else if (strength == 2 ) {
        $('#result').removeClass()
        $('#result').addClass('buena')
        return 'Buena'
    } else {
        $('#result').removeClass()
        $('#result').addClass('fuerte')
        return 'Fuerte'
    }
}

  $(document).on("change","#select01",function(){
    return  actualizarLog();
  });

  $(document).on("submit","#buscarLogForm",function(){
    return actualizarLog();
  });

  $(document).on("change","#select09",function(){
    return  actualizarGaleria();
  });
  $(document).on("change","#deteccion_movimiento",function(){
    return  actualizarGaleria();
  });
  $(document).on("submit","#buscarGaleria2",function(){
    
    return  actualizarGaleria();
  });
  $(document).on("click",".botonesDireccion",function(){
    return  actualizarImagen($(this).attr("id"));
  });
  $(document).on("click","#obtenerFoto",function(){
    return  obtenerFoto();
  });
  $(document).on("click","#actualizarFtp",function(){
    return  actualizarFtp();
  });
  $(document).on("change","#selectMarca",function(){
    var marca = $(this).val();
    $.ajax({
      url: "ajax_modelo_camara",
      type:"POST",
      data: {marca:marca},
      success: function(data){
        $("#formModelo").html(data);
      }

    });
  });
    
}); // end document.ready
;
