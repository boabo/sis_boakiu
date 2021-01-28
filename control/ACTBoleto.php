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
    
    function getTicketInformationRecursive() {
        $nro_ticket = $this->objParam->getParametro('nro_ticket');
        $array = array();


        $conexion = new ConexionSqlServer('172.17.110.6', 'SPConnection', 'Passw0rd', 'DBStage');
        $conn = $conexion->conectarSQL();

        $query_string = "Select DBStage.dbo.fn_getTicketInformation('$nro_ticket') "; // boleto miami 9303852215072

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

            $send = array(
                "nro_ticket" =>  $nro_ticket,
                "data" =>  $data_json,
            );

            echo json_encode($send);
        } else {
            $send = array(
                "error" => true,
                "message" =>  "No se pudo encontrar el ticket solicitado",
            );
            echo json_encode($send);

        }


    }

}

?>