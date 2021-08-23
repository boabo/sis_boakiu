<?php
/**
 *@package pXP
 *@file gen-ACTMediosPagoBoleto.php
 *@author  (Ismael Valdivia)
 *@date 20-07-2021 11:43:37
 *@description Clase que recibe los parametros enviados por la vista para mandar a la capa de Modelo
 */
class ACTMediosPagoBoleto extends ACTbase{

  function ModificarMedioPago(){


  $array_datos = array();

  $datos_para_stage = array();

  $cantidad_fp = $this->objParam->getParametro('cantidad_fp');
  $boleto = $this->objParam->getParametro('boleto');
  $fecha_boleto = $this->objParam->getParametro('fecha_boleto');
  $comision_venta = $this->objParam->getParametro('comision_venta');


  $datos_correctos = $this->objParam->arreglo_parametros;

  $datos = array();
  $datos_enviar_stage = array();
  $datos_oficial_stage = array();

  $datos_a_eliminar_stage = json_decode($this->objParam->getParametro('datos_modificados'));
  $cantidad_datos_eliminar = count($datos_a_eliminar_stage);

  $datos_eliminar = array();
  $datos_eliminar_array = array();
  $datos_oficial_stage_eliminar = array();

  for ($j=0; $j < $cantidad_datos_eliminar; $j++) {


    $datos_eliminar += ["id" => $datos_a_eliminar_stage[$j]->accountingPaymentKey];

    array_push($datos_eliminar_array,$datos_eliminar);


    $array_datos = [];
    $datos_eliminar = [];

  }

  /************************Separamos los datos***********************/


  for ($i=1; $i <= $cantidad_fp ; $i++) {

    /*Aqui Estructuramos datos de Inserccion para stage*/
    if (array_key_exists("pay_Code_".$i,$datos_correctos)) {
        $datos_para_stage += ["payCode" => $datos_correctos['pay_Code_'.$i]];
    } else {
        $datos_para_stage += ["payCode" => ""];
    }

    if (array_key_exists("pay_InstanceCode_".$i,$datos_correctos)) {
        $datos_para_stage += ["payInstanceCode" => $datos_correctos['pay_InstanceCode_'.$i]];
    } else {
        $datos_para_stage += ["payInstanceCode" => ""];
    }

    if (array_key_exists("pay_Description_".$i,$datos_correctos)) {
        $datos_para_stage += ["payDescription" => $datos_correctos['pay_Description_'.$i]];
    } else {
        $datos_para_stage += ["payDescription" => ""];
    }

    if (array_key_exists("pay_MethodCode_".$i,$datos_correctos)) {
        $datos_para_stage += ["payMethodCode" => $datos_correctos['pay_MethodCode_'.$i]];
    } else {
        $datos_para_stage += ["payMethodCode" => ""];
    }

    if (array_key_exists("pay_MethodDescription_".$i,$datos_correctos)) {
        $datos_para_stage += ["payMethodDescription" => $datos_correctos['pay_MethodDescription_'.$i]];
    } else {
        $datos_para_stage += ["payMethodDescription" => ""];
    }

    if (array_key_exists("pay_InstanceDescription_".$i,$datos_correctos)) {
        $datos_para_stage += ["payInstanceDescription" => $datos_correctos['pay_InstanceDescription_'.$i]];
    } else {
        $datos_para_stage += ["payInstanceDescription" => ""];
    }

    if (array_key_exists("pay_Currency_".$i,$datos_correctos)) {
        $datos_para_stage += ["payCurrency" => $datos_correctos['pay_Currency_'.$i]];
    } else {
        $datos_para_stage += ["payCurrency" => ""];
    }
    /*****************************************/

    /*Aqui Estructuramos datos de la moneda*/
    if (array_key_exists("id_moneda_".$i,$datos_correctos)) {
        $array_datos += ["id_moneda" => $datos_correctos['id_moneda_'.$i]];
    } else {
        $array_datos += ["id_moneda" => null];
    }
    /*****************************************/

    /*Aqui Estructuramos datos del medio de pago*/
    if (array_key_exists("forma_pago_".$i,$datos_correctos)) {
      $array_datos += ["id_medio_pago" => $datos_correctos['forma_pago_'.$i]];
    } else {
      $array_datos += ["id_medio_pago" => null];
    }
    /*****************************************/

    /*Aqui Estructuramos datos del numero de tarjeta*/
    if (array_key_exists("num_tarjeta_".$i,$datos_correctos)) {
        $array_datos += ["numero_tarjeta" => $datos_correctos['num_tarjeta_'.$i]];
        $datos_para_stage += ["creditCardNumber" => $datos_correctos['num_tarjeta_'.$i]];
    } else {
       $array_datos += ["numero_tarjeta" => null];
       $datos_para_stage += ["creditCardNumber" => ""];
    }
    /*****************************************/

    /*Aqui Estructuramos datos del codigo de tarjeta*/
    if (array_key_exists("cod_tarjeta_".$i,$datos_correctos)) {
        $array_datos += ["codigo_tarjeta" => $datos_correctos['cod_tarjeta_'.$i]];
        $datos_para_stage += ["authorizationCode" => $datos_correctos['cod_tarjeta_'.$i]];
    } else {
        $array_datos += ["codigo_tarjeta" => null];
        $datos_para_stage += ["authorizationCode" => ""];
    }
    /*****************************************/


    /*Aqui Estructuramos datos del MCO*/
    if (array_key_exists("mco_".$i,$datos_correctos)) {
        $array_datos += ["mco" => $datos_correctos['mco_'.$i]];
        $datos_para_stage += ["mco" => $datos_correctos['mco_'.$i]];
    } else {
      $array_datos += ["mco" => null];
        $datos_para_stage += ["mco" => ""];
    }
    /*****************************************/

    /*Aqui Estructuramos datos del MCO*/
    if (array_key_exists("id_auxiliar_".$i,$datos_correctos)) {
        $array_datos += ["id_auxiliar" => $datos_correctos['id_auxiliar_'.$i]];
    } else {
        $array_datos += ["id_auxiliar" => null];
    }
    /*****************************************/

    /*Aqui Estructuramos datos del Anticipo*/
    if (array_key_exists("id_auxiliar_anticipo_".$i,$datos_correctos)) {
        $array_datos += ["id_auxiliar_anticipo" => $datos_correctos['id_auxiliar_anticipo_'.$i]];
    } else {
        $array_datos += ["id_auxiliar_anticipo" => null];
    }
    /*****************************************/

    /*Aqui Estructuramos datos del id_venta*/
    if (array_key_exists("id_venta_".$i,$datos_correctos)) {
        $array_datos += ["id_venta" => $datos_correctos['id_venta_'.$i]];
    } else {
        $array_datos += ["id_venta" => null];
    }
    /*****************************************/

    /*Aqui Estructuramos datos del id_venta*/
    if (array_key_exists("saldo_recibo_".$i,$datos_correctos)) {
        $array_datos += ["saldo_recibo" => $datos_correctos['saldo_recibo_'.$i]];
    } else {
        $array_datos += ["saldo_recibo" => null];
    }
    /*****************************************/

    /*Aqui Estructuramos datos del monto_fp*/
    if (array_key_exists("monto_fp_".$i,$datos_correctos)) {
        $array_datos += ["monto_fp" => $datos_correctos['monto_fp_'.$i]];
        $datos_para_stage += ["payAmount" => $datos_correctos['monto_fp_'.$i]];
    } else {
        $array_datos += ["monto_fp" => null];
        $datos_para_stage += ["payAmount" => ""];
    }
    /*****************************************/



    $datos += ["medio_pago_".$i => [

                                      ($array_datos)
                                    ]
                ];


    array_push($datos_enviar_stage,$datos_para_stage);


    $array_datos = [];
    $datos_para_stage = [];




  }


  //var_dump("aqui llega data",json_encode($datos));exit;

  $this->objParam->addParametro('json_data', json_encode($datos));
  $this->objParam->addParametro('cantidad_fp', $cantidad_fp);
  $this->objParam->addParametro('boleto', $boleto);
  $this->objParam->addParametro('fecha_boleto', $fecha_boleto);
  $this->objParam->addParametro('comision_venta', $comision_venta);
  $this->objParam->addParametro('observaciones', "Modificación Medio de pagos ERP y STAGE");

  $this->objFunc=$this->create('MODMediosPagoBoleto');
  $this->res=$this->objFunc->ModificarMedioPago($this->objParam);

  if($this->res->getTipo()!='EXITO'){
      $this->res->imprimirRespuesta($this->res->generarJson());
      exit;
  } else {

    $data = array("insFP" => json_encode($datos_enviar_stage),
                  "delFP" => json_encode($datos_eliminar_array),
                  "tkt" => $boleto,
                  "issueDate" => $fecha_boleto

                );
    $datosEnvio = json_encode($data);

    $datos = $datosEnvio;


    $envio_dato = $datosEnvio;
    $request =  'http://sms.obairlines.bo/CommissionServices/ServiceComision.svc/ModPayMethod';
    $session = curl_init($request);
    curl_setopt($session, CURLOPT_CUSTOMREQUEST, "POST");
    curl_setopt($session, CURLOPT_POSTFIELDS, $envio_dato);
    curl_setopt($session, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($session, CURLOPT_HTTPHEADER, array(
            'Content-Type: application/json',
            'Content-Length: ' . strlen($envio_dato))
    );

    $result = curl_exec($session);
    curl_close($session);


    $respuesta = json_decode($result);

    $respuesta_final = json_decode($respuesta->ModPayMethodResult);
    $respuesta_estado_servicio = $respuesta_final->State;


    if ($respuesta_estado_servicio == true) {
      $respuesta_base_datos = $respuesta_final->Data;

      if ($respuesta_base_datos) {
        $respuesta_mensaje = $respuesta_base_datos[0]->Result;

        if ($respuesta_mensaje == 1) {
          $respuesta_mensaje = "Medio de Pago modificado Correctamente en ERP y STAGE";
          $error = true;
        } else {
          $error = false;
          $respuesta_mensaje = 'Error en la modificacion DB, No se modificó el medio de Pago en Stage vuelva a intentarlo, si el error Persiste contactarse con Area de Sistemas';
        }

      } else {
        $error = false;
        $respuesta_mensaje = 'Error en el Servicio cod: 2 No se modificó el medio de Pago en Stage vuelva a intentarlo, si el error Persiste contactarse con Area de Sistemas';
      }

    } else {
      $error = false;
      $respuesta_mensaje = 'Error en el servicio cod: 1 No se modificó el medio de Pago en Stage vuelva a intentarlo, si el error Persiste contactarse con Area de Sistemas';
    }

    $send = array(
        "success" => $error, // todo
        "data" => ["mensaje_exito" => $respuesta_mensaje]
    );
    echo json_encode($send);
  }




  }


  function ModificarMedioPagoStage(){

    $array_datos = array();

    $datos_para_stage = array();

    $cantidad_fp = $this->objParam->getParametro('cantidad_fp');
    $boleto = $this->objParam->getParametro('boleto');
    $fecha_boleto = $this->objParam->getParametro('fecha_boleto');
    $monto_venta = $this->objParam->getParametro('total_venta');
    $moneda_venta = $this->objParam->getParametro('moneda_venta');
    $comision_venta = $this->objParam->getParametro('comision_venta');

    $datos_correctos = $this->objParam->arreglo_parametros;

    $datos = array();
    $datos_enviar_stage = array();
    $datos_oficial_stage = array();

    $datos_a_eliminar_stage = json_decode($this->objParam->getParametro('datos_modificados'));
    $cantidad_datos_eliminar = count($datos_a_eliminar_stage);

    $datos_eliminar = array();
    $datos_eliminar_array = array();
    $datos_oficial_stage_eliminar = array();

    for ($j=0; $j < $cantidad_datos_eliminar; $j++) {

      $datos_eliminar += ["id" => $datos_a_eliminar_stage[$j]->accountingPaymentKey];

      array_push($datos_eliminar_array,$datos_eliminar);


      $datos_eliminar = [];

    }

    /************************Separamos los datos***********************/


    for ($i=1; $i <= $cantidad_fp ; $i++) {


      if (array_key_exists("pay_Code_".$i,$datos_correctos)) {

          $datos_para_stage += ["payCode" => $datos_correctos['pay_Code_'.$i]];
      } else {
          $datos_para_stage += ["payCode" => ""];
      }

      if (array_key_exists("pay_InstanceCode_".$i,$datos_correctos)) {
          $datos_para_stage += ["payInstanceCode" => $datos_correctos['pay_InstanceCode_'.$i]];
      } else {
          $datos_para_stage += ["payInstanceCode" => ""];
      }

      if (array_key_exists("pay_Description_".$i,$datos_correctos)) {
          $datos_para_stage += ["payDescription" => $datos_correctos['pay_Description_'.$i]];
      } else {
          $datos_para_stage += ["payDescription" => ""];
      }

      if (array_key_exists("pay_MethodCode_".$i,$datos_correctos)) {
          $datos_para_stage += ["payMethodCode" => $datos_correctos['pay_MethodCode_'.$i]];
      } else {
          $datos_para_stage += ["payMethodCode" => ""];
      }

      if (array_key_exists("pay_MethodDescription_".$i,$datos_correctos)) {
          $datos_para_stage += ["payMethodDescription" => $datos_correctos['pay_MethodDescription_'.$i]];
      } else {
          $datos_para_stage += ["payMethodDescription" => ""];
      }

      if (array_key_exists("pay_InstanceDescription_".$i,$datos_correctos)) {
          $datos_para_stage += ["payInstanceDescription" => $datos_correctos['pay_InstanceDescription_'.$i]];
      } else {
          $datos_para_stage += ["payInstanceDescription" => ""];
      }

      if (array_key_exists("pay_Currency_".$i,$datos_correctos)) {
          $datos_para_stage += ["payCurrency" => $datos_correctos['pay_Currency_'.$i]];
      } else {
          $datos_para_stage += ["payCurrency" => ""];
      }
      /*****************************************/

      /*Aqui Estructuramos datos de la moneda*/
      if (array_key_exists("id_moneda_".$i,$datos_correctos)) {
          $array_datos += ["id_moneda" => $datos_correctos['id_moneda_'.$i]];
      } else {
          $array_datos += ["id_moneda" => null];
      }
      /*****************************************/

      /*Aqui Estructuramos datos del medio de pago*/
      if (array_key_exists("forma_pago_".$i,$datos_correctos)) {
        $array_datos += ["id_medio_pago" => $datos_correctos['forma_pago_'.$i]];
      } else {
        $array_datos += ["id_medio_pago" => null];
      }
      /*****************************************/

      /*Aqui Estructuramos datos del numero de tarjeta*/
      if (array_key_exists("num_tarjeta_".$i,$datos_correctos)) {
          $array_datos += ["numero_tarjeta" => $datos_correctos['num_tarjeta_'.$i]];
          $datos_para_stage += ["creditCardNumber" => $datos_correctos['num_tarjeta_'.$i]];
      } else {
         $array_datos += ["numero_tarjeta" => null];
         $datos_para_stage += ["creditCardNumber" => ""];
      }
      /*****************************************/

      /*Aqui Estructuramos datos del codigo de tarjeta*/
      if (array_key_exists("cod_tarjeta_".$i,$datos_correctos)) {
          $array_datos += ["codigo_tarjeta" => $datos_correctos['cod_tarjeta_'.$i]];
          $datos_para_stage += ["authorizationCode" => $datos_correctos['cod_tarjeta_'.$i]];
      } else {
          $array_datos += ["codigo_tarjeta" => null];
          $datos_para_stage += ["authorizationCode" => ""];
      }
      /*****************************************/


      /*Aqui Estructuramos datos del MCO*/
      if (array_key_exists("mco_".$i,$datos_correctos)) {
          $array_datos += ["mco" => $datos_correctos['mco_'.$i]];
          $datos_para_stage += ["mco" => $datos_correctos['mco_'.$i]];
      } else {
        $array_datos += ["mco" => null];
          $datos_para_stage += ["mco" => ""];
      }
      /*****************************************/

      /*Aqui Estructuramos datos del MCO*/
      if (array_key_exists("id_auxiliar_".$i,$datos_correctos)) {
          $array_datos += ["id_auxiliar" => $datos_correctos['id_auxiliar_'.$i]];
      } else {
          $array_datos += ["id_auxiliar" => null];
      }
      /*****************************************/

      /*Aqui Estructuramos datos del Anticipo*/
      if (array_key_exists("id_auxiliar_anticipo_".$i,$datos_correctos)) {
          $array_datos += ["id_auxiliar_anticipo" => $datos_correctos['id_auxiliar_anticipo_'.$i]];
      } else {
          $array_datos += ["id_auxiliar_anticipo" => null];
      }
      /*****************************************/

      /*Aqui Estructuramos datos del id_venta*/
      if (array_key_exists("id_venta_".$i,$datos_correctos)) {
          $array_datos += ["id_venta" => $datos_correctos['id_venta_'.$i]];
      } else {
          $array_datos += ["id_venta" => null];
      }
      /*****************************************/

      /*Aqui Estructuramos datos del id_venta*/
      if (array_key_exists("saldo_recibo_".$i,$datos_correctos)) {
          $array_datos += ["saldo_recibo" => $datos_correctos['saldo_recibo_'.$i]];
      } else {
          $array_datos += ["saldo_recibo" => null];
      }
      /*****************************************/

      /*Aqui Estructuramos datos del monto_fp*/
      if (array_key_exists("monto_fp_".$i,$datos_correctos)) {
          $array_datos += ["monto_fp" => $datos_correctos['monto_fp_'.$i]];
          $datos_para_stage += ["payAmount" => $datos_correctos['monto_fp_'.$i]];
      } else {
          $array_datos += ["monto_fp" => null];
          $datos_para_stage += ["payAmount" => ""];
      }
      /*****************************************/

      $datos += ["medio_pago_".$i => [

                                        ($array_datos)
                                      ]
                  ];


      array_push($datos_enviar_stage,$datos_para_stage);


      $array_datos = [];

    }



    $this->objParam->addParametro('json_data', json_encode($datos));
    $this->objParam->addParametro('cantidad_fp', $cantidad_fp);
    $this->objParam->addParametro('boleto', $boleto);
    $this->objParam->addParametro('fecha_boleto', $fecha_boleto);
    $this->objParam->addParametro('total_venta', $monto_venta);
    $this->objParam->addParametro('moneda_venta', $moneda_venta);
    $this->objParam->addParametro('comision_venta', $comision_venta);

    $this->objFunc=$this->create('MODMediosPagoBoleto');
    $this->res=$this->objFunc->ControlDatosMediosPAgo($this->objParam);

     if($this->res->getTipo()!='EXITO'){
        $this->res->imprimirRespuesta($this->res->generarJson());
         exit;
    } else {
      $data = array("insFP" => json_encode($datos_enviar_stage),
                    "delFP" => json_encode($datos_eliminar_array),
                    "tkt" => $boleto,
                    "issueDate" => $fecha_boleto

                  );
      $datosEnvio = json_encode($data);

      $datos = $datosEnvio;


      $envio_dato = $datosEnvio;
      $request =  'http://sms.obairlines.bo/CommissionServices/ServiceComision.svc/ModPayMethod';
      $session = curl_init($request);
      curl_setopt($session, CURLOPT_CUSTOMREQUEST, "POST");
      curl_setopt($session, CURLOPT_POSTFIELDS, $envio_dato);
      curl_setopt($session, CURLOPT_RETURNTRANSFER, true);
      curl_setopt($session, CURLOPT_HTTPHEADER, array(
              'Content-Type: application/json',
              'Content-Length: ' . strlen($envio_dato))
      );

      $result = curl_exec($session);
      curl_close($session);


      $respuesta = json_decode($result);

      $respuesta_final = json_decode($respuesta->ModPayMethodResult);
      $respuesta_estado_servicio = $respuesta_final->State;


      if ($respuesta_estado_servicio == true) {
        $respuesta_base_datos = $respuesta_final->Data;

        if ($respuesta_base_datos) {
          $respuesta_mensaje = $respuesta_base_datos[0]->Result;

          if ($respuesta_mensaje == 1) {
            $respuesta_mensaje = "Medio de Pago modificado Correctamente en ERP y STAGE";
            $error = true;
          } else {
            $error = false;
            $respuesta_mensaje = 'Error en la modificacion DB, No se modificó el medio de Pago en Stage vuelva a intentarlo, si el error Persiste contactarse con Area de Sistemas';
          }

        } else {
          $error = false;
          $respuesta_mensaje = 'Error en el Servicio cod: 2 No se modificó el medio de Pago en Stage vuelva a intentarlo, si el error Persiste contactarse con Area de Sistemas';
        }

      } else {
        $error = false;
        $respuesta_mensaje = 'Error en el servicio cod: 1 No se modificó el medio de Pago en Stage vuelva a intentarlo, si el error Persiste contactarse con Area de Sistemas';
      }

      $send = array(
          "success" => $error, // todo
          "data" => ["mensaje_exito" => $respuesta_mensaje]
      );
      echo json_encode($send);
    }

  }

}

?>
