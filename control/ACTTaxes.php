<?php
/**
 *@package pXP
 *@file gen-ACTLiquidacion.php
 *@author  (admin)
 *@date 18-03-2022 01:54:37
 *@description Clase que recibe los parametros enviados por la vista para mandar a la capa de Modelo
HISTORIAL DE MODIFICACIONES:
#ISSUE				FECHA				AUTOR				DESCRIPCION
#0				18-03-2022 01:54:37								FAVIO FIGUEROA (FINGUER)

 */
include_once(dirname(__FILE__).'/../../lib/lib_modelo/ConexionSqlServer.php');

class ACTTaxes extends ACTbase{

    function getTaxCode() {

        $curl = curl_init();
        curl_setopt_array($curl, array(
            CURLOPT_URL => $_SESSION['_PXP_ND_URL'].'/api/boa-stage-nd/Ticket/getTaxCode',
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
    function updateTaxes() {

        $taxKey = $this->objParam->getParametro('taxKey');
        $taxCode = $this->objParam->getParametro('taxCode');

        $curl = curl_init();
        curl_setopt_array($curl, array(
            CURLOPT_URL => $_SESSION['_PXP_ND_URL'].'/api/boa-stage-nd/Ticket/updateTaxes',
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => '',
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 0,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => 'POST',
            CURLOPT_POSTFIELDS =>'{
                "taxKey": '.$taxKey.',
                "taxCode": "'.$taxCode.'"
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
}

?>
