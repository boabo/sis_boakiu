<?php
/**
 *@package pXP
 *@file gen-ACTLiquidacion.php
 *@author  (admin)
 *@date 23-04-2021 01:54:37
 *@description Clase que recibe los parametros enviados por la vista para mandar a la capa de Modelo
HISTORIAL DE MODIFICACIONES:
#ISSUE				FECHA				AUTOR				DESCRIPCION
#0				23-04-2021 01:54:37								FAVIO FIGUEROA (FINGUER)

 */
include_once(dirname(__FILE__).'/../../lib/lib_modelo/ConexionSqlServer.php');

class ACTBoleto extends ACTbase{

    function verifyPermissionForDisabled() {

        $curl = curl_init();
        curl_setopt_array($curl, array(
            CURLOPT_URL => $_SESSION['_PXP_ND_URL'].'/api/boa-stage-nd/Ticket/verifyPermissionForDisabled',
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => '',
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 0,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => 'POST',
            CURLOPT_POSTFIELDS =>'{
                "id_usuario": '.$_SESSION['ss_id_usuario'].'
            }
            ',
            CURLOPT_HTTPHEADER => array(
                'Authorization: ' . $_SESSION['_PXP_ND_TOKEN'],
                'Content-Type: application/json'
            ),
        ));
        $response = curl_exec($curl);

        curl_close($curl);
        echo $response;
        exit;



    }
  function getTicketInformationRecursive() {
        $nro_ticket = $this->objParam->getParametro('nro_ticket');

        // $this->objFunc=$this->create('MODBoleto');
        //
        // $this->res=$this->objFunc->verFacturaErpBoleto($this->objParam);
        //
        // if($this->res->getTipo()!='EXITO'){
        //
        //     $this->res->imprimirRespuesta($this->res->generarJson());
        //     exit;
        // }
        //
        // $datosErp = $this->res->getDatos();



        $array = array();


        $curl = curl_init();

        curl_setopt_array($curl, array(
            CURLOPT_URL => $_SESSION['_PXP_ND_URL'].'/api/boa-stage-nd/Ticket/getTicketInformation',
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => '',
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 0,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => 'POST',
            CURLOPT_POSTFIELDS =>'{
                "ticketNumber": '.$nro_ticket.',
                "recursive": false
            }
            ',
            CURLOPT_HTTPHEADER => array(
                'Authorization: ' . $_SESSION['_PXP_ND_TOKEN'],
                'Content-Type: application/json'
            ),
        ));

        $response = curl_exec($curl);


        curl_close($curl);

        $data_json = json_decode(preg_replace('/[\x00-\x1F\x80-\xFF]/', '', $response), true);



        $fecha_boleto = date('d/m/Y',strtotime($data_json[0]['issueDate']));
        $formato = $data_json[0]['source'];


        $this->objParam->addParametro('fecha_boleto',$fecha_boleto);
        $this->objParam->addParametro('formato',$formato);
        /*Cambiando para mandar la fecha del boleto y hacer conexion a la nueva base de datos*/
        $this->objFunc=$this->create('MODBoleto');

        $this->res=$this->objFunc->verFacturaErpBoleto($this->objParam);

        if($this->res->getTipo()!='EXITO'){

            $this->res->imprimirRespuesta($this->res->generarJson());
            exit;
        }

        $datosErp = $this->res->getDatos();
        /*************************************************************************************/





        /*Aqui aumentando para que recuperemos solo la forma de pago tarjeta*/
        $formas_pago = count($data_json[0]['payment']);

        $forma_pago_cc = array();

        for ($i=0; $i < $formas_pago; $i++) {
            if ($data_json[0]['payment'][$i]['paymentCode'] == 'CC' && $data_json[0]['payment'][$i]['paymentAmount'] > 0) {
              array_push($forma_pago_cc, $data_json[0]['payment'][$i]);
            }
        }
        /********************************************************************/

        /*Aqui aumentando para que recuperemos solo la forma de pago tarjeta desde las modificaciones de STAGE*/
        $formas_pago_modificadas = count($data_json[0]['accountingPayment']);

        $forma_pago_cc_modificadas_stage = array();

        for ($i=0; $i < $formas_pago_modificadas; $i++) {
            if ($data_json[0]['accountingPayment'][$i]['payCode'] == 'CC' && $data_json[0]['accountingPayment'][$i]['payAmount'] > 0) {
              array_push($forma_pago_cc_modificadas_stage, $data_json[0]['accountingPayment'][$i]);
            }
        }
        /*Aqui recuperamos los Id por defecto en las modificaciones de Stage*/
        $id_medio_pago_defecto = array();
        $medios_pago_modificadas_stage = array();

        for ($i=0; $i < $formas_pago_modificadas; $i++) {

          if ($data_json[0]['accountingPayment'][$i]['payAmount'] > 0) {
            $codigo_mp = $data_json[0]['accountingPayment'][$i]['payMethodCode'];
            $codigo_fp = $data_json[0]['accountingPayment'][$i]['payCode'];
            $description_mp = $data_json[0]['accountingPayment'][$i]['payDescription'];

            $this->objParam->addParametro('codigo_medio_pago',$codigo_mp);
            $this->objParam->addParametro('codigo_forma_pago',$codigo_fp);
            $this->objParam->addParametro('description_mp',$description_mp);

            $this->objFunc=$this->create('MODMediosPagoBoleto');
            $this->resMedioPago=$this->objFunc->recuperarMedioPago($this->objParam);

            if($this->resMedioPago->getTipo()!='EXITO'){
                $this->resMedioPago->imprimirRespuesta($this->resMedioPago->generarJson());
                exit;
            }

            $resultado = $this->resMedioPago->getDatos();

            $medio_pago_recuperado = $resultado["medio_pago"];


            array_push($id_medio_pago_defecto, json_decode($medio_pago_recuperado));
            array_push($medios_pago_modificadas_stage, $data_json[0]['accountingPayment'][$i]);
          }


        }

        $id_medio_pago_originales = array();
        $medios_pago_originales_stage = array();
        $formas_pago_originales = count($data_json[0]['payment']);
        /*Aqui para verificar si llega como external payments Ismael Valdivia(22/10/2021)*/
        $es_external = '';
        /*********************************************************************************/

        for ($i=0; $i < $formas_pago_originales; $i++) {
          if ($data_json[0]['payment'][$i]['paymentAmount'] > 0) {
            $codigo_mp = $data_json[0]['payment'][$i]['paymentMethodCode'];
            $codigo_fp = $data_json[0]['payment'][$i]['paymentCode'];
            $description_mp = $data_json[0]['payment'][$i]['paymentDescription'];

            /*Aqui condicion para almacenar si tiene external payment*/
            if ($codigo_fp == 'EXT') {
              $es_external = 'si';
            }

            $this->objParam->addParametro('codigo_medio_pago',$codigo_mp);
            $this->objParam->addParametro('codigo_forma_pago',$codigo_fp);
            $this->objParam->addParametro('description_mp',$description_mp);

            $this->objFunc=$this->create('MODMediosPagoBoleto');
            $this->resMedioPagoOriginal=$this->objFunc->recuperarMedioPago($this->objParam);

            if($this->resMedioPagoOriginal->getTipo()!='EXITO'){
                $this->resMedioPagoOriginal->imprimirRespuesta($this->resMedioPagoOriginal->generarJson());
                exit;
            }

            $resultado_original = $this->resMedioPagoOriginal->getDatos();

            $medio_pago_recuperado_original = $resultado_original["medio_pago"];


            array_push($id_medio_pago_originales, json_decode($medio_pago_recuperado_original));
            array_push($medios_pago_originales_stage, $data_json[0]['payment'][$i]);
          }

        }

        /********************************************************************/

        /*Recuperar el Codigo de Comercio para la Conciliacion*/
        $consiliacion = $data_json[0]['concilliation'];
        $recuperar_codigo_comercio = count($data_json[0]['concilliation']);

        $codigo_comercio_erp = array();

        for ($i=0; $i < $recuperar_codigo_comercio; $i++) {

            if ($data_json[0]['concilliation'][$i]['TerminalNumber'] != NULL && $data_json[0]['concilliation'][$i] && ($data_json[0]['concilliation'][$i]['Formato'] == 'LINKSER')) {

              $nro_comercio = $data_json[0]['concilliation'][$i]['TerminalNumber'];

              $this->objParam->addParametro('nro_comercio',$nro_comercio);

              $this->objFunc=$this->create('MODBoleto');
              $this->resData=$this->objFunc->recuperarNombreEstablecimiento($this->objParam);

              if($this->resData->getTipo()!='EXITO'){

                  $this->resData->imprimirRespuesta($this->resData->generarJson());
                  exit;
              }

              $resultado = $this->resData->getDatos();

              //var_dump("aqi llega el dato",$resultado);

              $establecimiento = ($resultado['establecimiento']);
              //var_dump("aqui resultado",$establecimiento);
              $data_json[0]['concilliation'][$i] += ["NameComercio"=>$establecimiento];
            } elseif ($data_json[0]['concilliation'][$i]['EstablishmentCode'] != NULL && $data_json[0]['concilliation'][$i] && ($data_json[0]['concilliation'][$i]['Formato'] == 'ATC')) {
              $nro_comercio = $data_json[0]['concilliation'][$i]['EstablishmentCode'];

              $this->objParam->addParametro('nro_comercio',$nro_comercio);

              $this->objFunc=$this->create('MODBoleto');
              $this->resData=$this->objFunc->recuperarNombreEstablecimiento($this->objParam);

              if($this->resData->getTipo()!='EXITO'){

                  $this->resData->imprimirRespuesta($this->resData->generarJson());
                  exit;
              }

              $resultado = $this->resData->getDatos();

              //var_dump("aqi llega el dato",$resultado);

              $establecimiento = ($resultado['establecimiento']);
              //var_dump("aqui resultado",$establecimiento);
              $data_json[0]['concilliation'][$i] += ["NameComercio"=>$establecimiento];
            }
        }
        /******************************************************/
        //var_dump("aqui llega datos",$data_json[0]); exit;
        if($data_json != null) {
            $send = array(
                "nro_ticket" =>  $nro_ticket,
                "data" =>  $data_json,
                "data_erp" =>  json_decode($datosErp['mensaje']),
                "forma_pago_tarjeta" => $forma_pago_cc,
                "nombre_comercio_erp"=>$codigo_comercio_erp,
                "forma_pago_modificadas_stage"=>$forma_pago_cc_modificadas_stage,
                "medios_pago_Defecto"=>$id_medio_pago_defecto,
                "medios_pago_Defecto_original"=>$id_medio_pago_originales,
                /*Medios de pago sin monto 0*/
                "medios_pago_originales_stage"=>$medios_pago_originales_stage,
                "medios_pago_modificadas_stage"=>$medios_pago_modificadas_stage,
                "tiene_external"=>$es_external
            );

            echo json_encode($send);
        } else {
            $send = array(
                "error" => false,
                "errorTicket" => true,
                "message" =>  "No se pudo encontrar el ticket solicitado, el mismo puede estar en un estado VOID o no haber sido emitido por AMADEUS",
            );
            echo json_encode($send);

        }


    }

    function getTicketInformationRecursiveForLiqui() {
        $billete = $this->objParam->getParametro('billete');






        $array = array();


        $conexion = new ConexionSqlServer('172.17.110.6', 'SPConnection', 'Passw0rd', 'DBStage');
        $conn = $conexion->conectarSQL();
        //$query_string = "exec DBStage.dbo.fn_getTicketInformation @ticketNumber= 9303852215072 "; // boleto miami 9303852215072
        //$query_string = "Select DBStage.dbo.fn_getTicketInformation('9302404396356') "; // boleto miami 9303852215072
        $query_string = "Select DBStage.dbo.fn_getTicketInformation('$billete') "; // boleto miami 9303852215072

        //$query_string = "select * from AuxBSPVersion";
        //$query_string = utf8_decode("select FlightItinerary from FactTicket where TicketNumber = '9302400056027'");
        @mssql_query('SET CONCAT_NULL_YIELDS_NULL ON');
        @mssql_query('SET ANSI_WARNINGS ON');
        @mssql_query('SET ANSI_PADDING ON');

        $query = @mssql_query($query_string, $conn);
        $row = mssql_fetch_array($query, MSSQL_ASSOC);

        $data_json_string = $row['computed'];
        $data_json = json_decode(preg_replace('/[\x00-\x1F\x80-\xFF]/', '', $data_json_string), true);




        if($data_json != null) {


            /*var_dump($data_json);
        exit;*/
            //var_dump($data_json_string);
            //$data_json = json_decode($data_json_string);
            $data = $data_json[0];


            //todo  cambiar a moneda boliviana cualquier moneda con la que se haya pagado el boleto




            $netAmount = $data["netAmount"];
            $totalAmount = $data["totalAmount"];
            $ticketNumber = $data["ticketNumber"];
            $taxes = $data["taxes"];
            /*var_dump($data["taxes"]);
            exit;*/
            $exento = 0;
            $iva = 0;

            //var_dump($taxes);
            foreach ($taxes as $tax) {
                //var_dump($tax["taxCode"]);
                //var_dump($tax->taxCode);
                //var_dump($tax["taxCode"]);
                //exit;
                if(trim($tax["taxCode"]) !== 'BO' && trim($tax["taxCode"]) !== 'QM' && trim($tax["taxCode"]) !== 'CP') {
                    $exento = $exento + $tax["taxAmount"];
                }

                if(trim($tax["taxCode"]) === 'BO') {
                    $iva = $iva + $tax["taxAmount"]; // solo deberia ser uno pero por si acaso
                }
            }

            array_push($array, array('seleccionado' => 'si',
                'billete' => $ticketNumber,
                'monto' => $totalAmount,
                'itinerary' => $data["itinerary"],
                'passengerName' => $data["passengerName"],
                'currency' => $data["currency"],
                'issueOfficeID' => $data["issueOfficeID"],
                'issueAgencyCode' => $data["issueAgencyCode"], // este es el noiata
                'netAmount' => $netAmount,
                'exento' => $exento,
                'payment' => $data["payment"],
                'taxes' => $data["taxes"],
                'iva' => $iva,
                'iva_contabiliza_no_liquida' => $iva,
                'tiene_nota' => 'no',
                'concepto_para_nota'=> trim($ticketNumber).'/'.trim($data["itinerary"]),
                'foid'=> trim($data["FOID"]),
                'fecha_emision'=> trim($data["issueDate"]),
                'concilliation' => $data["concilliation"],

            ));

            $OriginalTicket = $data["OriginalTicket"];
            //var_dump($OriginalTicket);
            while ($OriginalTicket != '') {

                $exento_hijo = 0;
                $iva_hijo = 0;
                foreach ($OriginalTicket["taxes"] as $tax) {
                    if($OriginalTicket["taxCode"] != 'BO' && $tax["taxCode"] != 'QM' && $tax["taxCode"] != 'CP') {
                        $exento_hijo = $exento_hijo + $tax["taxAmount"];
                    }
                    if(trim($tax["taxCode"]) === 'BO') {
                        $iva_hijo = $iva_hijo + $tax["taxAmount"]; // solo deberia ser uno pero por si acaso
                    }
                }
                array_push($array, array('seleccionado' => 'si',
                    'billete' => $OriginalTicket["ticketNumber"],
                    'monto' => $OriginalTicket["totalAmount"],
                    'itinerary' => $OriginalTicket["itinerary"],
                    'passengerName' => $data["passengerName"],
                    'currency' => $data["currency"],
                    'issueOfficeID' => $data["issueOfficeID"],
                    'issueAgencyCode' => $data["issueAgencyCode"],
                    'netAmount' => $data["netAmount"],
                    'exento' => $exento_hijo,
                    'payment' => $OriginalTicket["payment"],
                    'taxes' => $OriginalTicket["taxes"],
                    'iva' => $iva_hijo,
                    'iva_contabiliza_no_liquida' => $iva_hijo,
                    'tiene_nota' => 'no',
                    'concepto_para_nota'=> trim($OriginalTicket["ticketNumber"]).'/'.trim($OriginalTicket["itinerary"]),
                    'foid'=> trim($OriginalTicket["FOID"]),
                    'fecha_emision'=> trim($OriginalTicket["issueDate"]),
                    'concilliation' => $OriginalTicket["concilliation"]

                ));

                $OriginalTicket = $OriginalTicket["OriginalTicket"];
            }



            $send = array(
                "datos" =>  $array,
                "ticket_information" =>  $data,
                "total" => count($array),
            );

            echo json_encode($send);
        } else {
            $send = array(
                "error" => true,
                "mensaje" =>  "error en el servicio de orlando al querer decodificar el json",
            );
            echo json_encode($send);

        }


    }

    function disabledTicket() {
        $ticketNumber = $this->objParam->getParametro('ticketNumber');
        $motivo = $this->objParam->getParametro('motivo');
        $pnrCode = $this->objParam->getParametro('pnrCode');
        $issueDate = $this->objParam->getParametro('issueDate');

        $this->objFunc=$this->create('sis_ventas_facturacion/MODConsultaBoletos');
        $this->res=$this->objFunc->consultaBoletoInhabilitacion($this->objParam);

        if($this->res->getTipo()!='EXITO'){

			$this->res->imprimirRespuesta($this->res->generarJson());
			exit;
		}

        $res_erp = $this->res->getDatos();
        if($res_erp["inhabilitar"] === 'true' || $res_erp["periodo"] === 'true') {

            //debemos actualizar tambien en el stage


            $curl = curl_init();
            curl_setopt_array($curl, array(
                CURLOPT_URL => $_SESSION['_PXP_ND_URL'].'/api/boa-stage-nd/Ticket/updateTicketStatus',
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_ENCODING => '',
                CURLOPT_MAXREDIRS => 10,
                CURLOPT_TIMEOUT => 0,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                CURLOPT_CUSTOMREQUEST => 'POST',
                CURLOPT_POSTFIELDS =>'{
                    "ticketNumber": '.$ticketNumber.',
                    "pnrCode": "'.$pnrCode.'",
                    "issueDate": "'.$issueDate.'",
                    "motivo": "'.motivo.'"
                }
                ',
                CURLOPT_HTTPHEADER => array(
                    'Authorization: ' . $_SESSION['_PXP_ND_TOKEN'],
                    'Content-Type: application/json'
                ),
            ));
            $response = curl_exec($curl);

            curl_close($curl);
            $data_json = json_decode(preg_replace('/[\x00-\x1F\x80-\xFF]/', '', $response), true);

            $anulado_stage = 'N';
            if($data_json[0]['Result'] == 1) {
                $anulado_stage = 'Y';
            }
            $anulado_erp = 'N';
            if($res_erp["inhabilitar"] === 'true') {
                $anulado_erp = 'Y';
            }

            $send = array(
                "response_from_erp" =>  $res_erp["mensaje"], // todo
                "response_from_stage" =>  $data_json,
                "success" => true,
                "anulado_stage" => $anulado_stage,
                "anulado_erp" => $anulado_erp

            );

            $this->objParam->addParametro('boleto', $ticketNumber);
            $this->objParam->addParametro('motivo', $motivo);
            $this->objParam->addParametro('mensaje_stage', json_encode($data_json));
            $this->objParam->addParametro('mensaje_erp', $res_erp["mensaje"]);
            $this->objParam->addParametro('anulado_stage', $anulado_stage);
            $this->objParam->addParametro('anulado_erp', $anulado_erp);
            $this->objFunc=$this->create('MODBoleto');
            $this->res=$this->objFunc->guardarLogAnularBoleto($this->objParam);
            if ($this->res->getTipo() == 'ERROR') {
                $error = 'error';
                $mensaje_log_completo = "Error al guardar el fila en tabla  " . $this->res->getMensajeTec();
                $send["mensaje_log_completo"] = $mensaje_log_completo;
            }


            echo json_encode($send);

        } else {

            //no se pudo anular por que no existe el boleto o no se ha migrado
            $send = array(
                "response_from_erp" =>  $res_erp["mensaje"], // todo
                "success" => false
            );
            echo json_encode($send);

        }






    }

function testcontroller()
     {
         $ticketNumber = $this->objParam->getParametro('ticketNumber');
         $motivo = $this->objParam->getParametro('motivo');
         $pnrCode = $this->objParam->getParametro('pnrCode');
         $issueDate = $this->objParam->getParametro('issueDate');

         var_dump($ticketNumber);
         exit;

         echo 'llega aca';
     }

    function disabledTicketWithSiat() {


        $ticketNumber = $this->objParam->getParametro('ticketNumber');
        $motivo = $this->objParam->getParametro('motivo');
        $pnrCode = $this->objParam->getParametro('pnrCode');
        $issueDate = $this->objParam->getParametro('issueDate');
        $siatInvoice = $this->objParam->getParametro('siatInvoice');
        $motivoAnulacionSiat = $this->objParam->getParametro('motivoAnulacionSiat');

        $siatInvoiceObject = json_decode($siatInvoice);

        $data = array(
            "cuf" => $siatInvoiceObject->cuf,
            "codigoMotivoAnulacion" => $motivoAnulacionSiat,
            "credenciales" => '{DB163D83-330A-4AF1-8BF5-3B69F8BC3BED}{D9F9AACF-C49B-4E31-B0AA-C8C30AEDC0FD}'
        );


        $jdata = json_encode($data);
        $c = curl_init();
        curl_setopt($c, CURLOPT_URL, 'http://siatboa.boa.bo/FactTKT/Facturacion.svc/AnularFacturaBoleto');
        curl_setopt($c, CURLOPT_POST, true);
        curl_setopt($c, CURLOPT_POSTFIELDS, $jdata);
        curl_setopt($c, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($c, CURLOPT_CONNECTTIMEOUT, 20);
        curl_setopt($c, CURLOPT_HTTPHEADER, array(
            'Content-Type: application/json',
            'Content-Length: ' . strlen($jdata)));

        $ex = curl_exec($c);
        $status = curl_getinfo($c, CURLINFO_HTTP_CODE);
        if (!$status) {
            throw new Exception("No se pudo conectar con el servicio");
        }
        curl_close($c);
        $res = json_decode($ex);


        //http://skbpruebas.cloudapp.net/Fact/Facturacion.svc/AnularFacturaBoleto
        //http://skbpruebas.cloudapp.net/FactTKT/Facturacion.svc/AnularFacturaBoleto

        if($res->AnularFacturaBoletoResult != null && $res->AnularFacturaBoletoResult->Estado) {

            $this->disabledTicket();
            exit;

        } else {

            //no se pudo anular por que no existe el boleto o no se ha migrado
            $send = array(
                "response_from_erp" =>  'FROM SIAT->'.$res->AnularFacturaBoletoResult->Mensaje[0], // todo
                "success" => false
            );
            echo json_encode($send);
            exit;

        }




        exit;







    }

    /*Aumentando para modificar lar tarjetas*/
    function modificarTarjetasErp(){

      $this->objFunc=$this->create('MODBoleto');
      $this->res=$this->objFunc->modificarTarjetasErp($this->objParam);

      if($this->res->getTipo()!='EXITO'){
        $this->res->imprimirRespuesta($this->res->generarJson());
        exit;
      }

      $respuesta_erp = $this->res->getDatos();


      /*Aqui para guardar en el log de datos*/
      $this->objParam->addParametro('observaciones', "Modificacion MP Tarjetas ERP y STAGE");
      $this->objFunc=$this->create('MODBoleto');
      $this->res2=$this->objFunc->logModificaciones($this->objParam);

      if($this->res2->getTipo()!='EXITO'){
        $this->res2->imprimirRespuesta($this->res2->generarJson());
        exit;
      }

        /*Incluyenco la modificacion en el STAGE*/
        $data = array("ticketNumber"=>$this->objParam->getParametro('boleto_a_modificar'),
                      "nroTarjeta"=>$this->objParam->getParametro('num_tarjeta_1'),
                      "codAutorizacion"=>$this->objParam->getParametro('cod_tarjeta_1'),
                      "issueDate"=>$this->objParam->getParametro('issueDate'),
                      /*Aumentando para mandar nuevos campos*/
                      "nroTarjeta_ant"=>$this->objParam->getParametro('nro_tarjeta_1_old'),
                      "codAutorizacion_ant"=>$this->objParam->getParametro('nro_autorizacion_1_old'),
                          /*A solicitud de Orlando se incluira el idErp*/
                        "ErpId" => $respuesta_erp['forma_pago_1']
                    );
        $datosUpdate = json_encode($data);

        $envio_dato = $datosUpdate;

        $request =  'http://sms.obairlines.bo/CommissionServices/ServiceComision.svc/UpdatePaymentMethod';
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

        $respuesta_final = json_decode($respuesta->UpdatePaymentMethodResult);

        $respuesta_estado_servicio = $respuesta_final->State;

        if ($respuesta_estado_servicio == true) {
          $respuesta_base_datos = $respuesta_final->Data;

          if ($respuesta_base_datos) {
            $respuesta_mensaje = $respuesta_base_datos[0]->Result;

            if ($respuesta_mensaje == 1) {
              $respuesta_mensaje = "Medio de Pago modificado Correctamente en STAGE";
              $error = false;
            } else {
              $error = true;
              $respuesta_mensaje = 'Error en la modificacion DB';
            }

          } else {
            $error = true;
            $respuesta_mensaje = 'Error en el Servicio cod: 2';
          }

        } else {
          $error = true;
          $respuesta_mensaje = 'Error en el servicio cod: 1';
        }



        if ($this->objParam->getParametro('num_tarjeta_2') != '' && $this->objParam->getParametro('num_tarjeta_2') != null) {

          $data2 = array("ticketNumber"=>$this->objParam->getParametro('boleto_a_modificar'),
                        "nroTarjeta"=>$this->objParam->getParametro('num_tarjeta_2'),
                        "codAutorizacion"=>$this->objParam->getParametro('cod_tarjeta_2'),
                        "issueDate"=>$this->objParam->getParametro('issueDate'),
                        /*Aumentando para mandar nuevos campos*/
                        "nroTarjeta_ant"=>$this->objParam->getParametro('nro_tarjeta_2_old'),
                        "codAutorizacion_ant"=>$this->objParam->getParametro('nro_autorizacion_2_old'),
                            /*A solicitud de Orlando se incluira el idErp*/
                        "ErpId" => $respuesta_erp['forma_pago_2']
                      );
          $datosUpdate2 = json_encode($data2);

          $envio_dato2 = $datosUpdate2;

          $request2 =  'http://sms.obairlines.bo/CommissionServices/ServiceComision.svc/UpdatePaymentMethod';
          $session2 = curl_init($request2);
          curl_setopt($session2, CURLOPT_CUSTOMREQUEST, "POST");
          curl_setopt($session2, CURLOPT_POSTFIELDS, $envio_dato2);
          curl_setopt($session2, CURLOPT_RETURNTRANSFER, true);
          curl_setopt($session2, CURLOPT_HTTPHEADER, array(
                  'Content-Type: application/json',
                  'Content-Length: ' . strlen($envio_dato2))
          );

          $result2 = curl_exec($session2);
          curl_close($session2);

          $respuesta2 = json_decode($result2);

          $respuesta_final2 = json_decode($respuesta2->UpdatePaymentMethodResult);

          $respuesta_estado_servicio2 = $respuesta_final2->State;

          if ($respuesta_estado_servicio2 == true) {
            $respuesta_base_datos2 = $respuesta_final2->Data;

            if ($respuesta_base_datos2) {
              $respuesta_mensaje2 = $respuesta_base_datos2[0]->Result;

              if ($respuesta_mensaje2 == 1) {
                $respuesta_mensaje2 = "Medios de Pago modificados Correctamente en STAGE";
                $error2 = false;
              } else {
                $error2 = true;
                $respuesta_mensaje2 = 'Error en la modificacion DB';
              }

            } else {
              $error2 = true;
              $respuesta_mensaje2 = 'Error en el Servicio cod: 2';
            }

          } else {
            $error2 = true;
            $respuesta_mensaje2 = 'Error en el servicio cod: 1';
          }

          if (($error == false) && ($error2 == false)) {


            $send = array(
                "error" =>  $error, // todo
                "data" => ["mensaje_exito" => $respuesta_mensaje2]
            );
            echo json_encode($send);

          } else {

            $send = array(
                "error" =>  $error, // todo
                "data" => ["mensaje_exito" => $respuesta_mensaje2]
            );
            echo json_encode($send);

          }

        } else {


          $send = array(
              "error" =>  $error, // todo
              "data" => ["mensaje_exito" => "Datos Modificados Correctamente en ERP y Stage"]
          );
          echo json_encode($send);
        }

        /****************************************/




  	}

    function modificarTarjetaStage(){

      $this->objParam->addParametro('nro_boleto', $this->objParam->getParametro('boleto_a_modificar'));
      $this->objParam->addParametro('nro_tarjeta_1_old', $this->objParam->getParametro('nro_tarjeta_1_old'));
      $this->objParam->addParametro('nro_autorizacion_1_old', $this->objParam->getParametro('nro_autorizacion_1_old'));
      $this->objParam->addParametro('nro_tarjeta_2_old', $this->objParam->getParametro('nro_tarjeta_2_old'));
      $this->objParam->addParametro('nro_autorizacion_2_old', $this->objParam->getParametro('nro_autorizacion_2_old'));
      $this->objParam->addParametro('num_tarjeta_1', $this->objParam->getParametro('num_tarjeta_1'));
      $this->objParam->addParametro('cod_tarjeta_1', $this->objParam->getParametro('cod_tarjeta_1'));
      $this->objParam->addParametro('num_tarjeta_2', $this->objParam->getParametro('num_tarjeta_2'));
      $this->objParam->addParametro('cod_tarjeta_2', $this->objParam->getParametro('cod_tarjeta_2'));
      $this->objParam->addParametro('observaciones', "Modificacion MP Tarjetas Solo Stage");
      $this->objFunc=$this->create('MODBoleto');
      $this->res2=$this->objFunc->logModificaciones($this->objParam);

      if($this->res2->getTipo()!='EXITO'){
        $this->res2->imprimirRespuesta($this->res2->generarJson());
        exit;
      }


      $data = array("ticketNumber"=>$this->objParam->getParametro('boleto_a_modificar'),
                    "nroTarjeta"=>$this->objParam->getParametro('num_tarjeta_1'),
                    "codAutorizacion"=>$this->objParam->getParametro('cod_tarjeta_1'),
                    "issueDate"=>$this->objParam->getParametro('issueDate'),
                    /*Aumentando para mandar nuevos campos*/
                    "nroTarjeta_ant"=>$this->objParam->getParametro('nro_tarjeta_1_old'),
                    "codAutorizacion_ant"=>$this->objParam->getParametro('nro_autorizacion_1_old'),
                    /*A solicitud de Orlando se incluira el idErp*/
                    "ErpId" => null
                  );

      $datosUpdate = json_encode($data);

      $envio_dato = $datosUpdate;

      $request =  'http://sms.obairlines.bo/CommissionServices/ServiceComision.svc/UpdatePaymentMethod';
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

      $respuesta_final = json_decode($respuesta->UpdatePaymentMethodResult);

      $respuesta_estado_servicio = $respuesta_final->State;

      if ($respuesta_estado_servicio == true) {
        $respuesta_base_datos = $respuesta_final->Data;

        if ($respuesta_base_datos) {
          $respuesta_mensaje = $respuesta_base_datos[0]->Result;

          if ($respuesta_mensaje == 1) {
            $respuesta_mensaje = "Medio de Pago modificado Correctamente en STAGE";
            $error = false;
          } else {
            $error = true;
            $respuesta_mensaje = 'Error en la modificacion DB';
          }

        } else {
          $error = true;
          $respuesta_mensaje = 'Error en el Servicio cod: 2';
        }

      } else {
        $error = true;
        $respuesta_mensaje = 'Error en el servicio cod: 1';
      }

      if ($this->objParam->getParametro('num_tarjeta_2') != '' && $this->objParam->getParametro('num_tarjeta_2') != null) {

        $data2 = array("ticketNumber"=>$this->objParam->getParametro('boleto_a_modificar'),
                      "nroTarjeta"=>$this->objParam->getParametro('num_tarjeta_2'),
                      "codAutorizacion"=>$this->objParam->getParametro('cod_tarjeta_2'),
                      "issueDate"=>$this->objParam->getParametro('issueDate'),
                      /*Aumentando para mandar nuevos campos*/
                      "nroTarjeta_ant"=>$this->objParam->getParametro('nro_tarjeta_2_old'),
                      "codAutorizacion_ant"=>$this->objParam->getParametro('nro_autorizacion_2_old'),
                      "ErpId" => null
                    );
        $datosUpdate2 = json_encode($data2);

        $envio_dato2 = $datosUpdate2;

        $request2 =  'http://sms.obairlines.bo/CommissionServices/ServiceComision.svc/UpdatePaymentMethod';
        $session2 = curl_init($request2);
        curl_setopt($session2, CURLOPT_CUSTOMREQUEST, "POST");
        curl_setopt($session2, CURLOPT_POSTFIELDS, $envio_dato2);
        curl_setopt($session2, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($session2, CURLOPT_HTTPHEADER, array(
                'Content-Type: application/json',
                'Content-Length: ' . strlen($envio_dato2))
        );

        $result2 = curl_exec($session2);
        curl_close($session2);

        $respuesta2 = json_decode($result2);

        $respuesta_final2 = json_decode($respuesta2->UpdatePaymentMethodResult);

        $respuesta_estado_servicio2 = $respuesta_final2->State;

        if ($respuesta_estado_servicio2 == true) {
          $respuesta_base_datos2 = $respuesta_final2->Data;

          if ($respuesta_base_datos2) {
            $respuesta_mensaje2 = $respuesta_base_datos2[0]->Result;

            if ($respuesta_mensaje2 == 1) {
              $respuesta_mensaje2 = "Medios de Pago modificados Correctamente en STAGE";
              $error2 = false;
            } else {
              $error2 = true;
              $respuesta_mensaje2 = 'Error en la modificacion DB';
            }

          } else {
            $error2 = true;
            $respuesta_mensaje2 = 'Error en el Servicio cod: 2';
          }

        } else {
          $error2 = true;
          $respuesta_mensaje2 = 'Error en el servicio cod: 1';
        }

        if (($error == false) && ($error2 == false)) {

          $send = array(
              "error" =>  $error, // todo
              "data" => ["mensaje_exito" => $respuesta_mensaje2]
          );
          echo json_encode($send);

        } else {

          $send = array(
              "error" =>  $error, // todo
              "data" => ["mensaje_exito" => $respuesta_mensaje2]
          );
          echo json_encode($send);

        }

      } else {

        $send = array(
            "error" =>  $error, // todo
            "data" => ["mensaje_exito" => $respuesta_mensaje]
        );
        echo json_encode($send);

      }

    /****************************************/
  }

  function GetTicketData(){

    $data = array("pnr"=>$this->objParam->getParametro('pnr'),
                  "issueDate"=>$this->objParam->getParametro('issueDate'),
                  "nroTarjeta"=>$this->objParam->getParametro('nroTarjeta'),
                  "codAutorizacion"=>$this->objParam->getParametro('codAutorizacion'),
                  "tyCons"=>$this->objParam->getParametro('tyCons'),
                );
    $datosUpdate = json_encode($data);

    $envio_dato = $datosUpdate;
    //var_dump("aqui llega la respuesta",$envio_dato);
    $request =  'http://sms.obairlines.bo/CommissionServices/ServiceComision.svc/GetTicketData';
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


    $respuesta_final = json_decode($respuesta->GetTicketDataResult);

    $respuesta_estado_servicio = $respuesta_final->State;

    if ($respuesta_estado_servicio == true) {
      $respuesta_base_datos = $respuesta_final->Data;
      $respuesta_envio = json_encode($respuesta_base_datos);
      echo $respuesta_envio;
    }




  }

  function getConcilliation() {

    $nro_ticket = $this->objParam->getParametro('nro_ticket');

    if ($nro_ticket != '' && $nro_ticket != null  && $nro_ticket != 'null') {
      $array = array();
      $curl = curl_init();
      //var_dump("aqui llega el json devuelto",$nro_ticket);exit;
      curl_setopt_array($curl, array(
          CURLOPT_URL => $_SESSION['_PXP_ND_URL'].'/api/boa-stage-nd/Ticket/getConciliation',
          CURLOPT_RETURNTRANSFER => true,
          CURLOPT_ENCODING => '',
          CURLOPT_MAXREDIRS => 10,
          CURLOPT_TIMEOUT => 0,
          CURLOPT_FOLLOWLOCATION => true,
          CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
          CURLOPT_CUSTOMREQUEST => 'POST',
          CURLOPT_POSTFIELDS =>'{
              "ticketNumber": '.$nro_ticket.',
              "recursive": false
          }
          ',
          CURLOPT_HTTPHEADER => array(
              'Authorization: ' . $_SESSION['_PXP_ND_TOKEN'],
              'Content-Type: application/json'
          ),
      ));

      $response = curl_exec($curl);


      curl_close($curl);

      $data_json = json_decode(preg_replace('/[\x00-\x1F\x80-\xFF]/', '', $response), true);


      /*Recuperar el Codigo de Comercio para la Conciliacion*/
      $consiliacion = $data_json;
      $recuperar_codigo_comercio = count($data_json);

      $codigo_comercio_erp = array();

      for ($i=0; $i < $recuperar_codigo_comercio; $i++) {

          if ($data_json[$i]['TerminalNumber'] != NULL && $data_json[$i] && ($data_json[$i]['Formato'] == 'LINKSER')) {

            $nro_comercio = $data_json[$i]['TerminalNumber'];

            $this->objParam->addParametro('nro_comercio',$nro_comercio);

            $this->objFunc=$this->create('MODBoleto');
            $this->resData=$this->objFunc->recuperarNombreEstablecimiento($this->objParam);

            if($this->resData->getTipo()!='EXITO'){

                $this->resData->imprimirRespuesta($this->resData->generarJson());
                exit;
            }

            $resultado = $this->resData->getDatos();

            //var_dump("aqi llega el dato",$resultado);

            $establecimiento = ($resultado['establecimiento']);
            //var_dump("aqui resultado",$establecimiento);
            $data_json[$i] += ["NameComercio"=>$establecimiento];
          } else { //if ($data_json[$i] && ($data_json[$i]['Formato'] == 'ATC')) {
            $nro_comercio = $data_json[$i]['EstablishmentCode'];

            if ($nro_comercio != NULL) {
              $this->objParam->addParametro('nro_comercio',$nro_comercio);

              $this->objFunc=$this->create('MODBoleto');
              $this->resData=$this->objFunc->recuperarNombreEstablecimiento($this->objParam);

              if($this->resData->getTipo()!='EXITO'){

                  $this->resData->imprimirRespuesta($this->resData->generarJson());
                  exit;
              }

              $resultado = $this->resData->getDatos();

              //var_dump("aqi llega el dato",$resultado);

              $establecimiento = ($resultado['establecimiento']);
              //var_dump("aqui resultado",$establecimiento);
              $data_json[$i] += ["NameComercio"=>$establecimiento];
            } else {
              $data_json = Null;
            }

          }
      }
      /******************************************************/

      if($data_json != null) {
          $send = array(
              "conciliacion_oficial" =>  $data_json
          );

          echo json_encode($send);
      } else {
          $send = array(
              "conciliacion_oficial" => null
          );
          echo json_encode($send);

      }
    } else {
      $send = array(
          "conciliacion_oficial" => null
      );
      echo json_encode($send);
    }


  }
}

?>
