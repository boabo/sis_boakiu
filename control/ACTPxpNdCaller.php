<?php
/**
 *@package pXP
 *@file gen-ACTLiquidacion.php
 *@author  (Favio Figueroa)
 *@date 23-04-2021 01:54:37
 *@description Clase que recibe los parametros enviados por la vista para mandar a la capa de Modelo
HISTORIAL DE MODIFICACIONES:
#ISSUE				FECHA				AUTOR				DESCRIPCION
#0				23-04-2021 01:54:37								FAVIO FIGUEROA (FINGUER)

 */

class ACTPxpNdCaller extends ACTbase{


    function doRequest() {

        $controller = $this->objParam->getParametro('controller');
        $method = $this->objParam->getParametro('method');
        $params = $this->objParam->getParametro('params');

        $curl = curl_init();
        curl_setopt_array($curl, array(
            CURLOPT_URL => $_SESSION['_PXP_ND_URL'].'/api/'.$controller,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => '',
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 0,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_POSTFIELDS => $params,
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
