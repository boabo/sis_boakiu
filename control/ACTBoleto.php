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



        $this->objFunc=$this->create('MODBoleto');

        $this->res=$this->objFunc->verFacturaErpBoleto($this->objParam);

        if($this->res->getTipo()!='EXITO'){

            $this->res->imprimirRespuesta($this->res->generarJson());
            exit;
        }

        $datosErp = $this->res->getDatos();
      


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


        if($data_json != null) {

            $send = array(
                "nro_ticket" =>  $nro_ticket,
                "data" =>  $data_json,
                "data_erp" =>  json_decode($datosErp['mensaje']),
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

}

?>